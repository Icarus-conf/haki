import { Logger, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { InjectRepository } from '@nestjs/typeorm';
import {
  ConnectedSocket,
  MessageBody,
  OnGatewayConnection,
  OnGatewayDisconnect,
  SubscribeMessage,
  WebSocketGateway,
  WebSocketServer,
} from '@nestjs/websockets';
import { promises as fs } from 'fs';
import * as path from 'path';
import { Server, Socket } from 'socket.io';
import { IsNull, LessThanOrEqual, Not, Repository } from 'typeorm';
import { Message } from './chat/entities/message.entity';
import { Reaction } from './chat/entities/reaction.entity';
import { Group } from './groups/entities/group.entity';
import { AuthService } from './auth/auth.service';
import { GroupRead } from './platform/entities';
import { PushKind, PushService } from './push/push.service';
import { Friendship } from './users/entities/friendship.entity';
import { User } from './users/entities/user.entity';
import { UsersService } from './users/users.service';

@WebSocketGateway({
  cors: {
    origin: '*',
  },
})
export class ChatGateway implements OnGatewayConnection, OnGatewayDisconnect, OnModuleInit, OnModuleDestroy {
  @WebSocketServer()
  server: Server;

  // userId -> number of open sockets, so closing one device doesn't mark the user offline
  private onlineUsers = new Map<number, number>();
  private sendQueues = new Map<number, Promise<void>>();
  private readonly logger = new Logger(ChatGateway.name);
  private releaseTimer?: NodeJS.Timeout;
  // userId -> sockets whose app is on screen. A backgrounded iPhone keeps its socket for a
  // while, so "connected" isn't enough to skip a push; the app reports when it's in front.
  private foreground = new Map<number, Set<string>>();

  constructor(
    private jwtService: JwtService,
    @InjectRepository(Message)
    private readonly messageRepository: Repository<Message>,
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
    @InjectRepository(Reaction)
    private readonly reactionRepository: Repository<Reaction>,
    @InjectRepository(Friendship)
    private readonly friendshipRepository: Repository<Friendship>,
    @InjectRepository(Group)
    private readonly groupRepository: Repository<Group>,
    private readonly usersService: UsersService,
    private readonly push: PushService,
    private readonly auth: AuthService,
  ) { }

  // ===== SPAM GUARD =====
  // ponytail: in-memory sliding window per user on one API instance; Redis if this scales out
  static readonly RATE = { max: 30, windowMs: 10_000 };
  private sent = new Map<number, number[]>();
  /** userId -> times the limit was hit in the last day, for the dashboard's spam signals. */
  readonly rateHits = new Map<number, number[]>();

  /** True when this user may send another message now. */
  private allowSend(userId: number) {
    const now = Date.now();
    const recent = (this.sent.get(userId) ?? []).filter(t => now - t < ChatGateway.RATE.windowMs);
    if (recent.length >= ChatGateway.RATE.max) {
      const hits = (this.rateHits.get(userId) ?? []).filter(t => now - t < 86_400_000);
      this.rateHits.set(userId, [...hits, now]);
      this.sent.set(userId, recent);
      return false;
    }
    this.sent.set(userId, [...recent, now]);
    return true;
  }

  private setForeground(userId: number, socketId: string, on: boolean) {
    const set = this.foreground.get(userId) ?? new Set<string>();
    on ? set.add(socketId) : set.delete(socketId);
    if (set.size) this.foreground.set(userId, set);
    else this.foreground.delete(userId);
  }

  /** Push to everyone in [userIds] who doesn't have Haki open right now. */
  private pushAway(userIds: number[], kind: PushKind, chat: Record<string, number>) {
    const away = [...new Set(userIds)].filter(id => !this.foreground.has(id));
    this.push.notify(away, kind, chat).catch(e => this.logger.warn(`[Push] ${e.message}`));
  }

  @SubscribeMessage('app_state')
  handleAppState(@MessageBody() data: { foreground: boolean }, @ConnectedSocket() client: Socket) {
    const userPayload = client.data.user;
    if (userPayload) this.setForeground(parseInt(userPayload.sub), client.id, !!data?.foreground);
  }

  private toLocalISO(date: Date | null | undefined): string | null {
    if (!date) return null;
    // Return proper ISO 8601 string with 'Z' UTC indicator
    return date.toISOString();
  }

  private serializeReactions(reactions: Reaction[] | undefined) {
    return (reactions || []).map(r => ({
      id: r.id,
      emoji: r.emoji,
      userId: r.user?.id,
      username: r.user?.username,
    }));
  }

  /** One wire format for history, live messages and shared media. */
  private serializeMessage(m: Message, extra: Record<string, any> = {}) {
    return {
      id: m.id,
      sender: m.sender.displayName || m.sender.username,
      username: m.sender.username,
      senderId: m.sender.id,
      avatarUrl: m.sender.avatarUrl,
      message: m.content,
      attachmentUrl: m.attachmentUrl,
      mediaIv: m.mediaIv,
      mediaKeys: m.mediaKeys,
      attachmentType: m.attachmentType,
      timestamp: this.toLocalISO(m.createdAt),
      recipientId: m.recipient?.id ?? null,
      groupId: m.group?.id ?? null,
      isRead: m.isRead,
      editedAt: this.toLocalISO(m.editedAt),
      pinned: m.pinned,
      pollVotes: m.pollVotes ?? {},
      scheduledAt: this.toLocalISO(m.scheduledAt),
      expiresAt: this.toLocalISO(m.expiresAt),
      viewOnce: m.viewOnce ?? false,
      viewedAt: this.toLocalISO(m.viewedAt),
      reactions: this.serializeReactions(m.reactions),
      replyToMessageId: m.replyToMessageId,
      replyToSender: m.replyToSender,
      replyToMessage: m.replyToMessage,
      ...extra,
    };
  }

  // ===== SCHEDULED MESSAGES =====
  onModuleInit() {
    // ponytail: 5s poll on one API instance; use a job queue if this ever runs on several
    this.releaseTimer = setInterval(() => {
      this.releaseDue().catch(e => this.logger.error(`[Schedule] ${e.message}`));
      this.purgeExpired().catch(e => this.logger.error(`[Disappear] ${e.message}`));
    }, 5000);
  }

  onModuleDestroy() {
    clearInterval(this.releaseTimer);
  }

  /** Sends every scheduled message whose time has come, as if it were sent just now. */
  private async releaseDue() {
    const due = await this.messageRepository.find({
      where: { scheduledAt: LessThanOrEqual(new Date()) },
      relations: ['sender', 'recipient', 'group', 'reactions', 'reactions.user'],
      take: 100,
    });
    for (const m of due) {
      m.scheduledAt = null;
      m.createdAt = new Date();
      m.expiresAt = this.expiry(await this.timerFor(m)); // the timer starts when it is actually sent
      m.isRead = false;
      await this.messageRepository.save(m);
      await this.broadcastNew(m);
    }
  }

  // ===== DISAPPEARING MESSAGES =====
  static readonly TIMERS = [0, 3600, 86400, 604800, 2592000]; // off, 1h, 1d, 1w, 30d

  private friendshipOf(a: number, b: number) {
    return this.friendshipRepository.findOne({
      where: [{ user1: { id: a }, user2: { id: b } }, { user1: { id: b }, user2: { id: a } }],
    });
  }

  private async timerFor(m: Message): Promise<number> {
    if (m.group) {
      return (await this.groupRepository.findOne({ where: { id: m.group.id }, select: ['id', 'disappearSeconds'] }))?.disappearSeconds ?? 0;
    }
    if (m.recipient) return (await this.friendshipOf(m.sender.id, m.recipient.id))?.disappearSeconds ?? 0;
    return 0; // never in the Lounge
  }

  private expiry(seconds: number) {
    return seconds > 0 ? new Date(Date.now() + seconds * 1000) : null;
  }

  /** Deletes expired messages for real (row and encrypted file) and tells the open chats. */
  private async purgeExpired() {
    const gone = await this.messageRepository.find({
      where: { expiresAt: LessThanOrEqual(new Date()) },
      relations: ['sender', 'recipient', 'group'],
      take: 200,
    });
    for (const m of gone) {
      const id = m.id;
      await this.messageRepository.remove(m);
      this.deleteUpload(m.attachmentUrl);
      m.id = id;
      await this.emitToConversation(m, 'message_deleted', { messageId: id });
    }
  }

  /** Removes an uploaded chat file. basename() keeps a forged URL from escaping the folder. */
  private deleteUpload(url?: string | null) {
    if (!url?.startsWith('/uploads/messages/')) return;
    fs.unlink(path.join(process.cwd(), 'uploads', 'messages', path.basename(url))).catch(() => { });
  }

  @SubscribeMessage('set_disappearing')
  async handleSetDisappearing(
    @MessageBody() data: { recipientId?: number; groupId?: number; seconds: number },
    @ConnectedSocket() client: Socket,
  ) {
    const userId = Number(client.data.user?.sub);
    const seconds = Number(data?.seconds);
    if (!userId || !ChatGateway.TIMERS.includes(seconds)) return;
    if (data.groupId) {
      const ids = await this.groupMemberIds(data.groupId);
      if (!ids.includes(userId)) return;
      await this.groupRepository.update(data.groupId, { disappearSeconds: seconds });
      this.server.to(this.rooms(ids)).emit('disappearing_changed', { groupId: data.groupId, seconds, by: userId });
    } else if (data.recipientId) {
      const f = await this.friendshipOf(userId, data.recipientId);
      if (!f) return; // friends only
      await this.friendshipRepository.update(f.id, { disappearSeconds: seconds });
      this.server.to(`user_${userId}`).emit('disappearing_changed', { recipientId: data.recipientId, seconds, by: userId });
      this.server.to(`user_${data.recipientId}`).emit('disappearing_changed', { recipientId: userId, seconds, by: userId });
    }
  }

  // ===== VIEW ONCE =====
  /** The recipient opened it: delete the file and tell both phones. Called after their download. */
  @SubscribeMessage('open_view_once')
  async handleOpenViewOnce(@MessageBody() data: { messageId: number }, @ConnectedSocket() client: Socket) {
    const userId = Number(client.data.user?.sub);
    const m = data?.messageId ? await this.findWithParties(data.messageId) : null;
    if (!m?.viewOnce || m.viewedAt || m.recipient?.id !== userId) return;
    this.deleteUpload(m.attachmentUrl);
    m.viewedAt = new Date();
    m.attachmentUrl = null as any;
    m.mediaIv = null as any;
    m.mediaKeys = null;
    await this.messageRepository.save(m);
    await this.emitToConversation(m, 'message_viewed', this.serializeMessage(m));
  }

  /** For reports: may this user see this message? */
  async messageVisibleTo(messageId: number, userId: number) {
    const m = await this.findWithParties(messageId);
    return m && (await this.canSee(m, userId)) ? m : null;
  }

  /** Moderation of a reported message: removed for everyone in that chat. */
  async adminDeleteMessage(id: number) {
    const m = await this.findWithParties(id);
    if (!m) return false;
    await this.messageRepository.remove(m);
    this.deleteUpload(m.attachmentUrl);
    m.id = id;
    await this.emitToConversation(m, 'message_deleted', { messageId: id });
    return true;
  }

  private async broadcastNew(m: Message, tempId: string | null = null) {
    const data = this.serializeMessage(m, { tempId });
    await this.emitToConversation(m, 'message', data);
    if (m.group) {
      const ids = (await this.groupMemberIds(m.group.id)).filter(id => id !== m.sender.id);
      this.pushAway(ids, 'message', { g: m.group.id });
    } else if (m.recipient) {
      this.pushAway([m.recipient.id], 'message', { u: m.sender.id });
    } else {
      await this.notifyMentions(m, m.sender);
    }
  }

  private rooms(ids: number[]) {
    return ids.map(id => `user_${id}`);
  }

  private async groupMemberIds(groupId: number): Promise<number[]> {
    const g = await this.groupRepository.findOne({ where: { id: groupId }, relations: ['members'] });
    return g?.members.map(m => m.id) ?? [];
  }

  /** Who may see [m]: its two people, its group's members, or anyone for the Lounge. */
  private async canSee(m: Message, userId: number): Promise<boolean> {
    if (m.group) return (await this.groupMemberIds(m.group.id)).includes(userId);
    if (m.recipient) return m.sender.id === userId || m.recipient.id === userId;
    return true;
  }

  /** Emit to everyone in [m]'s conversation. */
  private async emitToConversation(m: Message, event: string, data: any) {
    if (m.group) {
      const ids = await this.groupMemberIds(m.group.id);
      if (ids.length) this.server.to(this.rooms(ids)).emit(event, data);
    } else if (m.recipient) {
      this.server.to(this.rooms([m.recipient.id, m.sender.id])).emit(event, data);
    } else {
      this.server.emit(event, data);
    }
  }

  private findWithParties(id: number) {
    return this.messageRepository.findOne({
      where: { id },
      relations: ['sender', 'recipient', 'group', 'reactions', 'reactions.user'],
    });
  }

  async handleConnection(client: Socket) {
    try {
      const token = (client.handshake.auth.token || client.handshake.headers.authorization)?.split(' ')[1];
      if (!token) throw new Error('No token provided');

      const payload = this.jwtService.verify(token);
      // Join the private room before any await, or events sent in the meantime are lost
      client.data.user = payload;
      client.join(`user_${payload.sub}`);

      const user = await this.userRepository.findOne({ where: { id: payload.sub } });
      if (!user || user.isBanned || !(await this.auth.sessionActive(payload.sid))) {
        client.data.user = null; // so handleDisconnect doesn't touch presence
        throw new Error('User not found, banned or device removed');
      }

      this.onlineUsers.set(payload.sub, (this.onlineUsers.get(payload.sub) ?? 0) + 1);
      this.setForeground(payload.sub, client.id, true); // apps connect when they come to the front
      this.broadcastOnlineUsers();

      this.logger.log(`Client authenticated: ${payload.username} (${client.id})`);

      // A call that rang while this phone was asleep (it was woken by CallKit to answer it)
      const pending = this.pendingOffers.get(Number(payload.sub));
      if (pending && Date.now() - pending.at < 45_000) client.emit('call_offer', pending.payload);

      // Send initial global history
      await this.sendHistory(client);

    } catch (e) {
      this.logger.log(`Connection rejected: ${e.message}`);
      client.disconnect();
    }
  }

  handleDisconnect(client: Socket) {
    const userPayload = client.data.user;
    if (userPayload) {
      this.leaveAllCalls(client.id);
      this.setForeground(userPayload.sub, client.id, false);
      const remaining = (this.onlineUsers.get(userPayload.sub) ?? 1) - 1;
      if (remaining > 0) this.onlineUsers.set(userPayload.sub, remaining);
      else this.onlineUsers.delete(userPayload.sub);
      this.broadcastOnlineUsers();
    }
    this.logger.log(`Client disconnected: ${client.id}`);
  }

  private broadcastOnlineUsers() {
    this.server.emit('online_users', Array.from(this.onlineUsers.keys()));
  }

  @SubscribeMessage('get_history')
  async handleGetHistory(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { recipientId?: number; groupId?: number; limit?: number }
  ) {
    await this.sendHistory(client, data?.recipientId, data?.groupId, data?.limit);
  }

  private async sendHistory(client: Socket, recipientId?: number, groupId?: number, limit = 50) {
    const userPayload = client.data.user;
    if (!userPayload) return;

    const userId = parseInt(userPayload.sub);
    // Search asks for more so it can look through older messages on the phone
    const take = Math.min(Math.max(Number(limit) || 50, 1), 500);
    const relations = ['sender', 'recipient', 'group', 'reactions', 'reactions.user'];

    let where: any;
    if (groupId) {
      if (!(await this.groupMemberIds(groupId)).includes(userId)) return;
      where = { group: { id: groupId } };
    } else if (recipientId) {
      where = [
        { sender: { id: userId }, recipient: { id: recipientId } },
        { sender: { id: recipientId }, recipient: { id: userId } },
      ];
    } else {
      where = { recipient: IsNull(), group: IsNull() }; // the Lounge never includes group messages
    }

    const all = (extra: any) => (Array.isArray(where) ? where.map(w => ({ ...w, ...extra })) : { ...where, ...extra });
    const [messages, pinned, scheduled] = await Promise.all([
      this.messageRepository.find({ where: all({ scheduledAt: IsNull() }), relations, order: { createdAt: 'DESC' }, take }),
      this.messageRepository.find({
        where: all({ pinned: true, scheduledAt: IsNull() }),
        relations,
        order: { createdAt: 'DESC' },
        take: 20,
      }),
      // Only the sender sees their own messages waiting to go out
      this.messageRepository.find({
        where: all({ scheduledAt: Not(IsNull()), sender: { id: userId } }),
        relations,
        order: { scheduledAt: 'ASC' },
      }),
    ]);
    // ponytail: hidden messages are filtered after the query, so a page can hold fewer than [take]
    const now = Date.now();
    const visible = (m: Message) => !(m.hiddenFor ?? []).includes(userId) && !(m.expiresAt && +m.expiresAt <= now);
    const disappearSeconds = groupId
      ? (await this.groupRepository.findOne({ where: { id: groupId }, select: ['id', 'disappearSeconds'] }))?.disappearSeconds ?? 0
      : recipientId ? (await this.friendshipOf(userId, recipientId))?.disappearSeconds ?? 0 : 0;

    // Fetched newest-first so we get the latest ones; send oldest-first for display
    const readers = groupId ? await this.groupReaders(groupId) : undefined;
    client.emit('history', {
      recipientId: recipientId || null,
      groupId: groupId || null,
      disappearSeconds,
      readers,
      messages: messages.reverse().filter(visible).map(m => this.serializeMessage(m)),
      pinned: pinned.filter(visible).map(m => this.serializeMessage(m)),
      scheduled: scheduled.map(m => this.serializeMessage(m)),
    });
  }

  /** A removed device: close its sockets now (its token stops working on the next request). */
  async disconnectSession(sid: string) {
    for (const s of await this.server.fetchSockets()) {
      if (s.data.user?.sid === sid) s.disconnect(true);
    }
  }

  disconnectUser(userId: number) {
    this.server.in(`user_${userId}`).disconnectSockets(true);
  }

  onlineUserIds(): number[] {
    return [...this.onlineUsers.keys()];
  }

  /** Moderation: remove a public Lounge message for everyone. Private/group chats are untouchable. */
  async adminDeleteLoungeMessage(id: number): Promise<boolean> {
    const m = await this.findWithParties(id);
    if (!m || m.group || m.recipient) return false;
    await this.messageRepository.remove(m);
    this.server.emit('message_deleted', { messageId: id });
    return true;
  }

  notifyStoryPosted(userId: number, friendIds: number[]) {
    for (const id of friendIds) this.server.to(`user_${id}`).emit('story_posted', { userId });
  }

  /** Friends and anyone sharing a group must start encrypting to the new key. */
  async notifyKeyChanged(userId: number, publicKey: string, friendIds: number[]) {
    const rows = await this.groupRepository
      .createQueryBuilder('g')
      .innerJoin('g.members', 'me', 'me.id = :userId', { userId })
      .innerJoin('g.members', 'other')
      .select('DISTINCT other.id', 'id')
      .getRawMany();
    const ids = new Set([...friendIds, ...rows.map(r => Number(r.id))]);
    ids.delete(userId);
    if (ids.size) this.server.to(this.rooms([...ids])).emit('user:key', { userId, publicKey });
  }

  notifyStoryLiked(ownerId: number, storyId: number, fromId: number) {
    this.server.to(`user_${ownerId}`).emit('story_liked', { storyId, userId: fromId });
  }

  notifyGroupChanged(groupId: number, memberIds: number[]) {
    if (memberIds.length) this.server.to(this.rooms(memberIds)).emit('group_updated', { groupId });
  }

  notifyFriendRemoved(userId: number, friendId: number) {
    this.server.to(`user_${userId}`).emit('friend_removed', { friendId });
    this.server.to(`user_${friendId}`).emit('friend_removed', { friendId: userId });
  }

  notifyFriendAccepted(recipientId: number, user: any) {
    this.server.to(`user_${recipientId}`).emit('friend_accepted', { user });
  }

  notifyFriendRequest(recipientId: number, sender: any) {
    this.server.to(`user_${recipientId}`).emit('friend_request', { sender });
  }

  @SubscribeMessage('delete_message')
  async handleDeleteMessage(
    @MessageBody() data: { messageId: number },
    @ConnectedSocket() client: Socket,
  ) {
    const userPayload = client.data.user;
    if (!userPayload) return;

    const message = await this.findWithParties(data.messageId);
    if (!message || message.sender.id !== userPayload.sub) return;

    await this.messageRepository.remove(message);
    this.deleteUpload(message.attachmentUrl);
    message.id = data.messageId; // remove() clears it
    await this.emitToConversation(message, 'message_deleted', { messageId: data.messageId });
  }

  /** Sender replaces the text. For private and group chats it is new ciphertext from the phone. */
  @SubscribeMessage('edit_message')
  async handleEditMessage(
    @MessageBody() data: { messageId: number; message: string },
    @ConnectedSocket() client: Socket,
  ) {
    const userPayload = client.data.user;
    if (!userPayload || typeof data?.message !== 'string' || !data.message) return;

    const message = await this.findWithParties(data.messageId);
    if (!message || message.sender.id !== userPayload.sub || message.attachmentType === 'voice') return;

    message.content = data.message;
    message.editedAt = new Date();
    await this.messageRepository.save(message);
    await this.emitToConversation(message, 'message_edited', this.serializeMessage(message));
  }

  /** "Delete for me": hide it from this user's history on every device; others keep it. */
  @SubscribeMessage('hide_message')
  async handleHideMessage(
    @MessageBody() data: { messageId: number },
    @ConnectedSocket() client: Socket,
  ) {
    const userPayload = client.data.user;
    if (!userPayload) return;
    const userId = parseInt(userPayload.sub);

    const message = await this.findWithParties(data.messageId);
    if (!message || !(await this.canSee(message, userId))) return;
    if (!(message.hiddenFor ?? []).includes(userId)) {
      message.hiddenFor = [...(message.hiddenFor ?? []), userId];
      await this.messageRepository.save(message);
    }
    this.server.to(`user_${userId}`).emit('message_hidden', { messageId: data.messageId });
  }

  @SubscribeMessage('pin_message')
  async handlePinMessage(
    @MessageBody() data: { messageId: number; pinned: boolean },
    @ConnectedSocket() client: Socket,
  ) {
    const userPayload = client.data.user;
    if (!userPayload) return;

    const message = await this.findWithParties(data.messageId);
    if (!message || !(await this.canSee(message, parseInt(userPayload.sub)))) return;
    // Pinning in the Lounge would let anyone pin for everyone; keep it to private and group chats
    if (!message.recipient && !message.group) return;

    message.pinned = !!data.pinned;
    await this.messageRepository.save(message);
    await this.emitToConversation(message, 'message_pinned', this.serializeMessage(message));
  }

  @SubscribeMessage('message')
  async handleMessage(
    @MessageBody() data: {
      message: string,
      attachmentUrl?: string,
      recipientId?: number,
      groupId?: number,
      tempId?: string,
      mediaIv?: string,
      mediaKeys?: any,
      attachmentType?: string,
      replyToMessageId?: number,
      replyToSender?: string,
      replyToMessage?: string,
      sendAt?: string,
      viewOnce?: boolean,
    },
    @ConnectedSocket() client: Socket,
  ) {
    const userPayload = client.data.user;
    if (!userPayload) return;
    const userId = parseInt(userPayload.sub);
    if (!this.allowSend(userId)) {
      client.emit('message_error', {
        recipientId: data?.recipientId ?? null, groupId: data?.groupId ?? null, tempId: data?.tempId ?? null,
        error: 'You’re sending messages too fast. Wait a few seconds.',
      });
      return;
    }

    // Handlers run concurrently, so quick successive messages could be saved out of order.
    // Chain each sender's messages so they persist and broadcast in the order sent.
    // ponytail: in-memory, single API instance; use a per-conversation sequence if this scales out
    const previous = this.sendQueues.get(userId) ?? Promise.resolve();
    const current = previous.then(() => this.processMessage(data, client, userId)).catch((e) =>
      this.logger.error(`[Message] Failed for user ${userId}: ${e.message}`),
    );
    this.sendQueues.set(userId, current);
    current.finally(() => {
      if (this.sendQueues.get(userId) === current) this.sendQueues.delete(userId);
    });
    return current;
  }

  private async processMessage(data: any, client: Socket, userId: number) {
    this.logger.debug(`[Message] Processing message from user ${userId} to ${data.recipientId}`);

    const sender = await this.userRepository.findOne({ where: { id: userId } });
    if (!sender) return;

    let recipient = null;
    let group: Group | null = null;
    if (data.groupId) {
      group = await this.groupRepository.findOne({ where: { id: data.groupId }, relations: ['members'] });
      if (!group || !group.members.some(m => m.id === userId)) return;
    } else if (data.recipientId) {
      recipient = await this.userRepository.findOne({ where: { id: data.recipientId } });
      if (!recipient) return;

      // Check if users have blocked each other
      const isBlocked = await this.usersService.isBlocked(userId, data.recipientId);
      if (isBlocked) {
        this.logger.debug(`[Message] Blocked: User ${userId} and ${data.recipientId}`);
        client.emit('message_error', {
          recipientId: data.recipientId,
          error: 'Message not sent. You have been blocked by this user or you have blocked them.'
        });
        return;
      }
    }

    // Scheduled: keep it (already encrypted) until its time; only the sender hears about it now
    const sendAt = data.sendAt ? new Date(data.sendAt) : null;
    const maxAhead = 30 * 24 * 3600 * 1000;
    const scheduled = sendAt && !isNaN(+sendAt) && +sendAt > Date.now() + 5000 && +sendAt < Date.now() + maxAhead
      ? sendAt : null;

    // Persist message
    const message = this.messageRepository.create({
      scheduledAt: scheduled,
      content: data.message,
      attachmentUrl: data.attachmentUrl,
      mediaIv: data.mediaIv,
      mediaKeys: data.mediaKeys,
      attachmentType: data.attachmentType,
      sender: sender,
      recipient: recipient ?? undefined,
      group: group ?? undefined,
      replyToMessageId: data.replyToMessageId,
      replyToSender: data.replyToSender,
      replyToMessage: data.replyToMessage,
      isRead: false,
      // View once: private chats only, and only for a photo or voice note
      viewOnce: !!data.viewOnce && !!recipient && !!data.attachmentUrl && ['image', 'voice'].includes(data.attachmentType),
    });
    if (!scheduled) message.expiresAt = this.expiry(group ? group.disappearSeconds ?? 0 : await this.timerFor(message));
    await this.messageRepository.save(message);
    this.logger.debug(`[Message] Persisted message ID ${message.id}`);

    if (scheduled) {
      this.server.to(`user_${sender.id}`).emit('message_scheduled', this.serializeMessage(message, { tempId: data.tempId || null }));
      return;
    }
    await this.broadcastNew(message, data.tempId || null);
  }

  // ===== POLLS =====
  /** Replace this user's votes on a poll. The server stores option numbers only. */
  @SubscribeMessage('poll_vote')
  async handlePollVote(
    @MessageBody() data: { messageId: number; options: number[] },
    @ConnectedSocket() client: Socket,
  ) {
    const userPayload = client.data.user;
    if (!userPayload || !Array.isArray(data?.options)) return;
    const userId = parseInt(userPayload.sub);
    const options = [...new Set(data.options.map(Number))].filter(o => Number.isInteger(o) && o >= 0 && o < 12);

    const message = await this.findWithParties(data.messageId);
    if (!message || message.scheduledAt || !(await this.canSee(message, userId))) return;

    // Atomic per-user update, so two people voting at once can't overwrite each other
    const rows = await this.messageRepository.query(
      `UPDATE messages SET "pollVotes" = CASE WHEN $2::jsonb = '[]'::jsonb THEN "pollVotes" - $1::text
         ELSE "pollVotes" || jsonb_build_object($1::text, $2::jsonb) END
       WHERE id = $3 RETURNING "pollVotes"`,
      [String(userId), JSON.stringify(options), message.id],
    );
    await this.emitToConversation(message, 'poll_votes', { messageId: message.id, pollVotes: rows[0]?.[0]?.pollVotes ?? rows[0]?.pollVotes ?? {} });
  }

  /** Lounge only (it is plain text): tell each @username that they were mentioned. */
  private async notifyMentions(message: Message, sender: User) {
    let text = message.content;
    try {
      const j = JSON.parse(text); // forwarded / preview envelope
      if (j && typeof j.text === 'string') text = j.text;
    } catch { /* plain text */ }
    const names = [...new Set([...text.matchAll(/@([A-Za-z0-9_.]{2,30})/g)].map(m => m[1].toLowerCase()))];
    if (!names.length) return;
    const users = await this.userRepository
      .createQueryBuilder('u')
      .where('LOWER(u.username) IN (:...names)', { names: names.slice(0, 10) })
      .getMany();
    for (const u of users) {
      if (u.id === sender.id) continue;
      this.pushAway([u.id], 'mention', { lounge: 1 });
      this.server.to(`user_${u.id}`).emit('mention', {
        messageId: message.id,
        from: sender.displayName || sender.username,
        text: text.slice(0, 120),
      });
    }
  }

  /** Recipient opened a private chat: mark the friend's messages read and tell the friend. */
  @SubscribeMessage('mark_read')
  async handleMarkRead(
    @MessageBody() data: { friendId?: number; groupId?: number },
    @ConnectedSocket() client: Socket,
  ) {
    const userPayload = client.data.user;
    if (!userPayload) return;
    const userId = parseInt(userPayload.sub);
    if (data?.groupId) return this.markGroupRead(userId, Number(data.groupId), client);
    if (!data?.friendId) return;
    // The user's other devices clear this chat's unread badge too
    client.to(`user_${userId}`).emit('read_sync', { friendId: data.friendId });

    const result = await this.messageRepository.update(
      { sender: { id: data.friendId }, recipient: { id: userId }, isRead: false },
      { isRead: true },
    );
    if (result.affected) {
      this.server.to(`user_${data.friendId}`).emit('messages_read', { readerId: userId });
    }
  }

  /** Readers' positions in a group, for "Seen by". */
  private async groupReaders(groupId: number) {
    const rows = await this.messageRepository.manager.getRepository(GroupRead).find({ where: { groupId } });
    return rows.map(r => ({ userId: r.userId, lastReadId: r.lastReadId }));
  }

  private async markGroupRead(userId: number, groupId: number, client: Socket) {
    const ids = await this.groupMemberIds(groupId);
    if (!ids.includes(userId)) return;
    const [last] = await this.messageRepository.query(
      `select max(id)::int id from messages where "groupId" = $1 and "scheduledAt" is null`, [groupId]);
    const lastReadId = last?.id ?? 0;
    // Only ever moves forward
    await this.messageRepository.query(
      `insert into group_reads ("userId", "groupId", "lastReadId") values ($1, $2, $3)
       on conflict ("userId", "groupId") do update set "lastReadId" = greatest(group_reads."lastReadId", excluded."lastReadId")`,
      [userId, groupId, lastReadId]);
    client.to(`user_${userId}`).emit('read_sync', { groupId });
    this.server.to(this.rooms(ids.filter(id => id !== userId))).emit('group_read', { groupId, userId, lastReadId });
  }

  // ===== GROUP CALLS =====
  // Mesh: every participant connects directly to every other one, so audio and video stay
  // end-to-end encrypted (DTLS-SRTP) with no media server. Fine for small groups.
  // ponytail: in-memory, one API instance; groupId -> userId -> socketId
  static readonly CALL_MAX = 6;
  private calls = new Map<number, Map<number, string>>();

  private callState(groupId: number) {
    return { groupId, participants: [...(this.calls.get(groupId)?.keys() ?? [])] };
  }

  private async announceCall(groupId: number) {
    const ids = await this.groupMemberIds(groupId);
    this.server.to(this.rooms(ids)).emit('group_call', this.callState(groupId));
  }

  /** Join (or start) a group's call. Returns who is already in it, so the joiner can connect to each. */
  @SubscribeMessage('gc_join')
  async handleGroupCallJoin(@MessageBody() data: { groupId: number; video?: boolean }, @ConnectedSocket() client: Socket) {
    const userId = Number(client.data.user?.sub);
    const groupId = Number(data?.groupId);
    const ids = await this.groupMemberIds(groupId);
    if (!userId || !ids.includes(userId)) return { error: 'Not a member' };
    const call = this.calls.get(groupId) ?? new Map<number, string>();
    if (!call.has(userId) && call.size >= ChatGateway.CALL_MAX) return { error: `Group calls are limited to ${ChatGateway.CALL_MAX} people` };
    const others = [...call.keys()].filter(id => id !== userId);
    const started = call.size === 0;
    call.set(userId, client.id);
    this.calls.set(groupId, call);
    await this.announceCall(groupId);
    if (started) this.pushAway(ids.filter(id => id !== userId), 'call', { g: groupId });
    return { participants: others };
  }

  @SubscribeMessage('gc_leave')
  async handleGroupCallLeave(@MessageBody() data: { groupId: number }, @ConnectedSocket() client: Socket) {
    const userId = Number(client.data.user?.sub);
    const call = this.calls.get(Number(data?.groupId));
    if (!call || call.get(userId) !== client.id) return { ok: false };
    call.delete(userId);
    if (!call.size) this.calls.delete(Number(data.groupId));
    await this.announceCall(Number(data.groupId));
    return { ok: true };
  }

  /** Offers, answers and ICE candidates between two people in the same call. */
  @SubscribeMessage('gc_signal')
  handleGroupCallSignal(@MessageBody() data: { groupId: number; to: number; signal: any }, @ConnectedSocket() client: Socket) {
    const userId = Number(client.data.user?.sub);
    const call = this.calls.get(Number(data?.groupId));
    const toSocket = call?.get(Number(data?.to));
    if (!call?.has(userId) || !toSocket) return;
    this.server.to(toSocket).emit('gc_signal', { groupId: Number(data.groupId), from: userId, signal: data.signal });
  }

  /** Current call in a group (for the "Join" banner when a chat opens). */
  @SubscribeMessage('gc_state')
  async handleGroupCallState(@MessageBody() data: { groupId: number }, @ConnectedSocket() client: Socket) {
    const userId = Number(client.data.user?.sub);
    if (!(await this.groupMemberIds(Number(data?.groupId))).includes(userId)) return null;
    return this.callState(Number(data.groupId));
  }

  private leaveAllCalls(socketId: string) {
    for (const [groupId, call] of this.calls) {
      for (const [userId, sid] of call) {
        if (sid !== socketId) continue;
        call.delete(userId);
        if (!call.size) this.calls.delete(groupId);
        this.announceCall(groupId).catch(() => { });
      }
    }
  }

  activeCalls() {
    return [...this.calls.entries()].map(([groupId, c]) => ({ groupId, people: c.size }));
  }

  // A phone woken by a VoIP push (CallKit) connects after the offer was sent; keep it briefly.
  // ponytail: in-memory, one API instance
  private pendingOffers = new Map<number, { payload: any; at: number }>();
  private clearOffer(...userIds: number[]) {
    for (const id of userIds) this.pendingOffers.delete(Number(id));
  }

  // WebRTC Signaling
  @SubscribeMessage('call_user')
  async handleCallUser(@MessageBody() data: { to: number; offer: any; video?: boolean }, @ConnectedSocket() client: Socket) {
    const userPayload = client.data.user;
    if (!userPayload) return;
    // Only friends who haven't blocked each other can ring (and wake) someone's phone
    const from = parseInt(userPayload.sub);
    const to = Number(data?.to);
    const friends = await this.usersService.getFriendIds(from);
    if (!friends.includes(to) || (await this.usersService.isBlocked(from, to))) {
      client.emit('call_rejected', { from: to });
      return;
    }
    const offer = { from: userPayload.sub, username: userPayload.username, offer: data.offer, video: !!data.video };
    this.pendingOffers.set(to, { payload: offer, at: Date.now() });
    this.server.to(`user_${data.to}`).emit('call_offer', offer);
    this.pushAway([data.to], 'call', { u: parseInt(userPayload.sub) });
  }

  @SubscribeMessage('call_answer')
  handleCallAnswer(@MessageBody() data: { to: number; answer: any }, @ConnectedSocket() client: Socket) {
    const userPayload = client.data.user;
    if (!userPayload) return;
    this.clearOffer(userPayload.sub, data.to);
    this.server.to(`user_${data.to}`).emit('call_answer', {
      from: userPayload.sub,
      answer: data.answer,
    });
  }

  @SubscribeMessage('ice_candidate')
  handleIceCandidate(@MessageBody() data: { to: number; candidate: any }, @ConnectedSocket() client: Socket) {
    const userPayload = client.data.user;
    if (!userPayload) return;
    this.server.to(`user_${data.to}`).emit('ice_candidate', {
      from: userPayload.sub,
      candidate: data.candidate,
    });
  }

  @SubscribeMessage('call_reject')
  handleCallReject(@MessageBody() data: { to: number }, @ConnectedSocket() client: Socket) {
    const userPayload = client.data.user;
    if (!userPayload) return;
    this.clearOffer(userPayload.sub, data.to);
    this.server.to(`user_${data.to}`).emit('call_rejected', {
      from: userPayload.sub,
    });
  }

  @SubscribeMessage('call_end')
  handleCallEnd(@MessageBody() data: { to: number }, @ConnectedSocket() client: Socket) {
    const userPayload = client.data.user;
    if (!userPayload) return;
    this.clearOffer(userPayload.sub, data.to);
    this.server.to(`user_${data.to}`).emit('call_ended', {
      from: userPayload.sub,
    });
  }

  // ===== STATUS MESSAGES =====
  notifyStatusChange(userId: number, statusMessage: string) {
    // Notify all friends about status change
    this.server.emit('user:status', { userId, statusMessage });
  }

  // ===== MESSAGE REACTIONS =====
  @SubscribeMessage('message:react')
  async handleReaction(
    @MessageBody() data: { messageId: number; emoji: string },
    @ConnectedSocket() client: Socket
  ) {
    const userPayload = client.data.user;
    if (!userPayload) return;
    const userId = parseInt(userPayload.sub);

    const message = await this.findWithParties(data.messageId);
    if (!message || !(await this.canSee(message, userId))) return;

    // Toggle: the same emoji again removes it
    const existingReaction = message.reactions?.find(r => r.user.id === userId && r.emoji === data.emoji);
    if (existingReaction) {
      await this.reactionRepository.delete(existingReaction.id);
      message.reactions = message.reactions.filter(r => r.id !== existingReaction.id);
    } else {
      const user = await this.userRepository.findOne({ where: { id: userId } });
      if (!user) return;
      const reaction = await this.reactionRepository.save(
        this.reactionRepository.create({ message, user, emoji: data.emoji }),
      );
      message.reactions = [...(message.reactions || []), reaction];
    }

    await this.emitToConversation(message, 'message:reaction', {
      messageId: data.messageId,
      reactions: this.serializeReactions(message.reactions),
    });
  }

  // ===== TYPING INDICATOR =====
  @SubscribeMessage('typing_start')
  handleTypingStart(@MessageBody() data: { recipientId?: number; groupId?: number }, @ConnectedSocket() client: Socket) {
    return this.relayTyping(client, data, true);
  }

  @SubscribeMessage('typing_stop')
  handleTypingStop(@MessageBody() data: { recipientId?: number; groupId?: number }, @ConnectedSocket() client: Socket) {
    return this.relayTyping(client, data, false);
  }

  private async relayTyping(client: Socket, data: { recipientId?: number; groupId?: number }, isTyping: boolean) {
    const userPayload = client.data.user;
    if (!userPayload) return;
    const userId = parseInt(userPayload.sub);
    const event = { userId, username: userPayload.username, isTyping, groupId: data?.groupId ?? null };
    if (data?.groupId) {
      const ids = await this.groupMemberIds(data.groupId);
      if (!ids.includes(userId)) return;
      const others = ids.filter(id => id !== userId);
      if (others.length) this.server.to(this.rooms(others)).emit('user_typing', event);
    } else if (data?.recipientId) {
      this.server.to(`user_${data.recipientId}`).emit('user_typing', event);
    }
  }

  // ===== BROADCAST SYSTEM =====
  broadcastSystemMessage(message: string) {
    this.server.emit('system_message', { message, timestamp: new Date().toISOString() });
    this.logger.log(`Broadcasted system message: ${message}`);
  }
}

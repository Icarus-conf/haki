import { Logger } from '@nestjs/common';
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
import { Server, Socket } from 'socket.io';
import { IsNull, Repository } from 'typeorm';
import { Message } from './chat/entities/message.entity';
import { Reaction } from './chat/entities/reaction.entity';
import { Friendship } from './users/entities/friendship.entity';
import { User } from './users/entities/user.entity';
import { UsersService } from './users/users.service';

@WebSocketGateway({
  cors: {
    origin: '*',
  },
})
export class ChatGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  private onlineUsers = new Set<number>();
  private readonly logger = new Logger(ChatGateway.name);

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
    private readonly usersService: UsersService,
  ) { }

  private toLocalISO(date: Date | null | undefined): string | null {
    if (!date) return null;
    // Return proper ISO 8601 string with 'Z' UTC indicator
    return date.toISOString();
  }

  async handleConnection(client: Socket) {
    try {
      const token = (client.handshake.auth.token || client.handshake.headers.authorization)?.split(' ')[1];
      if (!token) throw new Error('No token provided');

      const payload = this.jwtService.verify(token);
      client.data.user = payload;

      // Join private room
      client.join(`user_${payload.sub}`);

      this.onlineUsers.add(payload.sub);
      this.broadcastOnlineUsers();

      this.logger.log(`Client authenticated: ${payload.username} (${client.id})`);

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
      this.onlineUsers.delete(userPayload.sub);
      this.broadcastOnlineUsers();
    }
    this.logger.log(`Client disconnected: ${client.id}`);
  }

  private broadcastOnlineUsers() {
    this.server.emit('online_users', Array.from(this.onlineUsers));
  }

  @SubscribeMessage('get_history')
  async handleGetHistory(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { recipientId?: number }
  ) {
    await this.sendHistory(client, data.recipientId);
  }

  private async sendHistory(client: Socket, recipientId?: number) {
    const userPayload = client.data.user;
    if (!userPayload) return;

    const userId = parseInt(userPayload.sub);
    this.logger.debug(`[History] Fetching history for user ${userId}, recipientId: ${recipientId || 'Global'}`);

    let messages;

    if (recipientId) {
      // 1:1 History
      messages = await this.messageRepository.find({
        where: [
          { sender: { id: userId }, recipient: { id: recipientId } },
          { sender: { id: recipientId }, recipient: { id: userId } }
        ],
        relations: ['sender', 'recipient', 'reactions', 'reactions.user'],
        order: { createdAt: 'ASC' },
        take: 50,
      });
    } else {
      // Global History
      messages = await this.messageRepository.find({
        where: { recipient: IsNull() },
        relations: ['sender', 'reactions', 'reactions.user'],
        order: { createdAt: 'ASC' },
        take: 50,
      });
    }

    client.emit('history', {
      recipientId: recipientId || null,
      messages: messages.map(m => ({
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
        reactions: m.reactions || [],
        replyToMessageId: m.replyToMessageId,
        replyToSender: m.replyToSender,
        replyToMessage: m.replyToMessage,
      }))
    });
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

    const message = await this.messageRepository.findOne({
      where: { id: data.messageId },
      relations: ['sender', 'recipient']
    });

    if (!message || message.sender.id !== userPayload.sub) return;

    await this.messageRepository.remove(message);

    const deleteEvent = { messageId: data.messageId };
    if (message.recipient) {
      this.server.to(`user_${message.recipient.id}`).to(`user_${message.sender.id}`).emit('message_deleted', deleteEvent);
    } else {
      this.server.emit('message_deleted', deleteEvent);
    }
  }

  @SubscribeMessage('message')
  async handleMessage(
    @MessageBody() data: {
      message: string,
      attachmentUrl?: string,
      recipientId?: number,
      tempId?: string,
      mediaIv?: string,
      mediaKeys?: any,
      attachmentType?: string,
      replyToMessageId?: number,
      replyToSender?: string,
      replyToMessage?: string,
    },
    @ConnectedSocket() client: Socket,
  ) {
    const userPayload = client.data.user;
    if (!userPayload) return;

    const userId = parseInt(userPayload.sub);
    this.logger.debug(`[Message] Processing message from user ${userId} to ${data.recipientId}`);

    const sender = await this.userRepository.findOne({ where: { id: userId } });
    if (!sender) return;

    let recipient = null;
    if (data.recipientId) {
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

    // Persist message
    const message = this.messageRepository.create({
      content: data.message,
      attachmentUrl: data.attachmentUrl,
      mediaIv: data.mediaIv,
      mediaKeys: data.mediaKeys,
      attachmentType: data.attachmentType,
      sender: sender,
      recipient: recipient ?? undefined,
      replyToMessageId: data.replyToMessageId,
      replyToSender: data.replyToSender,
      replyToMessage: data.replyToMessage,
    });
    await this.messageRepository.save(message);
    this.logger.debug(`[Message] Persisted message ID ${message.id}`);

    const broadcastData = {
      id: message.id,
      sender: sender.displayName || sender.username,
      username: sender.username,
      senderId: sender.id,
      avatarUrl: sender.avatarUrl,
      message: data.message,
      attachmentUrl: data.attachmentUrl,
      mediaIv: data.mediaIv,
      mediaKeys: data.mediaKeys,
      attachmentType: data.attachmentType,
      timestamp: this.toLocalISO(message.createdAt),
      recipientId: data.recipientId || null,
      tempId: data.tempId || null,
      reactions: message.reactions || [],
      replyToMessageId: data.replyToMessageId,
      replyToSender: data.replyToSender,
      replyToMessage: data.replyToMessage,
    };

    if (data.recipientId) {
      // Private message
      this.server.to(`user_${data.recipientId}`).to(`user_${sender.id}`).emit('message', broadcastData);
    } else {
      // Global message
      this.server.emit('message', broadcastData);
    }
  }

  // WebRTC Signaling
  @SubscribeMessage('call_user')
  handleCallUser(@MessageBody() data: { to: number; offer: any }, @ConnectedSocket() client: Socket) {
    const userPayload = client.data.user;
    if (!userPayload) return;
    this.server.to(`user_${data.to}`).emit('call_offer', {
      from: userPayload.sub,
      username: userPayload.username,
      offer: data.offer,
    });
  }

  @SubscribeMessage('call_answer')
  handleCallAnswer(@MessageBody() data: { to: number; answer: any }, @ConnectedSocket() client: Socket) {
    const userPayload = client.data.user;
    if (!userPayload) return;
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
    this.server.to(`user_${data.to}`).emit('call_rejected', {
      from: userPayload.sub,
    });
  }

  @SubscribeMessage('call_end')
  handleCallEnd(@MessageBody() data: { to: number }, @ConnectedSocket() client: Socket) {
    const userPayload = client.data.user;
    if (!userPayload) return;
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

    const message = await this.messageRepository.findOne({
      where: { id: data.messageId },
      relations: ['sender', 'recipient', 'reactions', 'reactions.user'],
    });

    if (!message) return;

    // Check if user already reacted with this emoji
    const existingReaction = message.reactions?.find(
      r => r.user.id === userPayload.sub && r.emoji === data.emoji
    );

    this.logger.log(`[Reactions] Handle reaction: MsgId=${data.messageId}, User=${userPayload.sub}, Emoji=${data.emoji}`);
    this.logger.log(`[Reactions] Existing found: ${!!existingReaction}`);

    if (existingReaction) {
      // Remove reaction (toggle off)
      await this.reactionRepository.delete(existingReaction.id);
      message.reactions = message.reactions.filter(r => r.id !== existingReaction.id);
    } else {
      // Add reaction
      const user = await this.userRepository.findOne({ where: { id: userPayload.sub } });
      if (!user) return;

      const reaction = this.reactionRepository.create({
        message,
        user,
        emoji: data.emoji,
      });
      await this.reactionRepository.save(reaction);
      message.reactions = message.reactions || [];
      message.reactions.push(reaction);
    }

    // Notify both sender and recipient
    const recipientId = message.sender.id === userPayload.sub
      ? message.recipient?.id
      : message.sender.id;

    this.server.to(`user_${userPayload.sub}`).emit('message:reaction', {
      messageId: data.messageId,
      reactions: message.reactions.map(r => ({
        id: r.id,
        emoji: r.emoji,
        userId: r.user.id,
        username: r.user.username,
      })),
    });

    if (recipientId) {
      this.server.to(`user_${recipientId}`).emit('message:reaction', {
        messageId: data.messageId,
        reactions: message.reactions.map(r => ({
          id: r.id,
          emoji: r.emoji,
          userId: r.user.id,
          username: r.user.username,
        })),
      });
    }
  }

  // ===== TYPING INDICATOR =====
  @SubscribeMessage('typing_start')
  async handleTypingStart(
    @MessageBody() data: { recipientId: number },
    @ConnectedSocket() client: Socket
  ) {
    const userPayload = client.data.user;
    if (!userPayload || !data.recipientId) return;

    // Broadcast typing status to the recipient
    this.server.to(`user_${data.recipientId}`).emit('user_typing', {
      userId: userPayload.sub,
      username: userPayload.username,
      isTyping: true,
    });
  }

  @SubscribeMessage('typing_stop')
  async handleTypingStop(
    @MessageBody() data: { recipientId: number },
    @ConnectedSocket() client: Socket
  ) {
    const userPayload = client.data.user;
    if (!userPayload || !data.recipientId) return;

    // Broadcast typing stopped to the recipient
    this.server.to(`user_${data.recipientId}`).emit('user_typing', {
      userId: userPayload.sub,
      username: userPayload.username,
      isTyping: false,
    });
  }

}

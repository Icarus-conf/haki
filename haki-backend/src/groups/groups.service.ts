import { BadRequestException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, IsNull, Repository } from 'typeorm';
import { Message } from '../chat/entities/message.entity';
import { User } from '../users/entities/user.entity';
import { UsersService } from '../users/users.service';
import { Group } from './entities/group.entity';

const MAX_MEMBERS = 50; // every message is wrapped once per member's key on the phone

@Injectable()
export class GroupsService {
    constructor(
        @InjectRepository(Group) private readonly groups: Repository<Group>,
        @InjectRepository(User) private readonly users: Repository<User>,
        @InjectRepository(Message) private readonly messages: Repository<Message>,
        private readonly usersService: UsersService,
    ) { }

    serialize(g: Group, lastMessage?: Message | null) {
        return {
            id: g.id,
            name: g.name,
            ownerId: g.owner?.id,
            members: g.members.map(u => ({
                id: u.id,
                username: u.username,
                displayName: u.displayName,
                avatarUrl: u.avatarUrl,
                publicKey: u.publicKey,
            })),
            lastMessage: lastMessage
                ? {
                    content: lastMessage.content,
                    timestamp: lastMessage.createdAt.toISOString(),
                    senderId: lastMessage.sender?.id,
                    attachmentType: lastMessage.attachmentType,
                }
                : null,
        };
    }

    async findForMember(groupId: number, userId: number): Promise<Group> {
        const g = await this.groups.findOne({ where: { id: groupId }, relations: ['owner', 'members'] });
        if (!g) throw new NotFoundException('Group not found');
        if (!g.members.some(m => m.id === userId)) throw new ForbiddenException('Not a member');
        return g;
    }

    async mine(userId: number) {
        const ids = await this.groups
            .createQueryBuilder('g')
            .innerJoin('g.members', 'm', 'm.id = :userId', { userId })
            .select('g.id', 'id')
            .getRawMany();
        if (!ids.length) return [];
        const list = await this.groups.find({ where: { id: In(ids.map(r => r.id)) }, relations: ['owner', 'members'] });
        // ponytail: one query per group for the preview; fine for tens of groups
        return Promise.all(list.map(async g => {
            const last = await this.messages.findOne({
                where: { group: { id: g.id }, scheduledAt: IsNull() },
                relations: ['sender'],
                order: { createdAt: 'DESC' },
            });
            const [{ n }] = await this.messages.query(
                `select count(*)::int n from messages m
                 where m."groupId" = $1 and m."senderId" <> $2 and m."scheduledAt" is null
                   and m.id > coalesce((select "lastReadId" from group_reads where "groupId" = $1 and "userId" = $2), 0)`,
                [g.id, userId]);
            return { ...this.serialize(g, last), unreadCount: n };
        }));
    }

    /** Only the creator's friends can be added, so nobody is put in a group by a stranger. */
    private async friendsOf(userId: number, ids: number[]): Promise<User[]> {
        const friendIds = new Set(await this.usersService.getFriendIds(userId));
        const wanted = [...new Set(ids.map(Number))].filter(id => id !== userId);
        if (wanted.some(id => !friendIds.has(id))) throw new BadRequestException('You can only add your friends');
        return wanted.length ? this.users.findBy({ id: In(wanted) }) : [];
    }

    async create(userId: number, name: string, memberIds: number[]) {
        const title = (name ?? '').trim();
        if (!title || title.length > 60) throw new BadRequestException('Give the group a name (up to 60 characters)');
        const others = await this.friendsOf(userId, memberIds ?? []);
        if (!others.length) throw new BadRequestException('Add at least one friend');
        if (others.length + 1 > MAX_MEMBERS) throw new BadRequestException(`Groups can have up to ${MAX_MEMBERS} people`);
        const owner = await this.users.findOneByOrFail({ id: userId });
        const g = await this.groups.save(this.groups.create({ name: title, owner, members: [owner, ...others] }));
        return this.serialize(g);
    }

    async addMembers(groupId: number, userId: number, memberIds: number[]) {
        const g = await this.findForMember(groupId, userId);
        const fresh = (await this.friendsOf(userId, memberIds ?? [])).filter(u => !g.members.some(m => m.id === u.id));
        if (g.members.length + fresh.length > MAX_MEMBERS) throw new BadRequestException(`Groups can have up to ${MAX_MEMBERS} people`);
        g.members.push(...fresh);
        await this.groups.save(g);
        return this.serialize(g);
    }

    /** Returns the ids that should hear about the change (remaining members + the leaver). */
    async leave(groupId: number, userId: number): Promise<number[]> {
        const g = await this.findForMember(groupId, userId);
        const everyone = g.members.map(m => m.id);
        g.members = g.members.filter(m => m.id !== userId);
        if (g.members.length === 0) {
            await this.messages.delete({ group: { id: g.id } });
            await this.groups.remove(g);
        } else {
            if (g.owner?.id === userId) g.owner = g.members[0];
            await this.groups.save(g);
        }
        return everyone;
    }

    async memberIds(groupId: number): Promise<number[]> {
        const g = await this.groups.findOne({ where: { id: groupId }, relations: ['members'] });
        return g?.members.map(m => m.id) ?? [];
    }

    /** Everyone who shares a group with [userId] (for key-change notices). */
    async coMemberIds(userId: number): Promise<number[]> {
        const rows = await this.groups
            .createQueryBuilder('g')
            .innerJoin('g.members', 'me', 'me.id = :userId', { userId })
            .innerJoin('g.members', 'other')
            .select('DISTINCT other.id', 'id')
            .getRawMany();
        return rows.map(r => Number(r.id)).filter(id => id !== userId);
    }
}

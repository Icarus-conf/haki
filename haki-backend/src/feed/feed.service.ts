import { BadRequestException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { promises as fs } from 'fs';
import * as path from 'path';
import { DataSource, In, Repository } from 'typeorm';
import { ChatGateway } from '../chat.gateway';
import { UsersService } from '../users/users.service';
import { Post, PostComment, PostKey, PostReaction } from './feed.entities';

const MAX_MEDIA = 10;
const sealed = (s: unknown) => typeof s === 'string' && s.length > 0 && s.length < 64_000;
const author = (u: any) => ({ id: u.id, username: u.username, displayName: u.displayName, avatarUrl: u.avatarUrl });

@Injectable()
export class FeedService {
    constructor(
        @InjectRepository(Post) private posts: Repository<Post>,
        @InjectRepository(PostKey) private keys: Repository<PostKey>,
        @InjectRepository(PostComment) private comments: Repository<PostComment>,
        @InjectRepository(PostReaction) private reactions: Repository<PostReaction>,
        private users: UsersService,
        private gateway: ChatGateway,
        private db: DataSource,
    ) { }

    private emit(userIds: number[], event: string, data: any) {
        for (const id of new Set(userIds)) this.gateway.server.to(`user_${id}`).emit(event, data);
    }

    /** Posts I hold a key for, by me or by someone who is still my friend. */
    private async readable(userId: number, where: { ids?: number[]; before?: number; authorId?: number }, limit = 20) {
        const friends = await this.users.getFriendIds(userId);
        const qb = this.posts.createQueryBuilder('p')
            .innerJoin(PostKey, 'k', 'k."postId" = p.id and k."userId" = :me', { me: userId })
            .addSelect('k.key', 'mykey')
            .leftJoinAndSelect('p.author', 'a')
            .where('p."authorId" in (:...authors)', { authors: [userId, ...friends] })
            .orderBy('p.id', 'DESC')
            .limit(limit);
        if (where.ids) qb.andWhere('p.id in (:...ids)', { ids: where.ids });
        if (where.before) qb.andWhere('p.id < :before', { before: where.before });
        if (where.authorId) qb.andWhere('p."authorId" = :aid', { aid: where.authorId });
        const { entities, raw } = await qb.getRawAndEntities();
        if (!entities.length) return [];
        const keyOf = new Map(raw.map((r: any) => [r.p_id, r.mykey]));
        const ids = entities.map(p => p.id);
        const [counts, reacts, mine] = await Promise.all([
            this.db.query(`select "postId", count(*)::int n from post_comments where "postId" = any($1) group by 1`, [ids]),
            this.db.query(`select "postId", emoji, count(*)::int n from post_reactions where "postId" = any($1) group by 1, 2`, [ids]),
            this.reactions.find({ where: { postId: In(ids), userId } }),
        ]);
        const commentCount = new Map(counts.map((c: any) => [c.postId, c.n]));
        const myReaction = new Map(mine.map(r => [r.postId, r.emoji]));
        return entities.map(p => ({
            id: p.id,
            author: author(p.author),
            body: p.body,
            media: p.media,
            key: keyOf.get(p.id),
            commentsOff: p.commentsOff,
            createdAt: p.createdAt,
            commentCount: commentCount.get(p.id) ?? 0,
            reactions: Object.fromEntries(reacts.filter((r: any) => r.postId === p.id).map((r: any) => [r.emoji, r.n])),
            myReaction: myReaction.get(p.id) ?? null,
        }));
    }

    feed(userId: number, before?: number, authorId?: number) {
        return this.readable(userId, { before, authorId });
    }

    async one(userId: number, postId: number) {
        const [post] = await this.readable(userId, { ids: [postId] }, 1);
        if (!post) throw new NotFoundException('Post not found');
        return post;
    }

    async create(userId: number, dto: { body: string; media?: string[]; keys: Record<string, string>; commentsOff?: boolean }) {
        if (!sealed(dto?.body)) throw new BadRequestException('Post body missing');
        const media = dto.media ?? [];
        if (!Array.isArray(media) || media.length > MAX_MEDIA || media.some(m => typeof m !== 'string' || !m.startsWith('/uploads/messages/')))
            throw new BadRequestException(`Up to ${MAX_MEDIA} uploaded files`);
        const friends = new Set(await this.users.getFriendIds(userId));
        const readers = Object.entries(dto.keys ?? {}).map(([id, key]) => ({ userId: Number(id), key }));
        // Keys only for me and my friends: a post can't be pushed into a stranger's feed
        if (!readers.some(r => r.userId === userId) || readers.some(r => !(r.userId === userId || friends.has(r.userId)) || !sealed(r.key)))
            throw new BadRequestException('Keys must be for you and your friends');

        const post = await this.db.transaction(async em => {
            const p = await em.save(Post, em.create(Post, { authorId: userId, body: dto.body, media, commentsOff: !!dto.commentsOff }));
            await em.insert(PostKey, readers.map(r => ({ ...r, postId: p.id })));
            return p;
        });
        this.emit(readers.map(r => r.userId).filter(id => id !== userId), 'post_created', { postId: post.id, userId });
        return this.one(userId, post.id);
    }

    async remove(userId: number, postId: number) {
        const post = await this.posts.findOne({ where: { id: postId } });
        if (!post) throw new NotFoundException('Post not found');
        if (post.authorId !== userId) throw new ForbiddenException('Only the author can delete a post');
        const readers = await this.keys.find({ where: { postId }, select: ['userId'] });
        await this.posts.delete(postId);
        // basename() keeps a forged URL from escaping the folder
        await Promise.all(post.media.map(u => fs.unlink(path.join(process.cwd(), 'uploads', 'messages', path.basename(u))).catch(() => { })));
        this.emit(readers.map(r => r.userId), 'post_deleted', { postId });
        return { ok: true };
    }

    /** 404 unless I can read the post: same answer for "doesn't exist" and "not yours". */
    private async access(userId: number, postId: number) {
        const post = await this.posts.findOne({ where: { id: postId } });
        const key = post && await this.keys.findOne({ where: { postId, userId } });
        if (!post || !key) throw new NotFoundException('Post not found');
        if (post.authorId !== userId && !(await this.users.getFriendIds(userId)).includes(post.authorId))
            throw new NotFoundException('Post not found');
        return post;
    }

    async listComments(userId: number, postId: number) {
        await this.access(userId, postId);
        const rows = await this.comments.find({ where: { postId }, relations: ['author'], order: { id: 'ASC' }, take: 500 });
        return rows.map(c => ({ id: c.id, parentId: c.parentId, body: c.body, createdAt: c.createdAt, author: author(c.author) }));
    }

    async addComment(userId: number, postId: number, dto: { body: string; parentId?: number }) {
        const post = await this.access(userId, postId);
        if (post.commentsOff) throw new ForbiddenException('Comments are off for this post');
        if (!sealed(dto?.body)) throw new BadRequestException('Comment missing');
        let parent: PostComment | null = null;
        if (dto.parentId) {
            parent = await this.comments.findOne({ where: { id: dto.parentId, postId } });
            if (!parent) throw new BadRequestException('Reply target not found');
        }
        // Replies to a reply attach to the top comment: one level deep
        const c = await this.comments.save(this.comments.create({ postId, authorId: userId, body: dto.body, parentId: parent ? (parent.parentId ?? parent.id) : null }));
        const full = await this.comments.findOneOrFail({ where: { id: c.id }, relations: ['author'] });
        const data = { id: full.id, parentId: full.parentId, body: full.body, createdAt: full.createdAt, author: author(full.author), postId };
        const readers = (await this.keys.find({ where: { postId }, select: ['userId'] })).map(k => k.userId);
        this.emit(readers.filter(id => id !== userId), 'post_comment', { ...data, notify: [post.authorId, parent?.authorId].filter(id => id && id !== userId) });
        return data;
    }

    async removeComment(userId: number, postId: number, commentId: number) {
        const post = await this.access(userId, postId);
        const c = await this.comments.findOne({ where: { id: commentId, postId } });
        if (!c) throw new NotFoundException('Comment not found');
        if (c.authorId !== userId && post.authorId !== userId) throw new ForbiddenException('Not your comment');
        await this.comments.delete({ postId, parentId: commentId });
        await this.comments.delete(commentId);
        return { ok: true };
    }

    /** [emoji] null removes my reaction. */
    async react(userId: number, postId: number, emoji: string | null) {
        const post = await this.access(userId, postId);
        if (emoji == null) await this.reactions.delete({ postId, userId });
        else {
            if (typeof emoji !== 'string' || !emoji.length || emoji.length > 16) throw new BadRequestException('Bad reaction');
            await this.reactions.upsert({ postId, userId, emoji }, ['postId', 'userId']);
            if (post.authorId !== userId) this.emit([post.authorId], 'post_reacted', { postId, userId, emoji });
        }
        return { ok: true, emoji };
    }
}

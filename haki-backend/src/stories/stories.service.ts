import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, MoreThan, Repository } from 'typeorm';
import { Friendship } from '../users/entities/friendship.entity';
import { User } from '../users/entities/user.entity';
import { StoryView } from './entities/story-view.entity';
import { Story } from './entities/story.entity';

@Injectable()
export class StoriesService {
    constructor(
        @InjectRepository(Story)
        private readonly storiesRepository: Repository<Story>,
        @InjectRepository(User)
        private readonly usersRepository: Repository<User>,
        @InjectRepository(Friendship)
        private readonly friendshipRepository: Repository<Friendship>,
        @InjectRepository(StoryView)
        private readonly viewsRepository: Repository<StoryView>,
    ) { }

    /** A friend's active story, or 404 — viewers can't touch strangers' or expired stories. */
    private async visibleStory(storyId: number, userId: number): Promise<Story> {
        const story = await this.storiesRepository.findOne({ where: { id: storyId, expiresAt: MoreThan(new Date()) } });
        if (!story) throw new NotFoundException('Story not found');
        if (story.userId !== userId) {
            const friend = await this.friendshipRepository.findOne({
                where: [
                    { user1: { id: userId }, user2: { id: story.userId } },
                    { user1: { id: story.userId }, user2: { id: userId } },
                ],
            });
            if (!friend) throw new NotFoundException('Story not found');
        }
        return story;
    }

    /** Records that [userId] saw it; with [liked] set, also loves / un-loves it. Own views aren't counted. */
    async view(storyId: number, userId: number, liked?: boolean): Promise<Story | null> {
        const story = await this.visibleStory(storyId, userId);
        if (story.userId === userId) return null;
        await this.viewsRepository.upsert(
            { storyId, viewerId: userId, ...(liked === undefined ? {} : { liked }) },
            ['storyId', 'viewerId'],
        );
        return story;
    }

    async viewers(storyId: number, userId: number) {
        const story = await this.storiesRepository.findOne({ where: { id: storyId } });
        if (!story) throw new NotFoundException('Story not found');
        if (story.userId !== userId) throw new ForbiddenException('Only the owner sees who viewed');
        const views = await this.viewsRepository.find({
            where: { storyId },
            relations: ['viewer'],
            order: { liked: 'DESC', viewedAt: 'DESC' },
        });
        return views.map(v => ({
            user: { id: v.viewer.id, username: v.viewer.username, displayName: v.viewer.displayName, avatarUrl: v.viewer.avatarUrl },
            liked: v.liked,
            viewedAt: v.viewedAt.toISOString(),
        }));
    }

    async createStory(userId: number, content: string, type: 'text' | 'image' = 'image') {
        const expiresAt = new Date();
        expiresAt.setHours(expiresAt.getHours() + 24);

        const story = this.storiesRepository.create({
            userId,
            content,
            type,
            expiresAt,
        });

        return this.storiesRepository.save(story);
    }

    async getActiveStories(userId: number) {
        // Get all friend IDs from friendships table
        const friendships = await this.friendshipRepository.find({
            where: [
                { user1: { id: userId } },
                { user2: { id: userId } }
            ],
            relations: ['user1', 'user2']
        });

        const friendIds = friendships.map(f =>
            f.user1.id === userId ? f.user2.id : f.user1.id
        );

        const allIds = [userId, ...friendIds];

        // Filter in SQL: loading every story and filtering in memory grew with the whole app
        const stories = await this.storiesRepository.find({
            where: { userId: In(allIds), expiresAt: MoreThan(new Date()) },
            relations: ['user'],
            order: { createdAt: 'DESC' },
        });
        if (!stories.length) return [];
        const ids = stories.map(s => s.id);
        const [mine, counts] = await Promise.all([
            this.viewsRepository.find({ where: { storyId: In(ids), viewerId: userId } }),
            this.viewsRepository
                .createQueryBuilder('v')
                .select('v.storyId', 'storyId')
                .addSelect('COUNT(*)', 'views')
                .addSelect('SUM(CASE WHEN v.liked THEN 1 ELSE 0 END)', 'likes')
                .where('v.storyId IN (:...ids)', { ids })
                .groupBy('v.storyId')
                .getRawMany(),
        ]);
        const myView = new Map(mine.map(v => [v.storyId, v]));
        const count = new Map(counts.map(c => [Number(c.storyId), c]));
        return stories.map(s => ({
            ...s,
            seen: s.userId === userId || myView.has(s.id),
            liked: myView.get(s.id)?.liked ?? false,
            // Counts only for your own stories; friends don't see each other's numbers
            ...(s.userId === userId
                ? { viewCount: Number(count.get(s.id)?.views ?? 0), likeCount: Number(count.get(s.id)?.likes ?? 0) }
                : {}),
        }));
    }
}

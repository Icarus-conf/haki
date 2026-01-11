import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { MoreThan, Repository } from 'typeorm';
import { Friendship } from '../users/entities/friendship.entity';
import { User } from '../users/entities/user.entity';
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
    ) { }

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

        return this.storiesRepository.find({
            where: {
                userId: MoreThan(0), // Placeholder to allow mixing with 'In'
                expiresAt: MoreThan(new Date()),
            },
            relations: ['user'],
            order: { createdAt: 'DESC' },
        }).then(stories => stories.filter(s => allIds.includes(s.userId)));
    }
}

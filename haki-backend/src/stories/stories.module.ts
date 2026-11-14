import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Friendship } from '../users/entities/friendship.entity';
import { User } from '../users/entities/user.entity';
import { UsersModule } from '../users/users.module';
import { StoryView } from './entities/story-view.entity';
import { Story } from './entities/story.entity';
import { StoriesController } from './stories.controller';
import { StoriesService } from './stories.service';

@Module({
    imports: [TypeOrmModule.forFeature([Story, StoryView, User, Friendship]), UsersModule],
    controllers: [StoriesController],
    providers: [StoriesService],
    exports: [StoriesService],
})
export class StoriesModule { }

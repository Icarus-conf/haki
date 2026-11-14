import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { UsersModule } from '../users/users.module';
import { FeedController } from './feed.controller';
import { Post, PostComment, PostKey, PostReaction } from './feed.entities';
import { FeedService } from './feed.service';

@Module({
    imports: [TypeOrmModule.forFeature([Post, PostKey, PostComment, PostReaction]), UsersModule],
    controllers: [FeedController],
    providers: [FeedService],
})
export class FeedModule { }

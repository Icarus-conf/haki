import { Report } from './reports/report.entity';
import { AuditLog, GroupRead, InviteCode, Session, Setting } from './platform/entities';
import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { ServeStaticModule } from '@nestjs/serve-static';
import { TypeOrmModule } from '@nestjs/typeorm';
import { join } from 'path';
import { AdminModule } from './admin/admin.module';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { AuthModule } from './auth/auth.module';
import { Message } from './chat/entities/message.entity';
import { Reaction } from './chat/entities/reaction.entity';
import { BlockedUser } from './users/entities/blocked-user.entity';
import { FriendRequest } from './users/entities/friend-request.entity';
import { Friendship } from './users/entities/friendship.entity';
import { User } from './users/entities/user.entity';
import { UsersModule } from './users/users.module';

import { ChatModule } from './chat.module';
import { StoryView } from './stories/entities/story-view.entity';
import { Story } from './stories/entities/story.entity';
import { StoriesModule } from './stories/stories.module';
import { Group } from './groups/entities/group.entity';
import { GroupsModule } from './groups/groups.module';
import { PushDevice } from './push/push-device.entity';
import { PushModule } from './push/push.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    ServeStaticModule.forRoot({
      rootPath: join(process.cwd(), 'uploads'),
      serveRoot: '/uploads',
    }),
    TypeOrmModule.forRootAsync({
      imports: [ConfigModule],
      useFactory: (configService: ConfigService) => ({
        type: 'postgres',
        host: configService.get<string>('DATABASE_HOST'),
        port: configService.get<number>('DATABASE_PORT'),
        username: configService.get<string>('DATABASE_USER'),
        password: configService.get<string>('DATABASE_PASSWORD'),
        database: configService.get<string>('DATABASE_NAME'),
        entities: [User, Message, FriendRequest, Friendship, Story, Reaction, BlockedUser, Group, StoryView, PushDevice, Report, AuditLog, Setting, InviteCode, Session, GroupRead],
        synchronize: true, // Only for development
      }),
      inject: [ConfigService],
    }),
    TypeOrmModule.forFeature([Message, User]),
    UsersModule,
    AuthModule,
    ChatModule,
    StoriesModule,
    AdminModule,
    GroupsModule,
    PushModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule { }

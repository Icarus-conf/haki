import { Global, Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthModule } from './auth/auth.module';
import { ChatGateway } from './chat.gateway';
import { Message } from './chat/entities/message.entity';
import { Reaction } from './chat/entities/reaction.entity';
import { MessagesController } from './chat/messages.controller';
import { MessagesService } from './chat/messages.service';
import { Group } from './groups/entities/group.entity';
import { Friendship } from './users/entities/friendship.entity';
import { Report } from './reports/report.entity';
import { ReportsController } from './reports/reports.controller';
import { User } from './users/entities/user.entity';
import { UsersModule } from './users/users.module';

@Global()
@Module({
    imports: [
        TypeOrmModule.forFeature([Message, User, Reaction, Friendship, Group, Report]),
        AuthModule,
        UsersModule,
    ],
    controllers: [MessagesController, ReportsController],
    providers: [ChatGateway, MessagesService],
    exports: [ChatGateway, MessagesService],
})
export class ChatModule { }

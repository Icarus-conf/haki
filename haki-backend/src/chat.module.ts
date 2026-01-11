import { Global, Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthModule } from './auth/auth.module';
import { ChatGateway } from './chat.gateway';
import { Message } from './chat/entities/message.entity';
import { Reaction } from './chat/entities/reaction.entity';
import { Friendship } from './users/entities/friendship.entity';
import { User } from './users/entities/user.entity';
import { UsersModule } from './users/users.module';

@Global()
@Module({
    imports: [
        TypeOrmModule.forFeature([Message, User, Reaction, Friendship]),
        AuthModule,
        UsersModule,
    ],
    providers: [ChatGateway],
    exports: [ChatGateway],
})
export class ChatModule { }

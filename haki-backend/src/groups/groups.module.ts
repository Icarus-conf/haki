import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Message } from '../chat/entities/message.entity';
import { User } from '../users/entities/user.entity';
import { UsersModule } from '../users/users.module';
import { Group } from './entities/group.entity';
import { GroupsController } from './groups.controller';
import { GroupsService } from './groups.service';

@Module({
    imports: [TypeOrmModule.forFeature([Group, User, Message]), UsersModule],
    controllers: [GroupsController],
    providers: [GroupsService],
    exports: [GroupsService],
})
export class GroupsModule { }

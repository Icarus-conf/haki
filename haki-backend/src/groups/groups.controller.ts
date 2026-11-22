import { Body, Controller, Delete, Get, Param, ParseIntPipe, Post, Request, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { ChatGateway } from '../chat.gateway';
import { GroupsService } from './groups.service';

@UseGuards(JwtAuthGuard)
@Controller('groups')
export class GroupsController {
    constructor(private readonly groups: GroupsService, private readonly chat: ChatGateway) { }

    @Get()
    mine(@Request() req: any) {
        return this.groups.mine(req.user.sub);
    }

    @Post()
    async create(@Request() req: any, @Body() body: { name: string; memberIds: number[] }) {
        const g = await this.groups.create(req.user.sub, body.name, body.memberIds);
        this.chat.notifyGroupChanged(g.id, g.members.map(m => m.id));
        return g;
    }

    @Post(':id/members')
    async add(@Request() req: any, @Param('id', ParseIntPipe) id: number, @Body() body: { memberIds: number[] }) {
        const g = await this.groups.addMembers(id, req.user.sub, body.memberIds);
        this.chat.notifyGroupChanged(g.id, g.members.map(m => m.id));
        return g;
    }

    @Delete(':id/members/me')
    async leave(@Request() req: any, @Param('id', ParseIntPipe) id: number) {
        this.chat.notifyGroupChanged(id, await this.groups.leave(id, req.user.sub));
        return { ok: true };
    }
}

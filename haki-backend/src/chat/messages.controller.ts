import { Controller, Get, Param, Request, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { MessagesService } from './messages.service';

@Controller('messages')
export class MessagesController {
    constructor(private readonly messagesService: MessagesService) { }

    @UseGuards(JwtAuthGuard)
    @Get('shared-media/:recipientId')
    async getSharedMedia(@Request() req: any, @Param('recipientId') recipientId: string) {
        const userId = req.user.sub;
        return this.messagesService.getSharedMedia(userId, parseInt(recipientId));
    }
}

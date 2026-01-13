import { Controller, Get, Param, Query, Request, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { LinkPreviewService } from './link-preview.service';
import { MessagesService } from './messages.service';

@Controller('messages')
export class MessagesController {
    constructor(
        private readonly messagesService: MessagesService,
        private readonly linkPreviewService: LinkPreviewService
    ) { }

    @UseGuards(JwtAuthGuard)
    @Get('shared-media/:recipientId')
    async getSharedMedia(@Request() req: any, @Param('recipientId') recipientId: string) {
        const userId = req.user.sub;
        return this.messagesService.getSharedMedia(userId, parseInt(recipientId));
    }

    @UseGuards(JwtAuthGuard)
    @Get('link-preview')
    async getLinkPreview(@Query('url') url: string) {
        if (!url) return { error: 'URL is required' };
        return this.linkPreviewService.getLinkPreview(url);
    }
}

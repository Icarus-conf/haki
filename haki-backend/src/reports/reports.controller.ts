import { BadRequestException, Body, Controller, NotFoundException, Post, Request, UseGuards } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { ChatGateway } from '../chat.gateway';
import { Report } from './report.entity';

export const REPORT_REASONS = ['spam', 'harassment', 'hate', 'violence', 'sexual', 'scam', 'other'];

@Controller('reports')
@UseGuards(JwtAuthGuard)
export class ReportsController {
    constructor(
        @InjectRepository(Report) private readonly reports: Repository<Report>,
        private readonly chat: ChatGateway,
    ) { }

    @Post()
    async create(@Request() req: any, @Body() body: { messageId: number; reason: string; note?: string; content?: string }) {
        const userId = Number(req.user.sub);
        if (!REPORT_REASONS.includes(body?.reason)) throw new BadRequestException('Pick a reason');
        const m = await this.chat.messageVisibleTo(Number(body.messageId), userId);
        if (!m) throw new NotFoundException('Message not found');
        if (m.sender.id === userId) throw new BadRequestException('You can’t report your own message');

        const open = await this.reports.findOne({ where: { reporter: { id: userId }, messageId: m.id, status: 'open' } });
        if (open) return { success: true, id: open.id };

        const clip = (s: unknown, n: number) => (typeof s === 'string' && s.trim() ? s.trim().slice(0, n) : null);
        const report = await this.reports.save(this.reports.create({
            reporter: { id: userId },
            reported: { id: m.sender.id },
            messageId: m.id,
            reason: body.reason,
            note: clip(body.note, 500),
            // The Lounge is plain text on the server already; use the stored copy there
            content: m.group || m.recipient ? clip(body.content, 2000) : m.content,
            attachmentType: m.attachmentType ?? null,
            chat: m.group ? 'group' : m.recipient ? 'direct' : 'lounge',
        }));
        return { success: true, id: report.id };
    }
}

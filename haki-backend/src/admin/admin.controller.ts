import { Body, Controller, Get, Param, Patch, Post, Query, UseGuards } from '@nestjs/common';
import { promises as fs } from 'fs';
import * as path from 'path';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';
import { ChatGateway } from '../chat.gateway';
import { UsersService } from '../users/users.service';

@Controller('admin')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('admin')
export class AdminController {
    constructor(
        private usersService: UsersService,
        private chatGateway: ChatGateway
    ) { }

    @Get('stats')
    async getStats() {
        return this.usersService.getSystemStats();
    }

    @Get('users')
    async getUsers() {
        return this.usersService.getAllUsersAdmin();
    }

    @Patch('users/:id/ban')
    async banUser(@Param('id') id: string) {
        await this.usersService.setBanStatus(parseInt(id), true);
        return { success: true, message: 'User banned' };
    }

    @Patch('users/:id/unban')
    async unbanUser(@Param('id') id: string) {
        await this.usersService.setBanStatus(parseInt(id), false);
        return { success: true, message: 'User unbanned' };
    }

    @Post('broadcast')
    async broadcast(@Body() body: { message: string }) {
        if (!body.message) return { error: 'Message is required' };
        this.chatGateway.broadcastSystemMessage(body.message);
        return { success: true, message: 'Broadcast sent' };
    }

    @Get('storage/stats')
    async getStorageStats() {
        const stats = {
            totalSize: 0,
            avatarsSize: 0,
            messagesSize: 0,
            filesCount: 0,
            byType: { image: 0, video: 0, audio: 0, other: 0 }
        };

        const avatarDir = path.join(process.cwd(), 'uploads', 'avatars');
        const messageDir = path.join(process.cwd(), 'uploads', 'messages');

        await this.scanDir(avatarDir, stats, 'avatars');
        await this.scanDir(messageDir, stats, 'messages');

        return stats;
    }

    private async scanDir(dir: string, stats: any, category: string) {
        try {
            const files = await fs.readdir(dir);
            for (const file of files) {
                const filePath = path.join(dir, file);
                const fileStats = await fs.stat(filePath);
                if (fileStats.isFile()) {
                    stats.totalSize += fileStats.size;
                    stats.filesCount++;
                    if (category === 'avatars') stats.avatarsSize += fileStats.size;
                    if (category === 'messages') stats.messagesSize += fileStats.size;

                    const ext = path.extname(file).toLowerCase();
                    if (['.jpg', '.jpeg', '.png', '.gif', '.webp'].includes(ext)) stats.byType.image += fileStats.size;
                    else if (['.mp4', '.mov', '.avi'].includes(ext)) stats.byType.video += fileStats.size;
                    else if (['.mp3', '.m4a', '.wav', '.ogg'].includes(ext)) stats.byType.audio += fileStats.size;
                    else stats.byType.other += fileStats.size;
                }
            }
        } catch (e) {
            // dir might not exist
        }
    }

    @Post('storage/cleanup')
    async cleanupStorage(@Body() body: { days: number }) {
        const days = body.days || 365; // default 1 year
        const threshold = Date.now() - (days * 24 * 60 * 60 * 1000);
        let deletedCount = 0;
        let freedSize = 0;

        const dirs = [
            path.join(process.cwd(), 'uploads', 'avatars'),
            path.join(process.cwd(), 'uploads', 'messages')
        ];

        for (const dir of dirs) {
            try {
                const files = await fs.readdir(dir);
                for (const file of files) {
                    const filePath = path.join(dir, file);
                    const fileStats = await fs.stat(filePath);
                    if (fileStats.isFile() && fileStats.mtimeMs < threshold) {
                        await fs.unlink(filePath);
                        deletedCount++;
                        freedSize += fileStats.size;
                    }
                }
            } catch (e) { }
        }


        return { success: true, deletedCount, freedSize };
    }

    @Get('analytics')
    async getAnalytics() {
        return this.usersService.getAnalytics();
    }

    @Get('logs')
    async getLogs(@Query('lines') linesArg: string) {
        const linesToRead = parseInt(linesArg) || 100;
        const logPath = path.join(process.cwd(), 'logs', 'server.log');
        try {
            const content = await fs.readFile(logPath, 'utf-8');
            const lines = content.trim().split('\n');
            const recentLines = lines.slice(-linesToRead).reverse(); // Newest first
            return recentLines.map(line => {
                try {
                    return JSON.parse(line);
                } catch {
                    return { message: line };
                }
            });
        } catch (e) {
            return [{ message: 'No logs found or error reading logs.', timestamp: new Date().toISOString(), level: 'info' }];
        }
    }
}

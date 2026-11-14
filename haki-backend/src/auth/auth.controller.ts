import { Body, Controller, Delete, Get, Param, Post, Query, Request, UseGuards } from '@nestjs/common';
import { ChatGateway } from '../chat.gateway';
import { AuthService } from './auth.service';
import { JwtAuthGuard } from './jwt-auth.guard';

@Controller('auth')
export class AuthController {
    constructor(private authService: AuthService, private chat: ChatGateway) { }

    @Get('signup')
    async signup() {
        return { mode: await this.authService.signupMode() };
    }

    @Post('register')
    async register(@Body() body: any) {
        return this.authService.register(body.username, body.email, body.password, body.inviteCode);
    }

    @Post('login')
    async login(@Body() body: any) {
        return this.authService.login(body.username, body.password, body.code, { name: body.deviceName, platform: body.platform });
    }

    // ===== Devices =====
    @UseGuards(JwtAuthGuard)
    @Get('sessions')
    async sessions(@Request() req: any) {
        const list = (await this.authService.sessions(req.user.sub)).map(s => ({ ...s, current: s.id === req.user.sid }));
        // Signed in before devices were tracked: still show the device you're on (it can't be removed)
        if (!req.user.sid) {
            const now = new Date();
            list.unshift({ id: '', userId: req.user.sub, name: 'Phone', platform: 'ios', kind: 'login', createdAt: now, lastSeenAt: now, revokedAt: null, current: true });
        }
        return list;
    }

    @UseGuards(JwtAuthGuard)
    @Delete('sessions/:id')
    async revoke(@Request() req: any, @Param('id') id: string) {
        await this.authService.revokeSession(req.user.sub, id);
        this.chat.disconnectSession(id);
        return { success: true };
    }

    // ===== Two-step login =====
    @UseGuards(JwtAuthGuard)
    @Get('2fa')
    status(@Request() req: any) {
        return this.authService.twoFactorStatus(req.user.sub);
    }

    @UseGuards(JwtAuthGuard)
    @Post('2fa/setup')
    setup(@Request() req: any) {
        return this.authService.setupTwoFactor(req.user.sub);
    }

    @UseGuards(JwtAuthGuard)
    @Post('2fa/enable')
    enable(@Request() req: any, @Body() body: { code: string }) {
        return this.authService.enableTwoFactor(req.user.sub, body?.code);
    }

    @UseGuards(JwtAuthGuard)
    @Post('2fa/disable')
    disable(@Request() req: any, @Body() body: { code: string }) {
        return this.authService.disableTwoFactor(req.user.sub, body?.code);
    }

    // ===== Linking a new device =====
    @Post('link')
    startLink(@Body() body: { pub: string; name?: string; platform?: string }) {
        return this.authService.startLink(body?.pub, body?.name, body?.platform);
    }

    @Get('link/:code')
    pollLink(@Param('code') code: string, @Query('secret') secret: string) {
        return this.authService.pollLink(code, secret);
    }

    @UseGuards(JwtAuthGuard)
    @Get('link/:code/peek')
    peekLink(@Param('code') code: string) {
        return this.authService.peekLink(code);
    }

    @UseGuards(JwtAuthGuard)
    @Post('link/:code/approve')
    approveLink(@Request() req: any, @Param('code') code: string, @Body() body: { sealed: string; pub: string }) {
        return this.authService.approveLink(req.user, code, body?.sealed, body?.pub);
    }
}

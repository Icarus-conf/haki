import { Body, Controller, Post, Request, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { PushService } from './push.service';

@UseGuards(JwtAuthGuard)
@Controller('push/devices')
export class PushController {
    constructor(private readonly push: PushService) { }

    @Post()
    async register(@Request() req: any, @Body() body: { token: string; platform?: string }) {
        return { ok: await this.push.register(req.user.sub, body?.token, body?.platform) };
    }

    /** Sign-out: this phone stops getting this account's notifications. */
    @Post('remove')
    async remove(@Request() req: any, @Body() body: { token: string }) {
        await this.push.unregister(req.user.sub, body?.token);
        return { ok: true };
    }
}

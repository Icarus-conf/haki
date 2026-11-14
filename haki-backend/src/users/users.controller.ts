import {
    BadRequestException,
    Body,
    Controller,
    Delete,
    Get,
    Param,
    Put,
    Patch,
    Post,
    Request,
    UploadedFile,
    UseGuards,
    UseInterceptors
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { diskStorage } from 'multer';
import { extname } from 'path';
import { v4 as uuidv4 } from 'uuid';
import { JwtAuthGuard } from '../auth/jwt-auth.guard'; // I need to create this guard
import { ChatGateway } from '../chat.gateway';
import { UsersService } from './users.service';

@Controller('users')
export class UsersController {
    constructor(
        private readonly usersService: UsersService,
        private readonly chatGateway: ChatGateway
    ) { }

    /** Every "this is you" response carries the sealed username, or the app forgets it on refresh. */
    private async withHandle(user: any) {
        return user && { ...user, handleSealed: await this.usersService.handleSealedFor(user.id) };
    }

    @UseGuards(JwtAuthGuard)
    @Get('me')
    async getMe(@Request() req: any) {
        // Sealed to the user's own key: any of their phones can read it, the server can't
        return this.withHandle(await this.usersService.findOneById(req.user.sub));
    }

    @UseGuards(JwtAuthGuard)
    @Put('me/handle')
    async setHandle(@Request() req: any, @Body() body: { handle: string; sealed: string }) {
        await this.usersService.setHandle(req.user.sub, body?.handle, body?.sealed);
        return { success: true };
    }

    @UseGuards(JwtAuthGuard)
    @Delete('me/handle')
    async clearHandle(@Request() req: any) {
        await this.usersService.clearHandle(req.user.sub);
        return { success: true };
    }

    /** App data only this user can read (sealed to their own key on the phone). Restored with the 12 words. */
    @UseGuards(JwtAuthGuard)
    @Put('me/backup')
    async putBackup(@Request() req: any, @Body() body: { sealed: string }) {
        if (typeof body?.sealed !== 'string' || body.sealed.length > 2_000_000) throw new BadRequestException('Backup too large');
        await this.usersService.saveBackup(req.user.sub, body.sealed);
        return { success: true };
    }

    @UseGuards(JwtAuthGuard)
    @Get('me/backup')
    getBackup(@Request() req: any) {
        return this.usersService.backupFor(req.user.sub);
    }

    @UseGuards(JwtAuthGuard)
    @Patch('profile')
    async updateProfile(@Request() req: any, @Body() body: { displayName?: string; bio?: string; publicKey?: string; birthday?: string | null }) {
        if (body.birthday !== undefined) {
            // MM-DD with a real month/day, or null/'' to remove it
            const b = body.birthday || null;
            if (b && !/^(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01])$/.test(b)) throw new BadRequestException('Birthday must look like 04-23');
            body.birthday = b;
        }
        const before = body.publicKey ? await this.usersService.findOneById(req.user.sub) : null;
        const user = await this.usersService.updateProfile(req.user.sub, body);
        // A new key (new phone, restore) must reach friends right away, or they keep
        // encrypting to the old key and this user can't read their messages.
        if (body.publicKey && before?.publicKey !== body.publicKey) {
            const friendIds = await this.usersService.getFriendIds(req.user.sub);
            await this.chatGateway.notifyKeyChanged(req.user.sub, body.publicKey, friendIds);
        }
        return this.withHandle(user);
    }

    @UseGuards(JwtAuthGuard)
    @Patch('status')
    async updateStatus(@Request() req: any, @Body() body: { statusMessage: string }) {
        const user = await this.usersService.updateStatus(req.user.sub, body.statusMessage);
        // Notify all friends about status change
        this.chatGateway.notifyStatusChange(req.user.sub, body.statusMessage);
        return this.withHandle(user);
    }

    @UseGuards(JwtAuthGuard)
    @Post('avatar')
    @UseInterceptors(
        FileInterceptor('file', {
            storage: diskStorage({
                destination: './uploads/avatars',
                filename: (req, file, cb) => {
                    const fileName = uuidv4();
                    cb(null, `${fileName}${extname(file.originalname)}`);
                },
            }),
        }),
    )
    async uploadAvatar(@Request() req: any, @UploadedFile() file: Express.Multer.File) {
        const avatarUrl = `/uploads/avatars/${file.filename}`;
        await this.usersService.updateAvatar(req.user.sub, avatarUrl);
        return { avatarUrl };
    }

    @UseGuards(JwtAuthGuard)
    @Post('upload')
    @UseInterceptors(
        FileInterceptor('file', {
            storage: diskStorage({
                destination: './uploads/messages',
                filename: (req, file, cb) => {
                    const fileName = uuidv4();
                    cb(null, `${fileName}${extname(file.originalname)}`);
                },
            }),
            limits: { fileSize: 60 * 1024 * 1024 }, // 50 MB videos/files, plus encryption overhead
        }),
    )
    async uploadAttachment(@UploadedFile() file: Express.Multer.File) {
        return { attachmentUrl: `/uploads/messages/${file.filename}` };
    }

    @UseGuards(JwtAuthGuard)
    @Get('friends')
    async getFriends(@Request() req: any) {
        return this.usersService.getFriends(parseInt(req.user.sub));
    }

    @UseGuards(JwtAuthGuard)
    @Get('friends/requests')
    async getRequests(@Request() req: any) {
        return this.usersService.getPendingRequests(parseInt(req.user.sub));
    }

    @UseGuards(JwtAuthGuard)
    @Post('friends/requests')
    async sendRequest(@Request() req: any, @Body() body: { email?: string; username?: string }) {
        const identifier = (body.username ?? body.email ?? '').trim();
        if (!identifier) throw new BadRequestException('email or username is required');
        const request = await this.usersService.sendFriendRequest(parseInt(req.user.sub), identifier);

        // Notify recipient via gateway
        this.chatGateway.notifyFriendRequest(request.recipient.id, request.sender);

        return request;
    }

    @UseGuards(JwtAuthGuard)
    @Post('friends/requests/:id/accept')
    async acceptRequest(@Request() req: any, @Param('id') id: string) {
        const request = await this.usersService.acceptFriendRequest(parseInt(req.user.sub), parseInt(id));

        // Notify original sender that their request was accepted
        // Sender is request.sender, Recipient is request.recipient (me)
        this.chatGateway.notifyFriendAccepted(request.sender.id, request.recipient);

        return request;
    }

    @UseGuards(JwtAuthGuard)
    @Post('friends/requests/:id/decline')
    async declineRequest(@Request() req: any, @Param('id') id: string) {
        return this.usersService.declineFriendRequest(parseInt(req.user.sub), parseInt(id));
    }

    @UseGuards(JwtAuthGuard)
    @Post('friends/remove')
    async removeFriend(@Request() req: any, @Body() body: { friendId: number }) {
        await this.usersService.removeFriend(parseInt(req.user.sub), body.friendId);
        this.chatGateway.notifyFriendRemoved(parseInt(req.user.sub), body.friendId);
        return { success: true };
    }

    // Block/Unblock endpoints
    @UseGuards(JwtAuthGuard)
    @Post('block')
    async blockUser(@Request() req: any, @Body() body: { userId: number }) {
        await this.usersService.blockUser(parseInt(req.user.sub), body.userId);
        return { success: true };
    }

    @UseGuards(JwtAuthGuard)
    @Post('unblock')
    async unblockUser(@Request() req: any, @Body() body: { userId: number }) {
        await this.usersService.unblockUser(parseInt(req.user.sub), body.userId);
        return { success: true };
    }

    @UseGuards(JwtAuthGuard)
    @Get('blocked')
    async getBlockedUsers(@Request() req: any) {
        return this.usersService.getBlockedUsers(parseInt(req.user.sub));
    }
}


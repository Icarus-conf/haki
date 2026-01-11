import {
    Body,
    Controller,
    Get,
    Param,
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

    @UseGuards(JwtAuthGuard)
    @Get('me')
    getMe(@Request() req: any) {
        return this.usersService.findOneById(req.user.sub);
    }

    @UseGuards(JwtAuthGuard)
    @Get()
    findAll() {
        return this.usersService.findAll();
    }

    @UseGuards(JwtAuthGuard)
    @Patch('profile')
    updateProfile(@Request() req: any, @Body() body: { displayName?: string; bio?: string; publicKey?: string }) {
        return this.usersService.updateProfile(req.user.sub, body);
    }

    @UseGuards(JwtAuthGuard)
    @Patch('status')
    async updateStatus(@Request() req: any, @Body() body: { statusMessage: string }) {
        const user = await this.usersService.updateStatus(req.user.sub, body.statusMessage);
        // Notify all friends about status change
        this.chatGateway.notifyStatusChange(req.user.sub, body.statusMessage);
        return user;
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
    async sendRequest(@Request() req: any, @Body() body: { email: string }) {
        const request = await this.usersService.sendFriendRequest(parseInt(req.user.sub), body.email);

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
}


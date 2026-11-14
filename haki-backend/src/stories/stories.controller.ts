import {
    Body,
    Controller,
    Get,
    Param,
    ParseIntPipe,
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
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { ChatGateway } from '../chat.gateway';
import { UsersService } from '../users/users.service';
import { StoriesService } from './stories.service';

@Controller('stories')
export class StoriesController {
    constructor(
        private readonly storiesService: StoriesService,
        private readonly usersService: UsersService,
        private readonly chatGateway: ChatGateway,
    ) { }

    @UseGuards(JwtAuthGuard)
    @Get('active')
    async getActive(@Request() req: any) {
        return this.storiesService.getActiveStories(req.user.sub);
    }

    @UseGuards(JwtAuthGuard)
    @Post()
    @UseInterceptors(
        FileInterceptor('file', {
            storage: diskStorage({
                destination: './uploads/stories',
                filename: (req, file, cb) => {
                    const fileName = uuidv4();
                    cb(null, `${fileName}${extname(file.originalname)}`);
                },
            }),
        }),
    )
    async createStory(
        @Request() req: any,
        @UploadedFile() file: Express.Multer.File,
        @Body() body: { type?: 'text' | 'image' }
    ) {
        const content = `/uploads/stories/${file.filename}`;
        const story = await this.storiesService.createStory(req.user.sub, content, body.type || 'image');
        // Friends' story rows only refreshed on sign-in before; tell them now
        const friendIds = await this.usersService.getFriendIds(req.user.sub);
        this.chatGateway.notifyStoryPosted(req.user.sub, friendIds);
        return story;
    }

    @UseGuards(JwtAuthGuard)
    @Post(':id/view')
    async view(@Request() req: any, @Param('id', ParseIntPipe) id: number) {
        await this.storiesService.view(id, req.user.sub);
        return { ok: true };
    }

    /** Love (or un-love) a friend's story; the owner hears about a new love right away. */
    @UseGuards(JwtAuthGuard)
    @Post(':id/like')
    async like(@Request() req: any, @Param('id', ParseIntPipe) id: number, @Body() body: { liked?: boolean }) {
        const liked = body?.liked !== false;
        const story = await this.storiesService.view(id, req.user.sub, liked);
        if (story && liked) this.chatGateway.notifyStoryLiked(story.userId, id, req.user.sub);
        return { ok: true, liked };
    }

    @UseGuards(JwtAuthGuard)
    @Get(':id/viewers')
    viewers(@Request() req: any, @Param('id', ParseIntPipe) id: number) {
        return this.storiesService.viewers(id, req.user.sub);
    }
}

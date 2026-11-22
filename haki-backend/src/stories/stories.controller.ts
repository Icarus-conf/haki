import {
    BadRequestException,
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
import { promises as fs } from 'fs';
import { diskStorage } from 'multer';
import { v4 as uuidv4 } from 'uuid';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { ChatGateway } from '../chat.gateway';
import { StoriesService } from './stories.service';

/** Plain JPEG / PNG / GIF / WebP / HEIC-MP4 headers: a story file must be sealed, never the picture itself. */
const looksPlain = (b: Buffer) =>
    ['ffd8ff', '89504e47', '47494638', '52494646'].some(m => b.subarray(0, m.length / 2).toString('hex') === m) ||
    b.subarray(4, 8).toString('latin1') === 'ftyp';

async function head(path: string) {
    const f = await fs.open(path, 'r');
    try {
        const b = Buffer.alloc(12);
        await f.read(b, 0, 12, 0);
        return b;
    } finally {
        await f.close();
    }
}

@Controller('stories')
export class StoriesController {
    constructor(
        private readonly storiesService: StoriesService,
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
                // Sealed bytes: the name tells nothing about the content
                filename: (req, file, cb) => cb(null, `${uuidv4()}.enc`),
            }),
        }),
    )
    async createStory(
        @Request() req: any,
        @UploadedFile() file: Express.Multer.File,
        @Body() body: { type?: 'text' | 'image'; iv?: string; keys?: string }
    ) {
        if (!file) throw new BadRequestException('Story file missing');
        try {
            if (looksPlain(await head(file.path))) throw new BadRequestException('Story must be sealed on the device');
            let keys: Record<string, string>;
            try {
                keys = JSON.parse(body.keys ?? '');
            } catch {
                throw new BadRequestException('Story keys missing');
            }
            const content = `/uploads/stories/${file.filename}`;
            const { readers, ...story } = await this.storiesService.createStory(req.user.sub, content, body.iv ?? '', keys, body.type || 'image');
            // Only friends holding a key hear about it
            this.chatGateway.notifyStoryPosted(req.user.sub, readers.filter(id => id !== req.user.sub));
            return story;
        } catch (e) {
            await fs.unlink(file.path).catch(() => { });
            throw e;
        }
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

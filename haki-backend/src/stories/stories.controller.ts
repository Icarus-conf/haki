import {
    Body,
    Controller,
    Get,
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
import { StoriesService } from './stories.service';

@Controller('stories')
export class StoriesController {
    constructor(private readonly storiesService: StoriesService) { }

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
        return this.storiesService.createStory(req.user.sub, content, body.type || 'image');
    }
}

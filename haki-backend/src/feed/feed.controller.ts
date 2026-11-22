import { Body, Controller, Delete, Get, Param, ParseIntPipe, Post, Query, Request, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { FeedService } from './feed.service';

@Controller('feed')
@UseGuards(JwtAuthGuard)
export class FeedController {
    constructor(private feed: FeedService) { }

    /** Newest first, 20 at a time; pass the last id as [before] for more. [user] = one author's posts. */
    @Get()
    list(@Request() req: any, @Query('before') before?: string, @Query('user') user?: string) {
        return this.feed.feed(req.user.sub, Number(before) || undefined, Number(user) || undefined);
    }

    @Get(':id')
    one(@Request() req: any, @Param('id', ParseIntPipe) id: number) {
        return this.feed.one(req.user.sub, id);
    }

    @Post()
    create(@Request() req: any, @Body() body: any) {
        return this.feed.create(req.user.sub, body);
    }

    @Delete(':id')
    remove(@Request() req: any, @Param('id', ParseIntPipe) id: number) {
        return this.feed.remove(req.user.sub, id);
    }

    @Get(':id/comments')
    comments(@Request() req: any, @Param('id', ParseIntPipe) id: number) {
        return this.feed.listComments(req.user.sub, id);
    }

    @Post(':id/comments')
    comment(@Request() req: any, @Param('id', ParseIntPipe) id: number, @Body() body: any) {
        return this.feed.addComment(req.user.sub, id, body);
    }

    @Delete(':id/comments/:cid')
    uncomment(@Request() req: any, @Param('id', ParseIntPipe) id: number, @Param('cid', ParseIntPipe) cid: number) {
        return this.feed.removeComment(req.user.sub, id, cid);
    }

    @Post(':id/react')
    react(@Request() req: any, @Param('id', ParseIntPipe) id: number, @Body() body: { emoji?: string | null }) {
        return this.feed.react(req.user.sub, id, body?.emoji ?? null);
    }
}

import { BadRequestException, Body, Controller, Delete, Get, NotFoundException, Param, ParseIntPipe, Patch, Post, Put, Query, Request, UseGuards } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { promises as fs } from 'fs';
import * as path from 'path';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';
import { AuthService } from '../auth/auth.service';
import { ChatGateway } from '../chat.gateway';
import { UsersService } from '../users/users.service';

@Controller('admin')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('admin')
export class AdminController {
    constructor(
        private usersService: UsersService,
        private chatGateway: ChatGateway,
        private db: DataSource,
        private auth: AuthService,
    ) { }

    private audit(req: any, action: string, target?: string | number | null, detail?: string | null) {
        return this.db.query(`insert into audit_logs ("adminId", admin, action, target, detail) values ($1, $2, $3, $4, $5)`,
            [req.user.sub, req.user.username, action, target == null ? null : String(target), detail ?? null]);
    }

    /** createdAt is a naive timestamp in the DB's zone; shift it to the viewer's zone for day/hour buckets. */
    private static local(tz?: string) {
        return /^[A-Za-z_]+(\/[A-Za-z_+-]+){0,2}$|^UTC$/.test(tz ?? '') ? tz! : 'UTC';
    }

    /** One call for the whole Overview page. Only counts and timestamps: message content is E2EE anyway. */
    @Get('overview')
    async overview(@Query('tz') tzArg?: string) {
        const tz = AdminController.local(tzArg);
        const at = `("createdAt" at time zone current_setting('TimeZone')) at time zone $1`;
        const [totals] = await this.db.query(`select
            (select count(*) from users)::int users,
            (select count(*) from users where "isBanned")::int banned,
            (select count(*) from messages where "scheduledAt" is null)::int messages,
            (select count(*) from messages where "scheduledAt" is not null)::int scheduled,
            (select count(*) from groups)::int groups,
            (select count(*) from stories where "expiresAt" > now())::int "activeStories",
            (select count(*) from friendships)::int friendships,
            (select count(distinct "userId") from push_devices)::int "pushUsers",
            (select count(distinct "senderId") from messages where "createdAt" >= now() - interval '1 day')::int dau,
            (select count(distinct "senderId") from messages where "createdAt" >= now() - interval '7 days')::int wau,
            (select count(distinct "senderId") from messages where "createdAt" >= now() - interval '30 days')::int mau,
            (select count(*) from reports where status = 'open')::int "openReports",
            (select count(*) from users where "totpEnabled")::int "twoStepUsers"`);
        const daily = await this.db.query(
            `select to_char((${at})::date, 'YYYY-MM-DD') as "date", count(*)::int messages, count(distinct "senderId")::int active
             from messages where "createdAt" >= now() - interval '31 days' and "scheduledAt" is null group by 1`, [tz]);
        const signups = await this.db.query(
            `select to_char((${at})::date, 'YYYY-MM-DD') as "date", count(*)::int users
             from users where "createdAt" >= now() - interval '31 days' group by 1`, [tz]);
        const mix = await this.db.query(
            `select coalesce("attachmentType", 'text') kind,
                    case when "groupId" is not null then 'group' when "recipientId" is not null then 'direct' else 'lounge' end channel,
                    count(*)::int n
             from messages where "scheduledAt" is null group by 1, 2`);
        const heatmap = await this.db.query(
            `select extract(dow from ${at})::int as dow, extract(hour from ${at})::int as "hour", count(*)::int n
             from messages where "createdAt" >= now() - interval '28 days' and "scheduledAt" is null group by 1, 2`, [tz]);
        return { totals: { ...totals, online: this.chatGateway.onlineUserIds().length, calls: this.chatGateway.activeCalls().length }, daily, signups, mix, heatmap, tz };
    }

    // ===== REPORTS =====
    @Get('reports')
    async reports(@Query('status') status = 'open') {
        const st = ['open', 'resolved', 'dismissed'].includes(status) ? status : 'open';
        return this.db.query(
            `select r.id, r."messageId", r.reason, r.note, r.content, r."attachmentType", r.chat, r.status, r."createdAt", r."resolvedAt",
                    ru.id "reporterId", ru.username "reporterUsername", ru."displayName" "reporterName",
                    u.id "reportedId", u.username "reportedUsername", u."displayName" "reportedName", u."avatarUrl" "reportedAvatar", u."isBanned" "reportedBanned",
                    (select count(*) from reports x where x."reportedId" = u.id)::int "reportsAgainst",
                    exists(select 1 from messages m where m.id = r."messageId") "messageExists"
             from reports r join users ru on ru.id = r."reporterId" join users u on u.id = r."reportedId"
             where r.status = $1 order by r."createdAt" desc limit 200`, [st]);
    }

    @Patch('reports/:id')
    async resolveReport(@Request() req: any, @Param('id', ParseIntPipe) id: number, @Body() body: { status: string }) {
        if (!['resolved', 'dismissed', 'open'].includes(body?.status)) throw new NotFoundException('Unknown status');
        await this.audit(req, `report.${body.status === 'open' ? 'reopen' : body.status}`, `report #${id}`);
        await this.db.query(`update reports set status = $1, "resolvedAt" = case when $1 = 'open' then null else now() end where id = $2`, [body.status, id]);
        return { success: true };
    }

    /** Removes the reported message for everyone in its chat and closes every report about it. */
    @Delete('reports/:id/message')
    async deleteReported(@Request() req: any, @Param('id', ParseIntPipe) id: number) {
        const [r] = await this.db.query(`select "messageId" from reports where id = $1`, [id]);
        if (!r) throw new NotFoundException('No such report');
        await this.audit(req, 'message.delete', `message #${r.messageId}`, `from report #${id}`);
        await this.chatGateway.adminDeleteMessage(r.messageId);
        await this.db.query(`update reports set status = 'resolved', "resolvedAt" = now() where "messageId" = $1 and status = 'open'`, [r.messageId]);
        return { success: true };
    }

    /** Recent public Lounge messages (the only plaintext chat) for moderation. */
    @Get('lounge')
    async lounge(@Query('limit') limitArg?: string) {
        const limit = Math.min(Math.max(parseInt(limitArg ?? '') || 50, 1), 200);
        return this.db.query(
            `select m.id, m.content, m."createdAt", m."attachmentType", u.id "senderId", u.username, u."displayName", u."isBanned"
             from messages m join users u on u.id = m."senderId"
             where m."groupId" is null and m."recipientId" is null and m."scheduledAt" is null
             order by m.id desc limit $1`, [limit]);
    }

    @Delete('lounge/:id')
    async deleteLounge(@Request() req: any, @Param('id', ParseIntPipe) id: number) {
        const [m] = await this.db.query(`select left(content, 200) content from messages where id = $1`, [id]);
        if (!(await this.chatGateway.adminDeleteLoungeMessage(id))) throw new NotFoundException('No such Lounge message');
        await this.audit(req, 'lounge.delete', `message #${id}`, m?.content);
        return { success: true };
    }

    private async who(id: string | number) {
        const [u] = await this.db.query(`select username from users where id = $1`, [Number(id)]);
        return u ? `@${u.username}` : `user #${id}`;
    }

    // ===== AUDIT LOG =====
    @Get('audit')
    auditLog(@Query('limit') limitArg?: string) {
        const limit = Math.min(Math.max(parseInt(limitArg ?? '') || 100, 1), 500);
        return this.db.query(`select * from audit_logs order by id desc limit $1`, [limit]);
    }

    // ===== DEVICES (signed-in phones, computers and browsers; from sessions, never content) =====
    @Get('devices')
    async devices() {
        const q = (sql: string, args: any[] = []) => this.db.query(sql, args);
        // Which sessions have a live socket right now
        const live = new Set<string>();
        for (const s of await this.chatGateway.server.fetchSockets()) {
            const sid = (s.data as any)?.user?.sid;
            if (sid) live.add(sid);
        }
        const [platforms, daily, multi, push, recent, [totals]] = await Promise.all([
            q(`select platform,
                      count(*) filter (where "revokedAt" is null)::int active,
                      count(*) filter (where "revokedAt" is null and "lastSeenAt" >= now() - interval '7 days')::int "seen7d",
                      count(*) filter (where "revokedAt" is null and kind = 'linked')::int linked,
                      array_agg(id::text) filter (where "revokedAt" is null) ids
               from sessions group by 1 order by 2 desc`),
            q(`select to_char(d, 'YYYY-MM-DD') as day,
                      count(s.id) filter (where s.kind = 'login')::int logins,
                      count(s.id) filter (where s.kind = 'linked')::int links
               from generate_series(current_date - 13, current_date, interval '1 day') d
               left join sessions s on s."createdAt"::date = d::date
               group by d order by d`),
            q(`select least(n, 4)::int devices, count(*)::int users from (
                 select "userId", count(*) n from sessions where "revokedAt" is null group by 1) t
               group by 1 order by 1`),
            q(`select platform, count(*)::int count from push_devices group by 1 order by 2 desc`),
            q(`select s.id, u.username, s.name, s.platform, s.kind, s."createdAt", s."lastSeenAt", s."revokedAt"
               from sessions s join users u on u.id = s."userId" order by greatest(s."createdAt", coalesce(s."revokedAt", s."createdAt")) desc limit 15`),
            q(`select count(*) filter (where "revokedAt" is null)::int active,
                      count(*) filter (where "revokedAt" is null and kind = 'linked')::int linked,
                      count(*) filter (where "revokedAt" >= now() - interval '30 days')::int removed30d,
                      count(distinct "userId") filter (where "revokedAt" is null)::int users
               from sessions`),
        ]);
        const byPlatform = platforms.map((p: any) => {
            const { ids, ...rest } = p;
            return { ...rest, online: (ids ?? []).filter((id: string) => live.has(id)).length };
        });
        return {
            totals: { ...totals, online: live.size },
            platforms: byPlatform,
            daily,
            multi,
            push,
            recent: recent.map((r: any) => ({ ...r, online: live.has(r.id) })),
        };
    }

    /** Feed activity. Posts and comments are sealed, so this is counts only. */
    @Get('feed')
    async feedStats() {
        const q = (sql: string) => this.db.query(sql);
        const [[totals], daily, top] = await Promise.all([
            q(`select (select count(*) from posts)::int posts,
                      (select count(*) from posts where "createdAt" >= now() - interval '7 days')::int "posts7d",
                      (select count(*) from post_comments)::int comments,
                      (select count(*) from post_reactions)::int reactions,
                      (select count(distinct "authorId") from posts where "createdAt" >= now() - interval '7 days')::int "posters7d",
                      (select coalesce(sum(json_array_length(media::json)), 0) from posts)::int media,
                      (select round(avg(n), 1) from (select count(*) n from post_keys group by "postId") t)::float "avgReaders"`),
            q(`select to_char(d, 'YYYY-MM-DD') as day,
                      (select count(*) from posts p where p."createdAt"::date = d::date)::int posts,
                      (select count(*) from post_comments c where c."createdAt"::date = d::date)::int comments,
                      (select count(*) from post_reactions r where r."createdAt"::date = d::date)::int reactions
               from generate_series(current_date - 13, current_date, interval '1 day') d order by d`),
            q(`select u.username, count(p.id)::int posts,
                      (select count(*) from post_comments c join posts p2 on p2.id = c."postId" where p2."authorId" = u.id)::int comments
               from posts p join users u on u.id = p."authorId"
               where p."createdAt" >= now() - interval '30 days' group by u.id order by 2 desc limit 8`),
        ]);
        return { totals, daily, top };
    }

    // ===== SPAM SIGNALS (metadata only: counts and timestamps, never content) =====
    @Get('signals')
    async signals() {
        const rows: { id: number; kind: string; label: string; value: number }[] = [];
        const add = (list: any[], kind: string, label: (v: number) => string) =>
            list.forEach(r => rows.push({ id: Number(r.id), kind, label: label(Number(r.v)), value: Number(r.v) }));

        add(await this.db.query(
            `select "senderId" id, max(n) v from (
               select "senderId", count(*) n from messages where "createdAt" >= now() - interval '1 day'
               group by 1, date_trunc('minute', "createdAt")) t group by 1 having max(n) >= 15`),
            'burst', v => `${v} messages in one minute`);
        add(await this.db.query(
            `select r."senderId" id, count(*) v from friend_requests r
             where r."createdAt" >= now() - interval '1 day' group by 1 having count(*) >= 10`),
            'requests', v => `${v} friend requests today`);
        add(await this.db.query(
            `select u.id, count(m.id) v from users u join messages m on m."senderId" = u.id
             where u."createdAt" >= now() - interval '2 days' group by u.id having count(m.id) >= 50`),
            'new', v => `New account, ${v} messages already`);
        add(await this.db.query(
            `select "reportedId" id, count(*) v from reports where status = 'open' group by 1 having count(*) >= 2`),
            'reports', v => `${v} open reports`);
        const now = Date.now();
        for (const [id, hits] of this.chatGateway.rateHits) {
            const n = hits.filter(t => now - t < 86_400_000).length;
            if (n) rows.push({ id, kind: 'ratelimit', label: `Hit the send limit ${n}×`, value: n });
        }
        if (!rows.length) return [];

        const weight: Record<string, number> = { burst: 2, requests: 2, new: 1, reports: 3, ratelimit: 3 };
        const users = await this.db.query(
            `select id, username, "displayName", "avatarUrl", "isBanned", "createdAt" from users where id = any($1)`,
            [[...new Set(rows.map(r => r.id))]]);
        return users.map((u: any) => {
            const signals = rows.filter(r => r.id === u.id).map(({ kind, label, value }) => ({ kind, label, value }));
            return { ...u, signals, score: signals.reduce((a, s) => a + (weight[s.kind] ?? 1), 0) };
        }).sort((a: any, b: any) => b.score - a.score);
    }

    // ===== SIGN-UPS AND INVITES =====
    @Get('access')
    async access() {
        const [mode, invites] = await Promise.all([
            this.auth.signupMode(),
            this.db.query(`select * from invite_codes order by id desc limit 200`),
        ]);
        return { mode, invites };
    }

    @Put('access/mode')
    async setMode(@Request() req: any, @Body() body: { mode: string }) {
        if (!['open', 'invite', 'closed'].includes(body?.mode)) throw new BadRequestException('Unknown mode');
        await this.db.query(`insert into settings (key, value) values ('signupMode', $1) on conflict (key) do update set value = $1`, [body.mode]);
        await this.audit(req, 'signup.mode', body.mode);
        return { mode: body.mode };
    }

    @Post('invites')
    async createInvite(@Request() req: any, @Body() body: { maxUses?: number; days?: number; note?: string }) {
        const maxUses = Math.min(Math.max(Number(body?.maxUses) || 1, 1), 1000);
        const days = Number(body?.days) || 0;
        const code = AuthService.code(8);
        const [row] = await this.db.query(
            `insert into invite_codes (code, "maxUses", note, "createdBy", "expiresAt")
             values ($1, $2, $3, $4, case when $5::int > 0 then now() + ($5::int || ' days')::interval end) returning *`,
            [code, maxUses, body?.note?.slice(0, 80) || null, req.user.username, Math.min(days, 365)]);
        await this.audit(req, 'invite.create', code, `${maxUses} use${maxUses === 1 ? '' : 's'}${days ? `, ${days} days` : ''}`);
        return row;
    }

    @Delete('invites/:id')
    async revokeInvite(@Request() req: any, @Param('id', ParseIntPipe) id: number) {
        const rows = await this.db.query(`update invite_codes set revoked = true where id = $1 returning code`, [id]);
        const code = rows[0]?.[0]?.code ?? rows[0]?.code;
        if (!code) throw new NotFoundException('No such invite');
        await this.audit(req, 'invite.revoke', code);
        return { success: true };
    }

    @Get('stats')
    async getStats() {
        return this.usersService.getSystemStats();
    }

    @Get('users')
    async getUsers() {
        const online = new Set(this.chatGateway.onlineUserIds());
        const rows = await this.db.query(`select u.id, u.username, u.email, u."displayName", u."avatarUrl", u.role, u."isBanned", u."createdAt",
            (u."publicKey" is not null) "hasKey",
            (select count(*) from messages m where m."senderId" = u.id)::int messages,
            (select max(m."createdAt") from messages m where m."senderId" = u.id) "lastMessageAt",
            (select count(*) from friendships f where f."user1Id" = u.id or f."user2Id" = u.id)::int friends,
            (select count(*) from group_members g where g."usersId" = u.id)::int groups
            from users u order by u."createdAt" desc`);
        return rows.map((r: any) => ({ ...r, online: online.has(r.id) }));
    }

    @Patch('users/:id/ban')
    async banUser(@Request() req: any, @Param('id') id: string) {
        await this.usersService.setBanStatus(parseInt(id), true);
        await this.audit(req, 'user.ban', await this.who(id));
        this.chatGateway.disconnectUser(parseInt(id));
        return { success: true, message: 'User banned' };
    }

    @Patch('users/:id/unban')
    async unbanUser(@Request() req: any, @Param('id') id: string) {
        await this.usersService.setBanStatus(parseInt(id), false);
        await this.audit(req, 'user.unban', await this.who(id));
        return { success: true, message: 'User unbanned' };
    }

    @Post('broadcast')
    async broadcast(@Request() req: any, @Body() body: { message: string }) {
        if (!body.message) return { error: 'Message is required' };
        await this.audit(req, 'broadcast', null, body.message.slice(0, 500));
        this.chatGateway.broadcastSystemMessage(body.message);
        return { success: true, message: 'Broadcast sent' };
    }

    @Get('storage/stats')
    async getStorageStats() {
        const stats = {
            totalSize: 0,
            avatarsSize: 0,
            messagesSize: 0,
            storiesSize: 0,
            filesCount: 0,
            byType: { image: 0, video: 0, audio: 0, other: 0 }
        };

        const avatarDir = path.join(process.cwd(), 'uploads', 'avatars');
        const messageDir = path.join(process.cwd(), 'uploads', 'messages');

        await this.scanDir(avatarDir, stats, 'avatars');
        await this.scanDir(messageDir, stats, 'messages');
        await this.scanDir(path.join(process.cwd(), 'uploads', 'stories'), stats, 'stories');

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
                    if (category === 'stories') stats.storiesSize += fileStats.size;

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
    async cleanupStorage(@Request() req: any, @Body() body: { days: number }) {
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


        await this.audit(req, 'storage.cleanup', null, `${deletedCount} files older than ${days} days`);
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

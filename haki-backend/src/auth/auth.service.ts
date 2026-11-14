import { BadRequestException, ForbiddenException, Injectable, NotFoundException, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import { randomBytes } from 'crypto';
import { DataSource, IsNull } from 'typeorm';
import { Session, Setting } from '../platform/entities';
import { User } from '../users/entities/user.entity';
import { UsersService } from '../users/users.service';
import { newSecret, otpauthUri, verifyTotp } from './totp';

type Link = {
    secret: string; pub: string; name: string; platform: string; expires: number;
    approved?: { token: string; sealed: string; pub: string; username: string };
};

const CODE_ALPHABET = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789'; // no 0/O/1/I/L to misread

@Injectable()
export class AuthService {
    // ponytail: pending device links live in memory for 5 minutes; move to the DB if the API runs on several instances
    private links = new Map<string, Link>();

    constructor(
        private usersService: UsersService,
        private jwtService: JwtService,
        private db: DataSource,
    ) { }

    static code(len: number) {
        return [...randomBytes(len)].map(b => CODE_ALPHABET[b % CODE_ALPHABET.length]).join('');
    }

    // ===== SIGN-UP CONTROL =====
    async signupMode(): Promise<'open' | 'invite' | 'closed'> {
        const row = await this.db.getRepository(Setting).findOne({ where: { key: 'signupMode' } });
        return (row?.value as any) ?? 'open';
    }

    async register(username: string, email: string, pass: string, inviteCode?: string) {
        const mode = await this.signupMode();
        if (mode === 'closed') throw new ForbiddenException('Sign-ups are closed right now');
        let inviteId: number | null = null;
        if (mode === 'invite') {
            // Atomic: two people can't both use the last seat on a code
            const rows = await this.db.query(
                `update invite_codes set uses = uses + 1
                 where upper(code) = upper($1) and not revoked and uses < "maxUses" and ("expiresAt" is null or "expiresAt" > now())
                 returning id`, [String(inviteCode ?? '').trim()]);
            inviteId = rows[0]?.[0]?.id ?? rows[0]?.id ?? null;
            if (!inviteId) throw new ForbiddenException('You need a valid invite code to join');
        }
        try {
            const user = await this.usersService.create(username, email, await bcrypt.hash(pass, 10));
            const { password, ...result } = user;
            return result;
        } catch (e) {
            if (inviteId) await this.db.query(`update invite_codes set uses = uses - 1 where id = $1`, [inviteId]);
            throw e;
        }
    }

    // ===== SIGN-IN =====
    async login(username: string, pass: string, code?: string, device?: { name?: string; platform?: string }) {
        const user = await this.usersService.findForLogin(username);
        if (!user || !(await bcrypt.compare(pass, user.password))) {
            throw new UnauthorizedException();
        }
        if (user.isBanned) {
            throw new ForbiddenException('This account has been banned');
        }
        if (user.totpEnabled) {
            if (!code) throw new UnauthorizedException({ statusCode: 401, twoFactor: true, message: 'Enter the 6-digit code from your authenticator app' });
            if (!verifyTotp(user.totpSecret!, code)) throw new UnauthorizedException({ statusCode: 401, twoFactor: true, message: 'That code didn’t work. Try the newest one.' });
        }
        return { access_token: await this.issue(user, device, 'login') };
    }

    /** A token tied to a new device row, so the device can be signed out on its own later. */
    private async issue(user: Pick<User, 'id' | 'username' | 'role'>, device: { name?: string; platform?: string } = {}, kind = 'login') {
        const s = await this.db.getRepository(Session).save({
            userId: user.id,
            name: String(device.name || 'Phone').slice(0, 60),
            platform: ['ios', 'android', 'web', 'macos'].includes(device.platform ?? '') ? device.platform! : 'ios',
            kind,
        });
        return this.jwtService.sign({ username: user.username, sub: user.id, role: user.role, sid: s.id });
    }

    /** False when the token's device was removed. Tokens from before devices existed carry no sid. */
    async sessionActive(sid?: string) {
        if (!sid) return true;
        const repo = this.db.getRepository(Session);
        const s = await repo.findOne({ where: { id: sid }, select: ['id', 'revokedAt', 'lastSeenAt'] });
        if (!s || s.revokedAt) return false;
        if (Date.now() - +s.lastSeenAt > 60_000) await repo.update(s.id, { lastSeenAt: new Date() });
        return true;
    }

    sessions(userId: number) {
        return this.db.getRepository(Session).find({
            where: { userId, revokedAt: IsNull() },
            order: { lastSeenAt: 'DESC' },
        });
    }

    async revokeSession(userId: number, sid: string) {
        const res = await this.db.getRepository(Session).update({ id: sid, userId, revokedAt: IsNull() }, { revokedAt: new Date() });
        if (!res.affected) throw new NotFoundException('No such device');
    }

    // ===== TWO-STEP LOGIN =====
    private async totpRow(userId: number) {
        return this.db.getRepository(User).findOne({ where: { id: userId }, select: ['id', 'username', 'totpSecret', 'totpEnabled'] });
    }

    async twoFactorStatus(userId: number) {
        return { enabled: !!(await this.totpRow(userId))?.totpEnabled };
    }

    /** New secret, not active until [enableTwoFactor] confirms a code from it. */
    async setupTwoFactor(userId: number) {
        const u = await this.totpRow(userId);
        if (u?.totpEnabled) throw new BadRequestException('Two-step login is already on');
        const secret = newSecret();
        await this.db.getRepository(User).update(userId, { totpSecret: secret });
        return { secret, uri: otpauthUri(secret, u!.username) };
    }

    async enableTwoFactor(userId: number, code: string) {
        const u = await this.totpRow(userId);
        if (!u?.totpSecret || !verifyTotp(u.totpSecret, code)) throw new BadRequestException('That code didn’t work. Try the newest one.');
        await this.db.getRepository(User).update(userId, { totpEnabled: true });
        return { enabled: true };
    }

    async disableTwoFactor(userId: number, code: string) {
        const u = await this.totpRow(userId);
        if (!u?.totpEnabled) return { enabled: false };
        if (!verifyTotp(u.totpSecret!, code)) throw new BadRequestException('That code didn’t work. Try the newest one.');
        await this.db.getRepository(User).update(userId, { totpEnabled: false, totpSecret: null });
        return { enabled: false };
    }

    // ===== LINKED DEVICES =====
    // The new device shows a QR (code + its one-time public key). A signed-in phone scans it,
    // seals the account key to that public key and approves. The server only relays the sealed
    // blob, so it never sees the key. Both screens show a short fingerprint to compare.
    private sweep() {
        const now = Date.now();
        for (const [k, v] of this.links) if (v.expires < now) this.links.delete(k);
    }

    startLink(pub: string, name?: string, platform?: string) {
        this.sweep();
        if (!/^[A-Za-z0-9+/=]{40,60}$/.test(pub ?? '')) throw new BadRequestException('Bad key');
        if (this.links.size > 1000) throw new BadRequestException('Try again in a minute');
        const code = AuthService.code(8);
        const secret = randomBytes(16).toString('hex');
        this.links.set(code, { secret, pub, name: String(name || 'New device').slice(0, 60), platform: platform ?? 'ios', expires: Date.now() + 5 * 60_000 });
        return { code, secret, expiresIn: 300 };
    }

    /** Polled by the new device with the secret only it knows. Hands the result over once. */
    pollLink(code: string, secret: string) {
        const l = this.links.get(String(code).toUpperCase());
        if (!l || l.secret !== secret || l.expires < Date.now()) throw new NotFoundException('This code expired. Make a new one.');
        if (!l.approved) return { status: 'waiting' };
        this.links.delete(String(code).toUpperCase());
        return { status: 'approved', access_token: l.approved.token, sealed: l.approved.sealed, pub: l.approved.pub, username: l.approved.username };
    }

    /** The signed-in phone reads the new device's public key and name before approving. */
    peekLink(code: string) {
        const l = this.links.get(String(code ?? '').trim().toUpperCase());
        if (!l || l.expires < Date.now() || l.approved) throw new NotFoundException('That code isn’t valid any more');
        return { pub: l.pub, name: l.name, platform: l.platform };
    }

    async approveLink(user: { sub: number; username: string; role: string }, code: string, sealed: string, pub: string) {
        const key = String(code ?? '').trim().toUpperCase();
        const l = this.links.get(key);
        if (!l || l.expires < Date.now() || l.approved) throw new NotFoundException('That code isn’t valid any more');
        if (typeof sealed !== 'string' || sealed.length > 20000 || !/^[A-Za-z0-9+/=]{40,60}$/.test(pub ?? '')) throw new BadRequestException('Bad data');
        const token = await this.issue({ id: user.sub, username: user.username, role: user.role }, { name: l.name, platform: l.platform }, 'linked');
        l.approved = { token, sealed, pub, username: user.username };
        return { success: true };
    }
}

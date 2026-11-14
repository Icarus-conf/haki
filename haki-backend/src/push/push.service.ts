import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import * as http2 from 'http2';
import * as jwt from 'jsonwebtoken';
import { In, Repository } from 'typeorm';
import { PushDevice } from './push-device.entity';

export type PushKind = 'message' | 'call' | 'mention';

/**
 * Apple push (APNs) with token auth. Notifications carry no names and no message text —
 * only "New message" plus which chat to open — so Apple learns nothing about the chat.
 *
 * Needs APNS_KEY (the .p8 contents), APNS_KEY_ID, APNS_TEAM_ID, APNS_TOPIC (bundle id) and
 * APNS_PRODUCTION=true for App Store builds. Without them pushes are only logged.
 *
 * Calls go to the phone's VoIP (PushKit) token when it has one, so CallKit rings even when the
 * app is closed. Android uses Firebase Cloud Messaging (HTTP v1) with FCM_SERVICE_ACCOUNT set to
 * the service-account JSON from the Firebase console.
 */
@Injectable()
export class PushService {
    private readonly logger = new Logger(PushService.name);
    private session?: http2.ClientHttp2Session;
    private providerToken?: { value: string; at: number };

    constructor(@InjectRepository(PushDevice) private readonly devices: Repository<PushDevice>) { }

    private get configured() {
        return !!(process.env.APNS_KEY && process.env.APNS_KEY_ID && process.env.APNS_TEAM_ID);
    }

    private fcmToken?: { value: string; at: number };

    async register(userId: number, token: string, platform = 'ios') {
        if (!['ios', 'voip', 'android'].includes(platform)) return false;
        const valid = platform === 'android' ? /^[A-Za-z0-9:_-]{20,400}$/ : /^[0-9a-f]{32,200}$/i;
        if (!valid.test(token ?? '')) return false;
        // A token belongs to one phone; if someone else signed in there, it moves to them
        await this.devices.upsert({ userId, token: platform === 'android' ? token : token.toLowerCase(), platform }, ['token']);
        return true;
    }

    async unregister(userId: number, token: string) {
        await this.devices.delete({ userId, token: In([token ?? '', (token ?? '').toLowerCase()]) });
    }

    static payload(kind: PushKind, chat: Record<string, number>) {
        const body = kind === 'call' ? 'Incoming call' : kind === 'mention' ? 'You were mentioned in the Lounge' : 'New message';
        return {
            aps: {
                alert: { title: 'Haki', body },
                sound: 'default',
                'thread-id': Object.entries(chat).map(([k, v]) => `${k}${v}`).join('') || 'lounge',
                ...(kind === 'call' ? { 'interruption-level': 'time-sensitive' } : {}),
            },
            chat,
        };
    }

    /** Which of a user's devices get this push: calls go to VoIP tokens where the phone has one. */
    static pick<T extends Pick<PushDevice, 'userId' | 'platform'>>(devices: T[], kind: PushKind): T[] {
        const voipUsers = new Set(devices.filter(d => d.platform === 'voip').map(d => d.userId));
        return devices.filter(d => d.platform === 'android'
            || (kind === 'call' ? (d.platform === 'voip' || (d.platform === 'ios' && !voipUsers.has(d.userId))) : d.platform === 'ios'));
    }

    async notify(userIds: number[], kind: PushKind, chat: Record<string, number>) {
        if (!userIds.length) return;
        const devices = PushService.pick(await this.devices.find({ where: { userId: In(userIds) } }), kind);
        if (!devices.length) return;
        const apple = devices.filter(d => d.platform !== 'android');
        const android = devices.filter(d => d.platform === 'android');
        if (apple.length && !this.configured) this.logger.log(`[Push] APNs not configured; would send ${kind} to users ${[...new Set(apple.map(d => d.userId))].join(',')}`);
        if (android.length && !process.env.FCM_SERVICE_ACCOUNT) this.logger.log(`[Push] FCM not configured; would send ${kind} to users ${[...new Set(android.map(d => d.userId))].join(',')}`);
        const body = JSON.stringify(PushService.payload(kind, chat));
        await Promise.all([
            ...(this.configured ? apple : []).map(d => this.send(d, d.platform === 'voip' ? JSON.stringify({ kind, chat }) : body, kind).catch(e => this.logger.warn(`[Push] ${e.message}`))),
            ...(process.env.FCM_SERVICE_ACCOUNT ? android : []).map(d => this.sendFcm(d, kind, chat).catch(e => this.logger.warn(`[Push] ${e.message}`))),
        ]);
    }

    /** FCM HTTP v1 message: same content rules as APNs (no names, no text). Calls are data-only + high priority. */
    static fcmMessage(token: string, kind: PushKind, chat: Record<string, number>) {
        const { aps } = PushService.payload(kind, chat);
        const data = { kind, chat: JSON.stringify(chat) };
        return {
            message: {
                token,
                data,
                android: { priority: 'HIGH', ...(kind === 'call' ? { ttl: '30s' } : { notification: { tag: aps['thread-id'], channel_id: 'messages' } }) },
                ...(kind === 'call' ? {} : { notification: { title: aps.alert.title, body: aps.alert.body } }),
            },
        };
    }

    private async fcmAccess() {
        const sa = JSON.parse(process.env.FCM_SERVICE_ACCOUNT!);
        if (!this.fcmToken || Date.now() - this.fcmToken.at > 50 * 60 * 1000) {
            const now = Math.floor(Date.now() / 1000);
            const assertion = jwt.sign(
                { iss: sa.client_email, scope: 'https://www.googleapis.com/auth/firebase.messaging', aud: 'https://oauth2.googleapis.com/token', iat: now, exp: now + 3600 },
                sa.private_key, { algorithm: 'RS256' });
            const res = await fetch('https://oauth2.googleapis.com/token', {
                method: 'POST',
                headers: { 'content-type': 'application/x-www-form-urlencoded' },
                body: new URLSearchParams({ grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer', assertion }),
            });
            if (!res.ok) throw new Error(`FCM auth ${res.status}`);
            this.fcmToken = { value: (await res.json()).access_token, at: Date.now() };
        }
        return { token: this.fcmToken.value, project: sa.project_id as string };
    }

    private async sendFcm(device: PushDevice, kind: PushKind, chat: Record<string, number>) {
        const { token, project } = await this.fcmAccess();
        const res = await fetch(`https://fcm.googleapis.com/v1/projects/${project}/messages:send`, {
            method: 'POST',
            headers: { authorization: `Bearer ${token}`, 'content-type': 'application/json' },
            body: JSON.stringify(PushService.fcmMessage(device.token, kind, chat)),
        });
        if (res.ok) return;
        const text = await res.text();
        if (res.status === 404 || /UNREGISTERED/.test(text)) await this.devices.delete({ id: device.id });
        throw new Error(`FCM ${res.status} ${text.slice(0, 200)}`);
    }

    private bearer() {
        // Apple accepts a provider token for up to an hour; refresh after 50 minutes
        if (!this.providerToken || Date.now() - this.providerToken.at > 50 * 60 * 1000) {
            const key = process.env.APNS_KEY!.replace(/\\n/g, '\n');
            const value = jwt.sign({}, key, {
                algorithm: 'ES256',
                issuer: process.env.APNS_TEAM_ID,
                header: { alg: 'ES256', kid: process.env.APNS_KEY_ID! },
            });
            this.providerToken = { value, at: Date.now() };
        }
        return this.providerToken.value;
    }

    private client() {
        if (!this.session || this.session.closed || this.session.destroyed) {
            const host = process.env.APNS_PRODUCTION === 'true' ? 'https://api.push.apple.com' : 'https://api.sandbox.push.apple.com';
            this.session = http2.connect(host);
            this.session.on('error', e => this.logger.warn(`[Push] connection: ${e.message}`));
        }
        return this.session;
    }

    private send(device: PushDevice, body: string, kind: PushKind) {
        return new Promise<void>((resolve, reject) => {
            const req = this.client().request({
                ':method': 'POST',
                ':path': `/3/device/${device.token}`,
                authorization: `bearer ${this.bearer()}`,
                'apns-topic': (process.env.APNS_TOPIC || 'com.sleepless_icarus.haki') + (device.platform === 'voip' ? '.voip' : ''),
                'apns-push-type': device.platform === 'voip' ? 'voip' : 'alert',
                'apns-priority': '10',
                ...(kind === 'call' ? { 'apns-expiration': String(Math.floor(Date.now() / 1000) + 30) } : {}),
            });
            let status = 0;
            let data = '';
            req.on('response', h => (status = Number(h[':status'])));
            req.on('data', c => (data += c));
            req.on('end', async () => {
                if (status === 200) return resolve();
                // Uninstalled app / stale token: forget it
                if (status === 410 || /BadDeviceToken|Unregistered/.test(data)) await this.devices.delete({ id: device.id });
                reject(new Error(`APNs ${status} ${data}`));
            });
            req.on('error', reject);
            req.end(body);
        });
    }
}

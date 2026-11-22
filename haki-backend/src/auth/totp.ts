import { createHmac, randomBytes } from 'crypto';

/** Time-based one-time codes (RFC 6238, SHA-1, 6 digits, 30 s) — what every authenticator app speaks. */
const ALPHABET = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';

export function base32Encode(buf: Buffer) {
    let bits = '';
    for (const b of buf) bits += b.toString(2).padStart(8, '0');
    let out = '';
    for (let i = 0; i < bits.length; i += 5) out += ALPHABET[parseInt(bits.slice(i, i + 5).padEnd(5, '0'), 2)];
    return out;
}

function base32Decode(s: string) {
    let bits = '';
    for (const c of s.replace(/=+$/, '').toUpperCase()) {
        const v = ALPHABET.indexOf(c);
        if (v < 0) continue;
        bits += v.toString(2).padStart(5, '0');
    }
    const bytes: number[] = [];
    for (let i = 0; i + 8 <= bits.length; i += 8) bytes.push(parseInt(bits.slice(i, i + 8), 2));
    return Buffer.from(bytes);
}

export function newSecret() {
    return base32Encode(randomBytes(20));
}

export function totp(secret: string, at = Date.now()) {
    const counter = Buffer.alloc(8);
    counter.writeBigUInt64BE(BigInt(Math.floor(at / 30000)));
    const h = createHmac('sha1', base32Decode(secret)).update(counter).digest();
    const o = h[h.length - 1] & 0xf;
    return String((h.readUInt32BE(o) & 0x7fffffff) % 1_000_000).padStart(6, '0');
}

/** Accepts the code for now and one step either side, so a slow clock still works. */
export function verifyTotp(secret: string, code: string, at = Date.now()) {
    const c = String(code ?? '').replace(/\s/g, '');
    if (!/^\d{6}$/.test(c)) return false;
    return [-1, 0, 1].some(step => totp(secret, at + step * 30000) === c);
}

export function otpauthUri(secret: string, account: string) {
    return `otpauth://totp/Haki:${encodeURIComponent(account)}?secret=${secret}&issuer=Haki`;
}

// RFC 6238 test vector: ASCII "12345678901234567890" at 59 s → 287082 (6-digit SHA-1)
if (require.main === module) {
    const s = base32Encode(Buffer.from('12345678901234567890'));
    console.assert(totp(s, 59000) === '287082', 'totp vector');
    console.assert(verifyTotp(s, '287082', 59000) && !verifyTotp(s, '000000', 59000), 'verify');
    console.log('totp ok');
}

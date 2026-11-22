# Security

Haki is built so that the server never needs to read what people say. This page explains how that works, what it protects, and, just as important, what it doesn't.

Haki has **not** had an independent security audit. Read the limits below before relying on it for anything high-risk.

## Reporting a vulnerability

Please **don't open a public issue** for security problems.

Use GitHub's private reporting instead: **Security → Report a vulnerability** on this repository. Include steps to reproduce and what an attacker could do. You'll get a reply within a few days, and credit in the fix's release notes if you want it.

## How the encryption works

### Your account key
- Signing up creates **12 recovery words** (BIP-39).
- A **2048-bit RSA key pair** is derived from those words, so the same words always recreate the same key.
- The private key stays on your devices, in the platform keychain or keystore. The server only gets the public key.

### Messages and attachments
- Every message gets a fresh random **AES-256-GCM** key.
- That key is wrapped with **RSA-OAEP (SHA-256)** for each reader: the recipient and you, or every member of a group.
- Photos, videos, files and voice notes are encrypted the same way before upload. The server stores opaque blobs.

### Stories and the friends feed
- Each story or post gets its own AES-256-GCM key.
- The key is wrapped once per friend who is allowed to see it, and the server hands each reader **only their own wrapped key**.
- Post text, photos, videos and comments are all sealed with the post key.
- The server refuses to hand a key to anyone who isn't the author's friend.

### Linking a new device
1. The new device (a Mac, a PC or a browser) shows a QR code containing a one-time **X25519** public key.
2. Your phone scans it and derives a shared key (**X25519 + HKDF-SHA256**).
3. The phone seals your account key to the new device, which unseals it on its side.

The server relays the sealed blob but can't open it. Both screens show a short check code so you can confirm no one is in the middle.

### Checking who you're talking to
Each chat has a **safety number** built from both people's public keys. Compare it in person or over a call. If a friend's key changes, the app warns you.

### Calls
Voice and video calls use WebRTC, which encrypts the media between devices (DTLS-SRTP). When a call has to go through the TURN relay, the relay only forwards encrypted packets.

### Notifications
Push notifications say only "New message" or "Incoming call", plus which chat to open. Apple and Google never see message text.

## What the server can see

Encryption hides **content**, not **activity**. Whoever runs a Haki server can see:

- **Account details:** usernames, emails and password hashes.
- **Profiles:** display names, avatars, bios and status lines.
- **Who you are friends with**, and who messages whom, when and how often.
- **Group membership, and the size and timing of encrypted uploads.**
- **Reaction emoji** on posts and stories, and who loved what.
- **The public Lounge room.** It is deliberately not encrypted, and the app says so.

The admin dashboard is built on this: it shows counts and timestamps, never content.

## Known limits

These are honest trade-offs in the current design.

- **No forward secrecy.** Each account has one long-term key. Anyone who gets your 12 words, or the private key off an unlocked device, can decrypt your past messages if they also have the server's stored ciphertext. Signal's double ratchet avoids this; Haki doesn't implement it yet.
- **You trust the server for public keys.** A malicious server could hand out a fake key for a friend. Comparing safety numbers detects this; without that check, you're trusting the server.
- **RSA-2048 is not post-quantum.** A future quantum computer could break today's recorded traffic.
- **Metadata is visible**, as listed above.
- **New friends can't read old posts.** Posts are only wrapped for the friends you had when you posted. This is intended, but worth knowing.
- **Self-hosters are responsible for transport security.** Put the API behind HTTPS and use your own secrets (see the README).

## Running your own server safely

- Use fresh random values for `JWT_SECRET`, `POSTGRES_PASSWORD` and `TURN_PASSWORD` in `haki-backend/.env`, generated with `openssl rand -hex 32`.
- Serve the API and dashboard over HTTPS only.
- Keep Postgres off the public internet (by default it's published on 5432 for local development).
- Back up the database and the `uploads/` folder. Both are encrypted content, so losing them loses messages, and leaking them leaks metadata.

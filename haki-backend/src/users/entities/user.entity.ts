import { Column, CreateDateColumn, Entity, PrimaryGeneratedColumn } from 'typeorm';

@Entity('users')
export class User {
    @PrimaryGeneratedColumn()
    id: number;

    @Column({ unique: true })
    username: string;

    @Column({ unique: true })
    email: string;

    @Column({ default: 'user' })
    role: string;

    @Column({ default: false })
    isBanned: boolean;

    @Column({ nullable: true })
    displayName: string;

    @Column({ nullable: true })
    bio: string;

    @Column({ nullable: true, type: 'text' })
    avatarUrl: string;

    @Column({ nullable: true, type: 'text' })
    publicKey: string;

    @Column({ nullable: true, length: 100 })
    statusMessage: string;

    // Never loaded unless explicitly selected (see UsersService.findForLogin)
    @Column({ select: false })
    password: string;

    // Username for finding people: only a keyed hash is stored, so the server can match a
    // lookup but can't list or read usernames. The readable copy is sealed to the user's own key.
    @Column({ nullable: true, unique: true, select: false })
    handleHash: string;

    @Column({ nullable: true, type: 'text', select: false })
    handleSealed: string;

    /** Birthday as MM-DD, shown to friends only if the user sets it. */
    @Column({ type: 'varchar', length: 5, nullable: true })
    birthday: string | null;

    // Two-step login (authenticator app). The secret is pending until a code confirms it.
    @Column({ type: 'varchar', nullable: true, select: false })
    totpSecret: string | null;

    @Column({ default: false, select: false })
    totpEnabled: boolean;

    // App data only this user can read (contact notes, locked chats, checked keys), sealed to their key
    @Column({ type: 'text', nullable: true, select: false })
    backupSealed: string | null;

    @Column({ type: 'timestamptz', nullable: true, select: false })
    backupAt: Date | null;

    @CreateDateColumn()
    createdAt: Date;
}

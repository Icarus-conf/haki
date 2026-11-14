import { Column, CreateDateColumn, Entity, Index, PrimaryColumn, PrimaryGeneratedColumn } from 'typeorm';

/** Every moderation action taken from the dashboard, with who did it. */
@Entity('audit_logs')
export class AuditLog {
    @PrimaryGeneratedColumn()
    id: number;

    @Column()
    adminId: number;

    @Column()
    admin: string;

    @Column()
    action: string;

    @Column({ type: 'varchar', nullable: true })
    target: string | null;

    @Column({ type: 'text', nullable: true })
    detail: string | null;

    @CreateDateColumn({ type: 'timestamptz' })
    createdAt: Date;
}

/** Small key/value switches set from the dashboard (signupMode: open | invite | closed). */
@Entity('settings')
export class Setting {
    @PrimaryColumn()
    key: string;

    @Column({ type: 'text' })
    value: string;
}

@Entity('invite_codes')
export class InviteCode {
    @PrimaryGeneratedColumn()
    id: number;

    @Column({ unique: true })
    code: string;

    @Column({ default: 1 })
    maxUses: number;

    @Column({ default: 0 })
    uses: number;

    @Column({ type: 'varchar', nullable: true })
    note: string | null;

    @Column()
    createdBy: string;

    @Column({ type: 'timestamptz', nullable: true })
    expiresAt: Date | null;

    @Column({ default: false })
    revoked: boolean;

    @CreateDateColumn({ type: 'timestamptz' })
    createdAt: Date;
}

/** One signed-in device. Tokens carry its id, so removing a device signs it out everywhere. */
@Entity('sessions')
export class Session {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @Index()
    @Column()
    userId: number;

    @Column({ default: 'Phone' })
    name: string;

    @Column({ default: 'ios' })
    platform: string;

    /** 'login' or 'linked' (added by scanning a code on a signed-in phone). */
    @Column({ default: 'login' })
    kind: string;

    @CreateDateColumn({ type: 'timestamptz' })
    createdAt: Date;

    @Column({ type: 'timestamptz', default: () => 'now()' })
    lastSeenAt: Date;

    @Column({ type: 'timestamptz', nullable: true })
    revokedAt: Date | null;
}

/** How far each member has read a group, for "Seen by" and unread counts on every device. */
@Entity('group_reads')
@Index(['userId', 'groupId'], { unique: true })
export class GroupRead {
    @PrimaryGeneratedColumn()
    id: number;

    @Column()
    userId: number;

    @Column()
    groupId: number;

    @Column({ default: 0 })
    lastReadId: number;
}

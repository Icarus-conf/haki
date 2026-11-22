import { Column, CreateDateColumn, Entity, ManyToOne, PrimaryGeneratedColumn } from 'typeorm';
import { User } from '../users/entities/user.entity';

/**
 * A user reported a message. Private and group chats are end-to-end encrypted, so the
 * reporter's phone sends the text it decrypted; the server can't check it against the
 * ciphertext (no message franking), and the dashboard says so.
 */
@Entity('reports')
export class Report {
    @PrimaryGeneratedColumn()
    id: number;

    @ManyToOne(() => User, { onDelete: 'CASCADE' })
    reporter: User;

    @ManyToOne(() => User, { onDelete: 'CASCADE' })
    reported: User;

    // Plain number, not a relation: the report outlives the message if it gets deleted
    @Column()
    messageId: number;

    @Column()
    reason: string;

    @Column({ type: 'text', nullable: true })
    note: string | null;

    @Column({ type: 'text', nullable: true })
    content: string | null;

    @Column({ type: 'varchar', nullable: true })
    attachmentType: string | null;

    @Column()
    chat: string; // direct | group | lounge

    @Column({ default: 'open' })
    status: string; // open | resolved | dismissed

    @Column({ type: 'timestamptz', nullable: true })
    resolvedAt: Date | null;

    @CreateDateColumn()
    createdAt: Date;
}

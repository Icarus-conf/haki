import { Column, CreateDateColumn, Entity, ManyToOne, OneToMany, PrimaryGeneratedColumn } from 'typeorm';
import { Group } from '../../groups/entities/group.entity';
import { User } from '../../users/entities/user.entity';
import { Reaction } from './reaction.entity';

@Entity('messages')
export class Message {
    @PrimaryGeneratedColumn()
    id: number;

    @Column()
    content: string;

    @Column({ nullable: true })
    attachmentUrl: string;

    @Column({ nullable: true })
    mediaIv: string;

    @Column({ type: 'json', nullable: true })
    mediaKeys: any;

    @Column({ nullable: true })
    attachmentType: string;

    @ManyToOne(() => User)
    sender: User;

    @ManyToOne(() => User, { nullable: true })
    recipient?: User | null;

    // Set for group messages; recipient and group are both null in the public Lounge
    @ManyToOne(() => Group, { nullable: true, onDelete: 'CASCADE' })
    group?: Group | null;

    @OneToMany(() => Reaction, reaction => reaction.message, { eager: true })
    reactions: Reaction[];

    @Column({ nullable: true })
    replyToMessageId: number;

    @Column({ nullable: true })
    replyToSender: string;

    @Column({ nullable: true })
    replyToMessage: string;

    // Only meaningful for private messages: set when the recipient opens the chat.
    // DB default is true so rows that existed before this column don't all show as unread;
    // new messages are created with isRead: false explicitly (chat.gateway handleMessage).
    @Column({ default: true })
    isRead: boolean;

    @Column({ type: 'timestamptz', nullable: true })
    editedAt: Date | null;

    @Column({ default: false })
    pinned: boolean;

    // "Delete for me": users who hid this message. Filtered out of their history.
    @Column('int', { array: true, default: () => "'{}'" })
    hiddenFor: number[];

    // Polls: the question and options are inside the encrypted body; the server only keeps
    // { userId: [option indexes] } so it can count votes without knowing what they mean.
    @Column('jsonb', { default: () => "'{}'" })
    pollVotes: Record<string, number[]>;

    // Scheduled messages wait here (already encrypted on the phone) until this time.
    @Column({ type: 'timestamptz', nullable: true })
    scheduledAt: Date | null;

    // Disappearing messages: deleted (row and file) by the server once this passes.
    @Column({ type: 'timestamptz', nullable: true })
    expiresAt: Date | null;

    // View once (private chats, photo/voice): the file is deleted when the recipient opens it.
    @Column({ default: false })
    viewOnce: boolean;

    @Column({ type: 'timestamptz', nullable: true })
    viewedAt: Date | null;

    @CreateDateColumn()
    createdAt: Date;
}

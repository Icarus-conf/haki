import { Column, CreateDateColumn, Entity, ManyToOne, OneToMany, PrimaryGeneratedColumn } from 'typeorm';
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

    @OneToMany(() => Reaction, reaction => reaction.message, { eager: true })
    reactions: Reaction[];

    @Column({ nullable: true })
    replyToMessageId: number;

    @Column({ nullable: true })
    replyToSender: string;

    @Column({ nullable: true })
    replyToMessage: string;

    @CreateDateColumn()
    createdAt: Date;
}

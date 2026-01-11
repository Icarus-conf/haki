import { Column, CreateDateColumn, Entity, ManyToOne, PrimaryGeneratedColumn } from 'typeorm';
import { User } from '../../users/entities/user.entity';
import { Message } from './message.entity';

@Entity('reactions')
export class Reaction {
    @PrimaryGeneratedColumn()
    id: number;

    @ManyToOne(() => Message, message => message.reactions, { onDelete: 'CASCADE' })
    message: Message;

    @ManyToOne(() => User)
    user: User;

    @Column({ length: 10 })
    emoji: string;

    @CreateDateColumn()
    createdAt: Date;
}

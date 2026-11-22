import { Column, CreateDateColumn, Entity, ManyToOne, PrimaryGeneratedColumn } from 'typeorm';
import { User } from './user.entity';

@Entity('friend_requests')
export class FriendRequest {
    @PrimaryGeneratedColumn()
    id: number;

    @ManyToOne(() => User)
    sender: User;

    @ManyToOne(() => User)
    recipient: User;

    @Column({ default: 'pending' }) // pending, accepted, declined
    status: string;

    @CreateDateColumn()
    createdAt: Date;
}

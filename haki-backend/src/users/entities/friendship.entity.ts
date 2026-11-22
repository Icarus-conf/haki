import { Column, CreateDateColumn, Entity, ManyToOne, PrimaryGeneratedColumn } from 'typeorm';
import { User } from './user.entity';

@Entity('friendships')
export class Friendship {
    @PrimaryGeneratedColumn()
    id: number;

    @ManyToOne(() => User, { eager: true })
    user1: User;

    @ManyToOne(() => User, { eager: true })
    user2: User;

    /** Disappearing-message timer for this pair's chat, in seconds (0 = off). */
    @Column({ default: 0 })
    disappearSeconds: number;

    @CreateDateColumn()
    createdAt: Date;
}

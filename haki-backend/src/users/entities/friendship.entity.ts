import { CreateDateColumn, Entity, ManyToOne, PrimaryGeneratedColumn } from 'typeorm';
import { User } from './user.entity';

@Entity('friendships')
export class Friendship {
    @PrimaryGeneratedColumn()
    id: number;

    @ManyToOne(() => User, { eager: true })
    user1: User;

    @ManyToOne(() => User, { eager: true })
    user2: User;

    @CreateDateColumn()
    createdAt: Date;
}

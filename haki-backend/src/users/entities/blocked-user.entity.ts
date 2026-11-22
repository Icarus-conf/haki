import { CreateDateColumn, Entity, ManyToOne, PrimaryGeneratedColumn } from 'typeorm';
import { User } from '../../users/entities/user.entity';

@Entity('blocked_users')
export class BlockedUser {
    @PrimaryGeneratedColumn()
    id: number;

    @ManyToOne(() => User)
    blocker: User; // The user who blocked

    @ManyToOne(() => User)
    blocked: User; // The user who was blocked

    @CreateDateColumn()
    createdAt: Date;
}

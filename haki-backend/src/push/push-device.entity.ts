import { Column, CreateDateColumn, Entity, ManyToOne, PrimaryGeneratedColumn } from 'typeorm';
import { User } from '../users/entities/user.entity';

/** A phone that can receive push notifications for one user. */
@Entity('push_devices')
export class PushDevice {
    @PrimaryGeneratedColumn()
    id: number;

    @ManyToOne(() => User, { onDelete: 'CASCADE' })
    user: User;

    @Column()
    userId: number;

    @Column({ unique: true })
    token: string;

    @Column({ default: 'ios' })
    platform: string;

    @CreateDateColumn()
    createdAt: Date;
}

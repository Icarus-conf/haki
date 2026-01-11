import { Column, CreateDateColumn, Entity, ManyToOne, PrimaryGeneratedColumn } from 'typeorm';
import { User } from '../../users/entities/user.entity';

@Entity('stories')
export class Story {
    @PrimaryGeneratedColumn()
    id: number;

    @ManyToOne(() => User)
    user: User;

    @Column()
    userId: number;

    @Column({ type: 'text' })
    content: string;

    @Column({ default: 'image' })
    type: string; // 'text' | 'image'

    @CreateDateColumn()
    createdAt: Date;

    @Column()
    expiresAt: Date;
}

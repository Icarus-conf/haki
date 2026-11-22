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

    /** AES-GCM nonce of the sealed file at [content]; the server never has the key. */
    @Column({ type: 'text', nullable: true })
    iv: string | null;

    @CreateDateColumn()
    createdAt: Date;

    @Column()
    expiresAt: Date;
}

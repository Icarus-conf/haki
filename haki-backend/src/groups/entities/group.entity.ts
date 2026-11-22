import { Column, CreateDateColumn, Entity, JoinTable, ManyToMany, ManyToOne, PrimaryGeneratedColumn } from 'typeorm';
import { User } from '../../users/entities/user.entity';

/** An encrypted group chat. Messages are wrapped for every member's key on the sender's phone. */
@Entity('groups')
export class Group {
    @PrimaryGeneratedColumn()
    id: number;

    @Column()
    name: string;

    @ManyToOne(() => User)
    owner: User;

    @ManyToMany(() => User)
    @JoinTable({ name: 'group_members' })
    members: User[];

    /** Disappearing-message timer for the group, in seconds (0 = off). */
    @Column({ default: 0 })
    disappearSeconds: number;

    @CreateDateColumn()
    createdAt: Date;
}

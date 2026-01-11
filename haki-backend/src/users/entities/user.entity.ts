import { Column, CreateDateColumn, Entity, PrimaryGeneratedColumn } from 'typeorm';

@Entity('users')
export class User {
    @PrimaryGeneratedColumn()
    id: number;

    @Column({ unique: true })
    username: string;

    @Column({ unique: true })
    email: string;

    @Column({ nullable: true })
    displayName: string;

    @Column({ nullable: true })
    bio: string;

    @Column({ nullable: true, type: 'text' })
    avatarUrl: string;

    @Column({ nullable: true, type: 'text' })
    publicKey: string;

    @Column({ nullable: true, length: 100 })
    statusMessage: string;

    @Column()
    password: string;

    @CreateDateColumn()
    createdAt: Date;
}

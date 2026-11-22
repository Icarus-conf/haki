import { Column, CreateDateColumn, Entity, Index, ManyToOne, PrimaryGeneratedColumn, Unique } from 'typeorm';
import { User } from '../users/entities/user.entity';

/**
 * A friends-only post. The server never sees its text or media: [body] is AES-GCM sealed with a
 * per-post key, and that key is wrapped once per reader in [PostKey]. Having a key row = may read it.
 */
@Entity('posts')
export class Post {
    @PrimaryGeneratedColumn()
    id: number;

    @ManyToOne(() => User, { onDelete: 'CASCADE' })
    author: User;

    @Index()
    @Column()
    authorId: number;

    /** {data, iv}: sealed JSON {text, media: [{iv, kind, w, h, dur}]}. */
    @Column({ type: 'text' })
    body: string;

    /** Upload URLs of the sealed media files, in order; kept in clear only so they can be deleted. */
    @Column({ type: 'simple-json', default: '[]' })
    media: string[];

    @Column({ default: false })
    commentsOff: boolean;

    @CreateDateColumn()
    createdAt: Date;
}

@Entity('post_keys')
@Unique(['postId', 'userId'])
export class PostKey {
    @PrimaryGeneratedColumn()
    id: number;

    @ManyToOne(() => Post, { onDelete: 'CASCADE' })
    post: Post;

    @Column()
    postId: number;

    @Index()
    @Column()
    userId: number;

    /** The post key, RSA-OAEP wrapped to this reader. */
    @Column({ type: 'text' })
    key: string;
}

/** Sealed with the post's key, so only the post's readers can read comments. */
@Entity('post_comments')
export class PostComment {
    @PrimaryGeneratedColumn()
    id: number;

    @ManyToOne(() => Post, { onDelete: 'CASCADE' })
    post: Post;

    @Index()
    @Column()
    postId: number;

    @ManyToOne(() => User, { onDelete: 'CASCADE' })
    author: User;

    @Column()
    authorId: number;

    /** One level of replies, like Threads. */
    @Column({ type: 'int', nullable: true })
    parentId: number | null;

    @Column({ type: 'text' })
    body: string;

    @CreateDateColumn()
    createdAt: Date;
}

/** One reaction per reader per post; the heart is just the default emoji. */
@Entity('post_reactions')
@Unique(['postId', 'userId'])
export class PostReaction {
    @PrimaryGeneratedColumn()
    id: number;

    @ManyToOne(() => Post, { onDelete: 'CASCADE' })
    post: Post;

    @Index()
    @Column()
    postId: number;

    @Column()
    userId: number;

    @Column({ length: 16 })
    emoji: string;

    @CreateDateColumn()
    createdAt: Date;
}

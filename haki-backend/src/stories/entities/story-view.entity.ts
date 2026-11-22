import { Column, Entity, ManyToOne, PrimaryGeneratedColumn, Unique, UpdateDateColumn } from 'typeorm';
import { User } from '../../users/entities/user.entity';
import { Story } from './story.entity';

/** One friend having seen (and maybe loved) one story. Only the story's owner can list them. */
@Entity('story_views')
@Unique(['storyId', 'viewerId'])
export class StoryView {
    @PrimaryGeneratedColumn()
    id: number;

    @ManyToOne(() => Story, { onDelete: 'CASCADE' })
    story: Story;

    @Column()
    storyId: number;

    @ManyToOne(() => User, { onDelete: 'CASCADE' })
    viewer: User;

    @Column()
    viewerId: number;

    @Column({ default: false })
    liked: boolean;

    @UpdateDateColumn()
    viewedAt: Date;
}

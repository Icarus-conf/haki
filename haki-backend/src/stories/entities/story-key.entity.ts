import { Column, Entity, Index, ManyToOne, PrimaryGeneratedColumn, Unique } from 'typeorm';
import { Story } from './story.entity';

/** The story's AES key, RSA-OAEP wrapped to one reader (owner included). Having a row = may see it. */
@Entity('story_keys')
@Unique(['storyId', 'userId'])
export class StoryKey {
    @PrimaryGeneratedColumn()
    id: number;

    @ManyToOne(() => Story, { onDelete: 'CASCADE' })
    story: Story;

    @Column()
    storyId: number;

    @Index()
    @Column()
    userId: number;

    @Column({ type: 'text' })
    key: string;
}

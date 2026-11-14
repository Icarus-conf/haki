import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, IsNull, Repository } from 'typeorm';
import { Message } from './entities/message.entity';

@Injectable()
export class MessagesService {
    constructor(
        @InjectRepository(Message)
        private messageRepository: Repository<Message>,
    ) { }

    async getSharedMedia(userId: number, recipientId: number) {
        // Fetch all messages with attachments between these two users
        const messages = await this.messageRepository.find({
            where: [
                {
                    sender: { id: userId },
                    recipient: { id: recipientId },
                    attachmentType: In(['image']), // Only images for now, can add 'video' later
                    scheduledAt: IsNull(),
                },
                {
                    sender: { id: recipientId },
                    recipient: { id: userId },
                    attachmentType: In(['image']),
                    scheduledAt: IsNull(),
                },
            ],
            relations: ['sender', 'recipient', 'reactions', 'reactions.user'],
            order: { createdAt: 'DESC' },
        });

        // Filter out messages without attachments
        const mediaMessages = messages.filter(m => m.attachmentUrl != null);

        return mediaMessages.map((m) => ({
            id: m.id,
            sender: m.sender.displayName || m.sender.username,
            username: m.sender.username,
            senderId: m.sender.id,
            avatarUrl: m.sender.avatarUrl,
            message: m.content,
            attachmentUrl: m.attachmentUrl,
            mediaIv: m.mediaIv,
            mediaKeys: m.mediaKeys,
            attachmentType: m.attachmentType,
            timestamp: m.createdAt.toISOString(),
            recipientId: m.recipient?.id || null,
            reactions: (m.reactions || []).map(r => ({ id: r.id, emoji: r.emoji, userId: r.user?.id, username: r.user?.username })),
            isRead: m.isRead,
            replyToMessageId: m.replyToMessageId,
            replyToSender: m.replyToSender,
            replyToMessage: m.replyToMessage,
        }));
    }
}

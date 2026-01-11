import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Message } from '../chat/entities/message.entity';
import { BlockedUser } from './entities/blocked-user.entity';
import { FriendRequest } from './entities/friend-request.entity';
import { Friendship } from './entities/friendship.entity';
import { User } from './entities/user.entity';

@Injectable()
export class UsersService {
    constructor(
        @InjectRepository(User)
        private usersRepository: Repository<User>,
        @InjectRepository(FriendRequest)
        private friendRequestRepository: Repository<FriendRequest>,
        @InjectRepository(Friendship)
        private friendshipRepository: Repository<Friendship>,
        @InjectRepository(Message)
        private messageRepository: Repository<Message>,
        @InjectRepository(BlockedUser)
        private blockedUserRepository: Repository<BlockedUser>,
    ) { }

    async findOne(username: string): Promise<User | null> {
        return this.usersRepository.findOne({ where: { username } });
    }

    async findByEmail(email: string): Promise<User | null> {
        return this.usersRepository.findOne({ where: { email } });
    }

    async findOneById(id: number): Promise<User | null> {
        return this.usersRepository.findOne({ where: { id } });
    }

    async getFriends(id: number): Promise<any[]> {
        // Find all friendships where user is either user1 or user2
        const friendships = await this.friendshipRepository.find({
            where: [
                { user1: { id } },
                { user2: { id } }
            ],
            relations: ['user1', 'user2']
        });

        // Fetch blocks where user is involved
        const blocks = await this.blockedUserRepository.find({
            where: [
                { blocker: { id } },
                { blocked: { id } }
            ],
            relations: ['blocker', 'blocked']
        });

        const blockedIds = new Set(blocks.map(b =>
            b.blocker.id === id ? b.blocked.id : b.blocker.id
        ));

        const activeFriendships = friendships.filter(f => {
            const friendId = f.user1.id === id ? f.user2.id : f.user1.id;
            return !blockedIds.has(friendId);
        });

        const friendsWithChat = await Promise.all(activeFriendships.map(async (friendship) => {
            // Determine which user is the friend
            const isUser1 = friendship.user1.id === id;
            const friend = isUser1 ? friendship.user2 : friendship.user1;

            // Get last message
            const lastMessage = await this.messageRepository.findOne({
                where: [
                    { sender: { id }, recipient: { id: friend.id } },
                    { sender: { id: friend.id }, recipient: { id } }
                ],
                order: { createdAt: 'DESC' },
                relations: ['sender']
            });

            return {
                ...friend,
                lastMessage: lastMessage ? {
                    content: lastMessage.content,
                    timestamp: lastMessage.createdAt,
                    senderId: lastMessage.sender.id,
                    attachmentType: lastMessage.attachmentType
                } : null
            };
        }));

        return friendsWithChat;
    }

    async sendFriendRequest(senderId: number, friendEmail: string): Promise<FriendRequest> {
        const sender = await this.findOneById(senderId);
        const recipient = await this.findByEmail(friendEmail);

        if (!sender || !recipient) throw new Error('User or Friend not found');
        if (sender.id === recipient.id) throw new Error('Cannot add yourself');

        // Check if blocked
        const isBlocked = await this.isBlocked(sender.id, recipient.id);
        if (isBlocked) throw new Error('Cannot send friend request');

        // Check if already friends
        const existingFriendship = await this.friendshipRepository.findOne({
            where: [
                { user1: { id: sender.id }, user2: { id: recipient.id } },
                { user1: { id: recipient.id }, user2: { id: sender.id } }
            ]
        });
        if (existingFriendship) {
            throw new Error('Already friends');
        }

        // Check if request already exists
        const existing = await this.friendRequestRepository.findOne({
            where: [
                { sender: { id: sender.id }, recipient: { id: recipient.id }, status: 'pending' },
                { sender: { id: recipient.id }, recipient: { id: sender.id }, status: 'pending' }
            ]
        });
        if (existing) throw new Error('Request already pending');

        const request = this.friendRequestRepository.create({
            sender,
            recipient,
            status: 'pending'
        });
        return this.friendRequestRepository.save(request);
    }

    async getPendingRequests(userId: number): Promise<FriendRequest[]> {
        return this.friendRequestRepository.find({
            where: { recipient: { id: userId }, status: 'pending' },
            relations: ['sender']
        });
    }

    async acceptFriendRequest(userId: number, requestId: number): Promise<FriendRequest> {
        const request = await this.friendRequestRepository.findOne({
            where: { id: requestId, recipient: { id: userId }, status: 'pending' },
            relations: ['sender', 'recipient']
        });

        if (!request) throw new Error('Request not found');

        const user = await this.findOneById(request.recipient.id);
        const friend = await this.findOneById(request.sender.id);

        if (!user || !friend) throw new Error('User or Friend not found');

        // Check if friendship already exists
        const existingFriendship = await this.friendshipRepository.findOne({
            where: [
                { user1: { id: user.id }, user2: { id: friend.id } },
                { user1: { id: friend.id }, user2: { id: user.id } }
            ]
        });

        if (!existingFriendship) {
            // Create Friendship record
            const friendship = this.friendshipRepository.create({
                user1: user,
                user2: friend
            });
            await this.friendshipRepository.save(friendship);
        }

        request.status = 'accepted';
        return this.friendRequestRepository.save(request);
    }

    async declineFriendRequest(userId: number, requestId: number): Promise<void> {
        const request = await this.friendRequestRepository.findOne({
            where: { id: requestId, recipient: { id: userId }, status: 'pending' }
        });
        if (!request) throw new Error('Request not found');

        request.status = 'declined';
        await this.friendRequestRepository.save(request);
    }

    async removeFriend(userId: number, friendId: number): Promise<void> {
        const user = await this.findOneById(userId);
        const friend = await this.findOneById(friendId);

        if (!user || !friend) return;

        // Delete Friendship record
        await this.friendshipRepository.delete([
            { user1: { id: userId }, user2: { id: friendId } },
            { user1: { id: friendId }, user2: { id: userId } }
        ]);

        // Delete all messages between these two users (Optional - keep or remove based on requirement)
        await this.messageRepository.delete([
            { sender: { id: userId }, recipient: { id: friendId } },
            { sender: { id: friendId }, recipient: { id: userId } }
        ]);
    }



    async findAll(): Promise<User[]> {
        return this.usersRepository.find({
            select: ['id', 'username', 'displayName', 'bio', 'avatarUrl', 'publicKey', 'email'],
        });
    }

    async create(username: string, email: string, passwordHash: string): Promise<User> {
        const user = this.usersRepository.create({ username, email, password: passwordHash });
        return this.usersRepository.save(user);
    }

    async updateProfile(id: number, profile: { displayName?: string; bio?: string; publicKey?: string }): Promise<User | null> {
        await this.usersRepository.update(id, profile);
        return this.findOneById(id);
    }

    async updateAvatar(id: number, avatarUrl: string): Promise<User | null> {
        await this.usersRepository.update(id, { avatarUrl });
        return this.findOneById(id);
    }

    async updateStatus(id: number, statusMessage: string): Promise<User | null> {
        await this.usersRepository.update(id, { statusMessage });
        return this.findOneById(id);
    }

    // Block/Unblock functionality
    async blockUser(blockerId: number, blockedId: number): Promise<void> {
        const blocker = await this.findOneById(blockerId);
        const blocked = await this.findOneById(blockedId);

        if (!blocker || !blocked) throw new Error('User not found');
        if (blockerId === blockedId) throw new Error('Cannot block yourself');

        // Check if already blocked
        const existing = await this.blockedUserRepository.findOne({
            where: { blocker: { id: blockerId }, blocked: { id: blockedId } }
        });

        if (existing) throw new Error('User already blocked');

        const block = this.blockedUserRepository.create({
            blocker,
            blocked,
        });

        await this.blockedUserRepository.save(block);

        // Remove friendship if exists
        await this.removeFriend(blockerId, blockedId);
    }

    async unblockUser(blockerId: number, blockedId: number): Promise<void> {
        await this.blockedUserRepository.delete({
            blocker: { id: blockerId },
            blocked: { id: blockedId },
        });
    }

    async getBlockedUsers(userId: number): Promise<User[]> {
        const blocks = await this.blockedUserRepository.find({
            where: { blocker: { id: userId } },
            relations: ['blocked'],
        });

        return blocks.map(b => b.blocked);
    }

    async isBlocked(userId: number, targetId: number): Promise<boolean> {
        const block = await this.blockedUserRepository.findOne({
            where: [
                { blocker: { id: userId }, blocked: { id: targetId } },
                { blocker: { id: targetId }, blocked: { id: userId } },
            ],
        });

        return !!block;
    }
}

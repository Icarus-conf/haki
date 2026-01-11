import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_mobile/views/call_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user_model.dart';
import '../../providers/chat_provider.dart';
import '../../services/api_service.dart';

class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final UserModel? recipient;
  final bool isRecipientTyping;
  final List<int> onlineUserIds;
  final bool isEmbedded;

  const ChatAppBar({
    super.key,
    required this.recipient,
    required this.isRecipientTyping,
    required this.onlineUserIds,
    this.isEmbedded = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: const Color.fromARGB(255, 17, 38, 101),
      foregroundColor: const Color.fromARGB(255, 107, 92, 255),
      title: Row(
        children: [
          Hero(
            tag: 'avatar_${recipient?.id}',
            child: CircleAvatar(
              radius: 18,
              backgroundImage: recipient?.avatarUrl != null
                  ? CachedNetworkImageProvider('${ApiService.baseUrl}${recipient!.avatarUrl}')
                  : CachedNetworkImageProvider(
                          'https://api.dicebear.com/7.x/avataaars/png?seed=${recipient?.username ?? "Global"}',
                        )
                        as ImageProvider,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                recipient?.displayName ?? recipient?.username ?? '',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              // Show typing indicator or online status
              if (isRecipientTyping)
                const Text(
                  'typing...',
                  style: TextStyle(fontSize: 12, color: Colors.lightBlueAccent),
                )
              else if (recipient != null && onlineUserIds.contains(recipient!.id))
                const Text('Online', style: TextStyle(fontSize: 12, color: Colors.green)),
            ],
          ),
        ],
      ),
      leading: isEmbedded
          ? null
          : IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
      actions: [
        if (recipient != null) ...[
          IconButton(
            icon: const Icon(Icons.photo_library_outlined, color: Colors.white),
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/shared-media',
                arguments: {
                  'recipientId': recipient!.id,
                  'recipientName': recipient!.displayName ?? recipient!.username,
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.call, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CallView(recipientId: recipient!.id, isIncoming: false),
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) async {
              if (value == 'block') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Block User'),
                    content: Text(
                      'Are you sure you want to block ${recipient!.displayName ?? recipient!.username}?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Block', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );

                if (confirm == true && context.mounted) {
                  final chat = Provider.of<ChatProvider>(context, listen: false);
                  final success = await chat.blockUser(recipient!.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success ? 'User blocked successfully' : 'Failed to block user',
                        ),
                      ),
                    );
                    if (success) {
                      Navigator.pop(context); // Go back to home
                    }
                  }
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'block',
                child: Row(
                  children: [
                    Icon(Icons.block, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Block User', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

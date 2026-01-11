import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../models/friend_request_model.dart';
import '../../services/api_service.dart';

class FriendRequestsSection extends StatelessWidget {
  final List<FriendRequestModel> requests;
  final Function(int) onAccept;
  final Function(int) onDecline;

  const FriendRequestsSection({
    super.key,
    required this.requests,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color.fromARGB(255, 29, 30, 126), Color.fromARGB(255, 107, 92, 255)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'FRIEND REQUESTS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 29, 30, 126).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${requests.length}',
                  style: const TextStyle(
                    color: Color.fromARGB(255, 29, 30, 126),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...requests.map(
          (req) => _FriendRequestItem(
            request: req,
            onAccept: () => onAccept(req.id),
            onDecline: () => onDecline(req.id),
          ),
        ),
      ],
    );
  }
}

class _FriendRequestItem extends StatelessWidget {
  final FriendRequestModel request;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _FriendRequestItem({
    required this.request,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: const Color.fromARGB(255, 29, 30, 126).withValues(alpha: 0.05),
            blurRadius: 40,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.grey[100],
                        backgroundImage: request.sender.avatarUrl != null
                            ? CachedNetworkImageProvider(
                                '${ApiService.baseUrl}${request.sender.avatarUrl}',
                              )
                            : CachedNetworkImageProvider(
                                    'https://api.dicebear.com/7.x/avataaars/png?seed=${request.sender.username}',
                                  )
                                  as ImageProvider,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10b981),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.person_add, size: 10, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.sender.displayName ?? request.sender.username,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF1f2937),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Wants to connect with you',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 1),
            Row(
              children: [
                // Accept Button
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10b981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.check_rounded, color: Color(0xFF10b981), size: 22),
                    onPressed: onAccept,
                    tooltip: 'Accept',
                  ),
                ),
                const SizedBox(width: 8),
                // Decline Button
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFef4444).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFFef4444), size: 22),
                    onPressed: onDecline,
                    tooltip: 'Decline',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

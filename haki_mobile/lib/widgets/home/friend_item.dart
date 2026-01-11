import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../models/user_model.dart';
import '../../services/api_service.dart';

class FriendItem extends StatefulWidget {
  final UserModel user;
  final bool isOnline;
  final bool isPinned;
  final VoidCallback onTap;
  final VoidCallback onTogglePin;
  final VoidCallback? onLongPress;

  const FriendItem({
    super.key,
    required this.user,
    required this.isOnline,
    this.isPinned = false,
    required this.onTap,
    required this.onTogglePin,
    this.onLongPress,
  });

  @override
  State<FriendItem> createState() => _FriendItemState();
}

class _FriendItemState extends State<FriendItem> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));

    _glowAnimation = Tween<double>(
      begin: 0.05,
      end: 0.15,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(FriendItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    // No unread logic anymore
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color ?? Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Theme.of(context).primaryColor.withValues(alpha: _glowAnimation.value),
                  blurRadius: 40,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                onLongPress: widget.onLongPress,
                borderRadius: BorderRadius.circular(20),
                splashColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                highlightColor: Theme.of(context).primaryColor.withValues(alpha: 0.05),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: widget.isOnline
                                  ? Border.all(color: const Color(0xFF10b981), width: 3)
                                  : null,
                            ),
                            child: Hero(
                              tag: 'avatar_${widget.user.id}',
                              child: CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.grey[100],
                                backgroundImage: widget.user.avatarUrl != null
                                    ? CachedNetworkImageProvider(
                                        '${ApiService.baseUrl}${widget.user.avatarUrl}',
                                      )
                                    : CachedNetworkImageProvider(
                                            'https://api.dicebear.com/7.x/avataaars/png?seed=${widget.user.username}',
                                          )
                                          as ImageProvider,
                              ),
                            ),
                          ),
                          if (widget.isOnline)
                            Positioned(
                              bottom: 2,
                              right: 2,
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10b981),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
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
                              widget.user.displayName ?? widget.user.username,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            if (widget.user.bio != null && widget.user.bio!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                widget.user.bio!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Colors.grey[600], fontSize: 14),
                              ),
                            ],
                            if (widget.user.statusMessage != null &&
                                widget.user.statusMessage!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                widget.user.statusMessage!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                  fontStyle: FontStyle.italic,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ],
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          if (widget.isPinned)
                            const Icon(Icons.push_pin_rounded, color: Colors.orange, size: 16),
                          if (widget.isPinned) const SizedBox(width: 4),
                          Icon(Icons.chevron_right, color: Colors.grey[400]),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../models/user_model.dart';
import '../../services/api_service.dart';

class TypingIndicatorBubble extends StatelessWidget {
  final UserModel? recipient;

  const TypingIndicatorBubble({super.key, required this.recipient});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundImage: recipient?.avatarUrl != null
                ? CachedNetworkImageProvider('${ApiService.baseUrl}${recipient!.avatarUrl}')
                : CachedNetworkImageProvider(
                        'https://api.dicebear.com/7.x/avataaars/png?seed=${recipient?.username ?? "User"}',
                      )
                      as ImageProvider,
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const _TypingIndicatorDots(),
          ),
        ],
      ),
    );
  }
}

class _TypingIndicatorDots extends StatelessWidget {
  const _TypingIndicatorDots();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        3,
        (index) => Padding(
          padding: EdgeInsets.only(left: index > 0 ? 4 : 0),
          child: _AnimatedDot(delay: index * 200),
        ),
      ),
    );
  }
}

class _AnimatedDot extends StatefulWidget {
  final int delay;

  const _AnimatedDot({required this.delay});

  @override
  State<_AnimatedDot> createState() => _AnimatedDotState();
}

class _AnimatedDotState extends State<_AnimatedDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);

    _animation = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: Colors.grey[400], shape: BoxShape.circle),
      ),
    );
  }
}

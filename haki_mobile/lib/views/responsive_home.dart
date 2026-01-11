import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/chat_provider.dart';
import 'chat_view.dart';
import 'home_view.dart';

class ResponsiveHome extends StatelessWidget {
  const ResponsiveHome({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 600) {
          return const _TabletLayout();
        } else {
          return const HomeView();
        }
      },
    );
  }
}

class _TabletLayout extends StatelessWidget {
  const _TabletLayout();

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();

    return Scaffold(
      body: Row(
        children: [
          // Master: Contacts List
          const SizedBox(width: 320, child: HomeView(isEmbedded: true)),
          // Divider
          VerticalDivider(thickness: 1, width: 1, color: Colors.grey[200]),
          // Detail: Chat Area
          Expanded(
            child: chat.activeRecipient != null
                ? const ChatView(isEmbedded: true)
                : const _NoChatSelected(),
          ),
        ],
      ),
    );
  }
}

class _NoChatSelected extends StatelessWidget {
  const _NoChatSelected();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFf8fafc),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(Icons.forum_outlined, size: 64, color: Colors.grey[300]),
            ),
            const SizedBox(height: 24),
            Text(
              'Select a contact to start chatting',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[400]),
            ),
            const SizedBox(height: 8),
            Text(
              'Your messages will appear here',
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

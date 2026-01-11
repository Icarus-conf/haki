import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/chat_provider.dart';

class CallView extends StatefulWidget {
  final int recipientId;
  final bool isIncoming;

  const CallView({super.key, required this.recipientId, this.isIncoming = false});

  @override
  State<CallView> createState() => _CallViewState();
}

class _CallViewState extends State<CallView> {
  // Simple UI for now

  @override
  void initState() {
    super.initState();
    if (!widget.isIncoming) {
      // Start call immediately if outgoing
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<ChatProvider>().startCall(widget.recipientId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    // Find user details
    final user = chat.users.firstWhere(
      (u) => u.id == widget.recipientId,
      orElse: () => chat.me!,
    ); // Fallback

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.grey[800],
              child: const Icon(Icons.person, size: 60, color: Colors.white),
            ),
            const SizedBox(height: 24),
            Text(
              user.displayName ?? user.username,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(chat.callStatus, style: TextStyle(color: Colors.grey[400], fontSize: 16)),
            const Spacer(),

            // Actions
            Padding(
              padding: const EdgeInsets.only(bottom: 48),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (chat.isCallIncoming) ...[
                    // Decline
                    FloatingActionButton(
                      heroTag: 'decline',
                      onPressed: () {
                        context.read<ChatProvider>().declineCall();
                        Navigator.pop(context);
                      },
                      backgroundColor: Colors.red,
                      child: const Icon(Icons.call_end),
                    ),
                    // Accept
                    FloatingActionButton(
                      heroTag: 'accept',
                      onPressed: () {
                        context.read<ChatProvider>().acceptCall();
                      },
                      backgroundColor: Colors.green,
                      child: const Icon(Icons.call),
                    ),
                  ] else ...[
                    // Speaker toggle
                    FloatingActionButton(
                      heroTag: 'speaker',
                      onPressed: () {
                        context.read<ChatProvider>().toggleSpeaker();
                      },
                      backgroundColor: chat.isSpeakerOn
                          ? Theme.of(context).primaryColor
                          : Colors.grey[800],
                      elevation: 0,
                      child: Icon(
                        chat.isSpeakerOn ? Icons.volume_up : Icons.volume_mute,
                        color: Colors.white,
                      ),
                    ),
                    // End Call (Outgoing or Connected)
                    FloatingActionButton(
                      heroTag: 'end',
                      onPressed: () {
                        context.read<ChatProvider>().endCall();
                        Navigator.pop(context);
                      },
                      backgroundColor: Colors.red,
                      child: const Icon(Icons.call_end),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

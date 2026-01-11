import 'package:flutter/material.dart';

import '../../models/message_model.dart';
import '../voice_recorder.dart';
import 'attachment_preview.dart';

class ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final VoidCallback onAttachment;
  final Function(String path) onVoiceStop;
  final VoidCallback onVoiceCancel;
  final String? pendingAttachmentUrl;
  final VoidCallback onCancelAttachment;
  final MessageModel? replyToMessage;
  final VoidCallback onCancelReply;

  const ChatInput({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSend,
    required this.onAttachment,
    required this.onVoiceStop,
    required this.onVoiceCancel,
    this.pendingAttachmentUrl,
    required this.onCancelAttachment,
    this.replyToMessage,
    required this.onCancelReply,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (replyToMessage != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color ?? Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Replying to ${replyToMessage!.sender}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        replyToMessage!.message,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: onCancelReply,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        if (pendingAttachmentUrl != null)
          AttachmentPreview(attachmentPath: pendingAttachmentUrl!, onCancel: onCancelAttachment),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color ?? Colors.white,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.transparent
                    : pendingAttachmentUrl != null
                    ? Colors.transparent
                    : const Color(0xFFf3f4f6),
              ),
            ),
          ),
          child: SafeArea(
            child: Row(
              children: [
                IconButton(
                  onPressed: onAttachment,
                  icon: Icon(Icons.add_circle_outline, color: Theme.of(context).primaryColor),
                ),
                Expanded(
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
                      fillColor: Theme.of(context).brightness == Brightness.dark
                          ? Colors.black.withValues(alpha: 0.5)
                          : const Color(0xFFf9fafb),
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controller,
                  builder: (context, value, child) {
                    if (value.text.isNotEmpty || pendingAttachmentUrl != null) {
                      return Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color.fromARGB(255, 3, 6, 90),
                              Color.fromARGB(255, 98, 98, 197),
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: IconButton(
                          onPressed: onSend,
                          icon: const Icon(Icons.send, color: Colors.white, size: 20),
                        ),
                      );
                    } else {
                      return VoiceRecorder(onStop: onVoiceStop, onCancel: onVoiceCancel);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

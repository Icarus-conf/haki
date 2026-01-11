import 'package:flutter/material.dart';

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
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
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

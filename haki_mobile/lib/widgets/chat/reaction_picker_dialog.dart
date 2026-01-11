import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/message_model.dart';
import '../../providers/chat_provider.dart';

class ReactionPickerDialog {
  static void show(BuildContext context, MessageModel message) {
    final chat = context.read<ChatProvider>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: const EdgeInsets.all(16),
        content: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ['👍', '❤️', '😂', '😮', '😢', '🙏']
                .map(
                  (emoji) => InkWell(
                    onTap: () {
                      chat.chat.socket?.emit('message:react', {
                        'messageId': message.id,
                        'emoji': emoji,
                      });
                      Navigator.pop(context);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(emoji, style: const TextStyle(fontSize: 32)),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

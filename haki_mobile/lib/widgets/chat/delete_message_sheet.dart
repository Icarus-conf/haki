import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/message_model.dart';
import '../../providers/chat_provider.dart';
import 'undo_countdown_snackbar.dart';

class DeleteMessageSheet {
  static void show(BuildContext context, MessageModel message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text(
                'Delete Message',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
              onTap: () {
                Navigator.pop(context);
                final chat = context.read<ChatProvider>();
                chat.deleteMessageLocally(message);

                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Colors.grey[900],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    margin: const EdgeInsets.only(bottom: 100, left: 24, right: 24),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    content: UndoCountdownSnackbar(onUndo: () => chat.undoDelete(message)),
                    duration: const Duration(seconds: 5),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

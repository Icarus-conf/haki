import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/message_model.dart';
import '../../providers/chat_provider.dart';
import '../../services/api_service.dart';
import '../loading_indicator.dart';
import '../voice_player.dart';
import 'delete_message_sheet.dart';
import 'encrypted_image.dart';
import 'link_preview_card.dart';
import 'reaction_picker_dialog.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final bool isFollowing;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.isFollowing,
  });

  @override
  Widget build(BuildContext context) {
    final time = DateFormat.jm().format(message.timestamp.toLocal());

    return Padding(
      padding: EdgeInsets.only(top: isFollowing ? 2 : 12, bottom: isFollowing ? 0 : 4),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMe) ...[
                if (!isFollowing)
                  CircleAvatar(
                    radius: 14,
                    backgroundImage: message.avatarUrl != null
                        ? CachedNetworkImageProvider('${ApiService.baseUrl}${message.avatarUrl}')
                        : CachedNetworkImageProvider(
                                'https://api.dicebear.com/7.x/avataaars/png?seed=${message.username}',
                              )
                              as ImageProvider,
                  )
                else
                  const SizedBox(width: 28),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: GestureDetector(
                  onLongPress: () {
                    if (isMe) {
                      DeleteMessageSheet.show(context, message);
                    } else {
                      ReactionPickerDialog.show(context, message);
                    }
                  },
                  child: Container(
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: isMe
                          ? const LinearGradient(
                              colors: [
                                Color.fromARGB(255, 52, 55, 149),
                                Color.fromARGB(255, 98, 98, 197),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isMe ? null : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: Radius.circular(isMe ? 20 : 4),
                        bottomRight: Radius.circular(isMe ? 4 : 20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isMe && !isFollowing && message.recipientId == null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              message.sender,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                        if (message.replyToMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(8),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: isMe
                                  ? Colors.white.withValues(alpha: 0.2)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border(
                                left: BorderSide(
                                  color: isMe ? Colors.white : Theme.of(context).primaryColor,
                                  width: 3,
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  message.replyToSender ?? 'Unknown',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isMe ? Colors.white70 : Theme.of(context).primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  message.replyToMessage!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isMe ? Colors.white60 : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        Text(
                          message.message,
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black87,
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                        if (message.attachmentUrl != null) ...[
                          const SizedBox(height: 8),
                          _buildAttachment(context),
                        ],
                        if (_extractUrl(message.message) != null) ...[
                          const SizedBox(height: 8),
                          LinkPreviewCard(url: _extractUrl(message.message)!),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(top: 4, left: isMe ? 0 : 48, right: isMe ? 0 : 0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                Text(time, style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                if (isMe && message.isSending) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.access_time, size: 10, color: Colors.grey),
                ],
              ],
            ),
          ),
          if (message.reactions.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: 4, left: isMe ? 0 : 48),
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children: _groupReactions(message.reactions).entries.map((entry) {
                  final chat = context.read<ChatProvider>();
                  final isMyReaction = entry.value.any((r) => r.userId == chat.me?.id);
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isMyReaction ? Colors.blue.shade50 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: isMyReaction ? Border.all(color: Colors.blue, width: 1.5) : null,
                    ),
                    child: Text(
                      '${entry.key} ${entry.value.length}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAttachment(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Builder(
        builder: (context) {
          final isRemote =
              message.attachmentUrl!.startsWith('http') ||
              message.attachmentUrl!.startsWith('/uploads');
          final isEncrypted = message.mediaIv != null && message.mediaKeys != null;

          // Debug logging
          debugPrint('--- RENDERING ATTACHMENT ---');
          debugPrint('URL: ${message.attachmentUrl}');
          debugPrint('Type: ${message.attachmentType}');

          // Bulletproof detection for voice notes
          final isVoice =
              message.attachmentType == 'voice' ||
              message.attachmentUrl!.toLowerCase().contains('.m4a') ||
              (message.attachmentUrl!.toLowerCase().contains('.bin') &&
                  message.attachmentType != 'image');

          debugPrint('Detected as Voice: $isVoice');

          // Voice messages take priority
          if (isVoice) {
            return VoicePlayer(
              url: message.attachmentUrl!,
              iv: message.mediaIv,
              keys: message.mediaKeys,
            );
          }

          if (isRemote) {
            if (isEncrypted) {
              return EncryptedImage(
                url: message.attachmentUrl!,
                iv: message.mediaIv!,
                keys: message.mediaKeys!,
              );
            } else {
              return CachedNetworkImage(
                imageUrl: message.attachmentUrl!.startsWith('http')
                    ? message.attachmentUrl!
                    : '${ApiService.baseUrl}${message.attachmentUrl}',
                placeholder: (context, url) =>
                    const SizedBox(height: 200, child: Center(child: LoadingIndicator(size: 24))),
                errorWidget: (context, url, error) =>
                    const SizedBox(height: 200, child: Center(child: Icon(Icons.error))),
                fit: BoxFit.cover,
              );
            }
          } else {
            // Local file (Optimistic UI)
            final file = File(message.attachmentUrl!);
            if (file.existsSync()) {
              return Image.file(file, fit: BoxFit.cover);
            } else {
              return const SizedBox(
                height: 200,
                child: Center(child: Icon(Icons.broken_image, color: Colors.grey)),
              );
            }
          }
        },
      ),
    );
  }

  Map<String, List<dynamic>> _groupReactions(List<dynamic> reactions) {
    final Map<String, List<dynamic>> grouped = {};
    for (var reaction in reactions) {
      final emoji = reaction.emoji;
      grouped.putIfAbsent(emoji, () => []).add(reaction);
    }
    return grouped;
  }

  String? _extractUrl(String message) {
    final urlRegExp = RegExp(
      r'(https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|www\.[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|https?:\/\/[^\s]+)',
    );
    final match = urlRegExp.firstMatch(message);
    return match?.group(0);
  }
}

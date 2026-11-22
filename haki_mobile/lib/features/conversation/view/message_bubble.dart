import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/haki_theme.dart';
import '../../../core/widgets/glass.dart';
import '../../../models/message_envelope.dart';
import '../../../models/message_model.dart';
import '../../../models/reaction_model.dart';
import '../../../models/user_model.dart';
import '../../../services/api_service.dart';
import '../../../services/crypto_service.dart';
import '../../../widgets/chat/encrypted_image.dart';
import '../../../widgets/chat/link_preview_card.dart';
import '../../../widgets/voice_player.dart';
import 'chat_extras.dart';
import 'compose_extras.dart';
import 'package:chat_mobile/core/theme/haki_icons.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.myId,
    this.myUsername,
    this.highlight,
    required this.groupedWithPrevious,
    required this.showSenderName,
    required this.onLongPress,
    required this.onReactionTap,
    this.onVote,
    this.quotedText,
    this.onOpenViewOnce,
    this.onOpenFile,
  });

  /// View once: the recipient tapped to open it.
  final VoidCallback? onOpenViewOnce;

  /// Video / document: download, decrypt and open.
  final Future<void> Function()? onOpenFile;

  /// Polls: the user tapped option N.
  final ValueChanged<int>? onVote;

  /// Text of the message this one replies to, looked up locally by id.
  final String? quotedText;
  final MessageModel message;
  final bool isMe;
  final int myId;

  /// For highlighting "@me" mentions.
  final String? myUsername;

  /// Search text to mark inside the message.
  final String? highlight;
  final bool groupedWithPrevious;
  final bool showSenderName; // lounge: show who said it
  final VoidCallback onLongPress;
  final ValueChanged<String> onReactionTap;

  static const _tail = Radius.circular(8);
  static const _round = Radius.circular(24);

  @override
  Widget build(BuildContext context) {
    // Readable lines on wide windows too
    final maxWidth = (MediaQuery.sizeOf(context).width * 0.76).clamp(0.0, 520.0);
    final radius = BorderRadius.only(
      topLeft: _round,
      topRight: _round,
      bottomLeft: isMe ? _round : _tail,
      bottomRight: isMe ? _tail : _round,
    );
    final time = DateFormat.jm().format(message.timestamp.toLocal());
    final hasText = message.message.trim().isNotEmpty;
    final isReply = message.replyToMessageId != null || message.replyToMessage != null;
    final quote = quotedText ?? message.replyToMessage ?? 'Original message';
    final frameless = message.isImage && !message.viewOnce && !hasText && !isReply;

    final status = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (message.expiresAt != null)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Icon(HakiIcons.timer, size: 12, color: Colors.white.withValues(alpha: 0.65), semanticLabel: 'Disappears'),
          ),
        if (message.editedAt != null)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Text('edited', style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.6))),
          ),
        Text(time, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.72))),
        if (isMe) ...[
          const SizedBox(width: 4),
          Icon(
            message.isSending
                ? HakiIcons.clock
                : (message.isRead ? HakiIcons.checks : HakiIcons.check),
            size: 14,
            color: message.isRead ? HakiColors.lime : Colors.white.withValues(alpha: 0.72),
            semanticLabel: message.isSending ? 'Sending' : (message.isRead ? 'Read' : 'Sent'),
          ),
        ],
      ],
    );

    Widget content;
    if (message.sticker != null && !isReply) {
      content = Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (showSenderName)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                message.sender,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: HakiColors.auraFor(message.senderId)[0]),
              ),
            ),
          StickerBubble(sticker: message.sticker!, seed: message.senderId),
          Glass(radius: 12, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), child: status),
        ],
      );
    } else if (frameless) {
      // Photos stand on their own, no bubble frame
      content = ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: 320, minWidth: 180, minHeight: 140),
              child: _Attachment(message: message),
            ),
            Positioned(
              right: 10,
              bottom: 10,
              child: Glass(radius: 12, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), child: status),
            ),
          ],
        ),
      );
    } else {
      content = Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        padding: const EdgeInsets.fromLTRB(7, 7, 7, 8),
        decoration: BoxDecoration(
          color: isMe ? HakiColors.outgoingBubble : HakiColors.incomingBubble,
          borderRadius: radius,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showSenderName)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 2, 8, 2),
                child: Text(
                  message.sender,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: HakiColors.auraFor(message.senderId)[0],
                  ),
                ),
              ),
            if (message.forwarded)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 2, 8, 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(HakiIcons.arrowBendUpRight, size: 14, color: Colors.white.withValues(alpha: 0.65)),
                    const SizedBox(width: 4),
                    Text(
                      'Forwarded',
                      style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.white.withValues(alpha: 0.65)),
                    ),
                  ],
                ),
              ),
            if (isReply)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.replyToSender ?? '',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      quote,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.82)),
                    ),
                  ],
                ),
              ),
            if (message.storyRef != null) _StoryQuote(story: message.storyRef!, isMe: isMe),
            if (message.poll != null)
              PollCard(message: message, myId: myId, onVote: (i) => onVote?.call(i)),
            if (message.viewOnce)
              ViewOnceTile(message: message, isMe: isMe, onOpen: onOpenViewOnce)
            else if (message.isVideo || message.isFile)
              FileCard(message: message, onOpen: onOpenFile ?? () async {})
            else if (message.attachmentUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: message.isVoice
                    ? Padding(padding: const EdgeInsets.all(2), child: _Attachment(message: message))
                    : ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 300),
                        child: _Attachment(message: message),
                      ),
              ),
            if (hasText)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                child: CryptoService.undecryptable.contains(message.message)
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(HakiIcons.lock, size: 15, color: Colors.white.withValues(alpha: 0.6)),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Sent to an older key. Can’t be opened on this phone.',
                              style: TextStyle(
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Text.rich(
                        TextSpan(children: _spans(message.message)),
                        style: const TextStyle(fontSize: 15, height: 1.4),
                      ),
              ),
            if (message.linkPreview != null)
              Padding(padding: const EdgeInsets.only(top: 6), child: LinkPreviewCard(preview: message.linkPreview!)),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 6, 0),
              child: Align(alignment: Alignment.centerRight, widthFactor: 1, child: status),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(top: groupedWithPrevious ? 3 : 12),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          GestureDetector(onLongPress: onLongPress, onSecondaryTap: onLongPress, child: content),
          if (message.reactions.isNotEmpty)
            Transform.translate(
              offset: const Offset(0, -8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Wrap(
                  spacing: 4,
                  children: [
                    for (final e in _grouped(message.reactions).entries)
                      _ReactionChip(
                        emoji: e.key,
                        count: e.value.length,
                        mine: e.value.any((r) => r.userId == myId),
                        onTap: () => onReactionTap(e.key),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// @mentions in lime (yours on a lime chip) and search matches marked.
  List<InlineSpan> _spans(String text) {
    final q = highlight?.trim() ?? '';
    final pattern = RegExp(
      [r'@[A-Za-z0-9_.]{2,30}', if (q.isNotEmpty) RegExp.escape(q)].join('|'),
      caseSensitive: false,
    );
    final spans = <InlineSpan>[];
    var last = 0;
    for (final m in pattern.allMatches(text)) {
      if (m.start > last) spans.add(TextSpan(text: text.substring(last, m.start)));
      final part = m.group(0)!;
      if (q.isNotEmpty && part.toLowerCase() == q.toLowerCase()) {
        spans.add(TextSpan(
          text: part,
          style: const TextStyle(backgroundColor: HakiColors.lime, color: HakiColors.onLime),
        ));
      } else {
        final mine = myUsername != null && part.substring(1).toLowerCase() == myUsername!.toLowerCase();
        spans.add(TextSpan(
          text: part,
          style: mine
              ? const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: HakiColors.onLime,
                  backgroundColor: HakiColors.lime,
                )
              : const TextStyle(fontWeight: FontWeight.w700, color: HakiColors.lime),
        ));
      }
      last = m.end;
    }
    if (last < text.length) spans.add(TextSpan(text: text.substring(last)));
    return spans;
  }

  Map<String, List<ReactionModel>> _grouped(List<ReactionModel> reactions) {
    final map = <String, List<ReactionModel>>{};
    for (final r in reactions) {
      (map[r.emoji] ??= []).add(r);
    }
    return map;
  }
}

class _ReactionChip extends StatelessWidget {
  const _ReactionChip({required this.emoji, required this.count, required this.mine, required this.onTap});
  final String emoji;
  final int count;
  final bool mine;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$emoji, $count. ${mine ? 'Tap to remove yours' : 'Tap to add'}',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: mine ? const Color(0xFF2B2A12) : HakiColors.surfaceHigh,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: mine ? HakiColors.lime : HakiColors.ink, width: 2),
          ),
          child: Text('$emoji $count', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}

class _Attachment extends StatelessWidget {
  const _Attachment({required this.message});
  final MessageModel message;

  @override
  Widget build(BuildContext context) {
    final url = message.attachmentUrl!;
    if (message.isVoice) {
      return VoicePlayer(
        url: url,
        iv: message.mediaIv,
        keys: message.mediaKeys,
        knownDuration: message.durationSec == null ? null : Duration(seconds: message.durationSec!),
      );
    }

    final isRemote = url.startsWith('http') || url.startsWith('/uploads');
    if (!isRemote) {
      // Optimistic local preview while uploading (a blob: URL on the web)
      if (kIsWeb) return Image.network(url, fit: BoxFit.cover, errorBuilder: (_, _, _) => const _Broken());
      final file = File(url);
      return file.existsSync() ? Image.file(file, fit: BoxFit.cover) : const _Broken();
    }
    if (message.mediaIv != null && message.mediaKeys != null) {
      return EncryptedImage(url: url, iv: message.mediaIv!, keys: message.mediaKeys!);
    }
    return CachedNetworkImage(
      imageUrl: url.startsWith('http') ? url : '${ApiService.baseUrl}$url',
      fit: BoxFit.cover,
      placeholder: (_, _) => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
      errorWidget: (_, _, _) => const _Broken(),
    );
  }
}

/// "Replied to your story": a small thumbnail of the story above the reply text.
class _StoryQuote extends StatelessWidget {
  const _StoryQuote({required this.story, required this.isMe});
  final StoryRef story;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.22), borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: CachedNetworkImage(
              imageUrl: '${ApiService.baseUrl}${story.url}',
              width: 40,
              height: 56,
              fit: BoxFit.cover,
              // Stories expire after a day; the reply stays readable without the picture
              errorWidget: (_, _, _) => const SizedBox(
                width: 40,
                height: 56,
                child: Icon(HakiIcons.bookOpenText, size: 18, color: HakiColors.textMuted),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              isMe ? 'You replied to their story' : 'Replied to your story',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.white.withValues(alpha: 0.75)),
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
    );
  }
}

class _Broken extends StatelessWidget {
  const _Broken();

  @override
  Widget build(BuildContext context) => const SizedBox(
    height: 160,
    width: 200,
    child: Center(child: Icon(HakiIcons.imageBroken, color: HakiColors.textMuted)),
  );
}

/// Bubble-shaped "typing…" dots.
class TypingBubble extends StatefulWidget {
  const TypingBubble({super.key, required this.user});
  final UserModel user;

  @override
  State<TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<TypingBubble> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${widget.user.name} is typing',
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: const BoxDecoration(
            color: HakiColors.incomingBubble,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
              bottomRight: Radius.circular(24),
              bottomLeft: Radius.circular(8),
            ),
          ),
          child: AnimatedBuilder(
            animation: _c,
            builder: (_, _) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < 3; i++)
                  Container(
                    width: 7,
                    height: 7,
                    margin: EdgeInsets.only(left: i == 0 ? 0 : 5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      // Each dot pulses in turn: 0 → 1 → 0 brightness over one cycle
                      color: Colors.white.withValues(
                        alpha: 0.3 + 0.6 * (1 - (((_c.value - i * 0.2) % 1) * 2 - 1).abs()),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

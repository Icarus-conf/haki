import 'dart:async';
import 'package:cross_file/cross_file.dart';
import 'dart:typed_data';


import '../models/group_model.dart';
import '../models/message_envelope.dart';
import '../models/user_model.dart';
import 'api_service.dart';
import 'chat_service.dart';
import 'crypto_service.dart';
import 'link_preview_service.dart';

/// Where a message goes. Both null = the public Lounge (not encrypted).
typedef ChatTarget = ({UserModel? user, GroupModel? group});

/// Builds, encrypts, uploads and emits one message. Shared by the open chat and Forward.
class MessageSender {
  MessageSender({required this.api, required this.chat, required this.crypto});

  final ApiService api;
  final ChatService chat;
  final CryptoService crypto;

  /// Who can open the message: both people in a DM, every member in a group, null for the
  /// Lounge. Throws a readable error instead of ever falling back to plain text.
  static Map<String, String>? readerKeys(ChatTarget to, UserModel me) {
    final myKey = me.publicKey;
    if (to.group != null) {
      if (myKey == null) throw Exception('Your encryption key isn’t ready yet.');
      final keys = {
        for (final m in to.group!.members)
          if (m.publicKey != null) '${m.id}': m.publicKey!,
        '${me.id}': myKey,
      };
      if (keys.length < 2) throw Exception('Nobody else in this group has set up encryption yet.');
      return keys;
    }
    final user = to.user;
    if (user == null) return null;
    if (user.publicKey == null || myKey == null) {
      throw Exception('${user.name} hasn’t set up encryption yet. Ask them to open Haki once.');
    }
    return {'r': user.publicKey!, 's': myKey};
  }

  /// The encrypted (or, in the Lounge, plain) body. The link preview is built here, on the
  /// sender's phone, and travels inside the encrypted body.
  Future<String> body(
    String text,
    Map<String, String>? keys, {
    bool forwarded = false,
    PollData? poll,
    StoryRef? story,
    String? sticker,
    int? durationSec,
    FileMeta? file,
  }) async {
    final url = poll == null && file == null && sticker == null ? LinkPreviewService.firstUrl(text) : null;
    final preview = url == null ? null : await LinkPreviewService.fetch(url);
    final payload = MessageEnvelope.encode(
      text,
      preview: preview,
      forwarded: forwarded,
      poll: poll,
      story: story,
      sticker: sticker,
      durationSec: durationSec,
      file: file,
    );
    return keys == null ? payload : crypto.encryptFor(payload, keys);
  }

  Future<void> send({
    required ChatTarget to,
    required UserModel me,
    required String text,
    required String tempId,
    String? attachmentPath,
    String? attachmentType,
    int? replyToMessageId,
    String? replyToSender,
    bool forwarded = false,
    PollData? poll,
    StoryRef? story,
    String? sticker,
    int? durationSec,
    DateTime? sendAt,
    FileMeta? file,
    bool viewOnce = false,
  }) async {
    final keys = readerKeys(to, me);
    final payload = await body(
      text,
      keys,
      forwarded: forwarded,
      poll: poll,
      story: story,
      sticker: sticker,
      durationSec: durationSec,
      file: file,
    );
    String? attachmentUrl, mediaIv;
    Map<String, dynamic>? mediaKeys;

    if (attachmentPath != null) {
      if (keys != null) {
        final enc = await crypto.encryptMediaFor(await XFile(attachmentPath).readAsBytes(), keys);
        mediaIv = enc['iv'] as String;
        mediaKeys = enc['keys'] as Map<String, dynamic>;
        attachmentUrl = await api.uploadBytes(enc['data'] as Uint8List, 'enc_$tempId.bin');
      } else {
        attachmentUrl = await api.uploadAttachment(attachmentPath);
      }
      if (attachmentUrl == null) throw Exception('Upload failed');
    }

    chat.sendMessage(
      payload,
      recipientId: to.user?.id,
      groupId: to.group?.id,
      attachmentUrl: attachmentUrl,
      tempId: tempId,
      mediaIv: mediaIv,
      mediaKeys: mediaKeys,
      attachmentType: attachmentType,
      replyToMessageId: replyToMessageId,
      replyToSender: replyToSender,
      sendAt: sendAt,
      viewOnce: viewOnce && to.user != null,
      // Never upload the quoted text: it is already decrypted here and the server would
      // store it in plain text. Each phone shows the quote from its own copy (by id).
    );
  }
}

import 'package:freezed_annotation/freezed_annotation.dart';

import 'message_envelope.dart';
import 'reaction_model.dart';

part 'message_model.freezed.dart';

@Freezed(fromJson: false, toJson: false)
abstract class MessageModel with _$MessageModel {
  const MessageModel._();

  const factory MessageModel({
    int? id, // Database ID
    required String sender,
    required String username,
    required int senderId,
    String? avatarUrl,
    required String message,
    String? attachmentUrl,
    required DateTime timestamp,
    int? recipientId,
    int? groupId,
    String? tempId,
    @Default(false) bool isSending,
    @Default(false) bool isRead,
    String? mediaIv,
    Map<String, dynamic>? mediaKeys,
    String? attachmentType, // 'image' or 'voice'
    @Default([]) List<ReactionModel> reactions,
    int? replyToMessageId,
    String? replyToSender,
    String? replyToMessage,

    /// Decrypted from the message itself (see MessageEnvelope); never fetched by the reader.
    LinkPreview? linkPreview,
    @Default(false) bool forwarded,
    DateTime? editedAt,
    @Default(false) bool pinned,

    // From the encrypted body
    PollData? poll,
    StoryRef? storyRef,
    String? sticker,
    int? durationSec,

    /// userId → chosen option numbers (the server can count, not read, the poll).
    @Default({}) Map<int, List<int>> pollVotes,

    /// Set while a scheduled message waits on the server.
    DateTime? scheduledAt,

    /// Disappearing messages: the server deletes it at this time.
    DateTime? expiresAt,

    /// View once (private chats): the file is deleted once the recipient opens it.
    @Default(false) bool viewOnce,
    DateTime? viewedAt,

    /// Name and size of a shared video or document (from the encrypted body).
    FileMeta? file,
  }) = _MessageModel;

  factory MessageModel.fromJson(Map<String, dynamic> json) => MessageModel(
    id: json['id'],
    sender: json['sender'],
    username: json['username'],
    senderId: json['senderId'],
    avatarUrl: json['avatarUrl'],
    message: json['message'] ?? '',
    attachmentUrl: json['attachmentUrl'],
    timestamp: DateTime.parse(json['timestamp']),
    recipientId: json['recipientId'],
    groupId: json['groupId'],
    tempId: json['tempId'],
    isRead: json['isRead'] ?? false,
    mediaIv: json['mediaIv'],
    mediaKeys: json['mediaKeys'],
    attachmentType: json['attachmentType'],
    reactions:
        (json['reactions'] as List<dynamic>?)?.map((r) => ReactionModel.fromJson(r)).toList() ??
        const [],
    replyToMessageId: json['replyToMessageId'],
    replyToSender: json['replyToSender'],
    replyToMessage: json['replyToMessage'],
    editedAt: json['editedAt'] != null ? DateTime.parse(json['editedAt']) : null,
    pinned: json['pinned'] ?? false,
    pollVotes: parseVotes(json['pollVotes']),
    scheduledAt: json['scheduledAt'] != null ? DateTime.parse(json['scheduledAt']) : null,
    expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt']) : null,
    viewOnce: json['viewOnce'] ?? false,
    viewedAt: json['viewedAt'] != null ? DateTime.parse(json['viewedAt']) : null,
  );

  static Map<int, List<int>> parseVotes(dynamic raw) => {
    if (raw is Map)
      for (final e in raw.entries)
        if (int.tryParse('${e.key}') != null && e.value is List)
          int.parse('${e.key}'): [for (final o in e.value as List) (o as num).toInt()],
  };

  /// Copies the decrypted body's parts onto this message.
  MessageModel withBody(EnvelopeBody b) => copyWith(
    message: b.text,
    linkPreview: b.preview,
    forwarded: b.forwarded,
    poll: b.poll,
    storyRef: b.story,
    sticker: b.sticker,
    durationSec: b.durationSec,
    file: b.file,
    isSending: false,
  );

  bool get isVoice =>
      attachmentType == 'voice' || (attachmentUrl?.toLowerCase().contains('.m4a') ?? false);

  bool get isVideo => attachmentType == 'video';
  bool get isFile => attachmentType == 'file';

  /// Older messages have no type: anything that isn't voice was a photo.
  bool get isImage =>
      attachmentType == 'image' || (attachmentType == null && attachmentUrl != null && !isVoice);

  /// A view-once photo / voice note that has been opened (its file is gone).
  bool get isOpenedViewOnce => viewOnce && viewedAt != null;
}

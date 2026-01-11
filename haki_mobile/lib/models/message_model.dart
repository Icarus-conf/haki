import 'reaction_model.dart';

class MessageModel {
  final int? id; // Database ID
  final String sender;
  final String username;
  final int senderId;
  final String? avatarUrl;
  final String message;
  final String? attachmentUrl;
  final DateTime timestamp;
  final int? recipientId;
  final String? tempId;
  final bool isSending;
  final String? mediaIv;
  final Map<String, dynamic>? mediaKeys;
  final String? attachmentType; // 'image' or 'voice'
  final List<ReactionModel> reactions;

  MessageModel({
    this.id,
    required this.sender,
    required this.username,
    required this.senderId,
    this.avatarUrl,
    required this.message,
    this.attachmentUrl,
    required this.timestamp,
    this.recipientId,
    this.tempId,
    this.isSending = false,
    this.mediaIv,
    this.mediaKeys,
    this.attachmentType,
    this.reactions = const [],
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'],
      sender: json['sender'],
      username: json['username'],
      senderId: json['senderId'],
      avatarUrl: json['avatarUrl'],
      message: json['message'],
      attachmentUrl: json['attachmentUrl'],
      timestamp: DateTime.parse(json['timestamp']),
      recipientId: json['recipientId'],
      tempId: json['tempId'],
      isSending: false,
      mediaIv: json['mediaIv'],
      mediaKeys: json['mediaKeys'],
      attachmentType: json['attachmentType'],
      reactions:
          (json['reactions'] as List<dynamic>?)?.map((r) => ReactionModel.fromJson(r)).toList() ??
          [],
    );
  }

  MessageModel copyWith({
    int? id,
    String? sender,
    String? username,
    int? senderId,
    String? avatarUrl,
    String? message,
    String? attachmentUrl,
    DateTime? timestamp,
    int? recipientId,
    String? tempId,
    bool? isSending,
    String? mediaIv,
    Map<String, dynamic>? mediaKeys,
    String? attachmentType,
    List<ReactionModel>? reactions,
  }) {
    return MessageModel(
      id: id ?? this.id,
      sender: sender ?? this.sender,
      username: username ?? this.username,
      senderId: senderId ?? this.senderId,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      message: message ?? this.message,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      timestamp: timestamp ?? this.timestamp,
      reactions: reactions ?? this.reactions,
    );
  }

  @override
  String toString() {
    return 'MessageModel(id: $id, senderId: $senderId, recipientId: $recipientId)';
  }
}

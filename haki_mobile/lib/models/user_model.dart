import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';

/// Last message of a 1:1 chat as sent by `GET /users/friends` (content is still encrypted).
@Freezed(fromJson: false, toJson: false)
abstract class LastMessage with _$LastMessage {
  const factory LastMessage({
    required String content,
    required DateTime timestamp,
    required int senderId,
    String? attachmentType,
  }) = _LastMessage;

  factory LastMessage.fromJson(Map<String, dynamic> json) => LastMessage(
    content: json['content'] ?? '',
    timestamp: DateTime.parse(json['timestamp']),
    senderId: json['senderId'],
    attachmentType: json['attachmentType'],
  );
}

@Freezed(fromJson: false, toJson: false)
abstract class UserModel with _$UserModel {
  const UserModel._();

  const factory UserModel({
    required int id,
    required String username,
    String? email,
    String? displayName,
    String? bio,
    String? avatarUrl,
    String? publicKey,
    String? statusMessage,

    /// My own username, sealed to my key (only set on /users/me).
    String? handleSealed,

    /// 'MM-DD' if they chose to share it with friends.
    String? birthday,
    @Default(0) int unreadCount,
    LastMessage? lastMessage,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'],
    username: json['username'],
    email: json['email'],
    displayName: json['displayName'],
    bio: json['bio'],
    avatarUrl: json['avatarUrl'],
    publicKey: json['publicKey'],
    statusMessage: json['statusMessage'],
    handleSealed: json['handleSealed'],
    birthday: json['birthday'],
    unreadCount: json['unreadCount'] ?? 0,
    lastMessage: json['lastMessage'] != null ? LastMessage.fromJson(json['lastMessage']) : null,
  );

  /// 0 = today, 1 = tomorrow, … (null without a birthday). Feb 29 counts as Mar 1 in other years.
  int? daysToBirthday(DateTime now) {
    final b = birthday;
    if (b == null || !RegExp(r'^\d{2}-\d{2}$').hasMatch(b)) return null;
    final today = DateTime(now.year, now.month, now.day);
    var next = DateTime(now.year, int.parse(b.substring(0, 2)), int.parse(b.substring(3)));
    if (next.isBefore(today)) next = DateTime(now.year + 1, next.month, next.day);
    return next.difference(today).inDays;
  }

  String get name => (displayName?.isNotEmpty ?? false) ? displayName! : username;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}

import 'package:freezed_annotation/freezed_annotation.dart';

import 'user_model.dart';

part 'group_model.freezed.dart';

/// An encrypted group chat. Every message is wrapped for each member's key on the sender's phone.
@Freezed(fromJson: false, toJson: false)
abstract class GroupModel with _$GroupModel {
  const GroupModel._();

  const factory GroupModel({
    required int id,
    required String name,
    int? ownerId,
    @Default([]) List<UserModel> members,
    LastMessage? lastMessage,
    @Default(0) int unreadCount,
  }) = _GroupModel;

  factory GroupModel.fromJson(Map<String, dynamic> json) => GroupModel(
    id: json['id'],
    name: json['name'] ?? 'Group',
    ownerId: json['ownerId'],
    members: [for (final m in (json['members'] as List? ?? [])) UserModel.fromJson(Map<String, dynamic>.from(m))],
    lastMessage: json['lastMessage'] != null ? LastMessage.fromJson(Map<String, dynamic>.from(json['lastMessage'])) : null,
    unreadCount: json['unreadCount'] ?? 0,
  );

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '#';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  UserModel? member(int id) {
    for (final m in members) {
      if (m.id == id) return m;
    }
    return null;
  }
}

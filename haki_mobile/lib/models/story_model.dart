import 'package:freezed_annotation/freezed_annotation.dart';

import 'user_model.dart';

part 'story_model.freezed.dart';

@Freezed(fromJson: false, toJson: false)
abstract class StoryModel with _$StoryModel {
  const factory StoryModel({
    required int id,
    required int userId,
    required String content,
    required String type,
    required DateTime createdAt,
    required DateTime expiresAt,
    UserModel? user,
    @Default(false) bool seen,
    @Default(false) bool liked,

    /// Only on your own stories.
    int? viewCount,
    int? likeCount,
  }) = _StoryModel;

  factory StoryModel.fromJson(Map<String, dynamic> json) => StoryModel(
    id: json['id'],
    userId: json['userId'],
    content: json['content'],
    type: json['type'] ?? 'image',
    createdAt: DateTime.parse(json['createdAt']),
    expiresAt: DateTime.parse(json['expiresAt']),
    user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
    seen: json['seen'] ?? false,
    liked: json['liked'] ?? false,
    viewCount: json['viewCount'],
    likeCount: json['likeCount'],
  );
}

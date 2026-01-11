import 'user_model.dart';

class StoryModel {
  final int id;
  final int userId;
  final String content;
  final String type;
  final DateTime createdAt;
  final DateTime expiresAt;
  final UserModel? user;

  StoryModel({
    required this.id,
    required this.userId,
    required this.content,
    required this.type,
    required this.createdAt,
    required this.expiresAt,
    this.user,
  });

  factory StoryModel.fromJson(Map<String, dynamic> json) {
    return StoryModel(
      id: json['id'],
      userId: json['userId'],
      content: json['content'],
      type: json['type'] ?? 'image',
      createdAt: DateTime.parse(json['createdAt']),
      expiresAt: DateTime.parse(json['expiresAt']),
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
    );
  }
}

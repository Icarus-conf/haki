class ReactionModel {
  final int id;
  final String emoji;
  final int userId;
  final String username;

  ReactionModel({
    required this.id,
    required this.emoji,
    required this.userId,
    required this.username,
  });

  factory ReactionModel.fromJson(Map<String, dynamic> json) {
    return ReactionModel(
      id: json['id'] ?? 0,
      emoji: json['emoji'] ?? '',
      userId: json['userId'] ?? 0,
      username: json['username'] ?? 'Unknown',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'emoji': emoji, 'userId': userId, 'username': username};
  }
}

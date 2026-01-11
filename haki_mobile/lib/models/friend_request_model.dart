import 'user_model.dart';

class FriendRequestModel {
  final int id;
  final UserModel sender;
  final String status;
  final DateTime createdAt;

  FriendRequestModel({
    required this.id,
    required this.sender,
    required this.status,
    required this.createdAt,
  });

  factory FriendRequestModel.fromJson(Map<String, dynamic> json) {
    return FriendRequestModel(
      id: json['id'],
      sender: UserModel.fromJson(json['sender']),
      status: json['status'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

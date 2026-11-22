import 'package:freezed_annotation/freezed_annotation.dart';

import 'user_model.dart';

part 'friend_request_model.freezed.dart';

@Freezed(fromJson: false, toJson: false)
abstract class FriendRequestModel with _$FriendRequestModel {
  const factory FriendRequestModel({
    required int id,
    required UserModel sender,
    required String status,
    required DateTime createdAt,
  }) = _FriendRequestModel;

  factory FriendRequestModel.fromJson(Map<String, dynamic> json) => FriendRequestModel(
    id: json['id'],
    sender: UserModel.fromJson(json['sender']),
    status: json['status'],
    createdAt: DateTime.parse(json['createdAt']),
  );
}

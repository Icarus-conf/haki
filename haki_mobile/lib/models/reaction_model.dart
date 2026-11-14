import 'package:freezed_annotation/freezed_annotation.dart';

part 'reaction_model.freezed.dart';

@Freezed(fromJson: false, toJson: false)
abstract class ReactionModel with _$ReactionModel {
  const factory ReactionModel({
    required int id,
    required String emoji,
    required int userId,
    required String username,
  }) = _ReactionModel;

  factory ReactionModel.fromJson(Map<String, dynamic> json) => ReactionModel(
    id: json['id'] ?? 0,
    emoji: json['emoji'] ?? '',
    userId: json['userId'] ?? 0,
    username: json['username'] ?? 'Unknown',
  );
}

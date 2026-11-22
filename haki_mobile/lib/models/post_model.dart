import 'package:freezed_annotation/freezed_annotation.dart';

import 'user_model.dart';

part 'post_model.freezed.dart';

/// One sealed photo or video of a post. [url] is the encrypted file; [iv] opens it with the post key.
@freezed
abstract class PostMedia with _$PostMedia {
  const PostMedia._();

  const factory PostMedia({
    required String url,
    required String iv,
    @Default('image') String kind,
    @Default(1) double w,
    @Default(1) double h,
    int? dur,
  }) = _PostMedia;

  bool get isVideo => kind == 'video';
  double get aspect => h <= 0 ? 1 : w / h;

  Map<String, dynamic> toMeta() => {'iv': iv, 'kind': kind, 'w': w, 'h': h, 'dur': ?dur};
}

/// A friends-only post, already opened. [key] is this post's AES key (also opens comments).
@freezed
abstract class PostModel with _$PostModel {
  const PostModel._();

  const factory PostModel({
    required int id,
    required UserModel author,
    required String text,
    required List<PostMedia> media,
    required DateTime createdAt,
    required List<int> key,
    @Default(false) bool commentsOff,
    @Default(0) int commentCount,
    @Default({}) Map<String, int> reactions,
    String? myReaction,
  }) = _PostModel;

  int get reactionCount => reactions.values.fold(0, (a, b) => a + b);
  bool get hasPhoto => media.any((m) => !m.isVideo);
  bool get hasVideo => media.any((m) => m.isVideo);

  /// My reaction swapped for [emoji] (null = removed), counts kept in step.
  PostModel reacted(String? emoji) {
    final r = Map<String, int>.from(reactions);
    if (myReaction != null) {
      final n = (r[myReaction] ?? 1) - 1;
      n <= 0 ? r.remove(myReaction) : r[myReaction!] = n;
    }
    if (emoji != null) r[emoji] = (r[emoji] ?? 0) + 1;
    return copyWith(reactions: r, myReaction: emoji);
  }
}

@freezed
abstract class PostComment with _$PostComment {
  const factory PostComment({
    required int id,
    required UserModel author,
    required String text,
    required DateTime createdAt,
    int? parentId,
  }) = _PostComment;
}

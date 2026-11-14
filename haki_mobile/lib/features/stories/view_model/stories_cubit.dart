import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../models/story_model.dart';
import '../../../models/user_model.dart';
import '../../../services/api_service.dart';
import '../../../services/chat_service.dart';

part 'stories_cubit.freezed.dart';

@freezed
abstract class StoriesState with _$StoriesState {
  const StoriesState._();

  const factory StoriesState({
    @Default([]) List<StoryModel> stories,
    @Default(false) bool isPosting,
  }) = _StoriesState;

  /// Stories grouped per author, in the order they appear.
  Map<UserModel, List<StoryModel>> get byUser {
    final map = <int, List<StoryModel>>{};
    final users = <int, UserModel>{};
    for (final s in stories) {
      if (s.user == null) continue;
      (map[s.userId] ??= []).add(s);
      users[s.userId] = s.user!;
    }
    return {for (final id in map.keys) users[id]!: map[id]!};
  }
}

class StoriesCubit extends Cubit<StoriesState> {
  StoriesCubit({required this.api, required this.chat}) : super(const StoriesState()) {
    // A friend posted: refresh so their ring appears without pull-to-refresh
    _sub = chat.on('story_posted').listen((_) => load());
    // Someone loved my story: refresh the counts
    _likes = chat.on('story_liked').listen((_) => load());
  }

  final ApiService api;
  final ChatService chat;
  late final StreamSubscription _sub;
  late final StreamSubscription _likes;

  @override
  Future<void> close() async {
    await _sub.cancel();
    await _likes.cancel();
    return super.close();
  }

  Future<void> load() async {
    final data = await api.getActiveStories();
    if (!isClosed) emit(state.copyWith(stories: data.map((s) => StoryModel.fromJson(s)).toList()));
  }

  /// Marks it seen (once) so the ring dims and the owner's "seen by" updates.
  void markSeen(StoryModel story, int myId) {
    if (story.seen || story.userId == myId) return;
    _patch(story.id, (s) => s.copyWith(seen: true));
    api.markStorySeen(story.id);
  }

  Future<void> toggleLove(StoryModel story) async {
    final liked = !story.liked;
    _patch(story.id, (s) => s.copyWith(liked: liked, seen: true));
    if (!await api.likeStory(story.id, liked)) _patch(story.id, (s) => s.copyWith(liked: !liked));
  }

  void _patch(int id, StoryModel Function(StoryModel) f) =>
      emit(state.copyWith(stories: [for (final s in state.stories) s.id == id ? f(s) : s]));

  Future<bool> post(String filePath) async {
    emit(state.copyWith(isPosting: true));
    final res = await api.uploadStory(filePath);
    if (res != null) await load();
    emit(state.copyWith(isPosting: false));
    return res != null;
  }

  void clear() => emit(const StoriesState());
}

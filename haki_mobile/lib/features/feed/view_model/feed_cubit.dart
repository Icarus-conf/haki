import 'dart:async';
import 'dart:convert';

import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../models/post_model.dart';
import '../../../models/user_model.dart';
import '../../../services/api_service.dart';
import '../../../services/chat_service.dart';
import '../../../services/crypto_service.dart';

part 'feed_cubit.freezed.dart';

enum FeedFilter { all, photos, videos }

@freezed
abstract class FeedState with _$FeedState {
  const FeedState._();

  const factory FeedState({
    @Default([]) List<PostModel> posts,
    @Default(true) bool isLoading,
    @Default(true) bool hasMore,
    @Default(false) bool isPosting,
    @Default(FeedFilter.all) FeedFilter filter,
  }) = _FeedState;

  List<PostModel> get visible => switch (filter) {
    FeedFilter.all => posts,
    FeedFilter.photos => posts.where((p) => p.hasPhoto).toList(),
    FeedFilter.videos => posts.where((p) => p.hasVideo).toList(),
  };

  PostModel? byId(int id) => posts.where((p) => p.id == id).firstOrNull;
}

/// A photo or video picked for a new post, measured so the feed can lay it out before it loads.
typedef PickedMedia = ({XFile file, bool video, double w, double h, int? dur});

/// Friends' posts. Everything is sealed with a per-post key that only readers can unwrap.
class FeedCubit extends Cubit<FeedState> {
  FeedCubit({required this.api, required this.chat, required this.crypto}) : super(const FeedState());

  final ApiService api;
  final ChatService chat;
  final CryptoService crypto;
  UserModel? _me;
  final _subs = <StreamSubscription>[];

  /// Live comments for whoever has a post open.
  final _comments = StreamController<(int, PostComment)>.broadcast();
  Stream<(int, PostComment)> get comments => _comments.stream;

  void start(UserModel me) {
    _me = me;
    _subs.addAll([
      chat.on('post_created').listen((d) => _refreshOne(d['postId'] as int, prepend: true)),
      chat.on('post_deleted').listen((d) => _drop(d['postId'] as int)),
      chat.on('post_reacted').listen((d) => _refreshOne(d['postId'] as int)),
      chat.on('post_comment').listen(_onComment),
    ]);
    load();
  }

  void stop() {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
    _me = null;
    emit(const FeedState());
  }

  @override
  Future<void> close() async {
    stop();
    await _comments.close();
    return super.close();
  }

  void setFilter(FeedFilter f) => emit(state.copyWith(filter: f));

  Future<void> load() async {
    try {
      final rows = await api.feed();
      final posts = await _openAll(rows);
      if (!isClosed) {
        emit(state.copyWith(posts: posts, isLoading: false, hasMore: rows.length >= 20));
      }
    } catch (_) {
      if (!isClosed) emit(state.copyWith(isLoading: false));
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoading || state.posts.isEmpty) return;
    emit(state.copyWith(isLoading: true));
    try {
      final rows = await api.feed(before: state.posts.last.id);
      final more = await _openAll(rows);
      emit(state.copyWith(posts: [...state.posts, ...more], isLoading: false, hasMore: rows.length >= 20));
    } catch (_) {
      emit(state.copyWith(isLoading: false));
    }
  }

  // ===== Opening sealed posts =====
  final Map<int, List<int>> _keys = {};

  Future<List<PostModel>> _openAll(List<Map<String, dynamic>> rows) async => [
    for (final p in await Future.wait(rows.map(_open))) ?p,
  ];

  Future<PostModel?> _open(Map<String, dynamic> j) async {
    final me = _me;
    if (me == null) return null;
    final id = j['id'] as int;
    final key = _keys[id] ??= (await crypto.unwrapPostKey(j['key'] as String, me.username)) ?? const [];
    if (key.isEmpty) {
      return null; // not for this key (e.g. made before a key reset)
    }
    final clear = await crypto.openText(key, j['body'] as String);
    if (clear == null) return null;
    final body = jsonDecode(clear) as Map<String, dynamic>;
    final urls = List<String>.from(j['media'] ?? const []);
    final meta = List<Map<String, dynamic>>.from(body['media'] ?? const []);
    return PostModel(
      id: id,
      author: UserModel.fromJson(Map<String, dynamic>.from(j['author'])),
      text: (body['text'] ?? '') as String,
      media: [
        for (var i = 0; i < urls.length && i < meta.length; i++)
          PostMedia(
            url: urls[i],
            iv: meta[i]['iv'],
            kind: meta[i]['kind'] ?? 'image',
            w: (meta[i]['w'] as num?)?.toDouble() ?? 1,
            h: (meta[i]['h'] as num?)?.toDouble() ?? 1,
            dur: (meta[i]['dur'] as num?)?.toInt(),
          ),
      ],
      createdAt: DateTime.parse(j['createdAt']).toLocal(),
      key: key,
      commentsOff: j['commentsOff'] == true,
      commentCount: j['commentCount'] ?? 0,
      reactions: Map<String, int>.from(j['reactions'] ?? const {}),
      myReaction: j['myReaction'],
    );
  }

  Future<void> _refreshOne(int id, {bool prepend = false}) async {
    try {
      final p = await _open(await api.feedPost(id));
      if (p == null || isClosed) return;
      final exists = state.byId(id) != null;
      if (exists) {
        _patch(id, (_) => p);
      } else if (prepend) {
        emit(state.copyWith(posts: [p, ...state.posts]));
      }
    } catch (_) {}
  }

  void _drop(int id) => emit(state.copyWith(posts: state.posts.where((p) => p.id != id).toList()));

  void _patch(int id, PostModel Function(PostModel) f) =>
      emit(state.copyWith(posts: [for (final p in state.posts) p.id == id ? f(p) : p]));

  // ===== Writing =====

  /// Seals text and media with a new key, wraps it for [readers] and me, then posts.
  /// Returns null when posted, otherwise a message to show.
  Future<String?> post({
    required String text,
    required List<PickedMedia> media,
    required List<UserModel> readers,
    bool commentsOff = false,
  }) async {
    final me = _me;
    if (me == null || me.publicKey == null) {
      return 'Your keys are not ready yet';
    }
    emit(state.copyWith(isPosting: true));
    try {
      final pubs = {
        me.id.toString(): me.publicKey!,
        for (final f in readers)
          if (f.publicKey != null) f.id.toString(): f.publicKey!,
      };
      final (key, wrapped) = await crypto.newPostKey(pubs);
      final urls = <String>[];
      final meta = <Map<String, dynamic>>[];
      for (final m in media) {
        final (sealed, iv) = await crypto.sealBytes(key, await m.file.readAsBytes());
        final url = await api.uploadBytes(sealed, m.video ? 'post.mp4.enc' : 'post.jpg.enc');
        if (url == null) {
          throw ApiError('Upload failed. Check your connection.');
        }
        urls.add(url);
        meta.add(PostMedia(url: url, iv: iv, kind: m.video ? 'video' : 'image', w: m.w, h: m.h, dur: m.dur).toMeta());
      }
      final res = await api.createPost({
        'body': await crypto.sealText(key, jsonEncode({'text': text.trim(), 'media': meta})),
        'media': urls,
        'keys': wrapped,
        'commentsOff': commentsOff,
      });
      final p = await _open(res);
      emit(state.copyWith(isPosting: false, posts: [?p, ...state.posts]));
      return null;
    } on ApiError catch (e) {
      emit(state.copyWith(isPosting: false));
      return e.message;
    } catch (e) {
      debugPrint('Feed: post failed $e');
      emit(state.copyWith(isPosting: false));
      return 'Couldn\'t post. Try again.';
    }
  }

  Future<void> delete(PostModel p) async {
    _drop(p.id);
    try {
      await api.deletePost(p.id);
    } catch (_) {
      load();
    }
  }

  /// Same emoji again = take it back.
  Future<void> react(PostModel p, String emoji) async {
    final next = p.myReaction == emoji ? null : emoji;
    _patch(p.id, (x) => x.reacted(next));
    try {
      await api.reactToPost(p.id, next);
    } catch (_) {
      _patch(p.id, (_) => p);
    }
  }

  // ===== Comments =====
  Future<PostComment?> _openComment(List<int> key, Map<String, dynamic> c) async {
    final text = await crypto.openText(key, c['body'] as String);
    if (text == null) return null;
    return PostComment(
      id: c['id'],
      parentId: c['parentId'],
      author: UserModel.fromJson(Map<String, dynamic>.from(c['author'])),
      text: text,
      createdAt: DateTime.parse(c['createdAt']).toLocal(),
    );
  }

  Future<List<PostComment>> loadComments(PostModel p) async {
    final rows = await api.postComments(p.id);
    return [for (final c in await Future.wait(rows.map((c) => _openComment(p.key, c)))) ?c];
  }

  Future<PostComment?> addComment(PostModel p, String text, {int? parentId}) async {
    final res = await api.addPostComment(p.id, await crypto.sealText(p.key, text.trim()), parentId: parentId);
    _patch(p.id, (x) => x.copyWith(commentCount: x.commentCount + 1));
    return _openComment(p.key, res);
  }

  Future<void> deleteComment(PostModel p, PostComment c) async {
    await api.deletePostComment(p.id, c.id);
    _patch(p.id, (x) => x.copyWith(commentCount: (x.commentCount - 1).clamp(0, 1 << 30)));
  }

  Future<void> _onComment(dynamic d) async {
    final id = d['postId'] as int;
    final p = state.byId(id);
    if (p == null) return;
    _patch(id, (x) => x.copyWith(commentCount: x.commentCount + 1));
    final c = await _openComment(p.key, Map<String, dynamic>.from(d));
    if (c != null && !_comments.isClosed) _comments.add((id, c));
  }
}

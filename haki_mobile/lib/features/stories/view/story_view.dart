import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/haki_theme.dart';
import '../../../core/widgets/glass.dart';
import '../../../models/message_envelope.dart';
import '../../../models/post_model.dart';
import '../../../models/story_model.dart';
import '../../../models/user_model.dart';
import '../../../services/api_service.dart';
import '../../../services/chat_service.dart';
import '../../../services/crypto_service.dart';
import '../../../services/message_sender.dart';
import '../../../widgets/loading_indicator.dart';
import '../../feed/view/sealed_media.dart';
import '../../friends/view_model/friends_cubit.dart';
import '../../session/view_model/session_cubit.dart';
import '../view_model/stories_cubit.dart';
import 'package:chat_mobile/core/theme/haki_icons.dart';

class StoryView extends StatefulWidget {
  final UserModel user;
  final List<StoryModel> stories;

  const StoryView({super.key, required this.user, required this.stories});

  @override
  State<StoryView> createState() => _StoryViewState();
}

class _StoryViewState extends State<StoryView> {
  int _currentIndex = 0;
  double _progress = 0.0;
  Timer? _timer;
  bool _closing = false;
  bool _paused = false;
  final _reply = TextEditingController();
  final _replyFocus = FocusNode();

  late final UserModel _me = context.read<SessionCubit>().state.me!;

  /// Each story's AES key, unwrapped once with my private key.
  final _keys = <int, Future<List<int>?>>{};
  Future<List<int>?> _keyOf(StoryModel s) => _keys[s.id] ??= s.key == null || s.iv == null
      ? Future.value(null)
      : context.read<CryptoService>().unwrapPostKey(s.key!, _me.username);
  bool get _mine => widget.user.id == _me.id;

  @override
  void initState() {
    super.initState();
    // Stop the clock while typing a reply, so the story doesn't move on mid-sentence
    _replyFocus.addListener(() => setState(() => _paused = _replyFocus.hasFocus));
    _startTimer();
  }

  /// Live copy from the cubit, so loves and counts update while it is open.
  StoryModel get _story {
    final id = widget.stories[_currentIndex].id;
    final live = context.read<StoriesCubit>().state.stories.where((s) => s.id == id);
    return live.isEmpty ? widget.stories[_currentIndex] : live.first;
  }

  void _startTimer() {
    _timer?.cancel();
    _progress = 0.0;
    context.read<StoriesCubit>().markSeen(widget.stories[_currentIndex], _me.id);
    _timer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!mounted || _closing || _paused) return;
      if (_progress < 1.0) {
        setState(() => _progress += 0.01);
      } else {
        // Advance outside setState. The old code navigated from inside setState and never
        // stopped the timer, so it kept popping every 50ms: story, then Home, then an
        // empty navigator (black screen / "_debugLocked" red screen).
        _nextStory();
      }
    });
  }

  void _nextStory() {
    if (_closing) return;
    if (_currentIndex < widget.stories.length - 1) {
      setState(() => _currentIndex++);
      _startTimer();
    } else {
      _close();
    }
  }

  void _close() {
    if (_closing) return;
    _closing = true;
    _timer?.cancel();
    Navigator.of(context).maybePop();
  }

  void _previousStory() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
      _startTimer();
    }
  }

  Future<void> _sendReply() async {
    final text = _reply.text.trim();
    if (text.isEmpty) return;
    final story = _story;
    final owner = context.read<FriendsCubit>().state.byId(story.userId) ?? widget.user;
    final sender = MessageSender(
      api: context.read<ApiService>(),
      chat: context.read<ChatService>(),
      crypto: context.read<CryptoService>(),
    );
    _reply.clear();
    _replyFocus.unfocus();
    try {
      // An ordinary encrypted message to the owner, carrying which story it answers
      await sender.send(
        to: (user: owner, group: null),
        me: _me,
        text: text,
        tempId: DateTime.now().microsecondsSinceEpoch.toString(),
        story: StoryRef(id: story.id, url: story.content),
      );
      if (mounted) showHakiToast(context, 'Reply sent to ${owner.name}');
    } catch (e) {
      if (mounted) showHakiToast(context, e.toString().replaceFirst('Exception: ', ''), isError: true);
    }
  }

  Future<void> _showViewers() async {
    setState(() => _paused = true);
    final story = _story;
    await showModalBottomSheet(
      context: context,
      builder: (sheet) => SafeArea(
        child: FutureBuilder(
          future: context.read<ApiService>().storyViewers(story.id),
          builder: (context, snap) {
            final viewers = snap.data ?? const [];
            return ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: 12),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Text('Seen by ${viewers.length}', style: HakiText.display(26)),
                ),
                if (snap.connectionState != ConnectionState.done)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                else if (viewers.isEmpty)
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 4, 20, 20),
                    child: Text(
                      'No one yet. Friends who view it show up here.',
                      style: TextStyle(color: HakiColors.textMuted),
                    ),
                  ),
                for (final v in viewers)
                  ListTile(
                    leading: AuraAvatar(user: v.user, size: 40, radius: 14),
                    title: Text(v.user.name),
                    trailing: v.liked
                        ? const Icon(HakiIcons.heartFill, color: HakiColors.pink, semanticLabel: 'Loved it')
                        : null,
                  ),
              ],
            );
          },
        ),
      ),
    );
    if (mounted) setState(() => _paused = false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _reply.dispose();
    _replyFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<StoriesCubit>(); // rebuild on love / counts
    final story = _story;

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          GestureDetector(
            onTapDown: (details) {
              if (_replyFocus.hasFocus) return _replyFocus.unfocus();
              final x = details.globalPosition.dx;
              final width = MediaQuery.of(context).size.width;
              if (x < width / 3) {
                _previousStory();
              } else {
                _nextStory();
              }
            },
            onDoubleTap: _mine ? null : () => context.read<StoriesCubit>().toggleLove(story),
            child: Center(
              child: FutureBuilder(
                future: _keyOf(story),
                builder: (context, snap) {
                  final key = snap.data;
                  if (snap.connectionState != ConnectionState.done) return const LoadingIndicator(size: 40);
                  if (key == null) return const Icon(HakiIcons.lock, color: Colors.white54);
                  // Same download-and-open cache as feed photos; keyed so each story gets a fresh tile
                  return SealedMediaTile(
                    key: ValueKey(story.id),
                    media: PostMedia(url: story.content, iv: story.iv!),
                    postKey: key,
                    fit: BoxFit.contain,
                  );
                },
              ),
            ),
          ),

          // Top Progress Bars
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Row(
                children: List.generate(widget.stories.length, (index) {
                  return Expanded(
                    child: Container(
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: index < _currentIndex ? 1.0 : 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: index == _currentIndex
                          ? LinearProgressIndicator(
                              value: _progress,
                              backgroundColor: Colors.transparent,
                              valueColor: const AlwaysStoppedAnimation(Colors.white),
                            )
                          : const SizedBox.shrink(),
                    ),
                  );
                }),
              ),
            ),
          ),

          // Top Header (User Info)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 30, 16, 0),
              child: Row(
                children: [
                  // AuraAvatar: no third-party avatar service (DiceBear got every username)
                  AuraAvatar(user: widget.user, size: 40, radius: 14),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _mine ? 'Your story' : widget.user.name,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(_getTimeAgo(story.createdAt), style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    icon: const Icon(HakiIcons.x, color: Colors.white, size: 30),
                    onPressed: _close,
                  ),
                ],
              ),
            ),
          ),

          // Bottom: reply + love for friends' stories; who saw it for your own
          Positioned(
            left: 12,
            right: 12,
            bottom: 0,
            child: SafeArea(
              top: false,
              minimum: const EdgeInsets.only(bottom: 12),
              child: _mine
                  ? Center(
                      child: GestureDetector(
                        onTap: _showViewers,
                        child: Glass(
                          radius: 22,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(HakiIcons.eye, size: 18),
                              const SizedBox(width: 6),
                              Text('Seen by ${story.viewCount ?? 0}'),
                              if ((story.likeCount ?? 0) > 0) ...[
                                const SizedBox(width: 14),
                                const Icon(HakiIcons.heartFill, size: 18, color: HakiColors.pink),
                                const SizedBox(width: 4),
                                Text('${story.likeCount}'),
                              ],
                              const SizedBox(width: 4),
                              const Icon(HakiIcons.caretUp, size: 18),
                            ],
                          ),
                        ),
                      ),
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: Glass(
                            radius: 26,
                            padding: const EdgeInsets.only(left: 18, right: 6),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _reply,
                                    focusNode: _replyFocus,
                                    textCapitalization: TextCapitalization.sentences,
                                    onSubmitted: (_) => _sendReply(),
                                    textInputAction: TextInputAction.send,
                                    decoration: InputDecoration(
                                      hintText: 'Reply to ${widget.user.name.split(' ').first}…',
                                      filled: false,
                                      border: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                    ),
                                  ),
                                ),
                                ValueListenableBuilder(
                                  valueListenable: _reply,
                                  builder: (context, v, _) => v.text.trim().isEmpty
                                      ? const SizedBox(width: 8)
                                      : IconButton(
                                          tooltip: 'Send reply',
                                          onPressed: _sendReply,
                                          icon: const Icon(HakiIcons.arrowUp, color: HakiColors.lime),
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GlassIconButton(
                          icon: story.liked ? HakiIcons.heartFill : HakiIcons.heart,
                          tooltip: story.liked ? 'Unlove' : 'Love this story',
                          color: story.liked ? HakiColors.pink : null,
                          size: 52,
                          onPressed: () => context.read<StoriesCubit>().toggleLove(story),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}

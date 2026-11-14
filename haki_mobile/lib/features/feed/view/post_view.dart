import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/haki_theme.dart';
import '../../../core/utils/format.dart';
import '../../../core/utils/platform.dart';
import '../../../core/widgets/glass.dart';
import '../../../models/post_model.dart';
import '../../session/view_model/session_cubit.dart';
import '../view_model/feed_cubit.dart';
import 'feed_view.dart';
import 'package:chat_mobile/core/theme/haki_icons.dart';

/// A post with its reactions and comments (one level of replies, like Threads).
class PostView extends StatefulWidget {
  const PostView({super.key, required this.postId, this.focusComment = false});
  final int postId;
  final bool focusComment;

  static const route = '/post';

  static Future<void> open(BuildContext context, int postId, {bool focusComment = false}) => Navigator.push(
    context,
    MaterialPageRoute(
      settings: const RouteSettings(name: route),
      builder: (_) => PostView(postId: postId, focusComment: focusComment),
    ),
  );

  @override
  State<PostView> createState() => _PostViewState();
}

class _PostViewState extends State<PostView> {
  final _input = TextEditingController();
  final _focus = FocusNode();
  List<PostComment>? _comments;
  PostComment? _replyTo;
  bool _sending = false;
  StreamSubscription? _live;

  FeedCubit get _cubit => context.read<FeedCubit>();
  PostModel? get _post => _cubit.state.byId(widget.postId);

  @override
  void initState() {
    super.initState();
    _load();
    _live = _cubit.comments.where((e) => e.$1 == widget.postId).listen((e) {
      if (mounted && !(_comments?.any((c) => c.id == e.$2.id) ?? false)) {
        setState(() => _comments = [...?_comments, e.$2]);
      }
    });
    if (widget.focusComment) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
    }
  }

  @override
  void dispose() {
    _live?.cancel();
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final p = _post;
    if (p == null) return;
    try {
      final list = await _cubit.loadComments(p);
      if (mounted) setState(() => _comments = list);
    } catch (_) {
      if (mounted) setState(() => _comments = const []);
    }
  }

  Future<void> _send() async {
    final p = _post;
    final text = _input.text.trim();
    if (p == null || text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final c = await _cubit.addComment(p, text, parentId: _replyTo?.id);
      _input.clear();
      if (c != null && mounted) {
        setState(() {
          _comments = [...?_comments, c];
          _replyTo = null;
        });
      }
    } catch (e) {
      if (mounted) showHakiToast(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _commentMenu(PostComment c, bool canDelete) async {
    HapticFeedback.selectionClick();
    final p = _post;
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: HakiColors.surfaceHigh,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (p != null && !p.commentsOff)
              ListTile(
                leading: const Icon(HakiIcons.arrowBendUpLeft),
                title: const Text('Reply'),
                onTap: () => Navigator.pop(ctx, 'reply'),
              ),
            ListTile(
              leading: const Icon(HakiIcons.copy),
              title: const Text('Copy'),
              onTap: () => Navigator.pop(ctx, 'copy'),
            ),
            if (canDelete)
              ListTile(
                leading: const Icon(HakiIcons.trash, color: HakiColors.dangerText),
                title: const Text('Delete comment', style: TextStyle(color: HakiColors.dangerText)),
                onTap: () => Navigator.pop(ctx, 'delete'),
              ),
          ],
        ),
      ),
    );
    if (!mounted || p == null) return;
    switch (action) {
      case 'reply':
        _reply(c);
      case 'copy':
        Clipboard.setData(ClipboardData(text: c.text));
        showHakiToast(context, 'Copied');
      case 'delete':
        try {
          await _cubit.deleteComment(p, c);
          if (mounted) {
            setState(() => _comments = _comments?.where((x) => x.id != c.id && x.parentId != c.id).toList());
          }
        } catch (e) {
          if (mounted) showHakiToast(context, e.toString(), isError: true);
        }
    }
  }

  void _reply(PostComment c) {
    setState(() => _replyTo = c);
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final meId = context.select((SessionCubit c) => c.state.me?.id);
    return BlocBuilder<FeedCubit, FeedState>(
      buildWhen: (a, b) => a.byId(widget.postId) != b.byId(widget.postId),
      builder: (context, s) {
        final post = s.byId(widget.postId);
        if (post == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(
              child: Text('This post was deleted', style: TextStyle(color: HakiColors.textMuted)),
            ),
          );
        }
        final top = (_comments ?? const <PostComment>[]).where((c) => c.parentId == null).toList();
        return Scaffold(
          appBar: AppBar(
            title: const Text('Post'),
            backgroundColor: HakiColors.ink,
            surfaceTintColor: Colors.transparent,
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
                      children: [
                        PostCard(post: post, inDetail: true),
                        if (post.reactions.isNotEmpty) _ReactionChips(post: post),
                        const SizedBox(height: 14),
                        if (!post.commentsOff || (_comments?.isNotEmpty ?? false))
                          Padding(
                            padding: const EdgeInsets.fromLTRB(6, 0, 6, 10),
                            child: Text(switch (_comments?.length) {
                              null => 'Comments',
                              0 => 'No comments yet',
                              1 => '1 comment',
                              final n => '$n comments',
                            }, style: const TextStyle(color: HakiColors.textMuted, fontWeight: FontWeight.w600)),
                          ),
                        if (_comments == null)
                          const Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          ),
                        for (final c in top) ...[
                          _CommentRow(
                            comment: c,
                            onReply: post.commentsOff ? null : () => _reply(c),
                            onMenu: () => _commentMenu(c, c.author.id == meId || post.author.id == meId),
                          ),
                          for (final r in _comments!.where((x) => x.parentId == c.id))
                            Padding(
                              padding: const EdgeInsets.only(left: 44),
                              child: _CommentRow(
                                comment: r,
                                small: true,
                                onReply: post.commentsOff ? null : () => _reply(c),
                                onMenu: () => _commentMenu(r, r.author.id == meId || post.author.id == meId),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                  if (!post.commentsOff) _composer(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _composer() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_replyTo != null)
              Padding(
                padding: const EdgeInsets.only(left: 14, bottom: 6),
                child: Row(
                  children: [
                    const Icon(HakiIcons.arrowBendUpLeft, size: 15, color: HakiColors.textMuted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Replying to ${_replyTo!.author.name}',
                        style: const TextStyle(fontSize: 13, color: HakiColors.textMuted),
                      ),
                    ),
                    InkWell(
                      onTap: () => setState(() => _replyTo = null),
                      child: const Icon(HakiIcons.x, size: 18, color: HakiColors.textMuted),
                    ),
                  ],
                ),
              ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 4, 5, 4),
              decoration: BoxDecoration(color: HakiColors.surfaceHigh, borderRadius: BorderRadius.circular(28)),
              child: Row(
                children: [
                  Expanded(
                    child: CallbackShortcuts(
                      bindings: {if (Device.pointer) const SingleActivator(LogicalKeyboardKey.enter): _send},
                      child: TextField(
                        controller: _input,
                        focusNode: _focus,
                        minLines: 1,
                        maxLines: 5,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: _replyTo == null ? 'Write a comment' : 'Write a reply',
                          border: InputBorder.none,
                          filled: false,
                          isDense: true,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  ValueListenableBuilder(
                    valueListenable: _input,
                    builder: (_, v, _) => IconButton.filled(
                      tooltip: 'Send',
                      onPressed: v.text.trim().isEmpty || _sending ? null : _send,
                      style: IconButton.styleFrom(
                        backgroundColor: HakiColors.lime,
                        foregroundColor: HakiColors.onLime,
                        disabledBackgroundColor: Colors.white.withValues(alpha: 0.08),
                      ),
                      icon: _sending
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(HakiIcons.arrowUp),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReactionChips extends StatelessWidget {
  const _ReactionChips({required this.post});
  final PostModel post;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<FeedCubit>();
    final sorted = post.reactions.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 10, 4, 0),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final e in sorted)
            InkWell(
              borderRadius: BorderRadius.circular(99),
              onTap: () => cubit.react(post, e.key),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: post.myReaction == e.key ? HakiColors.lime.withValues(alpha: 0.16) : HakiColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                    color: post.myReaction == e.key ? HakiColors.lime.withValues(alpha: 0.6) : Colors.transparent,
                  ),
                ),
                child: Text('${e.key} ${e.value}', style: const TextStyle(fontSize: 13)),
              ),
            ),
          InkWell(
            borderRadius: BorderRadius.circular(99),
            onTap: () => pickReaction(context, post),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: HakiColors.surfaceHigh, borderRadius: BorderRadius.circular(99)),
              child: const Icon(HakiIcons.smileySticker, size: 17, color: HakiColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentRow extends StatelessWidget {
  const _CommentRow({required this.comment, required this.onMenu, this.onReply, this.small = false});
  final PostComment comment;
  final VoidCallback onMenu;
  final VoidCallback? onReply;
  final bool small;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AuraAvatar(user: comment.author, size: small ? 28 : 34, radius: small ? 10 : 12),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onLongPress: onMenu,
                  onSecondaryTap: onMenu,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 9),
                    decoration: BoxDecoration(
                      color: HakiColors.incomingBubble,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(comment.author.name, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(comment.text, style: const TextStyle(fontSize: 14.5, height: 1.35)),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 12, top: 3),
                  child: Row(
                    children: [
                      Text(
                        relativeTime(comment.createdAt),
                        style: const TextStyle(fontSize: 12, color: HakiColors.textMuted),
                      ),
                      if (onReply != null) ...[
                        const SizedBox(width: 14),
                        GestureDetector(
                          onTap: onReply,
                          child: const Text(
                            'Reply',
                            style: TextStyle(fontSize: 12, color: HakiColors.textMuted, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

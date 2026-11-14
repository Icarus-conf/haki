import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/haki_theme.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/glass.dart';
import '../../../models/post_model.dart';
import '../../session/view_model/session_cubit.dart';
import '../view_model/feed_cubit.dart';
import 'compose_post_view.dart';
import 'post_view.dart';
import 'sealed_media.dart';
import 'package:chat_mobile/core/theme/haki_icons.dart';

/// Friends' posts, newest first. Only friends you shared with can open them.
class FeedTab extends StatefulWidget {
  const FeedTab({super.key});

  @override
  State<FeedTab> createState() => _FeedTabState();
}

class _FeedTabState extends State<FeedTab> {
  @override
  Widget build(BuildContext context) {
    final cubit = context.read<FeedCubit>();
    return BlocBuilder<FeedCubit, FeedState>(
      builder: (context, s) {
        final posts = s.visible;
        return Stack(
          children: [
            const AuroraBackground(height: 380, colors: [HakiColors.teal, HakiColors.blue, HakiColors.violet]),
            SafeArea(
              bottom: false,
              child: NotificationListener<ScrollNotification>(
                onNotification: (n) {
                  if (n.metrics.extentAfter < 600) cubit.loadMore();
                  return false;
                },
                child: RefreshIndicator(
                  onRefresh: cubit.load,
                  color: HakiColors.lime,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 640),
                      child: CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                            sliver: SliverToBoxAdapter(child: _Header(state: s)),
                          ),
                          if (s.isLoading && s.posts.isEmpty)
                            const SliverFillRemaining(
                              hasScrollBody: false,
                              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            )
                          else if (posts.isEmpty)
                            SliverFillRemaining(hasScrollBody: false, child: _Empty(filtered: s.posts.isNotEmpty))
                          else
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(12, 0, 12, 140),
                              sliver: SliverList.separated(
                                itemCount: posts.length,
                                separatorBuilder: (_, _) => const SizedBox(height: 10),
                                itemBuilder: (context, i) => PostCard(key: ValueKey(posts[i].id), post: posts[i]),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.state});
  final FeedState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<FeedCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('Feed', style: HakiText.display(46))),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(HakiIcons.lockFill, size: 13, color: HakiColors.textMuted),
            const SizedBox(width: 5),
            Text(
              'Only friends you share with can see posts',
              style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.7)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          children: [
            for (final (f, label) in [
              (FeedFilter.all, 'Everything'),
              (FeedFilter.photos, 'Photos'),
              (FeedFilter.videos, 'Videos'),
            ])
              ChoiceChip(
                label: Text(label),
                selected: state.filter == f,
                onSelected: (_) => cubit.setFilter(f),
                showCheckmark: false,
                selectedColor: HakiColors.lime,
                backgroundColor: HakiColors.surfaceHigh,
                side: BorderSide.none,
                shape: const StadiumBorder(),
                labelStyle: TextStyle(
                  color: state.filter == f ? HakiColors.onLime : HakiColors.text,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.filtered});
  final bool filtered;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 140),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Glass(
            radius: 28,
            padding: const EdgeInsets.all(20),
            child: Icon(
              filtered ? HakiIcons.funnelX : HakiIcons.squaresFourFill,
              size: 38,
              color: HakiColors.lime,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            filtered ? 'Nothing here with this filter' : 'Share something with your friends',
            textAlign: TextAlign.center,
            style: HakiText.display(24),
          ),
          const SizedBox(height: 8),
          Text(
            filtered
                ? 'Try Everything to see all posts.'
                : 'Posts, photos and videos here are end-to-end encrypted. Only the friends you pick can open them.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, height: 1.4, color: Colors.white.withValues(alpha: 0.7)),
          ),
          if (!filtered) ...[
            const SizedBox(height: 20),
            LimeButton(label: 'New post', icon: HakiIcons.plus, onPressed: () => ComposePostView.open(context)),
          ],
        ],
      ),
    );
  }
}

const reactionChoices = ['❤️', '🔥', '😂', '😍', '😮', '😢', '👏'];

/// One post: avatar beside the name and text, media running to the card's edge, then actions.
class PostCard extends StatelessWidget {
  const PostCard({super.key, required this.post, this.inDetail = false});
  final PostModel post;
  final bool inDetail;

  static const _avatar = 40.0;
  static const _inset = 12 + _avatar + 10; // card padding + avatar + gap: text column's left edge

  @override
  Widget build(BuildContext context) {
    final mine = context.select((SessionCubit c) => c.state.me?.id) == post.author.id;
    final body = Container(
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.fromLTRB(12, 12, 0, 6),
      decoration: BoxDecoration(
        color: HakiColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AuraAvatar(user: post.author, size: _avatar, radius: 14),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Name shrinks first; the menu always sits at the right edge
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  post.author.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                                ),
                              ),
                              Text(
                                '  ·  ${relativeTime(post.createdAt)}',
                                style: const TextStyle(color: HakiColors.textMuted, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        _Menu(post: post, mine: mine),
                      ],
                    ),
                    if (post.text.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(right: 14, bottom: 2),
                        child: Text(
                          post.text,
                          maxLines: inDetail ? null : 8,
                          overflow: inDetail ? null : TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 15.5, height: 1.4),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (post.media.isNotEmpty) ...[
            const SizedBox(height: 10),
            Padding(
              padding: EdgeInsets.only(right: post.media.length > 2 ? 0 : 14),
              child: MediaStrip(post: post, leftInset: _inset - 12, heroScope: inDetail ? 'post' : 'feed'),
            ),
          ],
          Padding(
            padding: const EdgeInsets.only(left: _inset - 12 - 8),
            child: _Actions(post: post, inDetail: inDetail),
          ),
        ],
      ),
    );
    if (inDetail) return body;
    return GestureDetector(onTap: () => PostView.open(context, post.id), child: body);
  }
}

class _Menu extends StatelessWidget {
  const _Menu({required this.post, required this.mine});
  final PostModel post;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 28,
      child: PopupMenuButton<String>(
        tooltip: 'More',
        padding: EdgeInsets.zero,
        icon: const Icon(HakiIcons.dotsThree, size: 20, color: HakiColors.textMuted),
        color: HakiColors.surfaceHigh,
        onSelected: (v) async {
          if (v == 'copy') {
            Clipboard.setData(ClipboardData(text: post.text));
            showHakiToast(context, 'Copied');
          } else if (v == 'delete') {
            final cubit = context.read<FeedCubit>();
            final nav = Navigator.of(context);
            final inPost = ModalRoute.of(context)?.settings.name == PostView.route;
            final ok = await confirmAction(
              context,
              title: 'Delete post?',
              message: 'It disappears for everyone, with its comments, photos and videos.',
              action: 'Delete',
            );
            if (!ok) return;
            cubit.delete(post);
            if (inPost) {
              nav.pop();
            }
          }
        },
        itemBuilder: (_) => [
          if (post.text.isNotEmpty) const PopupMenuItem(value: 'copy', child: Text('Copy text')),
          if (mine)
            const PopupMenuItem(
              value: 'delete',
              child: Text('Delete post', style: TextStyle(color: HakiColors.dangerText)),
            ),
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.post, required this.inDetail});
  final PostModel post;
  final bool inDetail;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<FeedCubit>();
    final r = post.myReaction;
    final count = post.reactionCount;
    final muted = Colors.white.withValues(alpha: 0.7);
    return Row(
      children: [
        Semantics(
          button: true,
          label: r == null ? 'Love' : 'Remove reaction',
          hint: 'Long press for more reactions',
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              HapticFeedback.selectionClick();
              cubit.react(post, r ?? '❤️');
            },
            onLongPress: () => pickReaction(context, post),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  if (r == null)
                    Icon(HakiIcons.heart, size: 20, color: muted)
                  else if (r == '❤️')
                    const Icon(HakiIcons.heartFill, size: 20, color: HakiColors.lime)
                  else
                    Text(r, style: const TextStyle(fontSize: 17)),
                  if (count > 0) ...[
                    const SizedBox(width: 5),
                    Text('$count', style: TextStyle(fontSize: 13, color: r != null ? HakiColors.lime : muted)),
                  ],
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        if (!post.commentsOff)
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: inDetail ? null : () => PostView.open(context, post.id, focusComment: true),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Icon(HakiIcons.chatCircle, size: 19, color: muted),
                  if (post.commentCount > 0) ...[
                    const SizedBox(width: 5),
                    Text('${post.commentCount}', style: TextStyle(fontSize: 13, color: muted)),
                  ],
                ],
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Icon(HakiIcons.chatCircleSlash, size: 18, color: HakiColors.textMuted.withValues(alpha: 0.8)),
                const SizedBox(width: 5),
                const Text('Comments off', style: TextStyle(fontSize: 12, color: HakiColors.textMuted)),
              ],
            ),
          ),
      ],
    );
  }
}

/// Long-press on the heart: pick another reaction.
Future<void> pickReaction(BuildContext context, PostModel post) async {
  HapticFeedback.mediumImpact();
  final cubit = context.read<FeedCubit>();
  final emoji = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: HakiColors.surfaceHigh,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (final e in reactionChoices)
              InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => Navigator.pop(ctx, e),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: post.myReaction == e ? Colors.white.withValues(alpha: 0.14) : null,
                    shape: BoxShape.circle,
                  ),
                  child: Text(e, style: const TextStyle(fontSize: 30)),
                ),
              ),
          ],
        ),
      ),
    ),
  );
  if (emoji != null) cubit.react(post, emoji);
}

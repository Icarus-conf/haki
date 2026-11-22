import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/haki_theme.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/glass.dart';
import '../../../models/group_model.dart';
import '../../../models/user_model.dart';
import '../../../services/chat_lock.dart';
import '../../../services/message_sender.dart';
import '../../groups/view/group_avatar.dart';
import '../../groups/view/pick_friends_view.dart';
import '../../stories/view/story_view.dart';
import '../../friends/view_model/friends_cubit.dart';
import '../../session/view_model/session_cubit.dart';
import '../../settings/view_model/settings_cubit.dart';
import '../../stories/view_model/stories_cubit.dart';
import 'add_friend_sheet.dart';
import 'package:chat_mobile/core/theme/haki_icons.dart';

class ChatsTab extends StatefulWidget {
  const ChatsTab({super.key, required this.onOpenChat, required this.onOpenProfile});

  final ValueChanged<ChatTarget> onOpenChat;
  final VoidCallback onOpenProfile;

  @override
  State<ChatsTab> createState() => _ChatsTabState();
}

class _ChatsTabState extends State<ChatsTab> {
  final _search = TextEditingController();
  String _query = '';

  /// 'all', 'unread', 'groups', or a folder name prefixed with 'f:'.
  String _filter = 'all';

  /// Locked chats are shown (instead of the others) after Face ID, until the app leaves the screen.
  bool _showLocked = false;
  late final _lifecycle = AppLifecycleListener(
    onHide: () {
      if (_showLocked && mounted) setState(() => _showLocked = false);
    },
  );

  @override
  void initState() {
    super.initState();
    _lifecycle; // start listening
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _search.dispose();
    super.dispose();
  }

  Future<void> _revealLocked() async {
    if (await ChatLock.unlock('Show your locked chats') && mounted) setState(() => _showLocked = true);
  }

  static String _key(Object o) => o is GroupModel ? ChatFolder.groupKey(o.id) : ChatFolder.userKey((o as UserModel).id);

  void _open(UserModel? friend) {
    if (friend != null) context.read<FriendsCubit>().openChat(friend.id);
    widget.onOpenChat((user: friend, group: null));
  }

  void _openGroup(GroupModel g) => widget.onOpenChat((user: null, group: g));

  Future<void> _newGroup() async {
    final g = await PickFriendsView.newGroup(context);
    if (g != null && mounted) _openGroup(g);
  }

  @override
  Widget build(BuildContext context) {
    final me = context.select((SessionCubit c) => c.state.me)!;
    final friendsState = context.watch<FriendsCubit>().state;
    final pinnedIds = context.select((SettingsCubit c) => c.state.pinnedIds);
    final folders = context.select((SettingsCubit c) => c.state.folders);
    final locked = context.select((SettingsCubit c) => c.state.lockedChats);
    if (locked.isEmpty) _showLocked = false;
    // Locked chats never show in the normal list or search; after Face ID they show alone
    bool lockOk(Object o) => locked.contains(_key(o)) == _showLocked;
    final folder = _filter.startsWith('f:') ? folders.where((f) => f.name == _filter.substring(2)).firstOrNull : null;
    if (_filter.startsWith('f:') && folder == null) _filter = 'all'; // folder was deleted
    final q = _query.toLowerCase();
    final matches = friendsState.friends
        .where(lockOk)
        .where((f) => q.isEmpty || f.name.toLowerCase().contains(q) || f.username.toLowerCase().contains(q))
        .toList();
    final pinned = q.isEmpty && _filter == 'all' && !_showLocked
        ? matches.where((f) => pinnedIds.contains(f.id)).toList()
        : <UserModel>[];
    final rest = matches.where((f) => !pinned.contains(f)).toList();
    final groups = friendsState.groups
        .where(lockOk)
        .where((g) => q.isEmpty || g.name.toLowerCase().contains(q))
        .toList();
    // Friends and groups in one list, most recent conversation first
    DateTime? lastAt(Object o) => o is GroupModel ? o.lastMessage?.timestamp : (o as UserModel).lastMessage?.timestamp;
    bool inFilter(Object o) => switch (_filter) {
      'unread' => (o is GroupModel ? o.unreadCount : (o as UserModel).unreadCount) > 0,
      'groups' => o is GroupModel,
      _ when folder != null => folder.chats.contains(
        o is GroupModel ? ChatFolder.groupKey(o.id) : ChatFolder.userKey((o as UserModel).id),
      ),
      _ => true,
    };
    final rows = <Object>[...rest, ...groups].where(inFilter).toList()
      ..sort((a, b) {
        final at = lastAt(a), bt = lastAt(b);
        if (at == null && bt == null) return 0;
        if (at == null) return 1;
        if (bt == null) return -1;
        return bt.compareTo(at);
      });
    final unread = friendsState.totalUnread;

    return Stack(
      children: [
        const AuroraBackground(),
        RefreshIndicator(
          color: HakiColors.onLime,
          backgroundColor: HakiColors.lime,
          onRefresh: () async {
            await Future.wait([context.read<FriendsCubit>().load(), context.read<StoriesCubit>().load()]);
          },
          child: CustomScrollView(
            slivers: [
              SliverSafeArea(
                bottom: false,
                sliver: SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  sliver: SliverList.list(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Glass(
                              radius: 23,
                              child: SizedBox(
                                height: 46,
                                child: TextField(
                                  controller: _search,
                                  onChanged: (v) => setState(() => _query = v),
                                  textInputAction: TextInputAction.search,
                                  decoration: InputDecoration(
                                    hintText: 'Search',
                                    filled: false,
                                    border: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                    prefixIcon: Icon(HakiIcons.magnifyingGlass, color: Colors.white.withValues(alpha: 0.75)),
                                    suffixIcon: _query.isEmpty
                                        ? null
                                        : IconButton(
                                            tooltip: 'Clear search',
                                            icon: const Icon(HakiIcons.x, size: 18),
                                            onPressed: () => setState(() {
                                              _search.clear();
                                              _query = '';
                                            }),
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Semantics(
                            button: true,
                            label: 'Your profile',
                            child: GestureDetector(
                              onTap: widget.onOpenProfile,
                              child: AuraAvatar(user: me, size: 46, radius: 16),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      Text.rich(
                        TextSpan(
                          text: 'Hey ${me.name.split(' ').first},\n',
                          children: [
                            TextSpan(
                              text: unread == 0 ? 'all caught up' : '$unread unread',
                              style: HakiText.display(44, color: Colors.white.withValues(alpha: 0.55)),
                            ),
                          ],
                        ),
                        style: HakiText.display(44),
                      ),
                      const SizedBox(height: 22),
                      const _StoriesRow(),
                    ],
                  ),
                ),
              ),
              if (q.isEmpty)
                for (final f in friendsState.friends)
                  if ((f.daysToBirthday(DateTime.now()) ?? 9) <= 1)
                    SliverToBoxAdapter(
                      child: _ChatRow(
                        title: f.daysToBirthday(DateTime.now()) == 0
                            ? '${f.name}’s birthday is today'
                            : '${f.name}’s birthday is tomorrow',
                        leading: AuraAvatar(user: f, size: 52, radius: 19),
                        preview: f.daysToBirthday(DateTime.now()) == 0 ? '🎂 Say happy birthday' : '🎁 Don’t forget',
                        onTap: () => _open(f),
                      ),
                    ),
              if (pinned.isNotEmpty) ...[
                const _SectionTitle('Pinned'),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverGrid.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.98,
                    children: [
                      for (final f in pinned)
                        _PinnedCard(
                          friend: f,
                          preview: friendsState.typingIds.contains(f.id) ? 'typing…' : friendsState.previews[f.id],
                          onTap: () => _open(f),
                          onLongPress: () => _ChatActions.show(context, f),
                        ),
                    ],
                  ),
                ),
              ],
              _SectionTitle(
                q.isEmpty ? 'Chats' : 'Results',
                trailing: TextButton.icon(
                  onPressed: _newGroup,
                  icon: const Icon(HakiIcons.userCirclePlus, size: 18),
                  label: const Text('New group'),
                  style: TextButton.styleFrom(foregroundColor: HakiColors.lime),
                ),
              ),
              SliverToBoxAdapter(
                child: _FolderChips(selected: _filter, folders: folders, onSelect: (f) => setState(() => _filter = f)),
              ),
              if (_showLocked)
                SliverToBoxAdapter(
                  child: _ChatRow(
                    title: 'Locked chats',
                    leading: const _LockAvatar(),
                    preview: 'Showing ${locked.length} locked · tap to hide',
                    onTap: () => setState(() => _showLocked = false),
                  ),
                )
              else if (q.isEmpty && _filter == 'all') ...[
                SliverToBoxAdapter(
                  child: _ChatRow(
                    title: 'Haki Lounge',
                    leading: const _LoungeAvatar(),
                    preview: 'Public room · not encrypted',
                    onTap: () => _open(null),
                  ),
                ),
                if (locked.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _ChatRow(
                      title: 'Locked chats',
                      leading: const _LockAvatar(),
                      preview: '${locked.length} hidden · Face ID to open',
                      onTap: _revealLocked,
                    ),
                  ),
              ],
              if (!friendsState.isLoading && friendsState.friends.isEmpty && friendsState.groups.isEmpty)
                const SliverToBoxAdapter(child: _EmptyChats())
              else
                SliverList.builder(
                  itemCount: rows.length,
                  itemBuilder: (context, i) {
                    final row = rows[i];
                    if (row is GroupModel) {
                      return _ChatRow(
                        title: row.name,
                        leading: GroupAvatar(group: row),
                        preview: friendsState.groupPreviews[row.id] ?? '${row.members.length} people · encrypted',
                        previewHighlight: row.unreadCount > 0,
                        time: row.lastMessage == null ? null : chatTime(row.lastMessage!.timestamp),
                        unread: row.unreadCount,
                        onTap: () => _openGroup(row),
                        onLongPress: () => FolderPicker.show(context, ChatFolder.groupKey(row.id), row.name),
                      );
                    }
                    final f = row as UserModel;
                    final typing = friendsState.typingIds.contains(f.id);
                    return _ChatRow(
                      title: f.name,
                      leading: _PresenceAvatar(friend: f, online: friendsState.onlineIds.contains(f.id)),
                      preview: typing ? 'typing…' : (friendsState.previews[f.id] ?? f.statusMessage ?? 'Say hi'),
                      previewHighlight: typing || f.unreadCount > 0,
                      typing: typing,
                      time: f.lastMessage == null ? null : chatTime(f.lastMessage!.timestamp),
                      unread: f.unreadCount,
                      onTap: () => _open(f),
                      onLongPress: () => _ChatActions.show(context, f),
                    );
                  },
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 130)),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, {this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(20, 26, trailing == null ? 20 : 8, trailing == null ? 10 : 2),
      sliver: SliverToBoxAdapter(
        child: Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(text, style: HakiText.display(19, weight: FontWeight.w700)),
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

class _StoriesRow extends StatelessWidget {
  const _StoriesRow();

  @override
  Widget build(BuildContext context) {
    final stories = context.watch<StoriesCubit>().state;
    final byUser = stories.byUser;
    return SizedBox(
      height: 62,
      child: ListView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        children: [
          Tooltip(
            message: 'Add to your story',
            child: GestureDetector(
              onTap: stories.isPosting
                  ? null
                  : () async {
                      final img = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600);
                      if (img == null || !context.mounted) return;
                      final me = context.read<SessionCubit>().state.me;
                      if (me == null) return;
                      final ok = await context.read<StoriesCubit>().post(
                        img.path,
                        me: me,
                        friends: context.read<FriendsCubit>().state.friends,
                      );
                      if (context.mounted) {
                        showHakiToast(context, ok ? 'Story posted' : 'Couldn’t post story', isError: !ok);
                      }
                    },
              child: Glass(
                radius: 22,
                child: SizedBox(
                  width: 62,
                  height: 62,
                  child: stories.isPosting
                      ? const Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(HakiIcons.plus),
                ),
              ),
            ),
          ),
          for (final entry in byUser.entries)
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Semantics(
                button: true,
                label: '${entry.key.name}’s story',
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StoryView(user: entry.key, stories: entry.value),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      // Bright ring = something new; grey once you've seen all of them
                      gradient: entry.value.every((st) => st.seen)
                          ? const LinearGradient(colors: [Color(0xFF4A4A5A), Color(0xFF34343F)])
                          : const LinearGradient(colors: [HakiColors.lime, Color(0xFF8EE88A)]),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(2.5),
                      decoration: BoxDecoration(color: HakiColors.ink, borderRadius: BorderRadius.circular(20)),
                      child: AuraAvatar(user: entry.key, size: 52, radius: 18),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PinnedCard extends StatelessWidget {
  const _PinnedCard({required this.friend, required this.preview, required this.onTap, required this.onLongPress});

  final UserModel friend;
  final String? preview;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final aura = HakiColors.auraFor(friend.id);
    return Semantics(
      button: true,
      label: 'Pinned chat with ${friend.name}${friend.unreadCount > 0 ? ', ${friend.unreadCount} unread' : ''}',
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (friend.avatarUrl != null)
                AuraAvatar(user: friend, size: 400, radius: 0)
              else
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(center: const Alignment(-0.4, -0.6), radius: 1.2, colors: aura),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(
                      friend.initials,
                      style: HakiText.display(64, color: Colors.white.withValues(alpha: 0.3)),
                    ),
                  ),
                ),
              if (friend.unreadCount > 0) Positioned(right: 12, top: 12, child: CountBadge(friend.unreadCount)),
              Positioned(
                left: 8,
                right: 8,
                bottom: 8,
                child: Glass(
                  radius: 20,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        friend.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        preview ?? 'Say hi',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PresenceAvatar extends StatelessWidget {
  const _PresenceAvatar({required this.friend, required this.online});
  final UserModel friend;
  final bool online;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AuraAvatar(user: friend, size: 52, radius: 18),
        if (online)
          Positioned(
            right: -2,
            bottom: -2,
            child: Semantics(
              label: 'Online',
              child: Container(
                width: 15,
                height: 15,
                decoration: BoxDecoration(
                  color: HakiColors.lime,
                  shape: BoxShape.circle,
                  border: Border.all(color: HakiColors.ink, width: 3),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _LockAvatar extends StatelessWidget {
  const _LockAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(color: HakiColors.surfaceHigh, borderRadius: BorderRadius.circular(18)),
      child: const Icon(HakiIcons.lockFill, color: HakiColors.lime),
    );
  }
}

class _LoungeAvatar extends StatelessWidget {
  const _LoungeAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: RadialGradient(center: const Alignment(-0.4, -0.5), colors: HakiColors.auras[4]),
      ),
      child: Text('#', style: HakiText.display(22)),
    );
  }
}

class _ChatRow extends StatelessWidget {
  const _ChatRow({
    required this.title,
    required this.leading,
    required this.preview,
    required this.onTap,
    this.onLongPress,
    this.time,
    this.unread = 0,
    this.previewHighlight = false,
    this.typing = false,
  });

  final String title;
  final Widget leading;
  final String preview;
  final String? time;
  final int unread;
  final bool previewHighlight;
  final bool typing;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (time != null)
                        Text(
                          time!,
                          style: TextStyle(fontSize: 12, color: unread > 0 ? HakiColors.lime : HakiColors.textMuted),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          preview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            color: typing
                                ? HakiColors.lime
                                : (previewHighlight ? const Color(0xFFE4E4EE) : HakiColors.textMuted),
                          ),
                        ),
                      ),
                      if (unread > 0) ...[const SizedBox(width: 8), CountBadge(unread)],
                    ],
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

class _EmptyChats extends StatelessWidget {
  const _EmptyChats();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: HakiColors.surface, borderRadius: BorderRadius.circular(28)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('No chats yet', style: HakiText.display(24)),
            const SizedBox(height: 6),
            const Text(
              'Scan a friend’s Haki code or add them by email to start a private chat.',
              style: TextStyle(color: HakiColors.textMuted, height: 1.4),
            ),
            const SizedBox(height: 16),
            LimeButton(
              label: 'Add a friend',
              icon: HakiIcons.userPlus,
              onPressed: () => AddFriendSheet.show(context),
            ),
          ],
        ),
      ),
    );
  }
}

/// Long-press menu on a chat: pin, remove, block.
class _ChatActions {
  static void show(BuildContext context, UserModel friend) {
    final settings = context.read<SettingsCubit>();
    final friends = context.read<FriendsCubit>();
    final pinned = settings.state.pinnedIds.contains(friend.id);
    showModalBottomSheet(
      context: context,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(friend.name, style: HakiText.display(22, weight: FontWeight.w700)),
            ),
            ListTile(
              leading: Icon(pinned ? HakiIcons.pushPin : HakiIcons.pushPinFill),
              title: Text(pinned ? 'Unpin' : 'Pin to top'),
              onTap: () {
                Navigator.pop(sheet);
                settings.togglePin(friend.id);
              },
            ),
            ListTile(
              leading: const Icon(HakiIcons.folder),
              title: const Text('Add to folder…'),
              onTap: () {
                Navigator.pop(sheet);
                FolderPicker.show(context, ChatFolder.userKey(friend.id), friend.name);
              },
            ),
            ListTile(
              leading: const Icon(HakiIcons.userMinus),
              title: const Text('Remove friend'),
              onTap: () async {
                Navigator.pop(sheet);
                final sure = await confirmAction(
                  context,
                  title: 'Remove ${friend.name}?',
                  message: 'You’ll need a new friend request to chat again.',
                  action: 'Remove',
                );
                if (!sure) return;
                final ok = await friends.remove(friend.id);
                if (context.mounted) {
                  showHakiToast(context, ok ? 'Removed ${friend.name}' : 'Couldn’t remove', isError: !ok);
                }
              },
            ),
            ListTile(
              leading: const Icon(HakiIcons.prohibit, color: HakiColors.dangerText),
              title: const Text('Block', style: TextStyle(color: HakiColors.dangerText)),
              onTap: () async {
                Navigator.pop(sheet);
                final sure = await confirmAction(
                  context,
                  title: 'Block ${friend.name}?',
                  message: 'They won’t be able to message or call you.',
                  action: 'Block',
                );
                if (!sure) return;
                final ok = await friends.block(friend.id);
                if (context.mounted) {
                  showHakiToast(context, ok ? 'Blocked ${friend.name}' : 'Couldn’t block', isError: !ok);
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// All · Unread · Groups · your folders. Long-press a folder to delete it.
class _FolderChips extends StatelessWidget {
  const _FolderChips({required this.selected, required this.folders, required this.onSelect});
  final String selected;
  final List<ChatFolder> folders;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final chips = [
      ('all', 'All'),
      ('unread', 'Unread'),
      ('groups', 'Groups'),
      for (final f in folders) ('f:${f.name}', f.name),
    ];
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        children: [
          for (final (id, label) in chips)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onLongPress: id.startsWith('f:')
                    ? () async {
                        final sure = await confirmAction(
                          context,
                          title: 'Delete folder “$label”?',
                          message: 'The chats stay; only the folder goes.',
                          action: 'Delete',
                        );
                        if (sure && context.mounted) {
                          await context.read<SettingsCubit>().deleteFolder(label);
                          onSelect('all');
                        }
                      }
                    : null,
                child: ChoiceChip(
                  label: Text(label),
                  selected: selected == id,
                  onSelected: (_) => onSelect(id),
                  showCheckmark: false,
                  selectedColor: HakiColors.lime,
                  backgroundColor: HakiColors.surfaceHigh,
                  labelStyle: TextStyle(
                    color: selected == id ? HakiColors.onLime : HakiColors.text,
                    fontWeight: FontWeight.w600,
                  ),
                  side: BorderSide.none,
                  shape: const StadiumBorder(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Put one chat in folders (or a new one). Folders live on this phone only.
abstract final class FolderPicker {
  static Future<void> show(BuildContext context, String chatKey, String chatName) {
    final settings = context.read<SettingsCubit>();
    return showModalBottomSheet(
      context: context,
      builder: (sheet) => BlocBuilder<SettingsCubit, SettingsState>(
        bloc: settings,
        builder: (sheet, state) => SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.only(bottom: 12),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                child: Text('Folders for $chatName', style: HakiText.display(22, weight: FontWeight.w700)),
              ),
              for (final f in state.folders)
                CheckboxListTile(
                  value: f.chats.contains(chatKey),
                  onChanged: (_) => settings.toggleInFolder(f.name, chatKey),
                  title: Text(f.name),
                  activeColor: HakiColors.lime,
                  checkColor: HakiColors.onLime,
                ),
              ListTile(
                leading: const Icon(HakiIcons.folderPlus, color: HakiColors.lime),
                title: const Text('New folder'),
                onTap: () async {
                  final name = await _askName(sheet);
                  if (name != null) await settings.toggleInFolder(name, chatKey);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<String?> _askName(BuildContext context) {
    final ctl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (d) => AlertDialog(
        backgroundColor: HakiColors.surfaceHigh,
        title: const Text('New folder'),
        content: TextField(
          controller: ctl,
          autofocus: true,
          maxLength: 20,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Work, Family…'),
          onSubmitted: (v) => Navigator.pop(d, v.trim().isEmpty ? null : v.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(d, ctl.text.trim().isEmpty ? null : ctl.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    // ctl is not disposed here: the dialog's fields still use it while animating out
    // (the same crash the profile sheet had). It holds no native resources.
  }
}

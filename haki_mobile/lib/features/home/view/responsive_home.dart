import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/haki_theme.dart';
import '../../../core/utils/platform.dart';
import '../../../core/widgets/glass.dart';
import '../../../services/message_sender.dart';
import '../../conversation/view/conversation_view.dart';
import '../../feed/view/compose_post_view.dart';
import '../../feed/view/feed_view.dart';
import '../../friends/view_model/friends_cubit.dart';
import '../../friends/view_model/friends_state.dart';
import '../../profile/view/profile_view.dart';
import '../../profile/view/security_views.dart';
import 'add_friend_sheet.dart';
import 'chats_tab.dart';
import 'requests_tab.dart';
import 'package:chat_mobile/core/theme/haki_icons.dart';

/// Phone: tabs with a floating glass nav, chats open full screen.
/// Wide (tablet, computer, browser): a side rail, the list, and the open chat beside it.
class ResponsiveHome extends StatefulWidget {
  const ResponsiveHome({super.key});

  @override
  State<ResponsiveHome> createState() => _ResponsiveHomeState();
}

class _ResponsiveHomeState extends State<ResponsiveHome> {
  int _tab = 0;
  ChatTarget? _chat; // (user: null, group: null) = Haki Lounge

  bool get _wide => MediaQuery.sizeOf(context).width > 700;

  void _openChat(ChatTarget to) {
    if (_wide) {
      setState(() {
        _chat = to;
        _tab = 0;
      });
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ConversationView(recipient: to.user, group: to.group),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_wide) return _Shell(tab: _tab, onTab: (i) => setState(() => _tab = i), onOpenChat: _openChat);

    final listWidth = MediaQuery.sizeOf(context).width > 1100 ? 400.0 : 340.0;
    final chat = _chat;
    final main = chat != null
        ? ConversationView(
            key: ValueKey(chat.group != null ? 'g${chat.group!.id}' : (chat.user?.id ?? 'lounge')),
            recipient: chat.user,
            group: chat.group,
            embedded: true,
          )
        : const _NoChatOpen();

    return CallbackShortcuts(
      // Esc closes the open chat, like the phone's back swipe
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): () => setState(() => _chat = null)},
      child: Scaffold(
        body: Row(
          children: [
            _Rail(tab: _tab, onTab: (i) => setState(() => _tab = i)),
            if (_tab == 3)
              // You: one centered column, no list beside it
              Expanded(
                child: Center(
                  child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 680), child: const ProfileView()),
                ),
              )
            else if (_tab == 1)
              const Expanded(child: FeedTab())
            else ...[
              SizedBox(
                width: listWidth,
                child: IndexedStack(
                  index: _tab == 2 ? 1 : 0,
                  children: [
                    ChatsTab(onOpenChat: _openChat, onOpenProfile: () => setState(() => _tab = 3)),
                    const RequestsTab(),
                  ],
                ),
              ),
              const VerticalDivider(width: 1, thickness: 1, color: HakiColors.surfaceHigh),
              Expanded(child: main),
            ],
          ],
        ),
      ),
    );
  }
}

/// The left edge on wide screens: sections, add a friend, and this device's links.
class _Rail extends StatelessWidget {
  const _Rail({required this.tab, required this.onTab});
  final int tab;
  final ValueChanged<int> onTab;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<FriendsCubit, FriendsState, (int, int)>(
      selector: (s) => (s.totalUnread, s.requests.length),
      builder: (context, counts) {
        final items = [
          (HakiIcons.chatCircleFill, HakiIcons.chatCircle, 'Chats', counts.$1),
          (HakiIcons.squaresFourFill, HakiIcons.squaresFour, 'Feed', 0),
          (HakiIcons.usersFill, HakiIcons.users, 'Requests', counts.$2),
          (HakiIcons.userFill, HakiIcons.user, 'You', 0),
        ];
        return Container(
          width: 84,
          decoration: const BoxDecoration(
            color: HakiColors.surface,
            border: Border(right: BorderSide(color: HakiColors.surfaceHigh)),
          ),
          child: SafeArea(
            right: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Column(
                children: [
                  Text('h', style: HakiText.display(30, color: HakiColors.lime)),
                  const SizedBox(height: 22),
                  for (var i = 0; i < items.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Semantics(
                        selected: tab == i,
                        button: true,
                        label: items[i].$3,
                        child: Tooltip(
                          message: items[i].$3,
                          waitDuration: const Duration(milliseconds: 600),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => onTab(i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: 64,
                              height: 58,
                              decoration: BoxDecoration(
                                color: tab == i ? Colors.white.withValues(alpha: 0.12) : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                clipBehavior: Clip.none,
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        tab == i ? items[i].$1 : items[i].$2,
                                        size: 22,
                                        color: tab == i ? HakiColors.lime : Colors.white.withValues(alpha: 0.72),
                                      ),
                                      const SizedBox(height: 3),
                                      ExcludeSemantics(
                                        child: Text(
                                          items[i].$3,
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: tab == i ? FontWeight.w600 : FontWeight.w400,
                                            color: tab == i ? HakiColors.text : Colors.white.withValues(alpha: 0.72),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (items[i].$4 > 0) Positioned(top: 4, right: 10, child: CountBadge(items[i].$4)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Linked devices',
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DevicesView())),
                    icon: Icon(_deviceIcon, color: Colors.white.withValues(alpha: 0.72)),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: 52,
                    height: 52,
                    child: FloatingActionButton(
                      heroTag: 'add_friend_rail',
                      // On Feed the main action is posting; everywhere else it's adding a friend
                      tooltip: tab == 1 ? 'New post' : 'Add a friend',
                      onPressed: () => tab == 1 ? ComposePostView.open(context) : AddFriendSheet.show(context),
                      backgroundColor: HakiColors.lime,
                      foregroundColor: HakiColors.onLime,
                      shape: const CircleBorder(),
                      elevation: 0,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                        child: Icon(
                          tab == 1 ? HakiIcons.pencilSimple : HakiIcons.userPlus,
                          key: ValueKey(tab == 1), size: 22,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

IconData get _deviceIcon => Device.macos
    ? HakiIcons.laptop
    : Device.windows || Device.linux
    ? HakiIcons.laptop
    : Device.web
    ? HakiIcons.globe
    : HakiIcons.deviceTablet;

/// The right side before a chat is picked: what this device is and that it's private.
class _NoChatOpen extends StatelessWidget {
  const _NoChatOpen();

  @override
  Widget build(BuildContext context) {
    final where = Device.web ? 'in this browser' : 'on this ${Device.name}';
    return Stack(
      children: [
        const Positioned.fill(
          child: Opacity(
            opacity: 0.55,
            child: AuroraBackground(
              height: 520,
              fadeStart: 0.3,
              colors: [HakiColors.violet, HakiColors.blue, HakiColors.teal],
            ),
          ),
        ),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Glass(
                    radius: 30,
                    padding: const EdgeInsets.all(22),
                    child: Icon(_deviceIcon, size: 44, color: HakiColors.lime),
                  ),
                  const SizedBox(height: 24),
                  Text('Haki $where', textAlign: TextAlign.center, style: HakiText.display(32)),
                  const SizedBox(height: 10),
                  Text(
                    'Pick a chat on the left. Messages are end-to-end encrypted here too, and keep working when your phone is off.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, height: 1.45, color: Colors.white.withValues(alpha: 0.7)),
                  ),
                  const SizedBox(height: 22),
                  GlassButton(
                    label: 'Linked devices',
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DevicesView())),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(HakiIcons.lockFill, size: 13, color: HakiColors.textMuted),
                      const SizedBox(width: 6),
                      Text(
                        Device.pointer
                            ? 'Enter sends · Shift+Enter new line · Esc closes a chat'
                            : 'End-to-end encrypted',
                        style: const TextStyle(fontSize: 12, color: HakiColors.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Shell extends StatelessWidget {
  const _Shell({required this.tab, required this.onTab, required this.onOpenChat});

  final int tab;
  final ValueChanged<int> onTab;
  final ValueChanged<ChatTarget> onOpenChat;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          IndexedStack(
            index: tab,
            children: [
              ChatsTab(onOpenChat: onOpenChat, onOpenProfile: () => onTab(3)),
              const FeedTab(),
              const RequestsTab(),
              const ProfileView(),
            ],
          ),
          // Fade content out under the floating nav
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 130,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0, 0.7],
                    colors: [Color(0x0008080C), HakiColors.ink],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 0,
            child: SafeArea(
              top: false,
              minimum: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _NavBar(tab: tab, onTab: onTab),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 62,
                    height: 62,
                    child: FloatingActionButton(
                      heroTag: 'add_friend',
                      // On Feed the main action is posting; everywhere else it's adding a friend
                      tooltip: tab == 1 ? 'New post' : 'Add a friend',
                      onPressed: () => tab == 1 ? ComposePostView.open(context) : AddFriendSheet.show(context),
                      backgroundColor: HakiColors.lime,
                      foregroundColor: HakiColors.onLime,
                      shape: const CircleBorder(),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                        child: Icon(
                          tab == 1 ? HakiIcons.pencilSimple : HakiIcons.userPlus,
                          key: ValueKey(tab == 1),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  const _NavBar({required this.tab, required this.onTab});
  final int tab;
  final ValueChanged<int> onTab;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<FriendsCubit, FriendsState, (int, int)>(
      selector: (s) => (s.totalUnread, s.requests.length),
      builder: (context, counts) {
        final items = [
          (HakiIcons.chatCircleFill, HakiIcons.chatCircle, 'Chats', counts.$1),
          (HakiIcons.squaresFourFill, HakiIcons.squaresFour, 'Feed', 0),
          (HakiIcons.usersFill, HakiIcons.users, 'Requests', counts.$2),
          (HakiIcons.userFill, HakiIcons.user, 'You', 0),
        ];
        return Glass(
          radius: 31,
          padding: const EdgeInsets.all(6),
          child: SizedBox(
            height: 50,
            child: Row(
              children: [
                for (var i = 0; i < items.length; i++)
                  Expanded(
                    child: Semantics(
                      selected: tab == i,
                      button: true,
                      label: items[i].$3,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(25),
                        onTap: () => onTab(i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: tab == i ? Colors.white.withValues(alpha: 0.16) : Colors.transparent,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            clipBehavior: Clip.none,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    tab == i ? items[i].$1 : items[i].$2,
                                    size: 22,
                                    color: tab == i ? HakiColors.text : Colors.white.withValues(alpha: 0.72),
                                  ),
                                  const SizedBox(height: 2),
                                  ExcludeSemantics(
                                    child: Text(
                                      items[i].$3,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: tab == i ? FontWeight.w600 : FontWeight.w400,
                                        color: tab == i ? HakiColors.text : Colors.white.withValues(alpha: 0.72),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (items[i].$4 > 0) Positioned(top: 2, right: 18, child: CountBadge(items[i].$4)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

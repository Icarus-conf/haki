import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/chat_provider.dart';
import '../utils/story_helper.dart';
import '../widgets/home/add_friend_sheet.dart';
import '../widgets/home/custom_refresh_indicator_builder.dart';
import '../widgets/home/empty_state_widget.dart';
import '../widgets/home/friend_item.dart';
import '../widgets/home/friend_requests_section.dart';
import '../widgets/home/home_app_bar.dart';
import '../widgets/home/home_search_bar.dart';
import '../widgets/home/story_section.dart';
import 'call_view.dart';
import 'chat_view.dart';

class HomeView extends StatefulWidget {
  final bool isEmbedded;
  const HomeView({super.key, this.isEmbedded = false});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ChatProvider>().addListener(_onChatProviderChange);
      }
    });
  }

  @override
  void dispose() {
    // If possible, remove listener.
    // Since we used an anonymous function or method reference, we need to be careful.
    // context.read<ChatProvider>().removeListener(_onChatProviderChange);
    super.dispose();
  }

  void _onChatProviderChange() {
    if (!mounted) return;
    final chat = context.read<ChatProvider>();
    if (chat.isCallIncoming && chat.incomingCallUserId != null) {
      final incomingUserId = chat.incomingCallUserId;
      if (incomingUserId != null) {
        // Check if we are already in the call view to prevent stacking
        // For now, rely on minimal duplicate checks
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CallView(recipientId: incomingUserId, isIncoming: true),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    final me = chat.me;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          HomeAppBar(
            currentUser: me,
            isDarkMode: chat.isDarkMode,
            onToggleTheme: chat.toggleTheme,
            onAddFriend: () => AddFriendSheet.show(context),
          ),

          // Refreshable content area
          SliverFillRemaining(
            child: CustomRefreshIndicator(
              onRefresh: () async {
                await chat.refreshData();
              },
              builder: (context, child, controller) {
                return AnimatedBuilder(
                  animation: controller,
                  builder: (context, _) {
                    final offset = controller.value * 80.0;
                    return Stack(
                      children: [
                        // Content that moves with swipe
                        Transform.translate(offset: Offset(0, offset), child: child),
                        // Custom indicator
                        if (controller.state == IndicatorState.dragging ||
                            controller.state == IndicatorState.armed ||
                            controller.state == IndicatorState.loading)
                          Positioned(
                            top: offset - 60, // Position above the content
                            left: 0,
                            right: 0,
                            child: CustomRefreshIndicatorBuilder.build(controller),
                          ),
                      ],
                    );
                  },
                );
              },
              child: CustomScrollView(
                slivers: [
                  // Search Bar
                  SliverToBoxAdapter(child: HomeSearchBar(onSearchChanged: chat.updateSearchQuery)),

                  // Stories Section
                  SliverToBoxAdapter(
                    child: StorySection(
                      currentUser: me,
                      groupedStories: StoryHelper.groupStories(chat.stories),
                      onPostStory: chat.postStory,
                    ),
                  ),

                  // Friend Requests Section
                  if (chat.requests.isNotEmpty)
                    SliverToBoxAdapter(
                      child: FriendRequestsSection(
                        requests: chat.requests,
                        onAccept: chat.acceptRequest,
                        onDecline: chat.declineRequest,
                      ),
                    ),

                  // Friends List or Empty State
                  chat.filteredUsers.isEmpty &&
                          (chat.searchQuery.isNotEmpty || chat.requests.isEmpty)
                      ? SliverFillRemaining(
                          child: EmptyStateWidget(
                            searchQuery: chat.searchQuery,
                            isDarkMode: chat.isDarkMode,
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate((context, index) {
                            final user = chat.filteredUsers[index];
                            final isOnline = chat.onlineUserIds.contains(user.id);
                            final isPinned = chat.pinnedUserIds.contains(user.id);

                            return FriendItem(
                              user: user,
                              isOnline: isOnline,
                              isPinned: isPinned,
                              onTap: () {
                                chat.selectRecipient(user);
                                if (!widget.isEmbedded) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const ChatView()),
                                  );
                                }
                              },
                              onTogglePin: () => chat.togglePinUser(user.id),
                              onLongPress: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Remove Friend'),
                                    content: Text(
                                      'Are you sure you want to remove ${user.displayName ?? user.username}?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(ctx);
                                          chat.removeFriend(user.id);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Friend removed')),
                                          );
                                        },
                                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                                        child: const Text('Remove'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          }, childCount: chat.filteredUsers.length),
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

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../models/friend_request_model.dart';
import '../../../models/group_model.dart';
import '../../../models/user_model.dart';

part 'friends_state.freezed.dart';

@freezed
abstract class FriendsState with _$FriendsState {
  const FriendsState._();

  const factory FriendsState({
    /// Sorted by most recent message first.
    @Default([]) List<UserModel> friends,
    @Default([]) List<FriendRequestModel> requests,
    @Default([]) List<UserModel> blocked,
    @Default({}) Set<int> onlineIds,

    /// Decrypted one-line preview of each friend's last message.
    @Default({}) Map<int, String> previews,
    @Default({}) Set<int> typingIds,
    @Default(true) bool isLoading,
    int? activeChatId,

    /// Encrypted group chats, most recent first; previews keyed by group id.
    @Default([]) List<GroupModel> groups,
    @Default({}) Map<int, String> groupPreviews,
    int? activeGroupId,
  }) = _FriendsState;

  int get totalUnread =>
      friends.fold(0, (sum, f) => sum + f.unreadCount) + groups.fold(0, (sum, g) => sum + g.unreadCount);

  GroupModel? groupById(int id) {
    for (final g in groups) {
      if (g.id == id) return g;
    }
    return null;
  }

  UserModel? byId(int id) {
    for (final f in friends) {
      if (f.id == id) return f;
    }
    return null;
  }
}

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../models/friend_request_model.dart';
import '../../../models/group_model.dart';
import '../../../models/message_envelope.dart';
import '../../../models/message_model.dart';
import '../../../models/user_model.dart';
import '../../../services/api_service.dart';
import '../../../services/chat_service.dart';
import '../../../services/crypto_service.dart';
import 'friends_state.dart';

/// Chat list: friends with last-message previews and unread counts, requests,
/// presence, typing and blocking.
class FriendsCubit extends Cubit<FriendsState> {
  FriendsCubit({required this.api, required this.chat, required this.crypto})
    : super(const FriendsState());

  final ApiService api;
  final ChatService chat;
  final CryptoService crypto;

  UserModel? _me;
  final List<StreamSubscription> _subs = [];

  /// Called when a session starts.
  Future<void> start(UserModel me) async {
    await stop();
    _me = me;
    _subs.addAll([
      chat.onlineUsers.listen((ids) {
        final blocked = state.blocked.map((b) => b.id).toSet();
        emit(state.copyWith(onlineIds: ids.where((id) => !blocked.contains(id)).toSet()));
      }),
      chat.friendEvents.listen((_) => load()),
      chat.on('user:status').listen((d) => _patchFriend(
        d['userId'] as int,
        (f) => f.copyWith(statusMessage: d['statusMessage'] as String?),
      )),
      // A friend's key changed (new phone / restore): encrypt to the new one from now on
      chat.on('user:key').listen((d) {
        final id = d['userId'] as int, key = d['publicKey'] as String?;
        _patchFriend(id, (f) => f.copyWith(publicKey: key));
        _setGroups([
          for (final g in state.groups)
            g.copyWith(members: [for (final m in g.members) m.id == id ? m.copyWith(publicKey: key) : m]),
        ]);
      }),
      chat.on('group_updated').listen((_) => loadGroups()),
      chat.on('user_typing').listen((d) {
        if (d['groupId'] != null) return; // group typing shows inside the group only
        final ids = {...state.typingIds};
        (d['isTyping'] == true) ? ids.add(d['userId'] as int) : ids.remove(d['userId']);
        emit(state.copyWith(typingIds: ids));
      }),
      chat.messages.listen(_onMessage),
      // Read on another of my devices
      chat.on('read_sync').listen((d) {
        if (d['friendId'] != null) _patchFriend(d['friendId'] as int, (f) => f.copyWith(unreadCount: 0));
        if (d['groupId'] != null) {
          _setGroups([for (final g in state.groups) g.id == d['groupId'] ? g.copyWith(unreadCount: 0) : g]);
        }
      }),
    ]);
    await load();
  }

  Future<void> stop() async {
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
    _me = null;
    if (!isClosed) emit(const FriendsState());
  }

  Future<void> load() async {
    final results = await Future.wait([
      api.getFriends(),
      api.getFriendRequests(),
      api.getBlockedUsers(),
    ]);
    if (isClosed) return;
    final friends = _sorted((results[0] as List<UserModel>).map((f) {
      // Keep the open chat at 0 even if the server raced our mark_read
      return f.id == state.activeChatId ? f.copyWith(unreadCount: 0) : f;
    }).toList());
    emit(
      state.copyWith(
        friends: friends,
        requests: results[1].map((r) => FriendRequestModel.fromJson(r as Map<String, dynamic>)).toList(),
        blocked: results[2] as List<UserModel>,
        isLoading: false,
      ),
    );
    final previews = <int, String>{};
    for (final f in friends) {
      if (f.lastMessage != null) previews[f.id] = await _preview(f.lastMessage!);
    }
    if (!isClosed) emit(state.copyWith(previews: previews));
    await loadGroups();
  }

  Future<void> loadGroups() async {
    final groups = await api.getGroups();
    if (isClosed) return;
    // Counts come from the server (same on every device); the open group stays at 0
    _setGroups([for (final g in groups) g.id == state.activeGroupId ? g.copyWith(unreadCount: 0) : g]);
    final previews = <int, String>{};
    for (final g in groups) {
      if (g.lastMessage != null) previews[g.id] = await _preview(g.lastMessage!, group: g);
    }
    if (!isClosed) emit(state.copyWith(groupPreviews: previews));
  }

  Future<(GroupModel?, String?)> createGroup(String name, List<int> memberIds) async {
    final res = await api.createGroup(name, memberIds);
    if (res.$1 != null) await loadGroups();
    return res;
  }

  Future<String?> addToGroup(int groupId, List<int> memberIds) async {
    final (g, error) = await api.addGroupMembers(groupId, memberIds);
    if (g != null) await loadGroups();
    return error;
  }

  Future<bool> leaveGroup(int groupId) async {
    final ok = await api.leaveGroup(groupId);
    if (ok) await loadGroups();
    return ok;
  }

  void openGroup(int groupId) {
    emit(state.copyWith(activeGroupId: groupId));
    _setGroups([for (final g in state.groups) g.id == groupId ? g.copyWith(unreadCount: 0) : g]);
    chat.markGroupRead(groupId);
  }

  void closeGroup() => emit(state.copyWith(activeGroupId: null));

  /// The conversation screen for [friendId] opened.
  void openChat(int friendId) {
    emit(state.copyWith(activeChatId: friendId));
    _patchFriend(friendId, (f) => f.copyWith(unreadCount: 0));
    chat.markRead(friendId);
  }

  void closeChat() => emit(state.copyWith(activeChatId: null));

  Future<String?> sendRequest(String identifier) async {
    final value = identifier.trim().replaceFirst(RegExp(r'^haki:'), '');
    if (value.isEmpty) return 'Enter an email or Haki code';
    final error = await api.sendFriendRequest(value);
    if (error == null) await load();
    return error;
  }

  Future<void> accept(int requestId) async {
    if (await api.acceptFriendRequest(requestId)) await load();
  }

  Future<void> decline(int requestId) async {
    if (await api.declineFriendRequest(requestId)) await load();
  }

  Future<bool> remove(int friendId) async {
    final ok = await api.removeFriend(friendId);
    if (ok) await load();
    return ok;
  }

  Future<bool> block(int userId) async {
    final ok = await api.blockUser(userId);
    if (ok) await load();
    return ok;
  }

  Future<bool> unblock(int userId) async {
    final ok = await api.unblockUser(userId);
    if (ok) await load();
    return ok;
  }

  Future<void> _onMessage(MessageModel m) async {
    final me = _me;
    if (me == null) return;
    final mine = m.senderId == me.id;
    if (m.groupId != null) return _onGroupMessage(m, mine);
    if (m.recipientId == null) return; // global lounge isn't in the list
    final friendId = mine ? m.recipientId! : m.senderId;
    final last = LastMessage(
      content: m.message,
      timestamp: m.timestamp,
      senderId: m.senderId,
      attachmentType: m.attachmentType,
    );
    final countsAsUnread = !mine && state.activeChatId != friendId;
    _patchFriend(
      friendId,
      (f) => f.copyWith(
        lastMessage: last,
        unreadCount: countsAsUnread ? f.unreadCount + 1 : f.unreadCount,
      ),
    );
    final preview = await _preview(last);
    if (!isClosed) emit(state.copyWith(previews: {...state.previews, friendId: preview}));
  }

  Future<void> _onGroupMessage(MessageModel m, bool mine) async {
    final g = state.groupById(m.groupId!);
    if (g == null) return loadGroups(); // added to a group we haven't loaded yet
    final last = LastMessage(
      content: m.message,
      timestamp: m.timestamp,
      senderId: m.senderId,
      attachmentType: m.attachmentType,
    );
    final unread = !mine && state.activeGroupId != g.id;
    _setGroups([
      for (final x in state.groups)
        x.id == g.id ? x.copyWith(lastMessage: last, unreadCount: unread ? x.unreadCount + 1 : x.unreadCount) : x,
    ]);
    final preview = await _preview(last, group: g);
    if (!isClosed) emit(state.copyWith(groupPreviews: {...state.groupPreviews, g.id: preview}));
  }

  void _setGroups(List<GroupModel> groups) {
    if (isClosed) return;
    final sorted = [...groups]..sort((a, b) {
      final at = a.lastMessage?.timestamp, bt = b.lastMessage?.timestamp;
      if (at == null && bt == null) return a.name.compareTo(b.name);
      if (at == null) return 1;
      if (bt == null) return -1;
      return bt.compareTo(at);
    });
    emit(state.copyWith(groups: sorted));
  }

  Future<String> _preview(LastMessage m, {GroupModel? group}) async {
    final who = group?.member(m.senderId)?.name.split(' ').first;
    final prefix = m.senderId == _me?.id ? 'You: ' : (who != null ? '$who: ' : '');
    if (m.attachmentType == 'voice') return '${prefix}Voice message';
    if (m.attachmentType == 'image') return '${prefix}Photo';
    if (m.attachmentType == 'video') return '${prefix}Video';
    // ponytail: one RSA decrypt per chat row; cache by message id if the list gets long
    final body = MessageEnvelope.decode(
      await crypto.decrypt(m.content, _me!.username, preferKey: '${_me!.id}'),
    );
    final text = body.text;
    if (CryptoService.undecryptable.contains(text)) return '${prefix}Encrypted message';
    if (body.poll != null) return '${prefix}Poll: ${body.poll!.question}';
    if (body.sticker != null) return '$prefix${body.sticker} Sticker';
    if (body.file != null) return '$prefix📄 ${body.file!.name}';
    if (body.story != null) return '${prefix}Replied to a story: $text';
    return '$prefix$text';
  }

  void _patchFriend(int id, UserModel Function(UserModel) patch) {
    if (isClosed) return;
    emit(state.copyWith(friends: _sorted([for (final f in state.friends) f.id == id ? patch(f) : f])));
  }

  List<UserModel> _sorted(List<UserModel> list) => list
    ..sort((a, b) {
      final at = a.lastMessage?.timestamp, bt = b.lastMessage?.timestamp;
      if (at == null && bt == null) return a.name.compareTo(b.name);
      if (at == null) return 1;
      if (bt == null) return -1;
      return bt.compareTo(at);
    });

  @override
  Future<void> close() async {
    for (final s in _subs) {
      await s.cancel();
    }
    return super.close();
  }
}

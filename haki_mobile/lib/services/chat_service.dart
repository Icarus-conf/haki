import 'dart:async';
import 'dart:developer';

// ignore: library_prefixes
import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../models/message_model.dart';
import 'api_service.dart';

/// Socket.IO wrapper. Every server event is forwarded onto one broadcast bus when the
/// socket is created, so listeners can subscribe before or after `connect()` and still
/// receive events (previously `socket?.on(...)` ran while the socket was still null).
class ChatService {
  IO.Socket? socket;
  final _bus = StreamController<(String, dynamic)>.broadcast();

  static const _serverEvents = [
    'message',
    'history',
    'online_users',
    'friend_request',
    'friend_removed',
    'friend_accepted',
    'message_deleted',
    'message:reaction',
    'messages_read',
    'user_typing',
    'user:status',
    'user:key',
    'story_posted',
    'message_error',
    'system_message',
    'call_offer',
    'call_answer',
    'ice_candidate',
    'call_rejected',
    'call_ended',
    'message_edited',
    'message_hidden',
    'message_pinned',
    'mention',
    'group_updated',
    'poll_votes',
    'message_scheduled',
    'story_liked',
    'disappearing_changed',
    'message_viewed',
    'read_sync',
    'group_read',
    'group_call',
    'gc_signal',
  ];

  /// Raw payloads of one server event.
  Stream<dynamic> on(String event) => _bus.stream.where((e) => e.$1 == event).map((e) => e.$2);

  Stream<MessageModel> get messages => on('message').map((d) => MessageModel.fromJson(d));
  Stream<List<MessageModel>> get history => on(
    'history',
  ).map((d) => (d['messages'] as List).map((m) => MessageModel.fromJson(m)).toList());
  Stream<List<int>> get onlineUsers => on('online_users').map((d) => List<int>.from(d));
  Stream<dynamic> get friendEvents =>
      _bus.stream.where((e) => e.$1.startsWith('friend_')).map((e) => e.$2);
  Stream<int> get deletedMessages => on('message_deleted').map((d) => d['messageId'] as int);
  Stream<String> get systemMessages => on('system_message').map((d) => d['message'] as String);

  void connect(String token) {
    socket?.dispose();
    socket = IO.io(
      ApiService.baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': 'Bearer $token'})
          .enableForceNew()
          .build(),
    );
    socket!.onConnect((_) => log('Connected to Chat Socket'));
    socket!.onDisconnect((_) => log('Disconnected from Chat Socket'));
    for (final event in _serverEvents) {
      socket!.on(event, (data) => _bus.add((event, data)));
    }
  }

  void emit(String event, Map<String, dynamic> data) => socket?.emit(event, data);

  /// Emit and wait for the server's reply (null if not connected or no reply in 8 s).
  Future<dynamic> request(String event, Map<String, dynamic> data) {
    final s = socket;
    if (s == null) return Future.value(null);
    final done = Completer<dynamic>();
    s.emitWithAck(event, data, ack: (res) {
      if (!done.isCompleted) done.complete(res);
    });
    return done.future.timeout(const Duration(seconds: 8), onTimeout: () => null);
  }

  void sendMessage(
    String text, {
    int? recipientId,
    int? groupId,
    String? attachmentUrl,
    String? tempId,
    String? mediaIv,
    Map<String, dynamic>? mediaKeys,
    String? attachmentType,
    int? replyToMessageId,
    String? replyToSender,
    String? replyToMessage,
    DateTime? sendAt,
    bool viewOnce = false,
  }) {
    emit('message', {
      if (viewOnce) 'viewOnce': true,
      'sendAt': ?sendAt?.toUtc().toIso8601String(),
      'message': text,
      'recipientId': ?recipientId,
      'groupId': ?groupId,
      'attachmentUrl': ?attachmentUrl,
      'tempId': ?tempId,
      'mediaIv': ?mediaIv,
      'mediaKeys': ?mediaKeys,
      'attachmentType': ?attachmentType,
      'replyToMessageId': ?replyToMessageId,
      'replyToSender': ?replyToSender,
      'replyToMessage': ?replyToMessage,
    });
  }

  void setDisappearing(int seconds, {int? recipientId, int? groupId}) =>
      emit('set_disappearing', {'seconds': seconds, 'recipientId': ?recipientId, 'groupId': ?groupId});
  void openViewOnce(int messageId) => emit('open_view_once', {'messageId': messageId});
  void deleteMessage(int messageId) => emit('delete_message', {'messageId': messageId});
  void react(int messageId, String emoji) =>
      emit('message:react', {'messageId': messageId, 'emoji': emoji});
  void editMessage(int messageId, String body) => emit('edit_message', {'messageId': messageId, 'message': body});
  void hideMessage(int messageId) => emit('hide_message', {'messageId': messageId});
  void pinMessage(int messageId, bool pinned) => emit('pin_message', {'messageId': messageId, 'pinned': pinned});
  void vote(int messageId, List<int> options) => emit('poll_vote', {'messageId': messageId, 'options': options});
  void markRead(int friendId) => emit('mark_read', {'friendId': friendId});
  void markGroupRead(int groupId) => emit('mark_read', {'groupId': groupId});
  void emitTyping(bool typing, {int? recipientId, int? groupId}) => emit(
    typing ? 'typing_start' : 'typing_stop',
    {'recipientId': ?recipientId, 'groupId': ?groupId},
  );
  void requestHistory({int? recipientId, int? groupId, int? limit}) =>
      emit('get_history', {'recipientId': recipientId, 'groupId': ?groupId, 'limit': ?limit});

  void disconnect() {
    socket?.dispose();
    socket = null;
  }

  void dispose() {
    disconnect();
    _bus.close();
  }
}

import 'dart:async';
import 'dart:developer';

// ignore: library_prefixes
import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../models/message_model.dart';
import 'api_service.dart';

class ChatService {
  IO.Socket? socket;
  final _messageController = StreamController<MessageModel>.broadcast();
  final _historyController = StreamController<List<MessageModel>>.broadcast();
  final _onlineUsersController = StreamController<List<int>>.broadcast();
  final _friendRequestController = StreamController<dynamic>.broadcast();
  final _deleteController = StreamController<int>.broadcast();
  final _typingController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<MessageModel> get messages => _messageController.stream;
  Stream<List<MessageModel>> get history => _historyController.stream;
  Stream<List<int>> get onlineUsers => _onlineUsersController.stream;
  Stream<dynamic> get friendRequests => _friendRequestController.stream;
  Stream<int> get deletedMessages => _deleteController.stream;
  Stream<Map<String, dynamic>> get typingEvents => _typingController.stream;

  void connect(String token) {
    socket = IO.io(
      ApiService.baseUrl,
      IO.OptionBuilder().setTransports(['websocket']).setAuth({'token': 'Bearer $token'}).build(),
    );

    socket!.onConnect((_) => log('Connected to Chat Socket'));

    socket!.on('message', (data) {
      _messageController.add(MessageModel.fromJson(data));
    });

    socket!.on('history', (data) {
      final List msgs = data['messages'];
      _historyController.add(msgs.map((m) => MessageModel.fromJson(m)).toList());
    });

    socket!.on('online_users', (data) {
      _onlineUsersController.add(List<int>.from(data));
    });

    socket!.on('friend_request', (data) {
      _friendRequestController.add(data);
    });

    socket!.on('friend_removed', (data) {
      _friendRequestController.add(data);
    });

    socket!.on('friend_accepted', (data) {
      _friendRequestController.add(data);
    });

    socket!.on('message_deleted', (data) {
      _deleteController.add(data['messageId']);
    });

    socket!.on('user_typing', (data) {
      _typingController.add({
        'userId': data['userId'],
        'username': data['username'],
        'isTyping': data['isTyping'],
      });
    });

    socket!.onDisconnect((_) => log('Disconnected from Chat Socket'));
  }

  void sendMessage(
    String text, {
    int? recipientId,
    String? attachmentUrl,
    String? tempId,
    String? mediaIv,
    Map<String, dynamic>? mediaKeys,
    String? attachmentType,
    int? replyToMessageId,
    String? replyToSender,
    String? replyToMessage,
  }) {
    socket?.emit('message', {
      'message': text,
      if (recipientId != null) 'recipientId': recipientId,
      if (attachmentUrl != null) 'attachmentUrl': attachmentUrl,
      if (tempId != null) 'tempId': tempId,
      if (mediaIv != null) 'mediaIv': mediaIv,
      if (mediaKeys != null) 'mediaKeys': mediaKeys,
      if (attachmentType != null) 'attachmentType': attachmentType,
      if (replyToMessageId != null) 'replyToMessageId': replyToMessageId,
      if (replyToSender != null) 'replyToSender': replyToSender,
      if (replyToMessage != null) 'replyToMessage': replyToMessage,
    });
  }

  void deleteMessage(int messageId) {
    socket?.emit('delete_message', {'messageId': messageId});
  }

  void emitTypingStart(int recipientId) {
    socket?.emit('typing_start', {'recipientId': recipientId});
  }

  void emitTypingStop(int recipientId) {
    socket?.emit('typing_stop', {'recipientId': recipientId});
  }

  void requestHistory({int? recipientId}) {
    socket?.emit('get_history', {'recipientId': recipientId});
  }

  void disconnect() {
    socket?.disconnect();
  }

  void dispose() {
    socket?.disconnect();
    _messageController.close();
    _historyController.close();
    _onlineUsersController.close();
    _friendRequestController.close();
    _deleteController.close();
    _typingController.close();
  }
}

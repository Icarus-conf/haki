import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../models/message_model.dart';
import '../models/reaction_model.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/chat_service.dart';
import '../services/crypto_service.dart';

/// Manages messages, chat history, and typing indicators
class MessageManager extends ChangeNotifier {
  final ApiService _api;
  final ChatService _chat;
  final CryptoService _crypto;
  final UserModel? Function() _getMeCallback;

  List<MessageModel> _messages = [];
  UserModel? _activeRecipient;
  bool _isHistoryLoading = false;
  int? _loadingForRecipientId; // Track which recipient we're loading for (null = global chat)
  final Map<int, Timer> _pendingDeletes = {}; // messageId -> Timer
  final Map<int, bool> _typingUsers = {}; // userId -> isTyping

  MessageManager({
    required ApiService api,
    required ChatService chat,
    required CryptoService crypto,
    required UserModel? Function() getMeCallback,
  }) : _api = api,
       _chat = chat,
       _crypto = crypto,
       _getMeCallback = getMeCallback;

  // Getters
  List<MessageModel> get messages => _messages;
  UserModel? get activeRecipient => _activeRecipient;
  bool get isHistoryLoading => _isHistoryLoading;

  bool get isRecipientTyping {
    if (_activeRecipient == null) return false;
    return _typingUsers[_activeRecipient!.id] ?? false;
  }

  /// Setup message-related listeners
  void setupListeners() {
    // Message Reactions
    _chat.socket?.on('message:reaction', (data) {
      dev.log('Received message:reaction event: $data', name: 'MessageManager');

      final messageId = data['messageId'];
      final reactionsData = data['reactions'] as List<dynamic>?;

      if (reactionsData == null) {
        dev.log('No reactions data received', name: 'MessageManager');
        return;
      }

      final reactions = reactionsData
          .map((r) => ReactionModel.fromJson(r as Map<String, dynamic>))
          .toList();

      dev.log(
        'Parsed ${reactions.length} reactions for message $messageId',
        name: 'MessageManager',
      );

      // Update message in history
      final index = _messages.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        _messages[index] = _messages[index].copyWith(reactions: reactions);
        dev.log('Updated message $messageId with reactions', name: 'MessageManager');
        notifyListeners();
      } else {
        dev.log('Message $messageId not found in local messages', name: 'MessageManager');
      }
    });

    // Deleted Messages
    _chat.deletedMessages.listen((id) {
      _messages.removeWhere((m) => m.id == id);
      notifyListeners();
    });

    // Message History
    _chat.history.listen((msgs) async {
      try {
        dev.log(
          '📨 Received history response: ${msgs.length} messages, loading for recipient: $_loadingForRecipientId',
          name: 'MessageManager',
        );

        if (msgs.isEmpty) {
          dev.log('History is empty, stopping loading', name: 'MessageManager');
          if (_isHistoryLoading) {
            _messages = [];
            _isHistoryLoading = false;
            notifyListeners();
          }
          return;
        }

        final me = _getMeCallback();
        if (me == null) return;

        dev.log(
          'Processing history: ${msgs.length} messages for recipient: $_loadingForRecipientId',
          name: 'MessageManager',
        );

        // Decrypt all messages - backend should already filter them correctly
        final decryptedMsgs = await Future.wait(
          msgs.map((m) async {
            try {
              final text = await _crypto.decrypt(m.message, me.username);
              return MessageModel(
                id: m.id,
                sender: m.sender,
                username: m.username,
                senderId: m.senderId,
                avatarUrl: m.avatarUrl,
                message: text,
                attachmentUrl: m.attachmentUrl,
                timestamp: m.timestamp,
                recipientId: m.recipientId,
                mediaIv: m.mediaIv,
                mediaKeys: m.mediaKeys,
                attachmentType: m.attachmentType,
                reactions: m.reactions,
              );
            } catch (e) {
              dev.log('Error decrypting message ${m.id}: $e', name: 'MessageManager');
              return m.copyWith(message: 'Error decrypting message');
            }
          }),
        );

        dev.log('Decrypted ${decryptedMsgs.length} messages', name: 'MessageManager');
        _messages = decryptedMsgs;

        _isHistoryLoading = false;
        notifyListeners();
      } catch (e, stack) {
        dev.log(
          'Critical error in history listener: $e',
          name: 'MessageManager',
          error: e,
          stackTrace: stack,
        );
        if (_isHistoryLoading) {
          _isHistoryLoading = false;
          notifyListeners();
        }
      }
    });

    // New Messages
    _chat.messages.listen((m) async {
      final me = _getMeCallback();
      if (me == null) return;

      bool isRelevant = false;
      if (_activeRecipient == null) {
        if (m.recipientId == null) isRelevant = true;
      } else {
        if ((m.senderId == me.id && m.recipientId == _activeRecipient!.id) ||
            (m.senderId == _activeRecipient!.id && m.recipientId == me.id)) {
          isRelevant = true;
        }
      }

      if (isRelevant) {
        final index = _messages.indexWhere((msg) => msg.tempId != null && msg.tempId == m.tempId);
        final text = await _crypto.decrypt(m.message, me.username);
        final newMessage = MessageModel(
          id: m.id,
          sender: m.sender,
          username: m.username,
          senderId: m.senderId,
          avatarUrl: m.avatarUrl,
          message: text,
          attachmentUrl: m.attachmentUrl,
          timestamp: m.timestamp,
          recipientId: m.recipientId,
          isSending: false,
          mediaIv: m.mediaIv,
          mediaKeys: m.mediaKeys,
          attachmentType: m.attachmentType,
        );

        if (index != -1) {
          _messages[index] = newMessage;
        } else {
          _messages.add(newMessage);
        }
        notifyListeners();
      }
    });

    // Typing Indicator Listener
    _chat.typingEvents.listen((data) {
      final userId = data['userId'] as int;
      final isTyping = data['isTyping'] as bool;

      _typingUsers[userId] = isTyping;
      notifyListeners();
    });
  }

  /// Select a recipient for chat
  void selectRecipient(UserModel? user) {
    _activeRecipient = user;
    _loadingForRecipientId = user?.id; // Track which recipient we're loading for
    _isHistoryLoading = true;
    if (user != null) {
      dev.log('Selecting recipient ${user.id}', name: 'MessageManager');
      // Clear typing state for this user when entering chat
      _typingUsers[user.id] = false;
    } else {
      dev.log('Deselecting recipient. Back to global.', name: 'MessageManager');
    }
    _messages = []; // Clear current view
    notifyListeners();
    _chat.requestHistory(recipientId: user?.id);
  }

  /// Send typing notification
  void sendTypingNotification(bool isTyping) {
    if (_activeRecipient == null) return;

    if (isTyping) {
      _chat.emitTypingStart(_activeRecipient!.id);
    } else {
      _chat.emitTypingStop(_activeRecipient!.id);
    }
  }

  /// Send a message
  Future<void> sendMessage(String text, {String? attachmentPath}) async {
    final me = _getMeCallback();
    if (me == null) return;

    String finalMessage = text;
    String? finalAttachmentUrl;
    String? mediaIv;
    Map<String, dynamic>? mediaKeys;
    String? attachmentType;

    bool isE2EE = _activeRecipient != null && _activeRecipient!.publicKey != null;

    // Detect attachment type
    if (attachmentPath != null) {
      attachmentType = attachmentPath.toLowerCase().contains('.m4a') ? 'voice' : 'image';
    }

    if (isE2EE) {
      finalMessage = await _crypto.encrypt(
        text: text,
        recipientPubKey: _activeRecipient!.publicKey!,
        senderPubKey: me.publicKey!,
      );
    }

    if (attachmentPath != null) {
      if (isE2EE) {
        // Encrypt Media
        final bytes = await File(attachmentPath).readAsBytes();
        final encryptedResult = await _crypto.encryptMedia(
          bytes: bytes,
          recipientPubKey: _activeRecipient!.publicKey!,
          senderPubKey: me.publicKey!,
        );

        final encryptedBytes = encryptedResult['data'] as Uint8List;
        mediaIv = encryptedResult['iv'] as String;
        mediaKeys = encryptedResult['keys'] as Map<String, dynamic>;

        // Write to temp file
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/enc_${DateTime.now().millisecondsSinceEpoch}.bin');
        await tempFile.writeAsBytes(encryptedBytes);

        // Upload encrypted file
        finalAttachmentUrl = await _api.uploadAttachment(tempFile.path);

        // Cleanup
        try {
          await tempFile.delete();
        } catch (_) {}
      } else {
        // Plain Upload (Global or no public key)
        finalAttachmentUrl = await _api.uploadAttachment(attachmentPath);
      }
    }

    // Optimistic UI Update
    final tempId = DateTime.now().millisecondsSinceEpoch.toString();
    final optimisticMessage = MessageModel(
      sender: me.displayName ?? me.username,
      username: me.username,
      senderId: me.id,
      avatarUrl: me.avatarUrl,
      message: text,
      attachmentUrl: attachmentPath, // Use local path for immediate local preview
      timestamp: DateTime.now(),
      recipientId: _activeRecipient?.id,
      tempId: tempId,
      isSending: true,
      mediaIv: mediaIv,
      mediaKeys: mediaKeys,
      attachmentType: attachmentType,
    );

    _messages.add(optimisticMessage);
    notifyListeners();

    _chat.sendMessage(
      finalMessage,
      recipientId: _activeRecipient?.id,
      attachmentUrl: finalAttachmentUrl,
      tempId: tempId,
      mediaIv: mediaIv,
      mediaKeys: mediaKeys,
      attachmentType: attachmentType,
    );
  }

  /// Delete message locally with undo option
  void deleteMessageLocally(MessageModel message) {
    if (message.id == null) return;

    final index = _messages.indexWhere((m) => m.id == message.id);
    if (index == -1) return;

    _messages.removeAt(index);
    notifyListeners();

    // Start 5s timer
    final timer = Timer(const Duration(seconds: 5), () {
      _chat.deleteMessage(message.id!);
      _pendingDeletes.remove(message.id);
    });

    _pendingDeletes[message.id!] = timer;
  }

  /// Undo message deletion
  void undoDelete(MessageModel message) {
    if (message.id == null) return;

    final timer = _pendingDeletes[message.id];
    if (timer != null) {
      timer.cancel();
      _pendingDeletes.remove(message.id);

      // Re-insert message
      _messages.add(message);
      _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      notifyListeners();
    }
  }

  /// Upload attachment
  Future<String?> uploadAttachment(String filePath) async {
    return _api.uploadAttachment(filePath);
  }

  /// Clear messages and reset state
  void clear() {
    _messages = [];
    _activeRecipient = null;
    _loadingForRecipientId = null;
    _isHistoryLoading = false;
    _typingUsers.clear();
    for (var timer in _pendingDeletes.values) {
      timer.cancel();
    }
    _pendingDeletes.clear();
  }
}

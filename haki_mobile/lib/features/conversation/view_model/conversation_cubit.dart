import 'dart:async';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../../../models/group_model.dart';
import '../../../models/message_envelope.dart';
import '../../../models/message_model.dart';
import '../../../models/reaction_model.dart';
import '../../../models/user_model.dart';
import '../../../services/api_service.dart';
import '../../../services/chat_service.dart';
import '../../../services/crypto_service.dart';
import '../../../services/message_sender.dart';

part 'conversation_cubit.freezed.dart';

@freezed
abstract class ConversationState with _$ConversationState {
  const ConversationState._();

  const factory ConversationState({
    @Default([]) List<MessageModel> messages, // oldest first
    @Default([]) List<MessageModel> pinned, // newest first

    /// My messages waiting to be sent later (only I see these).
    @Default([]) List<MessageModel> scheduled,
    @Default(true) bool isLoading,

    /// People typing right now (one in a DM, any member in a group).
    @Default({}) Set<int> typingIds,

    /// Search text; empty = not searching. Matching happens here on the phone.
    @Default('') String query,
    @Default(false) bool searchingOlder,

    /// One-shot error for a toast; the view clears nothing, it just listens for changes.
    String? error,

    /// One-shot info toast (e.g. "Ana turned on disappearing messages").
    String? notice,

    /// Disappearing-message timer for this chat, in seconds (0 = off).
    @Default(0) int disappearSeconds,

    /// Groups: how far each member has read (user id -> last message id read).
    @Default({}) Map<int, int> readers,
  }) = _ConversationState;

  bool get isRecipientTyping => typingIds.isNotEmpty;

  List<MessageModel> get searchResults {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return messages;
    return [for (final m in messages) if (m.message.toLowerCase().contains(q)) m];
  }
}

/// One open chat: a friend ([recipient]), a [group], or the public Lounge when both are null.
class ConversationCubit extends Cubit<ConversationState> {
  ConversationCubit({
    required this.recipient,
    required this.me,
    required this.api,
    required this.chat,
    required this.crypto,
    this.group,
    this.liveRecipient,
    this.liveGroup,
    this.refreshFriends,
  }) : sender = MessageSender(api: api, chat: chat, crypto: crypto),
       super(const ConversationState()) {
    _subs.addAll([
      chat.on('history').listen(_onHistory),
      chat.messages.listen(_onMessage),
      chat.deletedMessages.listen(_drop),
      chat.on('message_hidden').listen((d) => _drop(d['messageId'] as int)),
      chat.on('message_edited').listen((d) => _onEdited(MessageModel.fromJson(Map<String, dynamic>.from(d)))),
      chat.on('message_pinned').listen((d) => _onPinned(MessageModel.fromJson(Map<String, dynamic>.from(d)))),
      chat.on('message:reaction').listen(_onReaction),
      chat.on('poll_votes').listen((d) {
        final votes = MessageModel.parseVotes(d['pollVotes']);
        emit(state.copyWith(
          messages: [for (final m in state.messages) m.id == d['messageId'] ? m.copyWith(pollVotes: votes) : m],
        ));
      }),
      chat.on('message_scheduled').listen((d) async {
        final m = MessageModel.fromJson(Map<String, dynamic>.from(d));
        if (!_belongsHere(m)) return;
        final msg = await _decrypted(m);
        if (isClosed) return;
        emit(state.copyWith(
          scheduled: [...state.scheduled.where((x) => x.id != msg.id), msg]
            ..sort((a, b) => a.scheduledAt!.compareTo(b.scheduledAt!)),
        ));
      }),
      chat.on('user_typing').listen((d) {
        final id = d['userId'] as int?;
        if (id == null || id == me.id) return;
        final here = group != null ? d['groupId'] == group!.id : (d['groupId'] == null && id == recipient?.id);
        if (!here) return;
        final ids = {...state.typingIds};
        d['isTyping'] == true ? ids.add(id) : ids.remove(id);
        emit(state.copyWith(typingIds: ids));
      }),
      chat.on('messages_read').listen((d) {
        if (recipient == null || d['readerId'] != recipient?.id) return;
        emit(state.copyWith(
          messages: [for (final m in state.messages) m.senderId == me.id ? m.copyWith(isRead: true) : m],
        ));
      }),
      chat.on('disappearing_changed').listen((d) {
        final here = group != null ? d['groupId'] == group!.id : (recipient != null && d['recipientId'] == recipient!.id);
        if (!here) return;
        final seconds = (d['seconds'] as num).toInt();
        final who = d['by'] == me.id ? 'You' : (group?.member(d['by'] as int)?.name ?? recipient?.name ?? 'Someone');
        emit(state.copyWith(
          disappearSeconds: seconds,
          notice: seconds == 0
              ? '$who turned off disappearing messages'
              : '$who set messages to disappear after ${disappearLabel(seconds)}',
        ));
      }),
      chat.on('message_viewed').listen((d) {
        final v = MessageModel.fromJson(Map<String, dynamic>.from(d));
        emit(state.copyWith(messages: [
          for (final m in state.messages)
            m.id == v.id ? m.copyWith(viewedAt: v.viewedAt, attachmentUrl: null, mediaKeys: null, mediaIv: null) : m,
        ]));
      }),
      chat.on('group_read').listen((d) {
        if (group == null || d['groupId'] != group!.id) return;
        emit(state.copyWith(readers: {...state.readers, d['userId'] as int: (d['lastReadId'] as num).toInt()}));
      }),
      chat.on('message_error').listen((d) {
        if (d is Map && d['error'] != null) emit(state.copyWith(error: d['error'].toString()));
      }),
    ]);
    chat.requestHistory(recipientId: recipient?.id, groupId: group?.id);
  }

  final UserModel? recipient;
  final GroupModel? group;
  final UserModel me;
  final ApiService api;
  final ChatService chat;
  final CryptoService crypto;
  final MessageSender sender;

  /// Latest friend / group data (keys change when people restore or switch phones).
  final UserModel? Function()? liveRecipient;
  final GroupModel? Function()? liveGroup;

  /// Re-fetches friends and groups; used once when a key is missing.
  final Future<void> Function()? refreshFriends;

  final List<StreamSubscription> _subs = [];
  bool _typing = false;
  bool _loadedOlder = false;
  final Map<int, Timer> _pendingDeletes = {};

  ChatTarget get _target => (
    user: recipient == null ? null : (liveRecipient?.call() ?? recipient),
    group: group == null ? null : (liveGroup?.call() ?? group),
  );

  bool _belongsHere(MessageModel m) {
    if (group != null) return m.groupId == group!.id;
    if (m.groupId != null) return false;
    final r = recipient;
    if (r == null) return m.recipientId == null;
    return (m.senderId == me.id && m.recipientId == r.id) || (m.senderId == r.id && m.recipientId == me.id);
  }

  Future<MessageModel> _decrypted(MessageModel m) async {
    try {
      return m.withBody(MessageEnvelope.decode(await crypto.decrypt(m.message, me.username, preferKey: '${me.id}')));
    } catch (_) {
      return m.copyWith(message: 'Couldn’t decrypt this message', isSending: false);
    }
  }

  Future<void> _onHistory(dynamic d) async {
    // Ignore a late history response for a chat the user already left
    if (d['recipientId'] != recipient?.id || d['groupId'] != group?.id) return;
    final raw = (d['messages'] as List).map((m) => MessageModel.fromJson(Map<String, dynamic>.from(m)));
    List<MessageModel> list(String key) =>
        [for (final m in d[key] as List? ?? const []) MessageModel.fromJson(Map<String, dynamic>.from(m))];
    final results = await Future.wait([
      Future.wait(raw.map(_decrypted)),
      Future.wait(list('pinned').map(_decrypted)),
      Future.wait(list('scheduled').map(_decrypted)),
    ]);
    if (isClosed) return;
    emit(state.copyWith(
      messages: results[0],
      pinned: results[1],
      scheduled: results[2],
      isLoading: false,
      searchingOlder: false,
      disappearSeconds: (d['disappearSeconds'] as num?)?.toInt() ?? 0,
      readers: {
        for (final r in d['readers'] as List? ?? const []) r['userId'] as int: (r['lastReadId'] as num).toInt(),
      },
    ));
  }

  /// Group members (not the sender) who have read [m].
  List<int> seenBy(MessageModel m) {
    final id = m.id;
    if (group == null || id == null) return const [];
    return [for (final e in state.readers.entries) if (e.key != m.senderId && e.value >= id) e.key];
  }

  Future<void> _onMessage(MessageModel m) async {
    if (!_belongsHere(m)) return;
    final msg = await _decrypted(m);
    if (isClosed) return;
    final list = [...state.messages];
    final i = list.indexWhere(
      (x) => (x.tempId != null && x.tempId == msg.tempId) || (x.id != null && x.id == msg.id),
    );
    if (i != -1) {
      list[i] = msg;
    } else {
      list.add(msg);
    }
    emit(state.copyWith(
      messages: list,
      typingIds: {...state.typingIds}..remove(m.senderId),
      scheduled: state.scheduled.where((x) => x.id != msg.id).toList(), // its time came
    ));
    if (recipient != null && m.senderId == recipient!.id) chat.markRead(recipient!.id);
    if (group != null && m.senderId != me.id) chat.markGroupRead(group!.id);
  }

  Future<void> _onEdited(MessageModel m) async {
    if (!_belongsHere(m)) return;
    final msg = await _decrypted(m);
    if (isClosed) return;
    MessageModel patch(MessageModel x) => x.id == msg.id
        ? x.copyWith(message: msg.message, linkPreview: msg.linkPreview, editedAt: msg.editedAt, isSending: false)
        : x;
    emit(state.copyWith(scheduled: state.scheduled.map(patch).toList()));
    emit(state.copyWith(messages: state.messages.map(patch).toList(), pinned: state.pinned.map(patch).toList()));
  }

  Future<void> _onPinned(MessageModel m) async {
    if (!_belongsHere(m)) return;
    final msg = await _decrypted(m);
    if (isClosed) return;
    final others = state.pinned.where((x) => x.id != msg.id);
    emit(state.copyWith(
      pinned: msg.pinned ? [msg, ...others] : others.toList(),
      messages: [for (final x in state.messages) x.id == msg.id ? x.copyWith(pinned: msg.pinned) : x],
    ));
  }

  void _drop(int id) => emit(state.copyWith(
    messages: state.messages.where((m) => m.id != id).toList(),
    pinned: state.pinned.where((m) => m.id != id).toList(),
    scheduled: state.scheduled.where((m) => m.id != id).toList(),
  ));

  void _onReaction(dynamic d) {
    final reactions = (d['reactions'] as List? ?? [])
        .map((r) => ReactionModel.fromJson(Map<String, dynamic>.from(r)))
        .toList();
    emit(state.copyWith(
      messages: [
        for (final m in state.messages) m.id == d['messageId'] ? m.copyWith(reactions: reactions) : m,
      ],
    ));
  }

  /// Keys can be missing right after someone sets up a phone; refetch once before giving up.
  Future<ChatTarget> _targetWithKeys() async {
    try {
      MessageSender.readerKeys(_target, me);
    } catch (_) {
      await refreshFriends?.call();
    }
    return _target;
  }

  Future<void> send(
    String text, {
    String? attachmentPath,
    MessageModel? replyTo,
    int? durationSec,
    PollData? poll,
    String? sticker,
    DateTime? sendAt,
    String? attachmentType,
    FileMeta? file,
    bool viewOnce = false,
  }) async {
    if (text.trim().isEmpty && attachmentPath == null && poll == null && sticker == null) return;
    attachmentType ??= attachmentPath == null
        ? null
        : (attachmentPath.toLowerCase().endsWith('.m4a') ? 'voice' : 'image');
    viewOnce = viewOnce && recipient != null && (attachmentType == 'image' || attachmentType == 'voice');
    final tempId = DateTime.now().microsecondsSinceEpoch.toString();

    if (sendAt != null) {
      // Nothing to show in the chat yet; the server echoes it into the scheduled list
      try {
        await sender.send(
          to: await _targetWithKeys(),
          me: me,
          text: text,
          tempId: tempId,
          attachmentPath: attachmentPath,
          attachmentType: attachmentType,
          poll: poll,
          sticker: sticker,
          durationSec: durationSec,
          sendAt: sendAt,
          file: file,
          viewOnce: viewOnce,
        );
      } catch (e) {
        emit(state.copyWith(error: 'Couldn’t schedule. ${_readable(e)}'));
      }
      return;
    }

    // Optimistic bubble first, so sending feels instant
    emit(state.copyWith(messages: [
      ...state.messages,
      MessageModel(
        sender: me.name,
        username: me.username,
        senderId: me.id,
        avatarUrl: me.avatarUrl,
        message: text,
        attachmentUrl: attachmentPath,
        attachmentType: attachmentType,
        timestamp: DateTime.now(),
        recipientId: recipient?.id,
        groupId: group?.id,
        tempId: tempId,
        isSending: true,
        replyToMessageId: replyTo?.id,
        replyToSender: replyTo?.sender,
        replyToMessage: replyTo?.message,
        poll: poll,
        sticker: sticker,
        durationSec: durationSec,
        file: file,
        viewOnce: viewOnce,
      ),
    ]));

    try {
      await sender.send(
        to: await _targetWithKeys(),
        me: me,
        text: text,
        tempId: tempId,
        attachmentPath: attachmentPath,
        attachmentType: attachmentType,
        replyToMessageId: replyTo?.id,
        replyToSender: replyTo?.sender,
        poll: poll,
        sticker: sticker,
        durationSec: durationSec,
        file: file,
        viewOnce: viewOnce,
      );
    } catch (e) {
      emit(state.copyWith(
        messages: state.messages.where((m) => m.tempId != tempId).toList(),
        error: 'Message not sent. ${_readable(e)}',
      ));
    }
  }

  /// Re-encrypts the new text for the same readers; the server only swaps the ciphertext.
  Future<void> edit(MessageModel m, String text) async {
    final id = m.id;
    if (id == null || text.trim().isEmpty || text == m.message) return;
    final before = state.messages;
    emit(state.copyWith(
      messages: [for (final x in before) x.id == id ? x.copyWith(message: text, editedAt: DateTime.now()) : x],
    ));
    try {
      final target = await _targetWithKeys();
      chat.editMessage(id, await sender.body(text, MessageSender.readerKeys(target, me), forwarded: m.forwarded));
    } catch (e) {
      emit(state.copyWith(messages: before, error: 'Couldn’t edit. ${_readable(e)}'));
    }
  }

  /// Tapping an option: single-choice polls switch your vote, multi-choice toggle it.
  void vote(MessageModel m, int option) {
    final id = m.id;
    if (id == null) return;
    final mine = m.pollVotes[me.id] ?? const [];
    final next = mine.contains(option)
        ? [for (final o in mine) if (o != option) o]
        : ((m.poll?.multi ?? false) ? [...mine, option] : [option]);
    // Optimistic; the server's poll_votes confirms
    emit(state.copyWith(
      messages: [
        for (final x in state.messages)
          x.id == id ? x.copyWith(pollVotes: {...x.pollVotes, me.id: next}..removeWhere((_, v) => v.isEmpty)) : x,
      ],
    ));
    chat.vote(id, next);
  }

  /// Either person (or any group member) can change the timer; new messages follow it.
  void setDisappearing(int seconds) {
    if (recipient == null && group == null) return;
    chat.setDisappearing(seconds, recipientId: recipient?.id, groupId: group?.id);
  }

  /// Downloads and decrypts a view-once photo / voice note, then tells the server it was
  /// opened (which deletes the file). Returns the local copy to show once.
  Future<String?> openViewOnce(MessageModel m) async {
    if (m.id == null || m.senderId == me.id || m.viewedAt != null || m.attachmentUrl == null) return null;
    try {
      final path = await _localCopy(m);
      chat.openViewOnce(m.id!);
      return path;
    } catch (e) {
      emit(state.copyWith(error: _readable(e)));
      return null;
    }
  }

  /// Decrypted copy of a video or document, for playing or opening on this phone.
  Future<String?> openFile(MessageModel m) async {
    try {
      return await _localCopy(m);
    } catch (e) {
      emit(state.copyWith(error: _readable(e)));
      return null;
    }
  }

  /// Sends the decrypted text with the report: the server can't read private chats.
  Future<String?> report(MessageModel m, String reason, {String? note}) async {
    if (m.id == null) return 'This message can’t be reported yet';
    final readable = !CryptoService.undecryptable.contains(m.message);
    return api.reportMessage(
      messageId: m.id!,
      reason: reason,
      note: note,
      content: readable ? [m.message, if (m.poll != null) 'Poll: ${m.poll!.question}', ?m.sticker].where((s) => s.trim().isNotEmpty).join('\n') : null,
    );
  }

  void cancelScheduled(MessageModel m) {
    if (m.id == null) return;
    _drop(m.id!);
    chat.deleteMessage(m.id!);
  }

  /// Hidden for me on every device; the other people keep it.
  void deleteForMe(MessageModel m) {
    if (m.id == null) return;
    _drop(m.id!);
    chat.hideMessage(m.id!);
  }

  void setPinned(MessageModel m, bool pinned) {
    if (m.id != null) chat.pinMessage(m.id!, pinned);
  }

  /// Search runs over decrypted messages on this phone; the first search pulls up to 500
  /// older messages so it isn't limited to the last screenful.
  void search(String query) {
    emit(state.copyWith(query: query));
    if (query.trim().isNotEmpty && !_loadedOlder) {
      _loadedOlder = true;
      emit(state.copyWith(searchingOlder: true));
      chat.requestHistory(recipientId: recipient?.id, groupId: group?.id, limit: 500);
    }
  }

  /// Sends a copy of [m] to [to], marked as forwarded. Photos are decrypted here and
  /// re-encrypted for the new readers; voice notes are forwarded the same way.
  Future<String?> forward(MessageModel m, ChatTarget to) async {
    try {
      String? path;
      if (m.attachmentUrl != null) path = await _localCopy(m);
      await sender.send(
        to: to,
        me: me,
        text: m.message,
        tempId: DateTime.now().microsecondsSinceEpoch.toString(),
        attachmentPath: path,
        attachmentType: m.attachmentType ?? (path == null ? null : 'image'),
        forwarded: true,
        poll: m.poll,
        sticker: m.sticker,
        durationSec: m.durationSec,
        file: m.file,
      );
      return null;
    } catch (e) {
      return 'Couldn’t forward. ${_readable(e)}';
    }
  }

  Future<String> _localCopy(MessageModel m) async {
    final url = m.attachmentUrl!;
    final res = await http.get(Uri.parse(url.startsWith('http') ? url : '${ApiService.baseUrl}$url'));
    if (res.statusCode != 200) throw Exception('Couldn’t download the attachment');
    var bytes = res.bodyBytes;
    if (m.mediaIv != null && m.mediaKeys != null) {
      final clear = await crypto.decryptMedia(
        encryptedBytes: bytes,
        ivBase64: m.mediaIv!,
        keys: m.mediaKeys!,
        username: me.username,
      );
      if (clear == null) throw Exception('Couldn’t open the attachment on this phone');
      bytes = clear;
    }
    final dir = await getTemporaryDirectory();
    if (m.file != null) {
      // Keep the real name (and extension) so the player / Quick Look knows what it is
      final safe = m.file!.name.replaceAll(RegExp(r'[^\w.\- ]'), '_');
      final folder = await Directory('${dir.path}/open_${DateTime.now().microsecondsSinceEpoch}').create();
      final out = File('${folder.path}/$safe');
      await out.writeAsBytes(bytes);
      return out.path;
    }
    final ext = m.isVoice ? 'm4a' : (m.isVideo ? 'mp4' : 'jpg');
    final file = File('${dir.path}/fwd_${DateTime.now().microsecondsSinceEpoch}.$ext');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  /// Removes locally now; really deletes after 5s unless [undoDelete] is called.
  void deleteWithUndo(MessageModel m) {
    final id = m.id;
    if (id == null) return;
    emit(state.copyWith(messages: state.messages.where((x) => x.id != id).toList()));
    _pendingDeletes[id] = Timer(const Duration(seconds: 5), () {
      chat.deleteMessage(id);
      _pendingDeletes.remove(id);
    });
  }

  void undoDelete(MessageModel m) {
    final timer = _pendingDeletes.remove(m.id);
    if (timer == null) return;
    timer.cancel();
    emit(state.copyWith(
      messages: [...state.messages, m]..sort((a, b) => a.timestamp.compareTo(b.timestamp)),
    ));
  }

  void react(MessageModel m, String emoji) {
    if (m.id != null) chat.react(m.id!, emoji);
  }

  /// Emits only on change, so calling it on every keystroke is cheap.
  void setTyping(bool typing) {
    if ((recipient == null && group == null) || typing == _typing) return;
    _typing = typing;
    chat.emitTyping(typing, recipientId: recipient?.id, groupId: group?.id);
  }

  static String disappearLabel(int s) => switch (s) {
    3600 => '1 hour',
    86400 => '1 day',
    604800 => '1 week',
    2592000 => '30 days',
    _ => '${s ~/ 60} minutes',
  };

  static String _readable(Object e) => e.toString().replaceFirst('Exception: ', '');

  @override
  Future<void> close() async {
    setTyping(false);
    // Leaving the chat shouldn't cancel deletes the user already confirmed
    for (final entry in _pendingDeletes.entries) {
      entry.value.cancel();
      chat.deleteMessage(entry.key);
    }
    for (final s in _subs) {
      await s.cancel();
    }
    return super.close();
  }
}

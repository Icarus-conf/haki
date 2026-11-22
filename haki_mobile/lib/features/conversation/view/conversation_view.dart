import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:video_player/video_player.dart';

import '../../../core/theme/haki_theme.dart';
import '../../../core/utils/format.dart';
import '../../../core/utils/platform.dart';
import '../../../core/widgets/glass.dart';
import '../../../models/group_model.dart';
import '../../../models/message_envelope.dart';
import '../../../models/message_model.dart';
import '../../../models/user_model.dart';
import '../../../services/api_service.dart';
import '../../../services/chat_lock.dart';
import '../../../services/chat_service.dart';
import '../../../services/crypto_service.dart';
import '../../../services/transcriber.dart';
import '../../../widgets/voice_recorder.dart';
import '../../call/view/call_view.dart';
import '../../friends/view_model/friends_cubit.dart';
import '../../groups/view/group_avatar.dart';
import '../../groups/view/group_info_sheet.dart';
import '../../session/view_model/session_cubit.dart';
import '../../settings/view_model/settings_cubit.dart';
import '../../call/view/group_call_view.dart';
import '../../call/view_model/group_call_cubit.dart';
import '../view_model/conversation_cubit.dart';
import 'chat_extras.dart';
import 'compose_extras.dart';
import 'forward_sheet.dart';
import 'message_bubble.dart';
import 'safety_number_sheet.dart';
import 'shared_media_view.dart';
import 'package:chat_mobile/core/theme/haki_icons.dart';

/// A private chat with [recipient], a [group] chat, or the public Haki Lounge when both are null.
class ConversationView extends StatelessWidget {
  const ConversationView({super.key, this.recipient, this.group, this.embedded = false});

  final UserModel? recipient;
  final GroupModel? group;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final friends = context.read<FriendsCubit>();
    return BlocProvider(
      create: (context) => ConversationCubit(
        recipient: recipient,
        group: group,
        me: context.read<SessionCubit>().me!,
        api: context.read<ApiService>(),
        chat: context.read<ChatService>(),
        crypto: context.read<CryptoService>(),
        liveRecipient: recipient == null ? null : () => friends.state.byId(recipient!.id),
        liveGroup: group == null ? null : () => friends.state.groupById(group!.id),
        refreshFriends: friends.load,
      ),
      child: _ConversationScreen(recipient: recipient, group: group, embedded: embedded),
    );
  }
}

class _ConversationScreen extends StatefulWidget {
  const _ConversationScreen({required this.recipient, required this.group, required this.embedded});
  final UserModel? recipient;
  final GroupModel? group;
  final bool embedded;

  @override
  State<_ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<_ConversationScreen> {
  final _text = TextEditingController();
  final _focus = FocusNode();
  final _searchText = TextEditingController();
  final _searchFocus = FocusNode();
  String? _attachment;
  MessageModel? _replyTo;
  MessageModel? _editing;

  /// "Send later" time for the next message, if chosen.
  DateTime? _sendAt;

  /// The next photo or voice note opens once (private chats only).
  bool _viewOnce = false;
  bool _searching = false;
  // Resolved in initState: dispose() must not look up ancestors
  late final FriendsCubit _friends;
  late final ConversationCubit _cubit;
  Timer? _typingIdle;

  bool get _isLounge => widget.recipient == null && widget.group == null;

  @override
  void initState() {
    super.initState();
    _friends = context.read<FriendsCubit>();
    _cubit = context.read<ConversationCubit>();
    if (widget.group != null) _friends.openGroup(widget.group!.id);
    // "typing…" follows actual keystrokes and stops after 4s idle, on send, or when cleared
    _text.addListener(() {
      final hasText = _text.text.trim().isNotEmpty;
      if (_editing == null) _cubit.setTyping(hasText);
      _typingIdle?.cancel();
      if (hasText) _typingIdle = Timer(const Duration(seconds: 4), () => _cubit.setTyping(false));
    });
  }

  @override
  void dispose() {
    _typingIdle?.cancel();
    if (widget.recipient != null) _friends.closeChat();
    if (widget.group != null) _friends.closeGroup();
    _text.dispose();
    _focus.dispose();
    _searchText.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _send() {
    final text = _text.text.trim();
    if (_editing != null) {
      _cubit.edit(_editing!, text);
    } else {
      _cubit.send(
        text,
        attachmentPath: _attachment,
        replyTo: _replyTo,
        sendAt: _sendAt,
        viewOnce: _viewOnce && _attachment != null,
      );
      if (_attachment != null) _viewOnce = false;
      if (_sendAt != null) showHakiToast(context, 'Scheduled for ${sendTimeLabel(_sendAt!)}');
    }
    _text.clear();
    setState(() {
      _attachment = null;
      _replyTo = null;
      _editing = null;
      _sendAt = null;
    });
  }

  /// [gif]: no resizing, so the picker keeps the animation.
  Future<void> _pickImage({bool gif = false}) async {
    final img = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: gif ? null : 2048);
    if (img != null) setState(() => _attachment = img.path);
  }

  Future<void> _openAttachMenu() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (sheet) => SafeArea(
        child: SizedBox(
          width: double.infinity, // full width, not shrunk to the icons
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Wrap(
              alignment: WrapAlignment.spaceEvenly,
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final (id, icon, label) in [
                  ('photo', HakiIcons.image, 'Photo'),
                  ('gif', HakiIcons.gif, 'GIF'),
                  ('sticker', HakiIcons.smiley, 'Sticker'),
                  // ponytail: videos and files are path-based; the web gets them once the media layer reads bytes
                  if (!kIsWeb) ('video', HakiIcons.videoCamera, 'Video'),
                  if (!kIsWeb) ('file', HakiIcons.paperclip, 'File'),
                  ('poll', HakiIcons.chartBar, 'Poll'),
                  ('later', HakiIcons.clockCountdown, 'Send later'),
                  if (widget.recipient != null) ('once', HakiIcons.numberCircleOne, 'View once'),
                ])
                  SizedBox(
                    width: 96,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => Navigator.pop(sheet, id),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundColor: HakiColors.surfaceHigh,
                              foregroundColor: HakiColors.lime,
                              child: Icon(icon),
                            ),
                            const SizedBox(height: 6),
                            Text(label, style: const TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    if (!mounted || choice == null) return;
    switch (choice) {
      case 'photo':
        await _pickImage();
      case 'gif':
        await _pickImage(gif: true);
      case 'sticker':
        final sticker = await StickerSheet.pick(context);
        if (sticker != null) _cubit.send('', sticker: sticker, sendAt: _sendAt);
        setState(() => _sendAt = null);
      case 'poll':
        final poll = await PollComposerSheet.show(context);
        if (poll != null) _cubit.send('', poll: poll, sendAt: _sendAt);
        setState(() => _sendAt = null);
      case 'video':
        final v = await ImagePicker().pickVideo(source: ImageSource.gallery);
        if (v != null) await _sendFile(v.path, v.name, 'video');
      case 'file':
        final files = await FilePicker.pickFiles();
        final f = files.isEmpty ? null : files.first;
        if (f?.path != null) await _sendFile(f!.path!, f.name, 'file');
      case 'once':
        setState(() => _viewOnce = true);
        showHakiToast(context, 'Your next photo or voice note can be opened once');
      case 'later':
        final at = await pickSendTime(context);
        if (at != null && mounted) {
          setState(() => _sendAt = at);
          _focus.requestFocus();
        }
    }
  }

  static const _maxFileBytes = 50 * 1024 * 1024;

  /// Videos and documents are encrypted like photos; their name and size travel encrypted.
  Future<void> _sendFile(String path, String name, String type) async {
    final size = await File(path).length();
    if (!mounted) return;
    if (size > _maxFileBytes) {
      showHakiToast(context, 'Files can be up to 50 MB', isError: true);
      return;
    }
    int? seconds;
    if (type == 'video') {
      // The picker's temp name means nothing to the reader; send "Video" and its length
      name = 'Video${name.contains('.') ? name.substring(name.lastIndexOf('.')) : '.mp4'}';
      final probe = VideoPlayerController.file(File(path));
      try {
        await probe.initialize();
        seconds = probe.value.duration.inSeconds;
      } catch (_) {
      } finally {
        await probe.dispose();
      }
    }
    _cubit.send(
      '',
      attachmentPath: path,
      attachmentType: type,
      file: FileMeta(name: name, size: size),
      durationSec: seconds,
      sendAt: _sendAt,
    );
    setState(() => _sendAt = null);
  }

  Future<void> _openViewOnce(MessageModel m) async {
    final path = await _cubit.openViewOnce(m);
    if (path != null && mounted) await ViewOnceViewer.show(context, m, path);
  }

  Future<void> _openFile(MessageModel m) async {
    final path = await _cubit.openFile(m);
    if (path == null || !mounted) return;
    if (m.isVideo) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VideoPlayerView(path: path, title: 'Video from ${m.sender}'),
        ),
      );
      return;
    }
    final r = await OpenFilex.open(path);
    if (r.type != ResultType.done && mounted) showHakiToast(context, 'No app here can open this file', isError: true);
  }

  Future<void> _report(MessageModel m) async {
    final picked = await ReportSheet.show(context);
    if (picked == null || !mounted) return;
    final error = await _cubit.report(m, picked.$1, note: picked.$2);
    if (!mounted) return;
    showHakiToast(context, error ?? 'Reported. Thanks for keeping Haki safe.', isError: error != null);
  }

  void _showScheduled(List<MessageModel> scheduled) {
    showModalBottomSheet(
      context: context,
      builder: (sheet) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: 12),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text('Scheduled', style: HakiText.display(26)),
            ),
            for (final m in scheduled)
              ListTile(
                leading: const Icon(HakiIcons.clockCountdown, color: HakiColors.lime),
                title: Text(
                  m.poll != null
                      ? 'Poll: ${m.poll!.question}'
                      : m.sticker ?? (m.message.isNotEmpty ? m.message : (m.isVoice ? 'Voice message' : 'Photo')),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  'Sends ${sendTimeLabel(m.scheduledAt!.toLocal())}',
                  style: const TextStyle(color: HakiColors.textMuted),
                ),
                trailing: TextButton(
                  onPressed: () {
                    Navigator.pop(sheet);
                    _cubit.cancelScheduled(m);
                    showHakiToast(context, 'Scheduled message cancelled');
                  },
                  child: const Text('Cancel'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _startEdit(MessageModel m) {
    setState(() {
      _editing = m;
      _replyTo = null;
      _attachment = null;
    });
    _text.text = m.message;
    _text.selection = TextSelection.collapsed(offset: _text.text.length);
    _focus.requestFocus();
  }

  void _cancelEdit() {
    setState(() => _editing = null);
    _text.clear();
  }

  void _setSearching(bool on) {
    setState(() => _searching = on);
    // autofocus won't move focus away from the composer, so ask for it explicitly
    if (on) WidgetsBinding.instance.addPostFrameCallback((_) => _searchFocus.requestFocus());
    if (!on) {
      _searchText.clear();
      _cubit.search('');
    }
  }

  Future<void> _forward(MessageModel m) async {
    final to = await ForwardSheet.pick(context);
    if (to == null || !mounted) return;
    final error = await _cubit.forward(m, to);
    if (!mounted) return;
    final name = to.group?.name ?? to.user?.name ?? 'the Lounge';
    showHakiToast(context, error ?? 'Forwarded to $name', isError: error != null);
  }

  /// "Seen by Ben, Carol" for my message in a group.
  Widget _seenBy(MessageModel m) {
    final g = _cubit.group!;
    final names = [for (final id in _cubit.seenBy(m)) g.member(id)?.name.split(' ').first].whereType<String>().toList();
    final everyone = names.length >= g.members.length - 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        children: [
          Icon(
            names.isEmpty ? HakiIcons.check : HakiIcons.checks,
            size: 18,
            color: names.isEmpty ? HakiColors.textMuted : HakiColors.lime,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              names.isEmpty
                  ? 'Not seen yet'
                  : everyone
                  ? 'Seen by everyone'
                  : 'Seen by ${names.join(', ')}',
              style: const TextStyle(color: HakiColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _translate(MessageModel m) async {
    try {
      final (text, from) = await Translator.translate(m.message);
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        builder: (_) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Translated from $from', style: const TextStyle(color: HakiColors.textMuted, fontSize: 13)),
                const SizedBox(height: 10),
                SelectableText(text, style: const TextStyle(fontSize: 18, height: 1.4)),
                const SizedBox(height: 14),
                const Row(
                  children: [
                    Icon(HakiIcons.lockFill, size: 14, color: HakiColors.lime),
                    SizedBox(width: 6),
                    Text('Translated on this phone', style: TextStyle(color: HakiColors.textMuted, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (mounted) showHakiToast(context, e.toString().replaceFirst('Exception: ', ''), isError: true);
    }
  }

  void _showActions(MessageModel m, bool isMe) {
    final readable = !CryptoService.undecryptable.contains(m.message);
    final canPin = !_isLounge && m.id != null;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // tall enough for every action, not cut at half the screen
      builder: (sheet) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isMe && _cubit.group != null && m.id != null) _seenBy(m),
              if (m.id != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      for (final e in const ['👍', '❤️', '😂', '😮', '😢', '🙏'])
                        IconButton(
                          tooltip: 'React $e',
                          onPressed: () {
                            Navigator.pop(sheet);
                            _cubit.react(m, e);
                          },
                          style: IconButton.styleFrom(
                            backgroundColor: HakiColors.surfaceHigh,
                            fixedSize: const Size(48, 48),
                          ),
                          icon: Text(e, style: const TextStyle(fontSize: 22)),
                        ),
                    ],
                  ),
                ),
              _action(sheet, HakiIcons.arrowBendUpLeft, 'Reply', () {
                setState(() {
                  _replyTo = m;
                  _editing = null;
                });
                _focus.requestFocus();
              }),
              if (isMe && m.id != null && m.message.trim().isNotEmpty && !m.isVoice && m.poll == null && readable)
                _action(sheet, HakiIcons.pencilSimple, 'Edit', () => _startEdit(m)),
              if (m.message.trim().isNotEmpty && readable && !m.viewOnce)
                _action(sheet, HakiIcons.copy, 'Copy', () {
                  Clipboard.setData(ClipboardData(text: m.message));
                  showHakiToast(context, 'Copied');
                }),
              if (m.id != null && readable && !m.viewOnce)
                _action(sheet, HakiIcons.arrowBendUpRight, 'Forward', () => _forward(m)),
              if (!isMe && Translator.supported && readable && m.message.trim().isNotEmpty && m.poll == null)
                _action(sheet, HakiIcons.translate, 'Translate', () => _translate(m)),
              if (canPin)
                _action(
                  sheet,
                  m.pinned ? HakiIcons.pushPin : HakiIcons.pushPinFill,
                  m.pinned ? 'Unpin' : 'Pin for everyone here',
                  () => _cubit.setPinned(m, !m.pinned),
                ),
              if (m.id != null)
                _action(sheet, HakiIcons.eyeSlash, 'Delete for me', () {
                  _cubit.deleteForMe(m);
                  showHakiToast(context, 'Deleted for you');
                }),
              if (!isMe && m.id != null) _action(sheet, HakiIcons.flag, 'Report', () => _report(m)),
              if (isMe && m.id != null)
                _action(sheet, HakiIcons.trash, 'Delete for everyone', () {
                  _cubit.deleteWithUndo(m);
                  showHakiToast(context, 'Message deleted', onUndo: () => _cubit.undoDelete(m));
                }, danger: true),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _action(BuildContext sheet, IconData icon, String label, VoidCallback onTap, {bool danger = false}) {
    return ListTile(
      leading: Icon(icon, color: danger ? HakiColors.dangerText : null),
      title: Text(label, style: danger ? const TextStyle(color: HakiColors.dangerText) : null),
      onTap: () {
        Navigator.pop(sheet);
        onTap();
      },
    );
  }

  /// Lounge: people you can @mention — your friends plus anyone who spoke here.
  List<UserModel> _mentionCandidates(UserModel me) {
    final seen = <String, UserModel>{};
    for (final f in _friends.state.friends) {
      seen[f.username] = f;
    }
    for (final m in _cubit.state.messages.reversed) {
      if (m.senderId != me.id) {
        seen.putIfAbsent(
          m.username,
          () => UserModel(id: m.senderId, username: m.username, displayName: m.sender, avatarUrl: m.avatarUrl),
        );
      }
    }
    return seen.values.toList();
  }

  void _insertMention(UserModel u) {
    final text = _text.text;
    final at = text.lastIndexOf('@');
    if (at == -1) return;
    final next = '${text.substring(0, at)}@${u.username} ';
    _text.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final me = context.select((SessionCubit c) => c.state.me)!;
    // Live friend / group data (status, key changes, members) when available
    final recipient = widget.recipient == null
        ? null
        : context.select((FriendsCubit c) => c.state.byId(widget.recipient!.id)) ?? widget.recipient;
    final group = widget.group == null
        ? null
        : context.select((FriendsCubit c) => c.state.groupById(widget.group!.id)) ?? widget.group;
    final online = recipient != null && context.select((FriendsCubit c) => c.state.onlineIds.contains(recipient.id));
    final pinned = context.select((ConversationCubit c) => c.state.pinned);
    final showPinned = pinned.isNotEmpty && !_searching;
    final scheduled = context.select((ConversationCubit c) => c.state.scheduled);
    final composerBar = _replyTo != null || _attachment != null || _editing != null;
    final extraBottom =
        (composerBar ? 64.0 : 0.0) +
        (_sendAt != null ? 44.0 : 0.0) +
        (scheduled.isNotEmpty ? 44.0 : 0.0) +
        (_viewOnce ? 44.0 : 0.0);
    final timer = context.select((ConversationCubit c) => c.state.disappearSeconds);
    final showTimer = timer > 0 && !_searching;
    final keyChanged =
        recipient != null &&
        !_searching &&
        context.select((SettingsCubit c) => c.state.keyChanged.contains(recipient.id));
    final callPeople = group == null
        ? const <int>[]
        : context.select((GroupCallCubit c) => c.state.active[group.id] ?? const <int>[]);
    final showCall = callPeople.isNotEmpty && !callPeople.contains(me.id) && !_searching;

    return MultiBlocListener(
      listeners: [
        BlocListener<ConversationCubit, ConversationState>(
          listenWhen: (a, b) => b.error != null && a.error != b.error,
          listener: (context, s) => showHakiToast(context, s.error!, isError: true),
        ),
        BlocListener<ConversationCubit, ConversationState>(
          listenWhen: (a, b) => b.notice != null && a.notice != b.notice,
          listener: (context, s) => showHakiToast(context, s.notice!),
        ),
      ],
      child: Scaffold(
        // expand: every child here is positioned, so without it the Stack would only be as
        // tall as the colour field and the composer would float mid-screen
        body: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: AuroraBackground(
                height: 300,
                fadeStart: 0.0,
                colors: [
                  group != null
                      ? HakiColors.auraFor(group.id + 3)[1]
                      : recipient == null
                      ? HakiColors.teal
                      : HakiColors.auraFor(recipient.id)[1],
                  HakiColors.blue,
                ],
              ),
            ),
            Positioned.fill(
              child: _MessageList(
                me: me,
                recipient: recipient,
                group: group,
                searching: _searching,
                extraTop: (showPinned ? 56 : 0) + (showTimer ? 40 : 0) + (keyChanged ? 48 : 0) + (showCall ? 48 : 0),
                extraBottom: extraBottom,
                onLongPress: _showActions,
                onOpenViewOnce: _openViewOnce,
                onOpenFile: _openFile,
                onReply: (m) {
                  setState(() {
                    _replyTo = m;
                    _editing = null;
                  });
                  _focus.requestFocus();
                },
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              top: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Column(
                    children: [
                      _searching
                          ? _SearchBar(
                              controller: _searchText,
                              focus: _searchFocus,
                              onChanged: _cubit.search,
                              onClose: () => _setSearching(false),
                            )
                          : _Header(
                              recipient: recipient,
                              group: group,
                              me: me,
                              online: online,
                              embedded: widget.embedded,
                              onSearch: () => _setSearching(true),
                            ),
                      if (showTimer)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: GestureDetector(
                            onTap: () async {
                              final s = await DisappearingSheet.pick(context, timer);
                              if (s != null && s != timer) _cubit.setDisappearing(s);
                            },
                            child: Glass(
                              radius: 16,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(HakiIcons.timer, size: 16, color: HakiColors.lime),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Messages disappear after ${ConversationCubit.disappearLabel(timer)}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      if (keyChanged)
                        _Banner(
                          icon: HakiIcons.key,
                          text: '${recipient.name}’s safety number changed',
                          action: 'Check',
                          onTap: () {
                            context.read<SettingsCubit>().acknowledgeKey(recipient.id);
                            SafetyNumberSheet.show(context, me: me, friend: recipient);
                          },
                        ),
                      if (showCall)
                        _Banner(
                          icon: HakiIcons.phoneFill,
                          text: '${callPeople.length} in a call',
                          action: 'Join',
                          onTap: () => GroupCallView.open(context, group!, me),
                        ),
                      if (showPinned) ...[
                        const SizedBox(height: 8),
                        _PinnedBar(pinned: pinned, onUnpin: (m) => _cubit.setPinned(m, false)),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 0,
              child: SafeArea(
                top: false,
                minimum: const EdgeInsets.only(bottom: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isLounge)
                      _MentionSuggestions(
                        controller: _text,
                        candidates: () => _mentionCandidates(me),
                        onPick: _insertMention,
                      ),
                    if (scheduled.isNotEmpty && _editing == null)
                      _Pill(
                        icon: HakiIcons.clockCountdown,
                        label: scheduled.length == 1
                            ? '1 scheduled · ${sendTimeLabel(scheduled.first.scheduledAt!.toLocal())}'
                            : '${scheduled.length} scheduled',
                        onTap: () => _showScheduled(scheduled),
                      ),
                    if (_viewOnce && _editing == null)
                      _Pill(
                        icon: HakiIcons.numberCircleOne,
                        label: 'View once · next photo or voice note',
                        onClose: () => setState(() => _viewOnce = false),
                      ),
                    if (_sendAt != null && _editing == null)
                      _Pill(
                        icon: HakiIcons.clock,
                        label: 'Next message sends ${sendTimeLabel(_sendAt!)}',
                        onClose: () => setState(() => _sendAt = null),
                      ),
                    _Composer(
                      controller: _text,
                      focus: _focus,
                      attachment: _attachment,
                      replyTo: _replyTo,
                      editing: _editing,
                      onCancelAttachment: () => setState(() => _attachment = null),
                      onCancelReply: () => setState(() => _replyTo = null),
                      onCancelEdit: _cancelEdit,
                      onPickImage: _openAttachMenu,
                      onSend: _send,
                      onVoice: (path, length) => _cubit.send(
                        '',
                        attachmentPath: path,
                        durationSec: length.inSeconds.clamp(1, 3600),
                        sendAt: _sendAt,
                        viewOnce: _viewOnce,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList({
    required this.me,
    required this.recipient,
    required this.group,
    required this.searching,
    required this.onLongPress,
    required this.onReply,
    required this.onOpenViewOnce,
    required this.onOpenFile,
    this.extraTop = 0,
    this.extraBottom = 0,
  });

  final ValueChanged<MessageModel> onOpenViewOnce;
  final Future<void> Function(MessageModel) onOpenFile;

  /// Room for the pinned bar / reply bar, so they never cover a message.
  final double extraTop;
  final double extraBottom;

  final UserModel me;
  final UserModel? recipient;
  final GroupModel? group;
  final bool searching;
  final void Function(MessageModel, bool isMe) onLongPress;
  final ValueChanged<MessageModel> onReply;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ConversationCubit>().state;
    final cubit = context.read<ConversationCubit>();
    final topInset = MediaQuery.paddingOf(context).top + 72 + extraTop;
    final bottomInset = MediaQuery.paddingOf(context).bottom + 96 + extraBottom;
    final isLounge = recipient == null && group == null;

    if (state.isLoading) return const Center(child: CircularProgressIndicator(strokeWidth: 2));

    final query = searching ? state.query.trim() : '';
    final msgs = (query.isEmpty ? state.messages : state.searchResults).reversed.toList(); // newest first
    final byId = {
      for (final m in state.messages)
        if (m.id != null) m.id!: m,
    };
    final typingId = state.typingIds.isEmpty ? null : state.typingIds.first;
    final typingUser = typingId == null ? null : (group?.member(typingId) ?? recipient);
    final typing = typingUser != null && !searching;

    if (query.isNotEmpty && msgs.isEmpty) {
      return Center(
        child: Text(
          state.searchingOlder ? 'Searching older messages…' : 'No messages match “$query”',
          style: const TextStyle(color: HakiColors.textMuted),
        ),
      );
    }

    if (msgs.isEmpty && !typing) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(isLounge ? HakiIcons.chats : HakiIcons.lockFill, size: 36, color: HakiColors.lime),
              const SizedBox(height: 12),
              Text(
                isLounge
                    ? 'The Lounge is public. Say hello to everyone.'
                    : group != null
                    ? 'Messages in ${group!.name} are end-to-end encrypted. Say hi!'
                    : 'Messages with ${recipient!.name} are end-to-end encrypted. Say hi!',
                textAlign: TextAlign.center,
                style: const TextStyle(color: HakiColors.textMuted, height: 1.4),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      reverse: true,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      // Padding is physical even in a reversed list: bottom clears the composer, top the header
      padding: EdgeInsets.fromLTRB(14, topInset, 14, bottomInset),
      itemCount: msgs.length + (typing ? 1 : 0) + 1, // +1 for the privacy note at the top
      itemBuilder: (context, index) {
        if (typing && index == 0) return TypingBubble(user: typingUser);
        final i = index - (typing ? 1 : 0);
        if (i == msgs.length) return _PrivacyNote(recipient: recipient, group: group);

        final m = msgs[i];
        final older = i + 1 < msgs.length ? msgs[i + 1] : null;
        final isMe = m.senderId == me.id;
        final newDay = older == null || dayLabel(older.timestamp) != dayLabel(m.timestamp);
        final grouped = !newDay && older.senderId == m.senderId && query.isEmpty;

        return Column(
          children: [
            if (newDay)
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 4),
                child: Text(
                  dayLabel(m.timestamp),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: HakiColors.textMuted),
                ),
              ),
            Dismissible(
              key: ValueKey('msg_${m.id ?? m.tempId}'),
              direction: DismissDirection.startToEnd,
              confirmDismiss: (_) async {
                onReply(m);
                return false;
              },
              background: const Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(HakiIcons.arrowBendUpLeft, color: HakiColors.lime),
                ),
              ),
              child: Align(
                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                child: MessageBubble(
                  // Groups: double tick once every other member has read it
                  message: isMe && cubit.group != null && m.id != null
                      ? m.copyWith(isRead: cubit.seenBy(m).length >= cubit.group!.members.length - 1)
                      : m,
                  isMe: isMe,
                  myId: me.id,
                  myUsername: me.username,
                  groupedWithPrevious: grouped,
                  showSenderName: recipient == null && !isMe && !grouped,
                  highlight: query.isEmpty ? null : query,
                  onLongPress: () => onLongPress(m, isMe),
                  onReactionTap: (emoji) => cubit.react(m, emoji),
                  onVote: (i) => cubit.vote(m, i),
                  quotedText: m.replyToMessageId == null ? null : byId[m.replyToMessageId]?.message,
                  onOpenViewOnce: () => onOpenViewOnce(m),
                  onOpenFile: () => onOpenFile(m),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote({required this.recipient, required this.group});
  final UserModel? recipient;
  final GroupModel? group;

  @override
  Widget build(BuildContext context) {
    final lounge = recipient == null && group == null;
    return Center(
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(color: HakiColors.surface, borderRadius: BorderRadius.circular(14)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(lounge ? HakiIcons.globeHemisphereWest : HakiIcons.lockFill, size: 13, color: HakiColors.textMuted),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                lounge
                    ? 'Public room · anyone on Haki can read'
                    : group != null
                    ? 'Only the ${group!.members.length} people in this group can read it'
                    : 'Only you and ${recipient!.name} can read this chat',
                style: const TextStyle(fontSize: 12, color: HakiColors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.focus, required this.onChanged, required this.onClose});
  final TextEditingController controller;
  final FocusNode focus;
  final ValueChanged<String> onChanged;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: 24,
      padding: const EdgeInsets.only(left: 14, right: 4),
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            Icon(HakiIcons.magnifyingGlass, color: Colors.white.withValues(alpha: 0.75)),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focus,
                onChanged: onChanged,
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  hintText: 'Search this chat',
                  filled: false,
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),
            IconButton(tooltip: 'Close search', icon: const Icon(HakiIcons.x), onPressed: onClose),
          ],
        ),
      ),
    );
  }
}

class _PinnedBar extends StatelessWidget {
  const _PinnedBar({required this.pinned, required this.onUnpin});
  final List<MessageModel> pinned;
  final ValueChanged<MessageModel> onUnpin;

  static String _label(MessageModel m) =>
      m.message.trim().isNotEmpty ? m.message : (m.isVoice ? 'Voice message' : 'Photo');

  @override
  Widget build(BuildContext context) {
    final top = pinned.first;
    return Semantics(
      button: true,
      label: 'Pinned messages',
      child: GestureDetector(
        onTap: () => showModalBottomSheet(
          context: context,
          builder: (sheet) => SafeArea(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: 12),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Text('Pinned', style: HakiText.display(26)),
                ),
                for (final m in pinned)
                  ListTile(
                    leading: const Icon(HakiIcons.pushPinFill, color: HakiColors.lime),
                    title: Text(_label(m), maxLines: 2, overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                      '${m.sender} · ${dayLabel(m.timestamp)}',
                      style: const TextStyle(color: HakiColors.textMuted),
                    ),
                    trailing: TextButton(
                      onPressed: () {
                        Navigator.pop(sheet);
                        onUnpin(m);
                      },
                      child: const Text('Unpin'),
                    ),
                  ),
              ],
            ),
          ),
        ),
        child: Glass(
          radius: 20,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              const Icon(HakiIcons.pushPinFill, size: 18, color: HakiColors.lime),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _label(top),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              if (pinned.length > 1)
                Text('+${pinned.length - 1}', style: const TextStyle(fontSize: 12, color: HakiColors.textMuted)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.recipient,
    required this.group,
    required this.me,
    required this.online,
    required this.embedded,
    required this.onSearch,
  });

  final UserModel? recipient;
  final GroupModel? group;
  final UserModel me;
  final bool online;
  final bool embedded;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final typingIds = context.select((ConversationCubit c) => c.state.typingIds);
    final locked = context.select((SettingsCubit c) => c.state.lockedChats.contains(_lockKey));
    final typing = typingIds.isNotEmpty;
    final g = group;
    final String subtitle;
    if (g != null) {
      final names = [for (final id in typingIds) g.member(id)?.name.split(' ').first].whereType<String>();
      subtitle = names.isEmpty
          ? '${g.members.length} people · encrypted'
          : '${names.join(', ')} ${names.length == 1 ? 'is' : 'are'} typing…';
    } else if (recipient == null) {
      subtitle = 'Public room';
    } else if (typing) {
      subtitle = 'typing…';
    } else if (recipient!.daysToBirthday(DateTime.now()) == 0) {
      subtitle = '🎂 Birthday today';
    } else if (online) {
      subtitle = 'online';
    } else {
      subtitle = (recipient!.statusMessage?.isNotEmpty ?? false) ? recipient!.statusMessage! : 'Encrypted';
    }

    return Row(
      children: [
        if (!embedded) ...[
          GlassIconButton(icon: HakiIcons.arrowLeft, tooltip: 'Back', onPressed: () => Navigator.pop(context)),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Glass(
            radius: 24,
            padding: const EdgeInsets.all(6),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: g == null ? null : () => _onMenu(context, 'group'),
                    child: Row(
                      children: [
                        if (g != null)
                          GroupAvatar(group: g, size: 36, radius: 13)
                        else if (recipient != null)
                          AuraAvatar(user: recipient!, size: 36, radius: 13)
                        else
                          Container(
                            width: 36,
                            height: 36,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(13),
                              gradient: RadialGradient(colors: HakiColors.auras[4]),
                            ),
                            child: Text('#', style: HakiText.display(16)),
                          ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                g?.name ?? recipient?.name ?? 'Haki Lounge',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                              ),
                              Text(
                                subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: (online || typing) ? HakiColors.lime : Colors.white.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'More',
                  icon: const Icon(HakiIcons.dotsThree),
                  color: HakiColors.surfaceHigh,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  onSelected: (v) => _onMenu(context, v),
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'search', child: Text('Search')),
                    if (g != null) const PopupMenuItem(value: 'group', child: Text('Group info')),
                    if (g != null || recipient != null) ...[
                      const PopupMenuItem(value: 'timer', child: Text('Disappearing messages')),
                      PopupMenuItem(value: 'lock', child: Text(locked ? 'Unlock chat' : 'Lock chat')),
                    ],
                    if (recipient != null) ...const [
                      PopupMenuItem(value: 'note', child: Text('Private note')),
                      PopupMenuItem(value: 'verify', child: Text('Verify safety number')),
                      PopupMenuItem(value: 'media', child: Text('Shared photos')),
                      PopupMenuItem(
                        value: 'block',
                        child: Text('Block', style: TextStyle(color: HakiColors.dangerText)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
        if (g != null) ...[
          const SizedBox(width: 8),
          GlassIconButton(
            icon: HakiIcons.phoneFill,
            tooltip: 'Group call',
            onPressed: () => GroupCallView.open(context, g, me),
          ),
        ],
        if (recipient != null) ...[
          const SizedBox(width: 8),
          GlassIconButton(
            icon: HakiIcons.videoCamera,
            tooltip: 'Video call',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CallView(peerId: recipient!.id, outgoing: true, video: true)),
            ),
          ),
          const SizedBox(width: 8),
          GlassIconButton(
            icon: HakiIcons.phoneFill,
            tooltip: 'Voice call',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CallView(peerId: recipient!.id, outgoing: true)),
            ),
          ),
        ],
      ],
    );
  }

  String get _lockKey =>
      group != null ? ChatFolder.groupKey(group!.id) : (recipient != null ? ChatFolder.userKey(recipient!.id) : '');

  Future<void> _onMenu(BuildContext context, String value) async {
    switch (value) {
      case 'timer':
        final cubit = context.read<ConversationCubit>();
        final s = await DisappearingSheet.pick(context, cubit.state.disappearSeconds);
        if (s != null && s != cubit.state.disappearSeconds) cubit.setDisappearing(s);
      case 'lock':
        final settings = context.read<SettingsCubit>();
        final locking = !settings.state.lockedChats.contains(_lockKey);
        if (!await ChatLock.available()) {
          if (context.mounted) {
            showHakiToast(context, 'Set up Face ID or a passcode on this device first', isError: true);
          }
          return;
        }
        if (!await ChatLock.unlock(locking ? 'Lock this chat' : 'Unlock this chat')) return;
        await settings.toggleLock(_lockKey);
        if (context.mounted) {
          showHakiToast(context, locking ? 'Locked. It’s now under Locked chats.' : 'Chat unlocked');
        }
      case 'search':
        onSearch();
      case 'group':
        final left = await GroupInfoSheet.show(context, group!);
        if (left && context.mounted && !embedded) Navigator.pop(context);
      case 'verify':
        context.read<SettingsCubit>().acknowledgeKey(recipient!.id);
        SafetyNumberSheet.show(context, me: me, friend: recipient!);
      case 'note':
        NoteSheet.show(context, recipient!);
      case 'media':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SharedMediaView(recipientId: recipient!.id, recipientName: recipient!.name),
          ),
        );
      case 'block':
        final r = recipient!;
        final sure = await confirmAction(
          context,
          title: 'Block ${r.name}?',
          message: 'They won’t be able to message or call you.',
          action: 'Block',
        );
        if (!sure || !context.mounted) return;
        final ok = await context.read<FriendsCubit>().block(r.id);
        if (!context.mounted) return;
        showHakiToast(context, ok ? 'Blocked ${r.name}' : 'Couldn’t block', isError: !ok);
        if (ok && !embedded) Navigator.pop(context);
    }
  }
}

/// Lounge: typing "@an" offers matching people; tapping one completes the name.
class _MentionSuggestions extends StatelessWidget {
  const _MentionSuggestions({required this.controller, required this.candidates, required this.onPick});
  final TextEditingController controller;
  final List<UserModel> Function() candidates;
  final ValueChanged<UserModel> onPick;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (context, value, _) {
        final match = RegExp(r'(?:^|\s)@([A-Za-z0-9_.]*)$').firstMatch(value.text);
        if (match == null) return const SizedBox.shrink();
        final q = match.group(1)!.toLowerCase();
        final people = candidates()
            .where((u) => u.username.toLowerCase().startsWith(q) || u.name.toLowerCase().startsWith(q))
            .take(5)
            .toList();
        if (people.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Glass(
            radius: 22,
            padding: const EdgeInsets.symmetric(vertical: 4),
            // ListTile ink needs a Material between it and the glass decoration
            child: Material(
              type: MaterialType.transparency,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final u in people)
                    ListTile(
                      dense: true,
                      leading: AuraAvatar(user: u, size: 30, radius: 11),
                      title: Text(u.name),
                      subtitle: Text('@${u.username}', style: const TextStyle(color: HakiColors.textMuted)),
                      onTap: () => onPick(u),
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

/// Small glass row above the composer (scheduled messages, "send later" time).
class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label, this.onTap, this.onClose});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Glass(
          radius: 18,
          padding: EdgeInsets.fromLTRB(14, onClose == null ? 9 : 2, onClose == null ? 14 : 2, onClose == null ? 9 : 2),
          child: Row(
            children: [
              Icon(icon, size: 18, color: HakiColors.lime),
              const SizedBox(width: 8),
              Expanded(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis)),
              if (onClose != null)
                IconButton(tooltip: 'Cancel', icon: const Icon(HakiIcons.x, size: 18), onPressed: onClose)
              else
                const Icon(HakiIcons.caretRight, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.focus,
    required this.attachment,
    required this.replyTo,
    required this.editing,
    required this.onCancelAttachment,
    required this.onCancelReply,
    required this.onCancelEdit,
    required this.onPickImage,
    required this.onSend,
    required this.onVoice,
  });

  final TextEditingController controller;
  final FocusNode focus;
  final String? attachment;
  final MessageModel? replyTo;
  final MessageModel? editing;
  final VoidCallback onCancelAttachment;
  final VoidCallback onCancelReply;
  final VoidCallback onCancelEdit;
  final VoidCallback onPickImage;
  final VoidCallback onSend;
  final void Function(String path, Duration length) onVoice;

  @override
  Widget build(BuildContext context) {
    final Widget? bar;
    final VoidCallback? onCancel;
    if (editing != null) {
      onCancel = onCancelEdit;
      bar = Row(
        children: [
          const Icon(HakiIcons.pencilSimple, size: 20, color: HakiColors.lime),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Editing: ${editing!.message}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
            ),
          ),
        ],
      );
    } else if (attachment != null) {
      onCancel = onCancelAttachment;
      bar = Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(File(attachment!), width: 40, height: 40, fit: BoxFit.cover),
          ),
          const SizedBox(width: 10),
          const Expanded(child: Text('Photo ready to send')),
        ],
      );
    } else if (replyTo != null) {
      onCancel = onCancelReply;
      bar = Row(
        children: [
          const Icon(HakiIcons.arrowBendUpLeft, size: 20, color: HakiColors.lime),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: '${replyTo!.sender}  ',
                style: const TextStyle(fontWeight: FontWeight.w600),
                children: [
                  TextSpan(
                    text: replyTo!.message.isEmpty ? 'Attachment' : replyTo!.message,
                    style: TextStyle(fontWeight: FontWeight.w400, color: Colors.white.withValues(alpha: 0.7)),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    } else {
      bar = null;
      onCancel = null;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (bar != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Glass(
              radius: 22,
              padding: const EdgeInsets.fromLTRB(14, 8, 4, 8),
              child: Row(
                children: [
                  Expanded(child: bar),
                  IconButton(
                    tooltip: editing != null ? 'Cancel edit' : (attachment != null ? 'Remove photo' : 'Cancel reply'),
                    icon: const Icon(HakiIcons.x, size: 18),
                    onPressed: onCancel,
                  ),
                ],
              ),
            ),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (editing == null) ...[
              GlassIconButton(
                icon: HakiIcons.plus,
                tooltip: 'Photo, GIF, sticker, poll or send later',
                onPressed: onPickImage,
                size: 52,
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Glass(
                radius: 26,
                padding: const EdgeInsets.only(left: 18, right: 6),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 52),
                  child: Row(
                    children: [
                      Expanded(
                        // Computers: Enter sends, Shift+Enter adds a line
                        child: CallbackShortcuts(
                          bindings: {
                            if (Device.pointer)
                              for (final key in [LogicalKeyboardKey.enter, LogicalKeyboardKey.numpadEnter])
                                SingleActivator(key): () {
                                  if (controller.text.trim().isNotEmpty || attachment != null) onSend();
                                },
                          },
                          child: TextField(
                            controller: controller,
                            focusNode: focus,
                            minLines: 1,
                            maxLines: 5,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(
                              hintText: 'Message',
                              filled: false,
                              border: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ),
                      ValueListenableBuilder(
                        valueListenable: controller,
                        builder: (context, value, _) {
                          final canSend = value.text.trim().isNotEmpty || attachment != null;
                          if (!canSend && editing == null && !kIsWeb) {
                            return VoiceRecorder(onStop: onVoice, onCancel: () {});
                          }
                          return IconButton(
                            tooltip: editing != null ? 'Save edit' : 'Send',
                            onPressed: canSend ? onSend : null,
                            style: IconButton.styleFrom(
                              backgroundColor: HakiColors.lime,
                              foregroundColor: HakiColors.onLime,
                              fixedSize: const Size(40, 40),
                            ),
                            icon: Icon(editing != null ? HakiIcons.check : HakiIcons.arrowUp, size: 20),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// A one-line notice under the header with one action (key changed, call running).
class _Banner extends StatelessWidget {
  const _Banner({required this.icon, required this.text, required this.action, required this.onTap});

  final IconData icon;
  final String text;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Glass(
        radius: 18,
        padding: const EdgeInsets.fromLTRB(14, 4, 4, 4),
        child: Row(
          children: [
            Icon(icon, size: 18, color: HakiColors.lime),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text, style: const TextStyle(fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            TextButton(onPressed: onTap, child: Text(action)),
          ],
        ),
      ),
    );
  }
}

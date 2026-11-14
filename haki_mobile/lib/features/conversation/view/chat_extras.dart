import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';

import '../../../core/theme/haki_theme.dart';
import '../../../core/widgets/glass.dart';
import '../../../models/message_model.dart';
import '../../../models/user_model.dart';
import '../../settings/view_model/settings_cubit.dart';
import '../../../widgets/voice_player.dart';
import '../view_model/conversation_cubit.dart';
import 'package:chat_mobile/core/theme/haki_icons.dart';

/// Disappearing-messages timer for a chat. Returns the chosen seconds, or null if dismissed.
abstract final class DisappearingSheet {
  static const options = [0, 3600, 86400, 604800, 2592000];

  static Future<int?> pick(BuildContext context, int current) => showModalBottomSheet<int>(
    context: context,
    builder: (sheet) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
            child: Text('Disappearing messages', style: HakiText.display(26)),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              'New messages are deleted from the server and every phone after this time. Everyone in the chat sees the change.',
              style: TextStyle(color: HakiColors.textMuted, fontSize: 13),
            ),
          ),
          for (final s in options)
            ListTile(
              leading: Icon(
                s == current ? HakiIcons.radioButtonFill : HakiIcons.circle,
                color: s == current ? HakiColors.lime : null,
              ),
              title: Text(s == 0 ? 'Off' : ConversationCubit.disappearLabel(s)),
              onTap: () => Navigator.pop(sheet, s),
            ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

/// Why the user is reporting a message. Returns (reason, note) or null.
abstract final class ReportSheet {
  static const reasons = {
    'spam': 'Spam',
    'harassment': 'Harassment or bullying',
    'hate': 'Hate speech',
    'violence': 'Violence or threats',
    'sexual': 'Sexual content',
    'scam': 'Scam or fraud',
    'other': 'Something else',
  };

  static Future<(String, String?)?> show(BuildContext context) => showModalBottomSheet<(String, String?)>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _ReportForm(),
  );
}

class _ReportForm extends StatefulWidget {
  const _ReportForm();

  @override
  State<_ReportForm> createState() => _ReportFormState();
}

class _ReportFormState extends State<_ReportForm> {
  String? _reason;
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Report message', style: HakiText.display(26)),
              const SizedBox(height: 4),
              const Text(
                'Haki can’t read your chats, so this message’s text is sent to the moderators with your report. They won’t see anything else.',
                style: TextStyle(color: HakiColors.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final e in ReportSheet.reasons.entries)
                    ChoiceChip(
                      label: Text(e.value),
                      selected: _reason == e.key,
                      onSelected: (_) => setState(() => _reason = e.key),
                      selectedColor: HakiColors.lime,
                      labelStyle: TextStyle(color: _reason == e.key ? HakiColors.onLime : null),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _note,
                maxLength: 500,
                maxLines: 3,
                minLines: 1,
                decoration: const InputDecoration(labelText: 'Anything else? (optional)'),
              ),
              const SizedBox(height: 8),
              LimeButton(
                label: 'Send report',
                icon: HakiIcons.flagFill,
                onPressed: _reason == null
                    ? null
                    : () => Navigator.pop(context, (_reason!, _note.text.trim().isEmpty ? null : _note.text.trim())),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A view-once photo or voice note: never shown inline, opened once from here.
class ViewOnceTile extends StatelessWidget {
  const ViewOnceTile({super.key, required this.message, required this.isMe, this.onOpen});
  final MessageModel message;
  final bool isMe;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final opened = message.viewedAt != null;
    final kind = message.isVoice ? 'Voice message' : 'Photo';
    final String label;
    if (opened) {
      label = 'Opened';
    } else if (isMe) {
      label = message.isSending ? 'Sending…' : 'Not opened yet';
    } else {
      label = 'Tap to open once';
    }
    final canOpen = !isMe && !opened && onOpen != null;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: canOpen ? onOpen : null,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 14, 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: opened ? Colors.white38 : HakiColors.lime, width: 2, style: opened ? BorderStyle.solid : BorderStyle.solid),
                color: opened ? Colors.transparent : HakiColors.lime.withValues(alpha: 0.12),
              ),
              child: Text('1', style: TextStyle(fontWeight: FontWeight.w800, color: opened ? Colors.white38 : HakiColors.lime)),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(kind, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(label, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows a decrypted view-once photo / voice note, then deletes the local copy.
abstract final class ViewOnceViewer {
  static Future<void> show(BuildContext context, MessageModel m, String path) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            title: const Text('View once'),
            leading: IconButton(icon: const Icon(HakiIcons.x), tooltip: 'Close', onPressed: () => Navigator.of(context).pop()),
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: m.isVoice
                        ? Glass(radius: 24, child: VoicePlayer(url: path, knownDuration: m.durationSec == null ? null : Duration(seconds: m.durationSec!)))
                        : InteractiveViewer(child: Image.file(File(path))),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'Gone for good when you close this. It was already deleted from the server.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: HakiColors.textMuted),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    try {
      File(path).deleteSync();
    } catch (_) {}
  }
}

/// A shared video or document. Tapping downloads, decrypts and opens it on this phone.
class FileCard extends StatefulWidget {
  const FileCard({super.key, required this.message, required this.onOpen});
  final MessageModel message;
  final Future<void> Function() onOpen;

  @override
  State<FileCard> createState() => _FileCardState();
}

class _FileCardState extends State<FileCard> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final m = widget.message;
    final video = m.isVideo;
    final meta = m.file;
    final name = video ? 'Video' : (meta?.name ?? 'File');
    final details = [
      if (video && m.durationSec != null) _clock(m.durationSec!),
      ?meta?.sizeLabel,
      if (!video) ?meta?.extension,
    ].join(' · ');

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: _busy || m.isSending
          ? null
          : () async {
              setState(() => _busy = true);
              await widget.onOpen();
              if (mounted) setState(() => _busy = false);
            },
      child: Container(
        width: 250,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.22), borderRadius: BorderRadius.circular(18)),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: video ? HakiColors.violet : HakiColors.surfaceHigh,
                borderRadius: BorderRadius.circular(14),
              ),
              child: _busy || m.isSending
                  ? const Padding(padding: EdgeInsets.all(13), child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(video ? HakiIcons.playFill : HakiIcons.fileText, color: video ? Colors.white : HakiColors.lime),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                  if (details.isNotEmpty)
                    Text(details, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _clock(int s) => '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
}

/// Full-screen player for a decrypted video; the temporary copy is deleted afterwards.
class VideoPlayerView extends StatefulWidget {
  const VideoPlayerView({super.key, required this.path, required this.title});
  final String path;
  final String title;

  @override
  State<VideoPlayerView> createState() => _VideoPlayerViewState();
}

class _VideoPlayerViewState extends State<VideoPlayerView> {
  late final VideoPlayerController _c = VideoPlayerController.file(File(widget.path));

  @override
  void initState() {
    super.initState();
    _c.initialize().then((_) {
      if (!mounted) return;
      setState(() {});
      _c.play();
    });
    _c.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _c.dispose();
    try {
      File(widget.path).deleteSync();
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final v = _c.value;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.transparent, title: Text(widget.title, overflow: TextOverflow.ellipsis)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: v.isInitialized
                    ? GestureDetector(
                        onTap: () => v.isPlaying ? _c.pause() : _c.play(),
                        child: AspectRatio(aspectRatio: v.aspectRatio, child: VideoPlayer(_c)),
                      )
                    : const CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            if (v.isInitialized)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 16, 12),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: v.isPlaying ? 'Pause' : 'Play',
                      icon: Icon(v.isPlaying ? HakiIcons.pauseFill : HakiIcons.playFill, size: 30),
                      onPressed: () => v.isPlaying ? _c.pause() : _c.play(),
                    ),
                    Expanded(
                      child: VideoProgressIndicator(
                        _c,
                        allowScrubbing: true,
                        colors: const VideoProgressColors(playedColor: HakiColors.lime, bufferedColor: Colors.white24),
                      ),
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


/// A private note about a contact. Lives on your phones and in your sealed backup only.
class NoteSheet extends StatefulWidget {
  const NoteSheet({super.key, required this.friend});
  final UserModel friend;

  static Future<void> show(BuildContext context, UserModel friend) => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => BlocProvider.value(value: context.read<SettingsCubit>(), child: NoteSheet(friend: friend)),
  );

  @override
  State<NoteSheet> createState() => _NoteSheetState();
}

class _NoteSheetState extends State<NoteSheet> {
  late final _text = TextEditingController(text: context.read<SettingsCubit>().state.notes[widget.friend.id] ?? '');

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  @override
  Widget build(BuildContext context) {
    final f = widget.friend;
    final b = f.birthday;
    final days = f.daysToBirthday(DateTime.now());
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('About ${f.name}', style: HakiText.display(26)),
              const SizedBox(height: 4),
              const Text(
                'Only you see this note. It’s saved on your phones and in your encrypted backup, never readable by Haki.',
                style: TextStyle(color: HakiColors.textMuted, fontSize: 13),
              ),
              if (b != null) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(HakiIcons.cakeFill, size: 18, color: HakiColors.lime),
                    const SizedBox(width: 8),
                    Text(
                      'Birthday ${int.parse(b.substring(3))} ${_months[int.parse(b.substring(0, 2)) - 1]}'
                      '${days == 0 ? ' · today 🎉' : days == 1 ? ' · tomorrow' : days != null && days < 30 ? ' · in $days days' : ''}',
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: _text,
                autofocus: true,
                maxLength: 1000,
                maxLines: 6,
                minLines: 3,
                decoration: const InputDecoration(labelText: 'Note', hintText: 'How you met, gift ideas, their kids’ names…'),
              ),
              const SizedBox(height: 8),
              LimeButton(
                label: 'Save note',
                icon: HakiIcons.check,
                onPressed: () async {
                  await context.read<SettingsCubit>().setNote(f.id, _text.text);
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

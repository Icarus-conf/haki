import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import '../../../core/theme/haki_theme.dart';
import '../../../core/widgets/glass.dart';
import '../../../models/user_model.dart';
import '../../friends/view_model/friends_cubit.dart';
import '../../session/view_model/session_cubit.dart';
import '../view_model/feed_cubit.dart';
import 'package:chat_mobile/core/theme/haki_icons.dart';

const _maxMedia = 10;
const _maxVideoBytes = 50 * 1024 * 1024;

/// New post: text, up to 10 photos or videos, and who can see it.
class ComposePostView extends StatefulWidget {
  const ComposePostView({super.key});

  static Future<void> open(BuildContext context) =>
      Navigator.push(context, MaterialPageRoute(fullscreenDialog: true, builder: (_) => const ComposePostView()));

  @override
  State<ComposePostView> createState() => _ComposePostViewState();
}

class _ComposePostViewState extends State<ComposePostView> {
  final _text = TextEditingController();
  final _media = <PickedMedia>[];
  final _previews = <XFile, Uint8List>{};
  Set<int>? _only; // null = all friends
  bool _commentsOff = false;
  bool _picking = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  bool _isVideo(XFile f) =>
      (f.mimeType?.startsWith('video/') ?? false) ||
      RegExp(r'\.(mp4|mov|m4v|webm|3gp)$', caseSensitive: false).hasMatch(f.name);

  Future<void> _pick() async {
    if (_media.length >= _maxMedia) {
      return showHakiToast(context, 'Up to $_maxMedia photos and videos');
    }
    setState(() => _picking = true);
    try {
      final files = await ImagePicker().pickMultipleMedia(
        maxWidth: 2048,
        imageQuality: 85,
        limit: _maxMedia - _media.length >= 2 ? _maxMedia - _media.length : null,
      );
      var skipped = 0;
      for (final f in files.take(_maxMedia - _media.length)) {
        final picked = await _measure(f);
        picked == null ? skipped++ : _media.add(picked);
      }
      if (skipped > 0 && mounted) {
        showHakiToast(context, 'Skipped $skipped video${skipped == 1 ? '' : 's'} over 50 MB', isError: true);
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  /// Size and length up front so the feed can lay tiles out before they're downloaded.
  Future<PickedMedia?> _measure(XFile f) async {
    if (_isVideo(f)) {
      if (await f.length() > _maxVideoBytes) return null;
      if (kIsWeb) return (file: f, video: true, w: 16.0, h: 9.0, dur: null);
      final c = VideoPlayerController.file(File(f.path));
      try {
        await c.initialize();
        final s = c.value.size;
        return (file: f, video: true, w: s.width, h: s.height, dur: c.value.duration.inSeconds);
      } catch (_) {
        return (file: f, video: true, w: 16.0, h: 9.0, dur: null);
      } finally {
        c.dispose();
      }
    }
    final bytes = await f.readAsBytes();
    _previews[f] = bytes;
    final img = await decodeImageFromList(bytes);
    final picked = (file: f, video: false, w: img.width.toDouble(), h: img.height.toDouble(), dur: null);
    img.dispose();
    return picked;
  }

  Future<void> _chooseAudience(List<UserModel> friends) async {
    final picked = await showModalBottomSheet<Set<int>?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: HakiColors.surface,
      builder: (_) => _AudienceSheet(friends: friends, initial: _only),
    );
    if (picked != null && mounted) {
      setState(() => _only = picked.isEmpty ? null : picked);
    }
  }

  Future<void> _post(List<UserModel> friends) async {
    final readers = _only == null ? friends : friends.where((f) => _only!.contains(f.id)).toList();
    final error = await context.read<FeedCubit>().post(
      text: _text.text,
      media: List.of(_media),
      readers: readers,
      commentsOff: _commentsOff,
    );
    if (!mounted) return;
    if (error != null) return showHakiToast(context, error, isError: true);
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.pop(context);
    showHakiToast(context, 'Posted');
  }

  @override
  Widget build(BuildContext context) {
    final me = context.select((SessionCubit c) => c.state.me);
    final friends = context.select((FriendsCubit c) => c.state.friends);
    final posting = context.select((FeedCubit c) => c.state.isPosting);
    final audience = _only == null
        ? 'All friends'
        : _only!.length == 1
        ? friends.where((f) => _only!.contains(f.id)).firstOrNull?.name ?? '1 friend'
        : '${_only!.length} friends';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: HakiColors.ink,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          tooltip: 'Close',
          icon: const Icon(HakiIcons.x),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('New post'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ValueListenableBuilder(
              valueListenable: _text,
              builder: (_, v, _) {
                final ready = (v.text.trim().isNotEmpty || _media.isNotEmpty) && !posting && !_picking;
                return FilledButton(
                  onPressed: ready ? () => _post(friends) : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: HakiColors.lime,
                    foregroundColor: HakiColors.onLime,
                    disabledBackgroundColor: Colors.white.withValues(alpha: 0.08),
                  ),
                  child: posting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Post', style: TextStyle(fontWeight: FontWeight.w700)),
                );
              },
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  children: [
                    Row(
                      children: [
                        if (me != null) AuraAvatar(user: me, size: 40, radius: 14),
                        const SizedBox(width: 10),
                        ActionChip(
                          onPressed: () => _chooseAudience(friends),
                          avatar: Icon(_only == null ? HakiIcons.users : HakiIcons.userFocus, size: 16),
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [Text(audience), const Icon(HakiIcons.caretDown, size: 18)],
                          ),
                          backgroundColor: HakiColors.surfaceHigh,
                          side: BorderSide.none,
                          shape: const StadiumBorder(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _text,
                      autofocus: true,
                      minLines: 3,
                      maxLines: null,
                      maxLength: 2000,
                      textCapitalization: TextCapitalization.sentences,
                      style: const TextStyle(fontSize: 18, height: 1.4),
                      decoration: const InputDecoration(
                        hintText: 'What\'s on your mind?',
                        border: InputBorder.none,
                        filled: false,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        counterText: '',
                      ),
                    ),
                    if (_media.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 150,
                        child: ReorderableListView.builder(
                          scrollDirection: Axis.horizontal,
                          buildDefaultDragHandles: false,
                          itemCount: _media.length,
                          onReorderItem: (a, b) => setState(() => _media.insert(b, _media.removeAt(a))),
                          itemBuilder: (context, i) => ReorderableDelayedDragStartListener(
                            key: ValueKey(_media[i].file),
                            index: i,
                            child: _PickedTile(
                              media: _media[i],
                              preview: _previews[_media[i].file],
                              onRemove: () => setState(() => _media.removeAt(i)),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          '${_media.length} of $_maxMedia · hold to reorder',
                          style: const TextStyle(fontSize: 12, color: HakiColors.textMuted),
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    Container(
                      decoration: BoxDecoration(color: HakiColors.surface, borderRadius: BorderRadius.circular(20)),
                      child: SwitchListTile(
                        value: _commentsOff,
                        onChanged: (v) => setState(() => _commentsOff = v),
                        activeThumbColor: HakiColors.onLime,
                        activeTrackColor: HakiColors.lime,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        secondary: const Icon(HakiIcons.chatCircleSlash),
                        title: const Text('Turn off comments'),
                      ),
                    ),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(8, 6, 16, 6),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: HakiColors.surfaceHigh)),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Add photos or videos',
                        onPressed: _picking || posting ? null : _pick,
                        icon: _picking
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(HakiIcons.images, color: HakiColors.lime),
                      ),
                      const Spacer(),
                      const Icon(HakiIcons.lockFill, size: 13, color: HakiColors.teal),
                      const SizedBox(width: 6),
                      const Text('End-to-end encrypted', style: TextStyle(fontSize: 12, color: HakiColors.textMuted)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PickedTile extends StatelessWidget {
  const _PickedTile({required this.media, required this.preview, required this.onRemove});
  final PickedMedia media;
  final Uint8List? preview;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final w = (150 * (media.w / media.h).clamp(0.62, 1.25)).toDouble();
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: w,
          height: 150,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (preview != null)
                Image.memory(preview!, fit: BoxFit.cover)
              else
                ColoredBox(
                  color: HakiColors.surfaceHigh,
                  child: Icon(
                    media.video ? HakiIcons.playCircle : HakiIcons.image,
                    size: 34,
                    color: HakiColors.lime,
                  ),
                ),
              if (media.video && media.dur != null)
                Positioned(
                  left: 8,
                  bottom: 8,
                  child: Text(
                    '${media.dur! ~/ 60}:${(media.dur! % 60).toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, shadows: [Shadow(blurRadius: 4)]),
                  ),
                ),
              Positioned(
                right: 4,
                top: 4,
                child: Material(
                  color: Colors.black54,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onRemove,
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(HakiIcons.x, size: 16, semanticLabel: 'Remove'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// All friends, or a hand-picked few. Returns an empty set for "all".
class _AudienceSheet extends StatefulWidget {
  const _AudienceSheet({required this.friends, required this.initial});
  final List<UserModel> friends;
  final Set<int>? initial;

  @override
  State<_AudienceSheet> createState() => _AudienceSheetState();
}

class _AudienceSheetState extends State<_AudienceSheet> {
  late bool _all = widget.initial == null;
  late final Set<int> _picked = {...?widget.initial};

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.92,
      builder: (context, scroll) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 12, 6),
            child: Row(
              children: [
                Expanded(child: Text('Who can see this', style: HakiText.display(22))),
                TextButton(
                  onPressed: !_all && _picked.isEmpty ? null : () => Navigator.pop(context, _all ? <int>{} : _picked),
                  child: const Text(
                    'Done',
                    style: TextStyle(color: HakiColors.lime, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              controller: scroll,
              children: [
                RadioGroup<bool>(
                  groupValue: _all,
                  onChanged: (v) => setState(() => _all = v ?? true),
                  child: const Column(
                    children: [
                      RadioListTile(value: true, title: Text('All friends'), secondary: Icon(HakiIcons.users)),
                      RadioListTile(
                        value: false,
                        title: Text('Only some friends'),
                        secondary: Icon(HakiIcons.userFocus),
                      ),
                    ],
                  ),
                ),
                if (!_all) ...[
                  const Divider(height: 1, color: HakiColors.surfaceHigh),
                  for (final f in widget.friends)
                    CheckboxListTile(
                      value: _picked.contains(f.id),
                      onChanged: (v) => setState(() => v == true ? _picked.add(f.id) : _picked.remove(f.id)),
                      secondary: AuraAvatar(user: f, size: 38, radius: 13),
                      title: Text(f.name),
                      subtitle: Text('@${f.username}', style: const TextStyle(color: HakiColors.textMuted)),
                      activeColor: HakiColors.lime,
                      checkColor: HakiColors.onLime,
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

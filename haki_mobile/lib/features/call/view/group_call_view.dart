import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../../core/theme/haki_theme.dart';
import '../../../core/widgets/glass.dart';
import '../../../models/group_model.dart';
import '../../../models/user_model.dart';
import '../view_model/group_call_cubit.dart';
import 'package:chat_mobile/core/theme/haki_icons.dart';

/// A group call: one tile per person (video, or their initials), mute / camera / speaker / leave.
class GroupCallView extends StatefulWidget {
  const GroupCallView({super.key, required this.group, required this.me, this.video = false});

  final GroupModel group;
  final UserModel me;
  final bool video;

  static Future<void> open(BuildContext context, GroupModel group, UserModel me, {bool video = false}) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => GroupCallView(group: group, me: me, video: video)));

  @override
  State<GroupCallView> createState() => _GroupCallViewState();
}

class _GroupCallViewState extends State<GroupCallView> {
  @override
  void initState() {
    super.initState();
    final cubit = context.read<GroupCallCubit>();
    if (cubit.state.groupId != widget.group.id) cubit.join(widget.group.id, video: widget.video);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GroupCallCubit, GroupCallState>(
      listenWhen: (a, b) => (a.inCall && !b.inCall) || (b.error != null && a.error != b.error),
      listener: (context, s) {
        if (s.error != null) showHakiToast(context, s.error!, isError: true);
        if (Navigator.canPop(context)) Navigator.pop(context);
      },
      builder: (context, s) {
        final cubit = context.read<GroupCallCubit>();
        final others = (s.active[widget.group.id] ?? const <int>[]).where((id) => id != widget.me.id).toList();
        final tiles = <Widget>[
          _Tile(user: widget.me, stream: s.cameraOff ? null : s.local, mirror: true, muted: s.muted, label: 'You'),
          for (final id in others)
            _Tile(
              key: ValueKey(id),
              user: widget.group.member(id) ?? UserModel(id: id, username: 'Someone'),
              stream: s.streams[id],
              connecting: !s.streams.containsKey(id),
            ),
        ];
        return Scaffold(
          body: Stack(
            children: [
              const AuroraBackground(height: 900, fadeStart: 0.4),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      Text(widget.group.name, style: HakiText.display(26), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(HakiIcons.lockFill, size: 14, color: HakiColors.lime),
                          const SizedBox(width: 6),
                          Text(
                            others.isEmpty ? 'Waiting for others to join…' : '${others.length + 1} in the call · end-to-end encrypted',
                            style: const TextStyle(color: HakiColors.textMuted, fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: GridView.count(
                          crossAxisCount: tiles.length <= 2 ? 1 : 2,
                          childAspectRatio: tiles.length <= 2 ? 1.5 : 0.8,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          children: tiles,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _Control(
                            icon: s.muted ? HakiIcons.microphoneSlash : HakiIcons.microphone,
                            label: s.muted ? 'Unmute' : 'Mute',
                            on: s.muted,
                            onTap: cubit.toggleMute,
                          ),
                          if (s.video)
                            _Control(
                              icon: s.cameraOff ? HakiIcons.videoCameraSlash : HakiIcons.videoCamera,
                              label: s.cameraOff ? 'Camera on' : 'Camera off',
                              on: s.cameraOff,
                              onTap: cubit.toggleCamera,
                            ),
                          _Control(
                            icon: s.speakerOn ? HakiIcons.speakerHigh : HakiIcons.ear,
                            label: s.speakerOn ? 'Speaker' : 'Earpiece',
                            on: s.speakerOn,
                            onTap: cubit.toggleSpeaker,
                          ),
                          _Control(
                            icon: HakiIcons.phoneDisconnectFill,
                            label: 'Leave',
                            danger: true,
                            onTap: cubit.leave,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Tile extends StatefulWidget {
  const _Tile({super.key, required this.user, this.stream, this.mirror = false, this.muted = false, this.connecting = false, this.label});

  final UserModel user;
  final MediaStream? stream;
  final bool mirror;
  final bool muted;
  final bool connecting;
  final String? label;

  @override
  State<_Tile> createState() => _TileState();
}

class _TileState extends State<_Tile> {
  final _renderer = RTCVideoRenderer();
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _renderer.initialize().then((_) {
      if (!mounted) return;
      _renderer.srcObject = widget.stream;
      setState(() => _ready = true);
    });
  }

  @override
  void didUpdateWidget(_Tile old) {
    super.didUpdateWidget(old);
    if (_ready && old.stream != widget.stream) _renderer.srcObject = widget.stream;
  }

  @override
  void dispose() {
    _renderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasVideo = _ready && (widget.stream?.getVideoTracks().isNotEmpty ?? false);
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        color: HakiColors.surfaceHigh,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasVideo)
              RTCVideoView(_renderer, mirror: widget.mirror, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover)
            else
              Center(child: AuraAvatar(user: widget.user, size: 76, radius: 28)),
            Positioned(
              left: 10,
              bottom: 10,
              right: 10,
              child: Row(
                children: [
                  Flexible(
                    child: Glass(
                      radius: 12,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: Text(
                        widget.connecting ? '${widget.label ?? widget.user.name} · connecting…' : widget.label ?? widget.user.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                  if (widget.muted) ...[
                    const SizedBox(width: 6),
                    const Icon(HakiIcons.microphoneSlash, size: 18, color: HakiColors.dangerText),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Control extends StatelessWidget {
  const _Control({required this.icon, required this.label, required this.onTap, this.on = false, this.danger = false});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool on;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: label,
          onPressed: onTap,
          style: IconButton.styleFrom(
            fixedSize: const Size(62, 62),
            backgroundColor: danger ? HakiColors.danger : on ? Colors.white : Colors.white.withValues(alpha: 0.12),
            foregroundColor: danger ? Colors.white : on ? Colors.black : Colors.white,
          ),
          icon: Icon(icon, size: 28),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: HakiColors.textMuted)),
      ],
    );
  }
}

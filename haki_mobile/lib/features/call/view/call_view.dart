import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../../core/theme/haki_theme.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/glass.dart';
import '../../../models/user_model.dart';
import '../../friends/view_model/friends_cubit.dart';
import '../view_model/call_cubit.dart';
import 'package:chat_mobile/core/theme/haki_icons.dart';

/// Voice or video call screen, for both outgoing ([outgoing] = true) and incoming calls.
class CallView extends StatefulWidget {
  const CallView({super.key, required this.peerId, this.outgoing = false, this.video = false});

  final int peerId;
  final bool outgoing;

  /// Outgoing only: start a video call. Incoming calls take this from the offer.
  final bool video;

  @override
  State<CallView> createState() => _CallViewState();
}

class _CallViewState extends State<CallView> {
  Timer? _ticker;
  final _local = RTCVideoRenderer();
  final _remote = RTCVideoRenderer();
  late final _rtc = context.read<CallCubit>().webrtc;
  bool _renderersReady = false;

  @override
  void initState() {
    super.initState();
    if (widget.outgoing) context.read<CallCubit>().start(widget.peerId, video: widget.video);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
    _initRenderers();
  }

  Future<void> _initRenderers() async {
    await Future.wait([_local.initialize(), _remote.initialize()]);
    if (!mounted) return;
    _rtc.localStream.addListener(_bindStreams);
    _rtc.remoteStream.addListener(_bindStreams);
    _bindStreams();
    setState(() => _renderersReady = true);
  }

  void _bindStreams() {
    _local.srcObject = _rtc.localStream.value;
    _remote.srcObject = _rtc.remoteStream.value;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _rtc.localStream.removeListener(_bindStreams);
    _rtc.remoteStream.removeListener(_bindStreams);
    _local.dispose();
    _remote.dispose();
    super.dispose();
  }

  bool get _remoteVideo =>
      _renderersReady && (_rtc.remoteStream.value?.getVideoTracks().isNotEmpty ?? false);
  bool get _localVideo => _renderersReady && _rtc.localStream.value != null;

  @override
  Widget build(BuildContext context) {
    final peer =
        context.select((FriendsCubit c) => c.state.byId(widget.peerId)) ??
        UserModel(id: widget.peerId, username: 'Unknown');

    return BlocConsumer<CallCubit, CallState>(
      listenWhen: (a, b) => a.phase != b.phase && b.phase == CallPhase.idle,
      // Remote side hung up / declined: close this screen (only if it's still on top)
      listener: (context, _) {
        if (ModalRoute.of(context)?.isCurrent ?? false) Navigator.pop(context);
      },
      builder: (context, call) {
        final cubit = context.read<CallCubit>();
        final status = switch (call.phase) {
          CallPhase.incoming => call.video ? 'Incoming video call' : 'Incoming voice call',
          CallPhase.dialing => 'Calling…',
          CallPhase.connecting => 'Connecting…',
          CallPhase.connected => mmss(DateTime.now().difference(call.connectedAt ?? DateTime.now())),
          CallPhase.ended => call.endReason ?? 'Call ended',
          CallPhase.idle => '',
        };

        return PopScope(
          // Back while ringing = decline; while in a call = hang up
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) return;
            if (call.phase == CallPhase.incoming) cubit.decline();
            if ({CallPhase.dialing, CallPhase.connecting, CallPhase.connected}.contains(call.phase)) cubit.hangUp();
          },
          child: Scaffold(
            body: Stack(
              children: [
                AuroraBackground(
                  height: MediaQuery.sizeOf(context).height,
                  fadeStart: 0.55,
                  colors: [HakiColors.auraFor(peer.id)[1], HakiColors.violet, HakiColors.blue],
                ),
                if (call.video && _remoteVideo)
                  Positioned.fill(
                    child: RTCVideoView(_remote, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
                  ),
                if (call.video && _localVideo && !call.cameraOff && call.phase != CallPhase.incoming)
                  Positioned(
                    right: 16,
                    top: MediaQuery.paddingOf(context).top + 56,
                    width: 108,
                    height: 160,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: RTCVideoView(
                        _local,
                        mirror: true,
                        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      ),
                    ),
                  ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                    child: Column(
                      children: [
                        const Glass(
                          radius: 16,
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(HakiIcons.lockFill, size: 13),
                              SizedBox(width: 6),
                              Text('End-to-end encrypted', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                        const Spacer(flex: 2),
                        // With the other person's video on screen, keep only a small name tag
                        if (!(call.video && _remoteVideo)) ...[
                          _Pulse(
                            active: call.phase != CallPhase.connected,
                            child: AuraAvatar(user: peer, size: 132, radius: 48),
                          ),
                          const SizedBox(height: 28),
                        ],
                        Text(peer.name, style: HakiText.display(call.video && _remoteVideo ? 24 : 34), textAlign: TextAlign.center),
                        const SizedBox(height: 8),
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            status,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withValues(alpha: 0.75),
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                        const Spacer(flex: 3),
                        if (call.phase == CallPhase.incoming)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _RoundAction(
                                label: 'Decline',
                                icon: HakiIcons.phoneDisconnectFill,
                                color: HakiColors.danger,
                                onPressed: () {
                                  cubit.decline();
                                  Navigator.pop(context);
                                },
                              ),
                              _RoundAction(
                                label: 'Accept',
                                icon: call.video ? HakiIcons.videoCamera : HakiIcons.phoneFill,
                                color: HakiColors.lime,
                                iconColor: HakiColors.onLime,
                                onPressed: cubit.accept,
                              ),
                            ],
                          )
                        else
                          Row(
                            children: [
                              Expanded(
                                child: Glass(
                                  radius: 38,
                                  padding: const EdgeInsets.all(8),
                                  child: Row(
                                    children: [
                                      _Toggle(
                                        icon: call.muted ? HakiIcons.microphoneSlash : HakiIcons.microphone,
                                        label: call.muted ? 'Unmute' : 'Mute',
                                        on: call.muted,
                                        onPressed: cubit.toggleMute,
                                      ),
                                      const SizedBox(width: 6),
                                      if (call.video && _localVideo) ...[
                                        _Toggle(
                                          icon: call.cameraOff ? HakiIcons.videoCameraSlash : HakiIcons.videoCamera,
                                          label: call.cameraOff ? 'Camera on' : 'Camera',
                                          on: call.cameraOff,
                                          onPressed: cubit.toggleCamera,
                                        ),
                                        const SizedBox(width: 6),
                                        _Toggle(
                                          icon: HakiIcons.cameraRotate,
                                          label: 'Flip',
                                          on: false,
                                          onPressed: cubit.switchCamera,
                                        ),
                                      ] else
                                        _Toggle(
                                          icon: HakiIcons.speakerHigh,
                                          label: call.speakerOn ? 'Speaker on' : 'Speaker',
                                          on: call.speakerOn,
                                          onPressed: cubit.toggleSpeaker,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              _RoundAction(
                                label: 'End call',
                                icon: HakiIcons.phoneDisconnectFill,
                                color: HakiColors.danger,
                                showLabel: false,
                                onPressed: () {
                                  cubit.hangUp();
                                  Navigator.pop(context);
                                },
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({required this.icon, required this.label, required this.on, required this.onPressed});
  final IconData icon;
  final String label;
  final bool on;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        toggled: on,
        child: SizedBox(
          height: 60,
          child: TextButton(
            onPressed: onPressed,
            style: TextButton.styleFrom(
              backgroundColor: on ? Colors.white : Colors.white.withValues(alpha: 0.14),
              foregroundColor: on ? HakiColors.ink : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [Icon(icon), Text(label, style: const TextStyle(fontSize: 11))],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
    this.iconColor = Colors.white,
    this.showLabel = true,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Color iconColor;
  final VoidCallback onPressed;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 76,
          height: 76,
          child: IconButton(
            tooltip: label,
            onPressed: onPressed,
            style: IconButton.styleFrom(backgroundColor: color, foregroundColor: iconColor),
            icon: Icon(icon, size: 30),
          ),
        ),
        if (showLabel) ...[const SizedBox(height: 8), ExcludeSemantics(child: Text(label))],
      ],
    );
  }
}

/// Soft breathing ring while ringing/connecting.
class _Pulse extends StatefulWidget {
  const _Pulse({required this.active, required this.child});
  final bool active;
  final Widget child;

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active || MediaQuery.disableAnimationsOf(context)) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) => Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 132 + 70 * _c.value,
            height: 132 + 70 * _c.value,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(48 + 20 * _c.value),
              border: Border.all(color: Colors.white.withValues(alpha: 0.35 * (1 - _c.value)), width: 2),
            ),
          ),
          child!,
        ],
      ),
      child: widget.child,
    );
  }
}

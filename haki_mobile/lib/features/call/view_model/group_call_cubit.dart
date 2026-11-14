import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../services/chat_service.dart';
import '../../../services/webrtc_service.dart';

part 'group_call_cubit.freezed.dart';

@freezed
abstract class GroupCallState with _$GroupCallState {
  const GroupCallState._();

  const factory GroupCallState({
    /// Calls running in my groups: group id -> who is in it (from the server).
    @Default({}) Map<int, List<int>> active,

    /// The group call I'm in (or joining).
    int? groupId,
    @Default(false) bool video,
    @Default(false) bool muted,
    @Default(false) bool cameraOff,
    @Default(true) bool speakerOn,

    /// Remote audio/video per person, and my own camera (null on voice calls).
    @Default({}) Map<int, MediaStream> streams,
    MediaStream? local,

    /// A call someone just started in one of my groups (shown as a banner until answered).
    int? ringing,
    String? error,
  }) = _GroupCallState;

  bool get inCall => groupId != null;
}

/// Group voice/video calls as a mesh: one direct, DTLS-SRTP-encrypted connection to each
/// person in the call, so there's no media server that could see or hear anything.
/// ponytail: mesh uploads your stream once per person; capped at 6 on the server. An SFU
/// (LiveKit/mediasoup with insertable-streams E2EE) is the upgrade path for bigger calls.
class GroupCallCubit extends Cubit<GroupCallState> {
  GroupCallCubit({required this.chat, required this.myId}) : super(const GroupCallState()) {
    _subs.addAll([
      chat.on('group_call').listen(_onCallState),
      chat.on('gc_signal').listen(_onSignal),
    ]);
  }

  final ChatService chat;
  final int? Function() myId;
  final List<StreamSubscription> _subs = [];
  final Map<int, RTCPeerConnection> _peers = {};
  final Map<int, List<RTCIceCandidate>> _pending = {};
  final Set<int> _remoteSet = {};

  void _onCallState(dynamic d) {
    final groupId = d['groupId'] as int;
    final people = [for (final p in d['participants'] as List) p as int];
    final before = state.active[groupId] ?? const [];
    final active = {...state.active};
    people.isEmpty ? active.remove(groupId) : active[groupId] = people;
    final me = myId();
    // Ring when a call starts in one of my groups and I'm free
    final ring = before.isEmpty && people.isNotEmpty && !people.contains(me) && !state.inCall
        ? groupId
        : (state.ringing == groupId && (people.isEmpty || people.contains(me)) ? null : state.ringing);
    emit(state.copyWith(active: active, ringing: ring));
    if (state.groupId == groupId) {
      for (final id in [..._peers.keys]) {
        if (!people.contains(id)) _closePeer(id);
      }
    }
  }

  void dismissRing() => emit(state.copyWith(ringing: null));

  Future<void> join(int groupId, {bool video = false}) async {
    if (state.inCall) return;
    emit(state.copyWith(groupId: groupId, video: video, ringing: null, error: null, speakerOn: true));
    try {
      if (!await Permission.microphone.request().isGranted) throw 'Haki needs the microphone for calls';
      final local = await _openMedia(video);
      emit(state.copyWith(local: local.getVideoTracks().isEmpty ? null : local));
      _localStream = local;
      Helper.setSpeakerphoneOn(true);
      final res = await chat.request('gc_join', {'groupId': groupId, 'video': video});
      if (res == null || res['error'] != null) throw (res?['error'] ?? 'Couldn’t join the call').toString();
      // The newcomer calls everyone already there; they answer
      for (final p in res['participants'] as List) {
        final id = p as int;
        final pc = await _peer(id);
        final offer = await pc.createOffer({'offerToReceiveAudio': true, 'offerToReceiveVideo': true});
        await pc.setLocalDescription(offer);
        _signal(id, {'type': 'offer', 'sdp': offer.sdp});
      }
    } catch (e) {
      dev.log('Group call join failed: $e', name: 'GroupCallCubit');
      await leave();
      emit(state.copyWith(error: e.toString()));
    }
  }

  MediaStream? _localStream;

  Future<MediaStream> _openMedia(bool video) async {
    if (video && (await Permission.camera.request()).isGranted) {
      try {
        return await navigator.mediaDevices.getUserMedia({
          'audio': true,
          'video': {'facingMode': 'user', 'width': 640, 'height': 480},
        });
      } catch (_) {/* no camera (simulator): audio only */}
    }
    return navigator.mediaDevices.getUserMedia({'audio': true, 'video': false});
  }

  void _signal(int to, Map<String, dynamic> signal) =>
      chat.emit('gc_signal', {'groupId': state.groupId, 'to': to, 'signal': signal});

  Future<RTCPeerConnection> _peer(int id) async {
    final existing = _peers[id];
    if (existing != null) return existing;
    final pc = await createPeerConnection(WebRTCService.iceConfig);
    _peers[id] = pc;
    pc.onIceCandidate = (c) => _signal(id, {
      'type': 'candidate',
      'candidate': c.candidate,
      'sdpMid': c.sdpMid,
      'sdpMLineIndex': c.sdpMLineIndex,
    });
    pc.onTrack = (e) {
      if (e.streams.isEmpty || isClosed) return;
      emit(state.copyWith(streams: {...state.streams, id: e.streams.first}));
    };
    pc.onConnectionState = (s) {
      if (s == RTCPeerConnectionState.RTCPeerConnectionStateFailed) _closePeer(id);
    };
    final local = _localStream;
    if (local != null) {
      for (final t in local.getTracks()) {
        await pc.addTrack(t, local);
      }
    }
    return pc;
  }

  Future<void> _onSignal(dynamic d) async {
    if (d['groupId'] != state.groupId) return;
    final from = d['from'] as int;
    final s = Map<String, dynamic>.from(d['signal'] as Map);
    try {
      switch (s['type']) {
        case 'offer':
          final pc = await _peer(from);
          await pc.setRemoteDescription(RTCSessionDescription(s['sdp'], 'offer'));
          await _flush(from);
          final answer = await pc.createAnswer();
          await pc.setLocalDescription(answer);
          _signal(from, {'type': 'answer', 'sdp': answer.sdp});
        case 'answer':
          final pc = _peers[from];
          if (pc == null) return;
          await pc.setRemoteDescription(RTCSessionDescription(s['sdp'], 'answer'));
          await _flush(from);
        case 'candidate':
          final c = RTCIceCandidate(s['candidate'], s['sdpMid'], s['sdpMLineIndex']);
          final pc = _peers[from];
          if (pc == null || !_remoteSet.contains(from)) {
            (_pending[from] ??= []).add(c);
          } else {
            await pc.addCandidate(c);
          }
      }
    } catch (e) {
      dev.log('Group call signal failed: $e', name: 'GroupCallCubit');
    }
  }

  /// ICE candidates that arrived before the other side's description.
  Future<void> _flush(int id) async {
    _remoteSet.add(id);
    for (final c in _pending.remove(id) ?? const <RTCIceCandidate>[]) {
      await _peers[id]?.addCandidate(c);
    }
  }

  void _closePeer(int id) {
    _peers.remove(id)?.close();
    _pending.remove(id);
    _remoteSet.remove(id);
    if (!isClosed) emit(state.copyWith(streams: {...state.streams}..remove(id)));
  }

  Future<void> leave() async {
    final g = state.groupId;
    if (g != null) await chat.request('gc_leave', {'groupId': g});
    for (final id in [..._peers.keys]) {
      _closePeer(id);
    }
    for (final t in _localStream?.getTracks() ?? <MediaStreamTrack>[]) {
      await t.stop();
    }
    await _localStream?.dispose();
    _localStream = null;
    if (!isClosed) {
      emit(state.copyWith(groupId: null, local: null, streams: {}, muted: false, cameraOff: false));
    }
  }

  void toggleMute() {
    for (final t in _localStream?.getAudioTracks() ?? <MediaStreamTrack>[]) {
      t.enabled = state.muted;
    }
    emit(state.copyWith(muted: !state.muted));
  }

  void toggleCamera() {
    for (final t in _localStream?.getVideoTracks() ?? <MediaStreamTrack>[]) {
      t.enabled = state.cameraOff;
    }
    emit(state.copyWith(cameraOff: !state.cameraOff));
  }

  void toggleSpeaker() {
    Helper.setSpeakerphoneOn(!state.speakerOn);
    emit(state.copyWith(speakerOn: !state.speakerOn));
  }

  @override
  Future<void> close() async {
    await leave();
    for (final s in _subs) {
      await s.cancel();
    }
    return super.close();
  }
}

import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../services/chat_service.dart';
import '../../../services/webrtc_service.dart';

part 'call_cubit.freezed.dart';

enum CallPhase { idle, incoming, dialing, connecting, connected, ended }

@freezed
abstract class CallState with _$CallState {
  const factory CallState({
    @Default(CallPhase.idle) CallPhase phase,
    int? peerId,
    @Default(false) bool video,
    @Default(false) bool cameraOff,
    @Default(false) bool speakerOn,
    @Default(false) bool muted,
    DateTime? connectedAt,
    String? endReason,
  }) = _CallState;
}

/// One voice call at a time. The peer id is kept here so hanging up always signals
/// the person on the call (it used to use whichever chat happened to be open).
class CallCubit extends Cubit<CallState> {
  CallCubit({required this.chat, required this.webrtc}) : super(const CallState()) {
    webrtc.onConnectionState = _onConnectionState;
    _subs.addAll([
      chat.on('call_offer').listen((d) {
        final from = d['from'] is String ? int.tryParse(d['from']) : d['from'] as int?;
        if (from == null) return;
        if (state.phase != CallPhase.idle && state.phase != CallPhase.ended) {
          chat.emit('call_reject', {'to': from}); // busy
          return;
        }
        _offer = d['offer'];
        emit(CallState(phase: CallPhase.incoming, peerId: from, video: d['video'] == true));
      }),
      chat.on('call_ended').listen((_) => _finish('Call ended')),
      chat.on('call_rejected').listen((_) => _finish('Declined')),
    ]);
  }

  final ChatService chat;
  final WebRTCService webrtc;
  final List<StreamSubscription> _subs = [];
  dynamic _offer;
  Timer? _resetTimer;

  Future<void> start(int peerId, {bool video = false}) async {
    _resetTimer?.cancel();
    // Video calls start on the loudspeaker, like every phone does
    emit(CallState(phase: CallPhase.dialing, peerId: peerId, video: video, speakerOn: video));
    try {
      await webrtc.startCall(peerId, video: video);
      if (video) webrtc.setSpeaker(true);
    } catch (e) {
      dev.log('Error starting call: $e', name: 'CallCubit');
      _finish('Couldn’t start the call');
    }
  }

  Future<void> accept() async {
    if (state.phase != CallPhase.incoming || state.peerId == null) return;
    emit(state.copyWith(phase: CallPhase.connecting, speakerOn: state.video));
    try {
      await webrtc.acceptCall(state.peerId!, _offer, video: state.video);
      if (state.video) webrtc.setSpeaker(true);
    } catch (e) {
      dev.log('Error accepting call: $e', name: 'CallCubit');
      _finish('Couldn’t connect');
    }
  }

  void decline() {
    if (state.peerId != null) chat.emit('call_reject', {'to': state.peerId});
    _finish('Declined');
  }

  void hangUp() {
    if (state.peerId != null) chat.emit('call_end', {'to': state.peerId});
    _finish('Call ended');
  }

  void toggleSpeaker() {
    webrtc.setSpeaker(!state.speakerOn);
    emit(state.copyWith(speakerOn: !state.speakerOn));
  }

  void toggleMute() {
    webrtc.setMuted(!state.muted);
    emit(state.copyWith(muted: !state.muted));
  }

  void toggleCamera() {
    webrtc.setCameraEnabled(state.cameraOff);
    emit(state.copyWith(cameraOff: !state.cameraOff));
  }

  void switchCamera() => webrtc.switchCamera();

  void _onConnectionState(RTCPeerConnectionState s) {
    switch (s) {
      case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
        emit(state.copyWith(phase: CallPhase.connected, connectedAt: DateTime.now()));
      case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
        _finish('Connection lost');
      default:
        break;
    }
  }

  void _finish(String reason) {
    if (state.phase == CallPhase.idle) return;
    webrtc.endCall();
    _offer = null;
    emit(state.copyWith(phase: CallPhase.ended, endReason: reason, speakerOn: false, muted: false, cameraOff: false));
    _resetTimer?.cancel();
    _resetTimer = Timer(const Duration(milliseconds: 1500), () {
      if (!isClosed && state.phase == CallPhase.ended) emit(const CallState());
    });
  }

  @override
  Future<void> close() async {
    _resetTimer?.cancel();
    for (final s in _subs) {
      await s.cancel();
    }
    webrtc.dispose();
    return super.close();
  }
}

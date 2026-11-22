import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';

import 'api_service.dart';
import 'chat_service.dart';

/// Voice or video peer connection. Signalling goes through [ChatService]; call lifecycle
/// (offer/end/reject events, UI state) lives in `CallCubit`.
class WebRTCService {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  void Function(RTCPeerConnectionState)? onConnectionState;

  /// Streams for the video views. Local is null on voice calls or when no camera is available.
  final localStream = ValueNotifier<MediaStream?>(null);
  final remoteStream = ValueNotifier<MediaStream?>(null);

  /// Candidates that arrive before the remote description (while ringing, or racing the
  /// answer) can't be added yet; they used to be dropped and the call never connected.
  final List<RTCIceCandidate> _pendingCandidates = [];
  bool _remoteSet = false;

  final ChatService _chat;
  final List<StreamSubscription> _subs = [];

  WebRTCService(this._chat) {
    _subs
      ..add(_chat.on('call_answer').listen(_handleAnswer))
      ..add(_chat.on('ice_candidate').listen(_handleIceCandidate));
  }

  // The coturn container runs next to the API, so reuse its host. Credentials match docker-compose.
  // Must match TURN_USER / TURN_PASSWORD in haki-backend/.env (pass with --dart-define)
  static const _turnUser = String.fromEnvironment('TURN_USER', defaultValue: 'user');
  static const _turnPassword = String.fromEnvironment('TURN_PASSWORD', defaultValue: 'password');

  // ponytail: static TURN user/password; switch to time-limited TURN REST credentials before production
  static final _turnHost = Uri.parse(ApiService.baseUrl).host;
  final Map<String, dynamic> _config = iceConfig;

  /// STUN/TURN servers, shared with group calls.
  static final Map<String, dynamic> iceConfig = {
    'iceServers': [
      {'urls': 'stun:$_turnHost:3478'},
      {'urls': 'turn:$_turnHost:3478', 'username': _turnUser, 'credential': _turnPassword},
    ],
  };

  Map<String, dynamic> _constraints(bool video) => {
    'mandatory': {'OfferToReceiveAudio': true, 'OfferToReceiveVideo': video},
    'optional': [],
  };

  Future<void> _createPeerConnection(int remoteUserId, {required bool video}) async {
    if (!await Permission.microphone.request().isGranted) {
      throw Exception('Microphone permission denied');
    }
    _peerConnection = await createPeerConnection(_config, _constraints(video));
    _peerConnection!.onConnectionState = (state) => onConnectionState?.call(state);
    _peerConnection!.onTrack = (e) {
      if (e.streams.isNotEmpty) remoteStream.value = e.streams.first;
    };
    _peerConnection!.onIceCandidate = (candidate) {
      _chat.emit('ice_candidate', {
        'to': remoteUserId,
        'candidate': {
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        },
      });
    };

    _localStream = await _openMedia(video);
    for (final track in _localStream!.getTracks()) {
      await _peerConnection!.addTrack(track, _localStream!);
    }
    final hasCamera = _localStream!.getVideoTracks().isNotEmpty;
    if (video && !hasCamera) {
      // No camera (denied, or a simulator): still receive the other person's video
      await _peerConnection!.addTransceiver(
        kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
        init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
      );
    }
    localStream.value = hasCamera ? _localStream : null;
  }

  /// Camera + mic for video calls, falling back to mic only when the camera can't be used.
  Future<MediaStream> _openMedia(bool video) async {
    // ponytail: a permission request that never answers (no camera, e.g. simulator) falls back
    // to audio after 20s; a real prompt is answered long before that
    final camera = video
        ? await Permission.camera.request().timeout(
            const Duration(seconds: 20),
            onTimeout: () => PermissionStatus.denied,
          )
        : PermissionStatus.denied;
    if (camera.isGranted) {
      try {
        return await navigator.mediaDevices.getUserMedia({
          'audio': true,
          'video': {'facingMode': 'user', 'width': 1280, 'height': 720},
        });
      } catch (e) {
        dev.log('Camera unavailable, continuing with audio: $e', name: 'WebRTCService');
      }
    }
    return navigator.mediaDevices.getUserMedia({'audio': true, 'video': false});
  }

  Future<void> startCall(int userId, {bool video = false}) async {
    _pendingCandidates.clear();
    await _createPeerConnection(userId, video: video);
    final offer = await _peerConnection!.createOffer(_constraints(video));
    await _peerConnection!.setLocalDescription(offer);
    _chat.emit('call_user', {
      'to': userId,
      'offer': {'sdp': offer.sdp, 'type': offer.type},
      'video': video,
    });
  }

  Future<void> acceptCall(int userId, dynamic remoteOffer, {bool video = false}) async {
    await _createPeerConnection(userId, video: video);
    await _peerConnection!.setRemoteDescription(
      RTCSessionDescription(remoteOffer['sdp'], remoteOffer['type']),
    );
    await _remoteReady();
    final answer = await _peerConnection!.createAnswer(_constraints(video));
    await _peerConnection!.setLocalDescription(answer);
    _chat.emit('call_answer', {
      'to': userId,
      'answer': {'sdp': answer.sdp, 'type': answer.type},
    });
  }

  Future<void> _handleAnswer(dynamic data) async {
    final pc = _peerConnection;
    if (pc == null) return;
    if (await pc.getSignalingState() != RTCSignalingState.RTCSignalingStateHaveLocalOffer) return;
    try {
      await pc.setRemoteDescription(
        RTCSessionDescription(data['answer']['sdp'], data['answer']['type']),
      );
      await _remoteReady();
    } catch (e) {
      dev.log('Error setting remote description: $e', name: 'WebRTCService');
    }
  }

  Future<void> _handleIceCandidate(dynamic data) async {
    final c = RTCIceCandidate(
      data['candidate']['candidate'],
      data['candidate']['sdpMid'],
      data['candidate']['sdpMLineIndex'],
    );
    final pc = _peerConnection;
    if (pc == null || !_remoteSet) return _pendingCandidates.add(c);
    try {
      await pc.addCandidate(c);
    } catch (e) {
      dev.log('Error adding ICE candidate: $e', name: 'WebRTCService');
    }
  }

  Future<void> _remoteReady() async {
    _remoteSet = true;
    final queued = [..._pendingCandidates];
    _pendingCandidates.clear();
    for (final c in queued) {
      try {
        await _peerConnection?.addCandidate(c);
      } catch (e) {
        dev.log('Error adding queued ICE candidate: $e', name: 'WebRTCService');
      }
    }
  }

  void setSpeaker(bool on) => Helper.setSpeakerphoneOn(on);

  void setMuted(bool muted) {
    for (final track in _localStream?.getAudioTracks() ?? <MediaStreamTrack>[]) {
      track.enabled = !muted;
    }
  }

  void setCameraEnabled(bool on) {
    for (final track in _localStream?.getVideoTracks() ?? <MediaStreamTrack>[]) {
      track.enabled = on;
    }
  }

  Future<void> switchCamera() async {
    final tracks = _localStream?.getVideoTracks() ?? [];
    if (tracks.isNotEmpty) await Helper.switchCamera(tracks.first);
  }

  void endCall() {
    _remoteSet = false;
    _pendingCandidates.clear();
    localStream.value = null;
    remoteStream.value = null;
    _localStream?.dispose();
    _peerConnection?.close();
    _localStream = null;
    _peerConnection = null;
  }

  void dispose() {
    endCall();
    for (final s in _subs) {
      s.cancel();
    }
  }
}

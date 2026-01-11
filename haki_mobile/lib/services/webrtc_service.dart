import 'dart:developer' as dev;

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';

import 'chat_service.dart';

typedef StreamStateCallback = void Function(MediaStream stream);

class WebRTCService {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  StreamStateCallback? onLocalStream;
  StreamStateCallback? onRemoteStream;
  Function(RTCPeerConnectionState)? onConnectionState;

  final ChatService _chatService;

  WebRTCService(this._chatService);

  // STUN/TURN configuration
  // For local dev with Docker Coturn:
  // Android Emulator needs 10.0.2.2 usually to access host,
  // but if tested on real device, it needs local IP.
  // Using localhost for iOS Sim / config for now.
  final Map<String, dynamic> _config = {
    'iceServers': [
      {'urls': 'stun:192.168.1.60:3478'},
      {'urls': 'turn:192.168.1.60:3478', 'username': 'user', 'credential': 'password'},
    ],
  };

  final Map<String, dynamic> _constraints = {
    'mandatory': {
      'OfferToReceiveAudio': true,
      'OfferToReceiveVideo': false, // Audio only for now
    },
    'optional': [],
  };

  Future<void> init() async {
    // Clear any existing listeners to prevent duplicates
    _chatService.socket?.off('call_offer');
    _chatService.socket?.off('call_answer');
    _chatService.socket?.off('ice_candidate');
    _chatService.socket?.off('call_rejected');
    _chatService.socket?.off('call_ended');

    // Listen to signaling events
    _chatService.socket?.on('call_offer', _handleOffer);
    _chatService.socket?.on('call_answer', _handleAnswer);
    _chatService.socket?.on('ice_candidate', _handleIceCandidate);
    _chatService.socket?.on('call_rejected', _handleReject);
    _chatService.socket?.on('call_ended', _handleEnd);
  }

  Future<void> _ensurePermissions() async {
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      status = await Permission.microphone.request();
      if (!status.isGranted) {
        dev.log('Microphone permission denied', name: 'WebRTCService');
        throw Exception('Microphone permission denied');
      }
    }
  }

  Future<void> _createPeerConnection(int remoteUserId) async {
    await _ensurePermissions();
    _peerConnection = await createPeerConnection(_config, _constraints);

    _peerConnection!.onConnectionState = (state) {
      if (onConnectionState != null) {
        onConnectionState!(state);
      }
    };

    _peerConnection!.onIceCandidate = (candidate) {
      _chatService.socket?.emit('ice_candidate', {
        'to': remoteUserId,
        'candidate': {
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        },
      });
    };

    _peerConnection!.onTrack = (event) {
      if (event.streams.isNotEmpty && onRemoteStream != null) {
        onRemoteStream!(event.streams[0]);
      }
    };

    _localStream = await navigator.mediaDevices.getUserMedia({'audio': true, 'video': false});
    if (onLocalStream != null) {
      onLocalStream!(_localStream!);
    }

    _localStream!.getTracks().forEach((track) {
      _peerConnection!.addTrack(track, _localStream!);
    });
  }

  Future<void> startCall(int userId) async {
    await _createPeerConnection(userId);
    RTCSessionDescription offer = await _peerConnection!.createOffer(_constraints);
    await _peerConnection!.setLocalDescription(offer);

    _chatService.socket?.emit('call_user', {
      'to': userId,
      'offer': {'sdp': offer.sdp, 'type': offer.type},
    });
  }

  Future<void> acceptCall(int userId, dynamic remoteOffer) async {
    await _createPeerConnection(userId);

    await _peerConnection!.setRemoteDescription(
      RTCSessionDescription(remoteOffer['sdp'], remoteOffer['type']),
    );

    RTCSessionDescription answer = await _peerConnection!.createAnswer(_constraints);
    await _peerConnection!.setLocalDescription(answer);

    _chatService.socket?.emit('call_answer', {
      'to': userId,
      'answer': {'sdp': answer.sdp, 'type': answer.type},
    });
  }

  void _handleOffer(dynamic data) {
    // Handled by UI triggers usually, just exposing callback or stream would be better.
    // For now, we assume CallProvider will handle listening to this.
  }

  void _handleAnswer(dynamic data) async {
    if (_peerConnection != null) {
      final state = await _peerConnection!.getSignalingState();
      if (state == RTCSignalingState.RTCSignalingStateHaveLocalOffer) {
        try {
          await _peerConnection!.setRemoteDescription(
            RTCSessionDescription(data['answer']['sdp'], data['answer']['type']),
          );
        } catch (e) {
          dev.log('Error setting remote description: $e', name: 'WebRTCService');
        }
      } else {
        dev.log(
          'Received answer but connection state is not HaveLocalOffer: $state',
          name: 'WebRTCService',
        );
      }
    }
  }

  void _handleIceCandidate(dynamic data) async {
    if (_peerConnection != null) {
      await _peerConnection!.addCandidate(
        RTCIceCandidate(
          data['candidate']['candidate'],
          data['candidate']['sdpMid'],
          data['candidate']['sdpMLineIndex'],
        ),
      );
    }
  }

  void _handleReject(dynamic data) {
    endCall();
  }

  void _handleEnd(dynamic data) {
    endCall();
  }

  void toggleSpeaker(bool isOn) {
    Helper.setSpeakerphoneOn(isOn);
  }

  void endCall() {
    _localStream?.dispose();
    _peerConnection?.close();
    _localStream = null;
    _peerConnection = null;
  }

  void dispose() {
    endCall();
    // Socket listeners cleanup?
    // ChatService manages socket, maybe just off listeners.
    _chatService.socket?.off('call_offer');
    _chatService.socket?.off('call_answer');
    _chatService.socket?.off('ice_candidate');
    _chatService.socket?.off('call_rejected');
    _chatService.socket?.off('call_ended');
  }
}

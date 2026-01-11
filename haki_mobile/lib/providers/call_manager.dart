import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../services/chat_service.dart';
import '../services/webrtc_service.dart';

/// Manages WebRTC calls
class CallManager extends ChangeNotifier {
  final ChatService _chat;
  final WebRTCService _webrtc;

  bool _isCallIncoming = false;
  int? _incomingCallUserId;
  dynamic _incomingCallOffer;
  String _callStatus = 'Idle';
  bool _isSpeakerOn = false;

  CallManager({required ChatService chat, required WebRTCService webrtc})
    : _chat = chat,
      _webrtc = webrtc;

  // Getters
  bool get isCallIncoming => _isCallIncoming;
  int? get incomingCallUserId => _incomingCallUserId;
  dynamic get incomingCallOffer => _incomingCallOffer;
  String get callStatus => _callStatus;
  bool get isSpeakerOn => _isSpeakerOn;

  /// Initialize WebRTC
  Future<void> init() async {
    await _webrtc.init();
  }

  /// Setup call-related listeners
  void setupListeners(int? Function() getActiveRecipientId) {
    _webrtc.onConnectionState = (state) {
      dev.log('WebRTC Connection State: $state', name: 'CallManager');
      switch (state) {
        case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
          _callStatus = 'Connected';
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
          _callStatus = 'Failed';
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
          _callStatus = 'Disconnected';
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateClosed:
          _callStatus = 'Ended';
          break;
        default:
          // Keep current status
          break;
      }
      notifyListeners();
    };

    // WebRTC Listeners
    _chat.socket?.on('call_offer', (data) {
      _isCallIncoming = true;
      if (data['from'] is String) {
        _incomingCallUserId = int.tryParse(data['from']);
      } else {
        _incomingCallUserId = data['from'];
      }
      _incomingCallOffer = data['offer'];
      _callStatus = 'Incoming Call...';
      notifyListeners();
    });

    _chat.socket?.on('call_ended', (_) {
      _isCallIncoming = false;
      _incomingCallUserId = null;
      _incomingCallOffer = null;
      _webrtc.endCall();
      notifyListeners();
    });
  }

  /// Start a call
  Future<void> startCall(int userId) async {
    _callStatus = 'Dialing...';
    notifyListeners();
    try {
      await _webrtc.startCall(userId);
    } catch (e) {
      dev.log('Error starting call: $e', name: 'CallManager');
      _callStatus = 'Failed';
      notifyListeners();
    }
  }

  /// Accept incoming call
  Future<void> acceptCall() async {
    if (_incomingCallUserId != null && _incomingCallOffer != null) {
      try {
        _callStatus = 'Connecting...';
        await _webrtc.acceptCall(_incomingCallUserId!, _incomingCallOffer);
        _isCallIncoming = false;
        notifyListeners();
      } catch (e) {
        dev.log('Error accepting call: $e', name: 'CallManager');
        _callStatus = 'Failed';
        notifyListeners();
      }
    }
  }

  /// Decline incoming call
  void declineCall() {
    if (_incomingCallUserId != null) {
      _chat.socket?.emit('call_reject', {'to': _incomingCallUserId});
      _isCallIncoming = false;
      _incomingCallUserId = null;
      _incomingCallOffer = null;
      _callStatus = 'Idle';
      notifyListeners();
    }
  }

  /// End active call
  void endCall(int? activeRecipientId) {
    _webrtc.endCall();
    if (activeRecipientId != null) {
      _chat.socket?.emit('call_end', {'to': activeRecipientId});
    }
    _callStatus = 'Ended';
    _isSpeakerOn = false;
    notifyListeners();

    // Reset to Idle after a delay
    Future.delayed(const Duration(seconds: 2), () {
      _callStatus = 'Idle';
      notifyListeners();
    });
  }

  /// Toggle speaker on/off
  void toggleSpeaker() {
    _isSpeakerOn = !_isSpeakerOn;
    _webrtc.toggleSpeaker(_isSpeakerOn);
    notifyListeners();
  }

  /// Clear call state
  void clear() {
    _isCallIncoming = false;
    _incomingCallUserId = null;
    _incomingCallOffer = null;
    _callStatus = 'Idle';
    _isSpeakerOn = false;
  }
}

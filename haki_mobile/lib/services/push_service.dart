import 'dart:developer' as dev;
import '../core/utils/platform.dart';

import 'package:flutter/services.dart';

import 'api_service.dart';

/// Push (APNs on iPhone, FCM on Android): asks permission, registers this phone's token with the server, and reports
/// taps on notifications. Notifications carry no names or text, only which chat to open.
class PushService {
  PushService(this.api);

  final ApiService api;
  static const _channel = MethodChannel('haki/push');
  String? _token;

  /// Called with `{u: friendId}`, `{g: groupId}` or `{lounge: 1}` when a notification is tapped.
  void Function(Map<String, dynamic> chat)? onOpen;

  /// iOS: APNs. Android: Firebase Cloud Messaging (needs the project's google-services.json).
  static bool get supported => Device.phone;

  Future<void> start() async {
    if (!supported) return;
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'token':
          _token = call.arguments as String;
          await api.registerPushToken(_token!, platform: Device.android ? 'android' : 'ios');
        case 'open':
          await _takePending(); // handled now; don't open it again on next start
          onOpen?.call(Map<String, dynamic>.from(call.arguments as Map));
        case 'error':
          dev.log('Push registration failed: ${call.arguments}', name: 'PushService');
      }
    });
    try {
      await _channel.invokeMethod('register');
      // App was launched by tapping a notification
      final pending = await _takePending();
      if (pending != null && pending.isNotEmpty) onOpen?.call(pending);
    } on PlatformException catch (e) {
      dev.log('Push unavailable: ${e.message}', name: 'PushService');
    }
  }

  Future<Map<String, dynamic>?> _takePending() async {
    final raw = await _channel.invokeMethod<Map>('takePendingChat');
    return raw == null ? null : Map<String, dynamic>.from(raw);
  }

  /// Sign-out: this phone stops receiving the account's notifications.
  Future<void> stop() async {
    final token = _token;
    if (token == null) return;
    _token = null;
    try {
      await api.unregisterPushToken(token);
    } catch (_) {}
  }
}

import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:uuid/uuid.dart';

import '../core/utils/platform.dart';
import 'api_service.dart';

/// The phone's own incoming-call screen: CallKit on iPhone, a full-screen call notification on
/// Android. Used when a call arrives while Haki isn't on screen.
abstract final class NativeCalls {
  static String? _id;

  static Stream<CallEvent?> get events => Device.phone ? FlutterCallkitIncoming.onEvent : const Stream.empty();

  static Future<void> showIncoming({required int peerId, required String name, required bool video}) async {
    if (!Device.phone) return; // computers: the in-app ring is enough
    _id = const Uuid().v4();
    await FlutterCallkitIncoming.showCallkitIncoming(CallKitParams(
      id: _id!,
      nameCaller: name,
      appName: 'Haki',
      handle: video ? 'Haki video call' : 'Haki voice call',
      type: video ? 1 : 0,
      duration: 45000,
      extra: {'u': peerId},
      ios: const IOSParams(handleType: 'generic', supportsVideo: true, includesCallsInRecents: false),
      android: const AndroidParams(isCustomNotification: false, isShowLogo: false, backgroundColor: '#0B0B12', actionColor: '#C6F432'),
    ));
  }

  /// Our call ended in the app: take down the system call screen too.
  static Future<void> end() async {
    _id = null;
    if (Device.phone) await FlutterCallkitIncoming.endAllCalls();
  }

  /// iPhone: register the PushKit token so calls ring through CallKit even when Haki is closed.
  static Future<void> registerVoip(ApiService api) async {
    if (!Device.ios) return;
    final token = await FlutterCallkitIncoming.getDevicePushTokenVoIP();
    if (token is String && token.isNotEmpty) await api.registerPushToken(token, platform: 'voip');
  }
}

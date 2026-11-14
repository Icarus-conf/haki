import 'package:local_auth/local_auth.dart';

/// Face ID / Touch ID / device passcode for locked chats. Nothing leaves the phone.
abstract final class ChatLock {
  static final _auth = LocalAuthentication();

  /// True when the phone has Face ID, Touch ID or a passcode set up.
  static Future<bool> available() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  static Future<bool> unlock(String reason) async {
    try {
      return await _auth.authenticate(localizedReason: reason);
    } catch (_) {
      return false;
    }
  }
}

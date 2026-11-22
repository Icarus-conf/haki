import '../core/utils/platform.dart';
import 'package:flutter/services.dart';

/// On-device speech-to-text for voice notes (iOS Speech framework, on-device only).
abstract final class Transcriber {
  static const _channel = MethodChannel('haki/transcribe');

  // ponytail: iOS only; Android needs its own on-device recognizer before this shows there
  static bool get supported => Device.ios;

  /// The text, or throws with a readable message.
  static Future<String> transcribe(String path) async {
    try {
      final text = await _channel.invokeMethod<String>('transcribe', {'path': path});
      if (text == null || text.trim().isEmpty) throw Exception('No speech found in this message');
      return text;
    } on PlatformException catch (e) {
      throw Exception(e.message ?? 'Couldn’t transcribe');
    }
  }
}

/// On-device translation of a message into the phone's language (Apple Translation, iOS 26+).
abstract final class Translator {
  static const _channel = MethodChannel('haki/translate');

  // ponytail: iOS only; Android could use ML Kit on-device translation
  static bool get supported => Device.ios;

  /// (translated text, source language name), or throws with a readable message.
  static Future<(String, String)> translate(String text) async {
    try {
      final r = await _channel.invokeMapMethod<String, dynamic>('translate', {'text': text});
      return (r!['text'] as String, r['from'] as String);
    } on PlatformException catch (e) {
      throw Exception(e.message ?? 'Couldn’t translate');
    }
  }
}

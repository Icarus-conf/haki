import 'package:flutter/foundation.dart';

/// Which kind of device this is. Safe on the web, where dart:io's Platform throws.
abstract final class Device {
  static TargetPlatform get _p => defaultTargetPlatform;
  static bool get web => kIsWeb;
  static bool get ios => !kIsWeb && _p == TargetPlatform.iOS;
  static bool get android => !kIsWeb && _p == TargetPlatform.android;
  static bool get macos => !kIsWeb && _p == TargetPlatform.macOS;
  static bool get windows => !kIsWeb && _p == TargetPlatform.windows;
  static bool get linux => !kIsWeb && _p == TargetPlatform.linux;
  static bool get phone => ios || android;
  static bool get desktop => macos || windows || linux;

  /// Mouse and keyboard first: desktop apps and the web on a computer.
  static bool get pointer => desktop || (kIsWeb && !(_p == TargetPlatform.iOS || _p == TargetPlatform.android));

  /// Shown in You → Devices.
  static String get name => ios
      ? 'iPhone'
      : android
          ? 'Android phone'
          : macos
              ? 'Mac'
              : windows
                  ? 'Windows PC'
                  : linux
                      ? 'Linux PC'
                      : 'Web browser';

  static String get id => web
      ? 'web'
      : ios
          ? 'ios'
          : android
              ? 'android'
              : macos
                  ? 'macos'
                  : windows
                      ? 'windows'
                      : 'linux';
}

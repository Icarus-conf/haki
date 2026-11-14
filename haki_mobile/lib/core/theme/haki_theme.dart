import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// "Aurora Glass" design tokens.
abstract final class HakiColors {
  static const ink = Color(0xFF08080C);
  static const surface = Color(0xFF15151D);
  static const surfaceHigh = Color(0xFF1C1C26);
  static const incomingBubble = Color(0xFF17171F);
  static const outgoingBubble = Color(0xFF5B4BFF);
  static const lime = Color(0xFFDDFB5C);
  static const onLime = Color(0xFF101300);
  static const violet = Color(0xFF7B5CFF);
  static const blue = Color(0xFF2E5BFF);
  static const teal = Color(0xFF18B39B);
  static const pink = Color(0xFFF05A9D);
  static const text = Color(0xFFF5F5FA);
  static const textMuted = Color(0xFF8E8EA6); // 6.3:1 on ink
  static const danger = Color(0xFFE5383B);
  static const dangerText = Color(0xFFF87171);

  /// Avatar auras: (light, mid, dark) stops of a radial gradient.
  static const auras = [
    [Color(0xFFD6C8FF), Color(0xFF7B5CFF), Color(0xFF2B1773)],
    [Color(0xFFBFE0FF), Color(0xFF2E7BFF), Color(0xFF0D2566)],
    [Color(0xFFFFD0E6), Color(0xFFF05A9D), Color(0xFF5E1238)],
    [Color(0xFFFFE2B8), Color(0xFFFF8A3D), Color(0xFF6B2A07)],
    [Color(0xFFC9FFF0), Color(0xFF18B39B), Color(0xFF07423A)],
  ];

  static List<Color> auraFor(int seed) => auras[seed.abs() % auras.length];
}

abstract final class HakiText {
  /// Big expressive headings (Bricolage Grotesque).
  static TextStyle display(double size, {Color color = HakiColors.text, FontWeight weight = FontWeight.w800}) =>
      GoogleFonts.bricolageGrotesque(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: 1.0,
        letterSpacing: -size * 0.035,
      );

  static TextStyle mono(double size, {Color color = HakiColors.text}) =>
      GoogleFonts.geistMono(fontSize: size, color: color, fontWeight: FontWeight.w500);
}

ThemeData buildHakiTheme() {
  final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);
  final text = GoogleFonts.geistTextTheme(base.textTheme).apply(
    bodyColor: HakiColors.text,
    displayColor: HakiColors.text,
  );
  return base.copyWith(
    scaffoldBackgroundColor: HakiColors.ink,
    textTheme: text,
    colorScheme: const ColorScheme.dark(
      primary: HakiColors.lime,
      onPrimary: HakiColors.onLime,
      secondary: HakiColors.violet,
      surface: HakiColors.ink,
      onSurface: HakiColors.text,
      error: HakiColors.dangerText,
    ),
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      foregroundColor: HakiColors.text,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: HakiColors.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: Color(0x55FFFFFF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: HakiColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(28))),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: HakiColors.surfaceHigh,
      contentTextStyle: text.bodyMedium,
      shape: const StadiumBorder(),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.07),
      hintStyle: const TextStyle(color: HakiColors.textMuted),
      labelStyle: const TextStyle(color: HakiColors.textMuted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: HakiColors.lime, width: 1.5),
      ),
    ),
    textSelectionTheme: const TextSelectionThemeData(cursorColor: HakiColors.lime),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: HakiColors.lime),
  );
}

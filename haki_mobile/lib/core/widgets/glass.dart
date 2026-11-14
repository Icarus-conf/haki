import 'dart:async';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../theme/haki_theme.dart';

/// Frosted "liquid glass" surface for floating chrome (nav, headers, composer).
class Glass extends StatelessWidget {
  const Glass({
    super.key,
    required this.child,
    this.radius = 28,
    this.padding = EdgeInsets.zero,
    this.tint = 0.09,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final double tint;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: r,
        boxShadow: const [BoxShadow(color: Color(0x59000000), blurRadius: 30, offset: Offset(0, 10))],
      ),
      child: ClipRRect(
        borderRadius: r,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: r,
              color: Colors.white.withValues(alpha: tint),
              border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Soft colour field that fades into ink. Uses radial gradients instead of blur so it
/// costs nothing per frame.
class AuroraBackground extends StatelessWidget {
  const AuroraBackground({
    super.key,
    this.height = 460,
    this.colors = const [HakiColors.violet, HakiColors.blue, HakiColors.teal],
    this.fadeStart = 0.35,
  });

  final double height;
  final List<Color> colors;
  final double fadeStart;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    Widget blob(Color c, double size, double left, double top, double strength) => Positioned(
      left: left,
      top: top,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [c.withValues(alpha: strength), c.withValues(alpha: 0)],
          ),
        ),
      ),
    );

    return IgnorePointer(
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            blob(colors[0], w * 1.2, -w * 0.45, -height * 0.3, 0.9),
            blob(colors[1], w * 1.1, w * 0.35, -height * 0.1, 0.8),
            if (colors.length > 2) blob(colors[2], w * 0.8, w * 0.1, height * 0.25, 0.45),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [fadeStart, 0.97],
                    colors: [HakiColors.ink.withValues(alpha: 0), HakiColors.ink],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Rounded-square avatar: the photo when there is one, otherwise a coloured aura with initials.
/// (Replaces the DiceBear fallback, which sent every username to a third-party server.)
class AuraAvatar extends StatelessWidget {
  const AuraAvatar({super.key, required this.user, this.size = 50, this.radius});

  final UserModel user;
  final double size;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius ?? size * 0.36);
    final aura = HakiColors.auraFor(user.id);
    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: r,
        gradient: RadialGradient(
          center: const Alignment(-0.4, -0.5),
          radius: 1.1,
          colors: aura,
          stops: const [0, 0.5, 1],
        ),
      ),
      child: Text(user.initials, style: HakiText.display(size * 0.36, weight: FontWeight.w700)),
    );
    if (user.avatarUrl == null) return fallback;
    return ClipRRect(
      borderRadius: r,
      child: CachedNetworkImage(
        imageUrl: '${ApiService.baseUrl}${user.avatarUrl}',
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, _) => fallback,
        errorWidget: (_, _, _) => fallback,
      ),
    );
  }
}

/// Primary call to action.
class LimeButton extends StatelessWidget {
  const LimeButton({super.key, required this.label, this.onPressed, this.icon, this.busy = false});

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: FilledButton(
        onPressed: busy ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: HakiColors.lime,
          foregroundColor: HakiColors.onLime,
          disabledBackgroundColor: HakiColors.lime.withValues(alpha: 0.5),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        child: busy
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: HakiColors.onLime),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label),
                  if (icon != null) ...[const SizedBox(width: 8), Icon(icon, size: 20)],
                ],
              ),
      ),
    );
  }
}

/// Secondary pill on glass.
class GlassButton extends StatelessWidget {
  const GlassButton({super.key, required this.label, this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: 29,
      tint: 0.12,
      child: SizedBox(
        height: 56,
        width: double.infinity,
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: HakiColors.text,
            shape: const StadiumBorder(),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          child: Text(label),
        ),
      ),
    );
  }
}

/// Round icon button on glass (back, call, attach…).
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.size = 48,
    this.color,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final double size;

  /// Icon colour; defaults to the text colour.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: size / 2,
      child: SizedBox(
        width: size,
        height: size,
        child: IconButton(
          tooltip: tooltip,
          onPressed: onPressed,
          icon: Icon(icon, size: size * 0.44, color: color ?? HakiColors.text),
        ),
      ),
    );
  }
}

/// Lime pill showing a count (unread, requests).
class CountBadge extends StatelessWidget {
  const CountBadge(this.count, {super.key});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 22),
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: HakiColors.lime, borderRadius: BorderRadius.circular(11)),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(color: HakiColors.onLime, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// Yes/no dialog for destructive actions.
Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  required String action,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(action, style: const TextStyle(color: HakiColors.dangerText)),
        ),
      ],
    ),
  );
  return ok ?? false;
}

void showHakiToast(BuildContext context, String message, {bool isError = false, VoidCallback? onUndo}) =>
    showTopToast(
      Overlay.of(context, rootOverlay: true),
      message,
      isError: isError,
      action: onUndo == null ? null : 'Undo',
      onAction: onUndo,
      duration: Duration(seconds: onUndo == null ? 4 : 5),
    );

OverlayEntry? _toast;
Timer? _toastTimer;

void hideTopToast() {
  _toastTimer?.cancel();
  _toast?.remove();
  _toast = null;
}

/// Toasts drop in from the top: at the bottom they covered the tab bar and the composer.
/// One at a time; a new one replaces the old. Swipe up to dismiss.
void showTopToast(
  OverlayState? overlay,
  String message, {
  bool isError = false,
  String? action,
  VoidCallback? onAction,
  Duration duration = const Duration(seconds: 4),
  int maxLines = 2,
}) {
  if (overlay == null) return;
  hideTopToast();
  late final OverlayEntry entry;
  void close() {
    if (_toast == entry) hideTopToast();
  }

  entry = OverlayEntry(
    builder: (context) => Positioned(
      top: MediaQuery.paddingOf(context).top + 8,
      left: 16,
      right: 16,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        builder: (context, t, child) => Opacity(
          opacity: t,
          child: Transform.translate(offset: Offset(0, (t - 1) * 24), child: child),
        ),
        child: Dismissible(
          key: ObjectKey(entry),
          direction: DismissDirection.up,
          onDismissed: (_) => close(),
          child: Material(
            color: HakiColors.surfaceHigh,
            shape: StadiumBorder(side: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
            elevation: 8,
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 6, action == null ? 20 : 6, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        message,
                        maxLines: maxLines,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: isError ? HakiColors.dangerText : HakiColors.text, fontSize: 14),
                      ),
                    ),
                  ),
                  if (action != null)
                    TextButton(
                      style: TextButton.styleFrom(foregroundColor: HakiColors.lime),
                      onPressed: () {
                        close();
                        onAction?.call();
                      },
                      child: Text(action, style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
  _toast = entry;
  overlay.insert(entry);
  _toastTimer = Timer(duration, close);
}

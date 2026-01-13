import 'dart:async';

import 'package:flutter/material.dart';

class ToastUtils {
  static void showToast(
    BuildContext context,
    String message, {
    bool isError = false,
    VoidCallback? onUndo,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _ToastWidget(
        message: message,
        isError: isError,
        onUndo: onUndo == null
            ? null
            : () {
                onUndo();
                overlayEntry.remove();
              },
      ),
    );

    overlay.insert(overlayEntry);

    // Remove the toast after a delay
    // If undo is available, give it more time (5s), otherwise 3s
    Future.delayed(Duration(seconds: onUndo != null ? 5 : 3), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final bool isError;
  final VoidCallback? onUndo;

  const _ToastWidget({required this.message, this.isError = false, this.onUndo});

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _offset;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    final duration = Duration(seconds: widget.onUndo != null ? 5 : 3);

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      reverseDuration: const Duration(milliseconds: 300),
    );

    _opacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _offset = Tween<Offset>(
      begin: const Offset(0, 0.5), // Start slightly below
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();

    // Start fade out before removing
    _countdownTimer = Timer(duration - const Duration(milliseconds: 400), () {
      if (mounted) {
        _controller.reverse();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 50,
      left: 20,
      right: 20,
      child: Material(
        color: Colors.transparent,
        child: PointerInterceptor(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return FadeTransition(
                opacity: _opacity,
                child: SlideTransition(
                  position: _offset,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: widget.isError
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF1E293B), // Red or Dark Slate
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!widget.isError && widget.onUndo == null) ...[
                            const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                            const SizedBox(width: 12),
                          ],
                          if (widget.isError) ...[
                            const Icon(Icons.error_outline, color: Colors.white, size: 20),
                            const SizedBox(width: 12),
                          ],
                          Flexible(
                            child: Text(
                              widget.message,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          if (widget.onUndo != null) ...[
                            const SizedBox(width: 12),
                            Container(
                              height: 24,
                              width: 1,
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                            const SizedBox(width: 4),
                            TextButton(
                              onPressed: widget.onUndo,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text(
                                'UNDO',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// Helper widget to intercept pointer events if needed, for now just a pass through
// In complex apps, we might need to block touches below or allow them.
// By default OverlayEntry blocks touches only on the widget itself.
class PointerInterceptor extends StatelessWidget {
  final Widget child;
  const PointerInterceptor({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    return child;
  }
}

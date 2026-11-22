import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../core/theme/haki_theme.dart';
import '../core/widgets/glass.dart';
import 'package:chat_mobile/core/theme/haki_icons.dart';

class VoiceRecorder extends StatefulWidget {
  /// The recording and how long it is (shown to the other person before they play it).
  final void Function(String path, Duration length) onStop;
  final VoidCallback onCancel;

  const VoiceRecorder({super.key, required this.onStop, required this.onCancel});

  @override
  State<VoiceRecorder> createState() => _VoiceRecorderState();
}

class _VoiceRecorderState extends State<VoiceRecorder> with TickerProviderStateMixin {
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  bool _isStarting = false;
  DateTime? _startTime;
  Timer? _timer;
  Duration _duration = Duration.zero;
  double _initialDragX = 0;
  bool _isCancelled = false;

  late AnimationController _pulseController;
  late AnimationController _scaleController;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    ); // pulses only while recording: a repeating ticker redraws the screen every frame

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Initialize scale controller to normal scale
    _scaleController.value = 1.0;
  }

  @override
  void dispose() {
    _recorder.dispose();
    _timer?.cancel();
    _pulseController.dispose();
    _scaleController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      // Add haptic feedback
      HapticFeedback.lightImpact();

      setState(() {
        _isStarting = true;
      });

      // Scale animation for smooth start
      _scaleController.forward().then((_) {
        _scaleController.reverse();
      });

      if (await Permission.microphone.request().isGranted) {
        final tempDir = await getTemporaryDirectory();
        final path = '${tempDir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _recorder.start(const RecordConfig(), path: path);

        setState(() {
          _isRecording = true;
          _isStarting = false;
          _startTime = DateTime.now();
          _duration = Duration.zero;
          _isCancelled = false;
          _initialDragX = 0;
        });

        // Start wave animation
        _waveController.repeat();
        _pulseController.repeat(reverse: true);

        // Start timer with shorter interval for smoother updates
        _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
          if (mounted) {
            setState(() {
              _duration = DateTime.now().difference(_startTime!);
            });
          }
        });
      } else {
        setState(() {
          _isStarting = false;
        });
      }
    } catch (e) {
      debugPrint('Error starting recording: $e');
      setState(() {
        _isStarting = false;
      });
    }
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    _waveController.stop();
    _pulseController.stop();

    // Add haptic feedback
    if (_isCancelled) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.mediumImpact();
    }

    final path = await _recorder.stop();
    setState(() {
      _isRecording = false;
      _isStarting = false;
    });

    // A tap or very short hold is almost always accidental: don't send a blip
    final tooShort = _duration < const Duration(seconds: 1);
    if (!_isCancelled && path != null && tooShort) {
      try {
        await File(path).delete();
      } catch (_) {}
      widget.onCancel();
      if (mounted) showHakiToast(context, 'Hold the mic to record, release to send');
      return;
    }

    if (!_isCancelled && path != null) {
      widget.onStop(path, _duration);
    } else if (_isCancelled && path != null) {
      try {
        await File(path).delete();
        widget.onCancel();
      } catch (_) {}
    }
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (details) {
        _initialDragX = details.localPosition.dx;
        _startRecording();
      },
      onLongPressEnd: (details) {
        _stopRecording();
      },
      onLongPressMoveUpdate: (details) {
        if (_isRecording) {
          final currentDragX = details.localPosition.dx;
          final dragDistance = currentDragX - _initialDragX;

          setState(() {
            // Cancel threshold: 80px to the left
            if (dragDistance < -80) {
              if (!_isCancelled) {
                _isCancelled = true;
                HapticFeedback.selectionClick();
              }
            } else {
              _isCancelled = false;
            }
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: _isRecording
            ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
            : EdgeInsets.zero,
        decoration: BoxDecoration(
          gradient: _isRecording
              ? LinearGradient(
                  colors: _isCancelled
                      ? [HakiColors.danger.withValues(alpha: 0.25), HakiColors.danger.withValues(alpha: 0.25)]
                      : [HakiColors.surfaceHigh, HakiColors.surfaceHigh],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          borderRadius: BorderRadius.circular(_isRecording ? 24 : 28),
          border: _isRecording
              ? Border.all(
                  color: _isCancelled
                      ? Colors.red.withValues(alpha: 0.3)
                      : Colors.blue.withValues(alpha: 0.2),
                  width: 2,
                )
              : null,
          boxShadow: _isRecording
              ? [
                  BoxShadow(
                    color: (_isCancelled ? Colors.red : Colors.blue).withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: _isRecording || _isStarting
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Recording indicator with pulse
                  ScaleTransition(
                    scale: _scaleController,
                    child: FadeTransition(
                      opacity: _pulseController,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _isCancelled ? Colors.red : Colors.red.shade600,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (_isCancelled ? Colors.red : Colors.red.shade600).withValues(
                                alpha: 0.5,
                              ),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Timer
                  Text(
                    _formatDuration(_duration),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: _isCancelled ? Colors.red : Colors.white,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Cancel instruction
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Row(
                      key: ValueKey(_isCancelled),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          HakiIcons.arrowLeft,
                          size: 14,
                          color: _isCancelled ? Colors.red : HakiColors.textMuted,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          _isCancelled ? "Cancel" : "Slide",
                          style: TextStyle(
                            color: _isCancelled ? Colors.red : HakiColors.textMuted,
                            fontSize: 12,
                            fontWeight: _isCancelled ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: HakiColors.lime,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: HakiColors.lime.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(HakiIcons.microphone, color: HakiColors.onLime, size: 20),
              ),
      ),
    );
  }
}

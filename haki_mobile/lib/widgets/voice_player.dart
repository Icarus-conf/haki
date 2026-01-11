import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../providers/chat_provider.dart';
import '../services/api_service.dart';

class VoicePlayer extends StatefulWidget {
  final String url;
  final String? iv;
  final Map<String, dynamic>? keys;

  const VoicePlayer({super.key, required this.url, this.iv, this.keys});

  @override
  State<VoicePlayer> createState() => _VoicePlayerState();
}

class _VoicePlayerState extends State<VoicePlayer> with SingleTickerProviderStateMixin {
  final AudioPlayer _player = AudioPlayer();
  PlayerState _playerState = PlayerState.stopped;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isLoading = false;
  bool _isInitialized = false;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    _player.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => _playerState = state);
        if (state == PlayerState.playing) {
          _waveController.repeat();
        } else {
          _waveController.stop();
        }
      }
    });
    _player.onDurationChanged.listen((duration) {
      if (mounted) setState(() => _duration = duration);
    });
    _player.onPositionChanged.listen((position) {
      if (mounted) setState(() => _position = position);
    });
    _player.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() {
          _playerState = PlayerState.completed;
          _position = Duration.zero;
        });
        _waveController.reset();
      }
    });
  }

  Future<void> _setupAndPlay() async {
    if (_isInitialized) {
      if (_playerState == PlayerState.playing) {
        await _player.pause();
      } else {
        await _player.resume();
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final chat = context.read<ChatProvider>();
      final isRemote = widget.url.startsWith('http') || widget.url.startsWith('/uploads');
      final isEncrypted = widget.iv != null && widget.keys != null;

      if (isRemote) {
        final uri = widget.url.startsWith('http')
            ? Uri.parse(widget.url)
            : Uri.parse('${ApiService.baseUrl}${widget.url}');

        final response = await http.get(uri);
        if (response.statusCode == 200) {
          if (isEncrypted) {
            final decrypted = await chat.crypto.decryptMedia(
              encryptedBytes: response.bodyBytes,
              ivBase64: widget.iv!,
              keys: widget.keys!,
              username: chat.me!.username,
            );
            if (decrypted != null) {
              final tempDir = await getTemporaryDirectory();
              final tempFile = File(
                '${tempDir.path}/dec_${DateTime.now().millisecondsSinceEpoch}.m4a',
              );
              await tempFile.writeAsBytes(decrypted);
              await _player.setSourceDeviceFile(tempFile.path);
            } else {
              throw Exception('Decryption failed');
            }
          } else {
            await _player.setSourceUrl(uri.toString());
          }
        }
      } else {
        // Local file - always unencrypted (optimistic UI for sender)
        final file = File(widget.url);
        if (file.existsSync()) {
          await _player.setSourceDeviceFile(widget.url);
        }
      }

      _isInitialized = true;
      await _player.resume();
    } catch (e) {
      debugPrint('Error playing audio: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _player.dispose();
    _waveController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    final bool isPlaying = _playerState == PlayerState.playing;

    // Clamp position to duration to prevent overflow
    final safePosition = _position.inMilliseconds > _duration.inMilliseconds
        ? _duration
        : _position;

    final progress = _duration.inMilliseconds > 0
        ? (safePosition.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      width: 260,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.purple.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Play/Pause Button with Animation
          GestureDetector(
            onTap: _isLoading ? null : _setupAndPlay,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color.fromARGB(255, 52, 55, 149),
                    const Color.fromARGB(255, 98, 98, 197),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(
                      isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
            ),
          ),
          const SizedBox(width: 12),

          // Waveform and Progress
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Animated Waveform
                SizedBox(
                  height: 32,
                  child: AnimatedBuilder(
                    animation: _waveController,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: _WaveformPainter(
                          progress: progress,
                          animationValue: _waveController.value,
                          isPlaying: isPlaying,
                        ),
                        size: const Size(double.infinity, 32),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 4),

                // Time Display
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(safePosition),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.mic_rounded, size: 10, color: Colors.grey[600]),
                          const SizedBox(width: 2),
                          Text(
                            _formatDuration(_duration),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final double progress;
  final double animationValue;
  final bool isPlaying;

  _WaveformPainter({required this.progress, required this.animationValue, required this.isPlaying});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    const barCount = 40;
    final barWidth = 2.0;
    final spacing = (size.width - (barCount * barWidth)) / (barCount - 1);

    for (int i = 0; i < barCount; i++) {
      final x = i * (barWidth + spacing);

      // Create varied heights for waveform effect
      final baseHeight = size.height * 0.3;
      final waveHeight =
          size.height *
          0.7 *
          (0.3 +
              0.7 *
                  (1 +
                      (i % 3 == 0
                          ? 0.5
                          : i % 2 == 0
                          ? 0.3
                          : 0.1)));

      // Animate when playing
      final animatedHeight = isPlaying
          ? waveHeight * (0.7 + 0.3 * (1 + (animationValue * 2 - 1) * (i % 2 == 0 ? 1 : -1)).abs())
          : waveHeight;

      final height = baseHeight + animatedHeight * 0.5;

      // Color based on progress
      final barProgress = i / barCount;
      final isPlayed = barProgress <= progress;

      paint.color = isPlayed ? const Color.fromARGB(255, 52, 55, 149) : Colors.grey.shade300;

      final y1 = (size.height - height) / 2;
      final y2 = y1 + height;

      canvas.drawLine(Offset(x, y1), Offset(x, y2), paint);
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.animationValue != animationValue ||
        oldDelegate.isPlaying != isPlaying;
  }
}

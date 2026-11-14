import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../features/session/view_model/session_cubit.dart';
import '../core/theme/haki_theme.dart';
import '../core/widgets/glass.dart';
import '../services/api_service.dart';
import '../services/transcriber.dart';
import 'package:chat_mobile/core/theme/haki_icons.dart';

class VoicePlayer extends StatefulWidget {
  final String url;
  final String? iv;
  final Map<String, dynamic>? keys;

  const VoicePlayer({super.key, required this.url, this.iv, this.keys, this.knownDuration});

  /// Length sent inside the encrypted message, so it shows before the first play.
  final Duration? knownDuration;

  @override
  State<VoicePlayer> createState() => _VoicePlayerState();
}

class _VoicePlayerState extends State<VoicePlayer> with SingleTickerProviderStateMixin {
  /// Only one voice note plays at a time.
  static _VoicePlayerState? _active;

  /// Decrypted audio file per URL, so replaying (or a rebuilt list) doesn't decrypt again.
  static final Map<String, String> _decryptedFiles = {};

  /// Transcripts per URL for this app session (made on the phone, never uploaded).
  static final Map<String, String> _transcripts = {};
  bool _transcribing = false;

  final AudioPlayer _player = AudioPlayer();

  /// iOS can emit a late "playing" after "completed" for very short clips; ignore it
  /// until the user presses play again.
  bool _finished = false;
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
    _duration = widget.knownDuration ?? Duration.zero;
    _initPlayer();
  }

  /// A playable local file: the sender's own recording, or the downloaded + decrypted copy.
  Future<String> _localFile() async {
    final isRemote = widget.url.startsWith('http') || widget.url.startsWith('/uploads');
    if (!isRemote) return widget.url;
    final cached = _decryptedFiles[widget.url];
    if (cached != null && File(cached).existsSync()) return cached;
    final file = File('${(await getTemporaryDirectory()).path}/dec_${DateTime.now().microsecondsSinceEpoch}.m4a');
    await file.writeAsBytes(await _download());
    _decryptedFiles[widget.url] = file.path;
    return file.path;
  }

  /// The voice note's clear bytes (downloaded, then decrypted when it's end-to-end).
  Future<Uint8List> _download() async {
    final session = context.read<SessionCubit>();
    final uri = Uri.parse(widget.url.startsWith('http') ? widget.url : '${ApiService.baseUrl}${widget.url}');
    final response = await http.get(uri);
    if (response.statusCode != 200) throw Exception('Couldn’t download the voice message');
    var bytes = response.bodyBytes;
    if (widget.iv != null && widget.keys != null) {
      final decrypted = await session.crypto.decryptMedia(
        encryptedBytes: bytes,
        ivBase64: widget.iv!,
        keys: widget.keys!,
        username: session.me!.username,
      );
      if (decrypted == null) throw Exception('Decryption failed');
      bytes = decrypted;
    }
    return bytes;
  }

  Future<void> _transcribe() async {
    if (_transcribing || _transcripts.containsKey(widget.url)) return;
    setState(() => _transcribing = true);
    try {
      final text = await Transcriber.transcribe(await _localFile());
      _transcripts[widget.url] = text;
    } catch (e) {
      if (mounted) showHakiToast(context, e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _transcribing = false);
    }
  }

  Future<void> _initPlayer() async {
    _player.onPlayerStateChanged.listen((_) {
      if (mounted) {
        // Read the real state: for very short clips "completed" can arrive before a late
        // "playing" event, which left the pause icon stuck.
        final state = _player.state;
        if (_finished && state == PlayerState.playing) return;
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
        _finished = true;
        setState(() {
          _playerState = PlayerState.completed;
          _position = Duration.zero;
        });
        _waveController.reset();
      }
    });
  }

  Future<void> _playExclusively() async {
    if (_active != null && _active != this && _active!.mounted) await _active!._player.pause();
    _active = this;
    _finished = false;
    await _player.resume();
  }

  Future<void> _setupAndPlay() async {
    if (_isInitialized) {
      if (_player.state == PlayerState.playing) {
        await _player.pause();
      } else {
        await _playExclusively();
      }
      return;
    }
    setState(() => _isLoading = true);

    try {
      // No files on the web: play straight from memory
      if (kIsWeb) {
        await _player.setSourceBytes(await _download(), mimeType: 'audio/mp4');
      } else {
        await _player.setSourceDeviceFile(await _localFile());
      }
      _isInitialized = true;
      await _playExclusively();
    } catch (e) {
      debugPrint('Error playing audio: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    if (_active == this) _active = null;
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

    final transcript = _transcripts[widget.url];
    final player = Container(
      width: 260,
      padding: const EdgeInsets.all(12),

      child: Row(
        children: [
          // Play/Pause Button with Animation
          GestureDetector(
            onTap: _isLoading ? null : _setupAndPlay,
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(color: HakiColors.lime, shape: BoxShape.circle),
              child: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(HakiColors.onLime),
                      ),
                    )
                  : Icon(
                      isPlaying ? HakiIcons.pauseFill : HakiIcons.playFill,
                      color: HakiColors.onLime,
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
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(HakiIcons.microphone, size: 10, color: Colors.white.withValues(alpha: 0.8)),
                          const SizedBox(width: 2),
                          Text(
                            _formatDuration(_duration),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.85),
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
    if (!Transcriber.supported) return player;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        player,
        if (transcript != null)
          Container(
            width: 260,
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
            child: Text(transcript, style: TextStyle(fontSize: 14, height: 1.35, color: Colors.white.withValues(alpha: 0.9))),
          )
        else
          Padding(
            padding: const EdgeInsets.only(left: 6, bottom: 2),
            child: TextButton.icon(
              onPressed: _transcribing ? null : _transcribe,
              icon: _transcribing
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(HakiIcons.textAlignLeft, size: 16),
              label: Text(_transcribing ? 'Transcribing on this phone…' : 'Show text'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white.withValues(alpha: 0.85),
                visualDensity: VisualDensity.compact,
                textStyle: const TextStyle(fontSize: 12),
              ),
            ),
          ),
      ],
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

      paint.color = isPlayed ? HakiColors.lime : Colors.white.withValues(alpha: 0.35);

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

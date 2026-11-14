import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

import '../../../core/theme/haki_theme.dart';
import '../../../models/post_model.dart';
import '../../../services/api_service.dart';
import '../../../services/crypto_service.dart';
import 'package:chat_mobile/core/theme/haki_icons.dart';

/// Downloads and opens sealed post media once; scrolling back reuses the clear bytes.
/// ponytail: in-memory, 60 items, cleared on restart. Disk cache if feeds get photo-heavy.
abstract final class SealedMediaCache {
  static final Map<String, Uint8List> _done = {};
  static final Map<String, Future<Uint8List?>> _pending = {};

  static Uint8List? peek(String url) => _done[url];

  static Future<Uint8List?> load(CryptoService crypto, PostMedia m, List<int> key) {
    final hit = _done[m.url];
    if (hit != null) return SynchronousFuture(hit);
    return _pending[m.url] ??= () async {
      try {
        final res = await http.get(Uri.parse('${ApiService.baseUrl}${m.url}'));
        if (res.statusCode != 200) return null;
        final clear = await crypto.openBytes(key, res.bodyBytes, m.iv);
        if (clear != null) {
          if (_done.length >= 60) _done.remove(_done.keys.first);
          _done[m.url] = clear;
        }
        return clear;
      } catch (_) {
        return null;
      } finally {
        _pending.remove(m.url);
      }
    }();
  }
}

/// One tile of a post: the photo, or a video poster with its length.
class SealedMediaTile extends StatefulWidget {
  const SealedMediaTile({super.key, required this.media, required this.postKey, this.fit = BoxFit.cover});
  final PostMedia media;
  final List<int> postKey;
  final BoxFit fit;

  @override
  State<SealedMediaTile> createState() => _SealedMediaTileState();
}

class _SealedMediaTileState extends State<SealedMediaTile> {
  Uint8List? _bytes;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    if (widget.media.isVideo) {
      return; // videos open on tap; no poster frame without decoding them
    }
    _bytes = SealedMediaCache.peek(widget.media.url);
    if (_bytes == null) {
      SealedMediaCache.load(context.read<CryptoService>(), widget.media, widget.postKey).then((b) {
        if (mounted) setState(() => b == null ? _failed = true : _bytes = b);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.media;
    if (m.isVideo) {
      return DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [HakiColors.surfaceHigh, HakiColors.violet.withValues(alpha: 0.35)],
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.45), shape: BoxShape.circle),
                child: const Icon(HakiIcons.playFill, color: HakiColors.lime, size: 28),
              ),
            ),
            if (m.dur != null) Positioned(right: 8, bottom: 8, child: MediaTag(_clock(m.dur!))),
          ],
        ),
      );
    }
    if (_bytes != null) {
      return Image.memory(
        _bytes!,
        fit: widget.fit,
        gaplessPlayback: true,
        width: double.infinity,
        height: double.infinity,
      );
    }
    return ColoredBox(
      color: HakiColors.surfaceHigh,
      child: Center(
        child: _failed
            ? const Icon(HakiIcons.lock, color: HakiColors.textMuted)
            : const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
      ),
    );
  }
}

class MediaTag extends StatelessWidget {
  const MediaTag(this.label, {super.key});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(99)),
    child: Text(
      label,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
    ),
  );
}

String _clock(int s) => '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';

/// Threads/X-style media: 1 fills the width, 2 sit side by side, 3+ are a sideways row with a peek.
/// [leftInset] lines the row up with the text above while letting it run to the card edge.
class MediaStrip extends StatelessWidget {
  const MediaStrip({super.key, required this.post, this.leftInset = 0, this.height = 230, this.heroScope = 'feed'});
  final PostModel post;
  final double leftInset;
  final double height;

  /// Keeps the feed's and the post screen's copies from flying between each other.
  final String heroScope;

  void _open(BuildContext context, int i) => MediaViewer.open(context, post, i, heroScope: heroScope);

  Widget _tile(BuildContext context, int i, {double? w, double? h}) => Semantics(
    button: true,
    label: post.media[i].isVideo ? 'Video ${i + 1} of ${post.media.length}' : 'Photo ${i + 1} of ${post.media.length}',
    child: GestureDetector(
      onTap: () => _open(context, i),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: w,
          height: h,
          child: Hero(
            tag: '$heroScope${post.id}_$i',
            child: SealedMediaTile(key: ValueKey(post.media[i].url), media: post.media[i], postKey: post.key),
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final media = post.media;
    if (media.isEmpty) return const SizedBox.shrink();
    if (media.length == 1) {
      return Padding(
        padding: EdgeInsets.only(left: leftInset),
        child: LayoutBuilder(
          builder: (context, c) {
            // Keep its shape, within sane bounds (no 1px-tall panoramas, no endless portraits)
            final h = (c.maxWidth / media[0].aspect.clamp(0.75, 1.9)).clamp(140.0, 420.0);
            return _tile(context, 0, w: c.maxWidth, h: h);
          },
        ),
      );
    }
    if (media.length == 2) {
      return Padding(
        padding: EdgeInsets.only(left: leftInset),
        child: SizedBox(
          height: height * 0.9,
          child: Row(
            children: [
              Expanded(child: _tile(context, 0, h: double.infinity)),
              const SizedBox(width: 6),
              Expanded(child: _tile(context, 1, h: double.infinity)),
            ],
          ),
        ),
      );
    }
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.only(left: leftInset, right: 14),
        itemCount: media.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, i) => Stack(
          children: [
            _tile(context, i, w: height * media[i].aspect.clamp(0.62, 1.25), h: height),
            if (i == media.length - 1) Positioned(right: 8, top: 8, child: MediaTag('${media.length}')),
          ],
        ),
      ),
    );
  }
}

/// Full screen: swipe through every photo and video of the post.
class MediaViewer extends StatefulWidget {
  const MediaViewer({super.key, required this.post, required this.start, required this.heroScope});
  final PostModel post;
  final int start;
  final String heroScope;

  static Future<void> open(BuildContext context, PostModel post, int start, {String heroScope = 'feed'}) =>
      Navigator.push(
        context,
        PageRouteBuilder(
          opaque: false,
          barrierColor: Colors.black,
          pageBuilder: (_, _, _) => MediaViewer(post: post, start: start, heroScope: heroScope),
          transitionsBuilder: (_, a, _, child) => FadeTransition(opacity: a, child: child),
        ),
      );

  @override
  State<MediaViewer> createState() => _MediaViewerState();
}

class _MediaViewerState extends State<MediaViewer> {
  late final _pages = PageController(initialPage: widget.start);
  late int _i = widget.start;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = widget.post.media;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          media.length > 1 ? '${_i + 1} of ${media.length}' : widget.post.author.name,
          style: const TextStyle(fontSize: 16),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: PageView.builder(
        controller: _pages,
        itemCount: media.length,
        onPageChanged: (i) => setState(() => _i = i),
        itemBuilder: (context, i) => media[i].isVideo
            ? _SealedVideo(media: media[i], postKey: widget.post.key, active: i == _i)
            : Hero(
                tag: '${widget.heroScope}${widget.post.id}_$i',
                child: InteractiveViewer(
                  maxScale: 4,
                  child: Center(
                    child: SealedMediaTile(
                      key: ValueKey(media[i].url),
                      media: media[i],
                      postKey: widget.post.key,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

/// Opens the video into a temp file (deleted after) and plays it while its page is showing.
class _SealedVideo extends StatefulWidget {
  const _SealedVideo({required this.media, required this.postKey, required this.active});
  final PostMedia media;
  final List<int> postKey;
  final bool active;

  @override
  State<_SealedVideo> createState() => _SealedVideoState();
}

class _SealedVideoState extends State<_SealedVideo> {
  VideoPlayerController? _c;
  File? _file;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    if (kIsWeb) return setState(() => _failed = true);
    final bytes = await SealedMediaCache.load(context.read<CryptoService>(), widget.media, widget.postKey);
    if (bytes == null) return mounted ? setState(() => _failed = true) : null;
    final f = File('${(await getTemporaryDirectory()).path}/post_${widget.media.url.hashCode}.mp4');
    await f.writeAsBytes(bytes, flush: true);
    final c = VideoPlayerController.file(f);
    await c.initialize();
    c.setLooping(true);
    c.addListener(() => mounted ? setState(() {}) : null);
    if (!mounted) {
      c.dispose();
      return;
    }
    setState(() {
      _file = f;
      _c = c;
    });
    if (widget.active) c.play();
  }

  @override
  void didUpdateWidget(covariant _SealedVideo old) {
    super.didUpdateWidget(old);
    if (widget.active != old.active) widget.active ? _c?.play() : _c?.pause();
  }

  @override
  void dispose() {
    _c?.dispose();
    try {
      _file?.deleteSync();
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _c;
    if (_failed) {
      return Center(
        child: Text(
          kIsWeb ? 'Videos play in the Haki app' : 'Couldn\'t open this video',
          style: const TextStyle(color: HakiColors.textMuted),
        ),
      );
    }
    if (c == null) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    final v = c.value;
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: GestureDetector(
                onTap: () => v.isPlaying ? c.pause() : c.play(),
                child: AspectRatio(aspectRatio: v.aspectRatio, child: VideoPlayer(c)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 16, 12),
            child: Row(
              children: [
                IconButton(
                  tooltip: v.isPlaying ? 'Pause' : 'Play',
                  icon: Icon(v.isPlaying ? HakiIcons.pauseFill : HakiIcons.playFill, size: 30),
                  onPressed: () => v.isPlaying ? c.pause() : c.play(),
                ),
                Expanded(
                  child: VideoProgressIndicator(
                    c,
                    allowScrubbing: true,
                    colors: const VideoProgressColors(playedColor: HakiColors.lime, bufferedColor: Colors.white24),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

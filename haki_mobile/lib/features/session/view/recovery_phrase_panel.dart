import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/theme/haki_theme.dart';
import '../../../core/widgets/glass.dart';

/// The 12 words (hidden until revealed) plus a QR backup that can be saved to Photos.
/// Shared by sign-up onboarding and Profile › Recovery words.
class RecoveryPhrasePanel extends StatefulWidget {
  const RecoveryPhrasePanel({super.key, required this.mnemonic});
  final String mnemonic;

  @override
  State<RecoveryPhrasePanel> createState() => _RecoveryPhrasePanelState();
}

class _RecoveryPhrasePanelState extends State<RecoveryPhrasePanel> {
  bool _revealed = false;
  bool _showQr = false;
  final _qrKey = GlobalKey();

  Future<void> _saveQr() async {
    try {
      final boundary = _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      final image = await boundary?.toImage(pixelRatio: 3);
      final bytes = await image?.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) return;
      final result = await ImageGallerySaver.saveImage(
        bytes.buffer.asUint8List(),
        name: 'haki_recovery_${DateTime.now().millisecondsSinceEpoch}',
      );
      if (mounted && result['isSuccess'] == true) showHakiToast(context, 'Saved to your photos');
    } catch (e) {
      if (mounted) showHakiToast(context, 'Couldn’t save: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final words = widget.mnemonic.split(' ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: HakiColors.surface, borderRadius: BorderRadius.circular(24)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'YOUR RECOVERY PHRASE',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.8, color: HakiColors.textMuted),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => setState(() => _revealed = !_revealed),
                    icon: Icon(_revealed ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
                    label: Text(_revealed ? 'Hide' : 'Reveal'),
                    style: TextButton.styleFrom(foregroundColor: HakiColors.lime),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 2.6,
                children: [
                  for (var i = 0; i < words.length; i++)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(color: HakiColors.surfaceHigh, borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          Text('${i + 1}'.padLeft(2, '0'), style: HakiText.mono(11, color: HakiColors.textMuted)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _revealed ? words[i] : '•••••',
                              style: HakiText.mono(13),
                              overflow: TextOverflow.fade,
                              softWrap: false,
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
        const SizedBox(height: 12),
        GlassButton(
          label: _showQr ? 'Hide QR backup' : 'Show QR backup',
          onPressed: () => setState(() => _showQr = !_showQr),
        ),
        if (_showQr) ...[
          const SizedBox(height: 12),
          Center(
            child: RepaintBoundary(
              key: _qrKey,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                child: QrImageView(data: widget.mnemonic, size: 200, backgroundColor: Colors.white),
              ),
            ),
          ),
          TextButton.icon(
            onPressed: _saveQr,
            icon: const Icon(Icons.download_rounded),
            label: const Text('Save QR to photos'),
            style: TextButton.styleFrom(foregroundColor: HakiColors.lime),
          ),
        ],
      ],
    );
  }
}

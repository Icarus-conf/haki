import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../providers/chat_provider.dart';
import '../utils/toast_utils.dart';

class RecoveryPhraseView extends StatefulWidget {
  const RecoveryPhraseView({super.key});

  @override
  State<RecoveryPhraseView> createState() => _RecoveryPhraseViewState();
}

class _RecoveryPhraseViewState extends State<RecoveryPhraseView> {
  String? _mnemonic;
  bool _isRevealed = false;
  bool _isLoading = true;
  final GlobalKey _qrKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadPhrase();
  }

  Future<void> _loadPhrase() async {
    final chat = context.read<ChatProvider>();
    if (chat.me == null) {
      Navigator.pop(context);
      return;
    }

    // Try to get existing mnemonic first
    String? mnemonic = await chat.crypto.getMnemonic(chat.me!.username);

    // If no mnemonic exists, generate one and store it
    if (mnemonic == null) {
      mnemonic = await chat.crypto.generateMnemonic();
      await chat.crypto.storeMnemonic(chat.me!.username, mnemonic);
    }

    // Mark as viewed
    await chat.crypto.markRecoveryPhraseViewed(chat.me!.username);

    setState(() {
      _mnemonic = mnemonic;
      _isLoading = false;
    });
  }

  Future<void> _saveQRToGallery() async {
    try {
      // Capture the QR code as an image
      final boundary = _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final pngBytes = byteData.buffer.asUint8List();

      // Save to gallery
      final result = await ImageGallerySaver.saveImage(
        pngBytes,
        name: 'haki_recovery_phrase_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (mounted && result['isSuccess'] == true) {
        ToastUtils.showToast(context, 'QR code saved to gallery!');
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.showToast(context, 'Failed to save: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final words = _mnemonic?.split(' ') ?? [];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Recovery Phrase'),
        backgroundColor: const Color.fromARGB(255, 29, 30, 126),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.orange, width: 2),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'CRITICAL: Write these 12 words down on paper and store them in a safe place. They are the ONLY way to recover your account if you lose your device.',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Your Recovery Phrase',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() => _isRevealed = !_isRevealed);
                        },
                        icon: Icon(_isRevealed ? Icons.visibility_off : Icons.visibility),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 3,
                    ),
                    itemCount: words.length,
                    itemBuilder: (context, index) {
                      return Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardTheme.color,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[800]!
                                : Colors.grey.shade200,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              '${index + 1}.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _isRevealed ? words[index] : '••••••',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'monospace',
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 56,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Recovery Phrase QR Code'),
                                  content: SizedBox(
                                    width: 280,
                                    height: 280,
                                    child: RepaintBoundary(
                                      key: _qrKey,
                                      child: Container(
                                        width: 280,
                                        height: 280,
                                        color: Colors.white,
                                        padding: const EdgeInsets.all(16),
                                        child: QrImageView(
                                          data: _mnemonic!,
                                          version: QrVersions.auto,
                                          backgroundColor: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  actions: [
                                    TextButton.icon(
                                      onPressed: () async {
                                        await _saveQRToGallery();
                                      },
                                      icon: const Icon(Icons.save),
                                      label: const Text('Save to Gallery'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Close'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            icon: const Icon(Icons.qr_code_2),
                            label: const Text('Show QR Code'),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Theme.of(context).primaryColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: _mnemonic!));
                              ToastUtils.showToast(context, 'Copied to clipboard!');
                            },
                            icon: const Icon(Icons.copy),
                            label: const Text('Copy'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.blue.shade900.withValues(alpha: 0.3)
                          : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Security Tips',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '• Never share this phrase with anyone\n'
                          '• Store offline (not in cloud or screenshots)\n'
                          '• Losing this phrase means permanent data loss',
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

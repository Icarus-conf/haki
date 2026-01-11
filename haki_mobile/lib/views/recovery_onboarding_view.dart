import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../providers/chat_provider.dart';

class RecoveryOnboardingView extends StatefulWidget {
  final String mnemonic;

  const RecoveryOnboardingView({super.key, required this.mnemonic});

  @override
  State<RecoveryOnboardingView> createState() => _RecoveryOnboardingViewState();
}

class _RecoveryOnboardingViewState extends State<RecoveryOnboardingView> {
  bool _hasAcknowledged = false;
  bool _isRevealed = false;
  final GlobalKey _qrKey = GlobalKey();

  Future<void> _saveQRToGallery() async {
    try {
      final boundary = _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final pngBytes = byteData.buffer.asUint8List();

      final result = await ImageGallerySaver.saveImage(
        pngBytes,
        name: 'haki_recovery_phrase_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (mounted && result['isSuccess'] == true) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('QR code saved to gallery!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final words = widget.mnemonic.split(' ');

    return PopScope(
      canPop: false, // Prevent back navigation
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                const Icon(
                  Icons.shield_rounded,
                  size: 80,
                  color: Color.fromARGB(255, 107, 92, 255),
                ),
                const SizedBox(height: 24),
                Text(
                  'Backup Your Recovery Phrase',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 28),
                ),
                const SizedBox(height: 16),
                Text(
                  'This is the ONLY way to recover your account if you lose your device. Write these 12 words down on paper and store them safely.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.red, width: 2),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Never share these words. Anyone with them can access your account.',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Your Recovery Phrase',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _isRevealed = !_isRevealed),
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
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
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
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
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
                                      data: widget.mnemonic,
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
                        label: const Text('Show QR'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: widget.mnemonic));
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(const SnackBar(content: Text('Copied to clipboard!')));
                        },
                        icon: const Icon(Icons.copy),
                        label: const Text('Copy'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.blue.shade900.withValues(alpha: 0.3)
                        : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: CheckboxListTile(
                    value: _hasAcknowledged,
                    onChanged: (value) => setState(() => _hasAcknowledged = value ?? false),
                    title: const Text(
                      'I have written down my recovery phrase',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text(
                      'I understand that losing this phrase means permanent loss of my encrypted messages',
                      style: TextStyle(fontSize: 12),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _hasAcknowledged
                        ? () async {
                            final chat = context.read<ChatProvider>();
                            if (chat.me != null) {
                              await chat.crypto.markRecoveryPhraseViewed(chat.me!.username);
                            }
                            // Instead of pop, we update the state to trigger App rebuild
                            chat.setNeedsOnboarding(false);
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Continue to App', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

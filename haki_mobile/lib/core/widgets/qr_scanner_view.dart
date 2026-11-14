import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'glass.dart';
import 'package:chat_mobile/core/theme/haki_icons.dart';

/// Full-screen camera that pops with the first QR value it reads.
class QrScannerView extends StatefulWidget {
  const QrScannerView({super.key, required this.title});
  final String title;

  static Future<String?> scan(BuildContext context, {required String title}) =>
      Navigator.push<String>(context, MaterialPageRoute(builder: (_) => QrScannerView(title: title)));

  @override
  State<QrScannerView> createState() => _QrScannerViewState();
}

class _QrScannerViewState extends State<QrScannerView> {
  bool _done = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              final value = capture.barcodes.map((b) => b.rawValue).whereType<String>().firstOrNull;
              if (value == null || _done) return;
              _done = true;
              Navigator.pop(context, value);
            },
          ),
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(36),
                border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 3),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  GlassIconButton(
                    icon: HakiIcons.x,
                    tooltip: 'Close scanner',
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 12),
                  Glass(
                    radius: 24,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                    child: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

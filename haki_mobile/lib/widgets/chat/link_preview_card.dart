import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/haki_theme.dart';
import '../../models/message_envelope.dart';

/// Renders a preview that arrived inside the encrypted message. It never fetches anything,
/// so reading a message doesn't reveal your IP address to the linked site.
class LinkPreviewCard extends StatelessWidget {
  const LinkPreviewCard({super.key, required this.preview});
  final LinkPreview preview;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      link: true,
      label: 'Open ${preview.title}',
      child: GestureDetector(
        onTap: () async {
          final uri = Uri.tryParse(preview.url);
          if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.22), borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (preview.site != null)
                Text(
                  preview.site!.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, letterSpacing: 0.6, color: Colors.white.withValues(alpha: 0.65)),
                ),
              const SizedBox(height: 2),
              Text(
                preview.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: HakiColors.text),
              ),
              if (preview.description != null) ...[
                const SizedBox(height: 2),
                Text(
                  preview.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.75)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

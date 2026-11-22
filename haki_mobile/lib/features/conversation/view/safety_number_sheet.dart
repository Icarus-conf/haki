import 'package:flutter/material.dart';

import '../../../core/theme/haki_theme.dart';
import '../../../models/user_model.dart';
import '../../../services/crypto_service.dart';

/// Compare this number with your friend in person or on a call. If it matches on both
/// phones, nobody swapped a key in between. With no friend it shows your own key's fingerprint.
class SafetyNumberSheet extends StatelessWidget {
  const SafetyNumberSheet({super.key, required this.me, this.friend});

  final UserModel me;
  final UserModel? friend;

  static Future<void> show(BuildContext context, {required UserModel me, UserModel? friend}) =>
      showModalBottomSheet(context: context, builder: (_) => SafetyNumberSheet(me: me, friend: friend));

  @override
  Widget build(BuildContext context) {
    final keys = [me.publicKey, if (friend != null) friend!.publicKey];
    final missing = keys.any((k) => k == null);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(friend == null ? 'Your key fingerprint' : 'Safety number', style: HakiText.display(30)),
            const SizedBox(height: 8),
            Text(
              friend == null
                  ? 'This identifies the encryption key on this phone. It changes only if you restore with different words.'
                  : 'Compare these digits with ${friend!.name}. If they match on both phones, your chat is private end to end.',
              style: const TextStyle(color: HakiColors.textMuted, height: 1.4),
            ),
            const SizedBox(height: 20),
            if (missing)
              const Text(
                'This person hasn’t set up encryption yet. Ask them to open Haki once.',
                style: TextStyle(color: HakiColors.dangerText),
              )
            else
              FutureBuilder(
                future: CryptoService.safetyNumber(keys.cast<String>()),
                builder: (context, snap) {
                  if (!snap.hasData) return const LinearProgressIndicator();
                  final groups = snap.data!.split(' ');
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(color: HakiColors.surfaceHigh, borderRadius: BorderRadius.circular(22)),
                    child: Wrap(
                      spacing: 18,
                      runSpacing: 12,
                      children: [for (final g in groups) Text(g, style: HakiText.mono(20, color: HakiColors.lime))],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

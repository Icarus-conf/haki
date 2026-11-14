import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/haki_theme.dart';
import '../../../core/widgets/glass.dart';
import '../../../core/widgets/qr_scanner_view.dart';
import '../view_model/session_cubit.dart';

/// Shown when the account already has a key but this phone doesn't (new phone, reinstall).
/// The 12 words recreate the same key, so this phone and the others all keep working.
class UnlockView extends StatefulWidget {
  const UnlockView({super.key, required this.name});
  final String name;

  @override
  State<UnlockView> createState() => _UnlockViewState();
}

class _UnlockViewState extends State<UnlockView> {
  final _phrase = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _phrase.dispose();
    super.dispose();
  }

  Future<void> _unlock() async {
    setState(() => _busy = true);
    final error = await context.read<SessionCubit>().unlockWithWords(_phrase.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (error != null) showHakiToast(context, error, isError: true);
  }

  Future<void> _startFresh() async {
    final sure = await confirmAction(
      context,
      title: 'Start fresh on this phone?',
      message:
          'Haki will create a new key and 12 new words. Your older messages won’t open here, and your other phone will stop receiving new messages until you sign in there again with the new words.',
      action: 'Start fresh',
    );
    if (!sure || !mounted) return;
    setState(() => _busy = true);
    await context.read<SessionCubit>().startFreshOnThisPhone();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const AuroraBackground(height: 380, colors: [HakiColors.teal, HakiColors.violet, HakiColors.blue]),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
              children: [
                const Icon(Icons.lock_rounded, color: HakiColors.lime, size: 34),
                const SizedBox(height: 16),
                Text('Unlock your messages', style: HakiText.display(40)),
                const SizedBox(height: 10),
                Text(
                  'Hi ${widget.name}. Your account is already set up on another phone. Enter your 12 recovery words to read your messages here too. Your other phone keeps working.',
                  style: TextStyle(fontSize: 15, height: 1.45, color: Colors.white.withValues(alpha: 0.75)),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _phrase,
                  minLines: 3,
                  maxLines: 4,
                  autocorrect: false,
                  enableSuggestions: false,
                  style: HakiText.mono(14),
                  decoration: InputDecoration(
                    labelText: '12 recovery words',
                    alignLabelWithHint: true,
                    suffixIcon: IconButton(
                      tooltip: 'Scan recovery QR',
                      icon: const Icon(Icons.qr_code_scanner_rounded),
                      onPressed: () async {
                        final v = await QrScannerView.scan(context, title: 'Scan recovery QR');
                        if (v != null) _phrase.text = v;
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                LimeButton(label: 'Unlock', icon: Icons.lock_open_rounded, busy: _busy, onPressed: _unlock),
                const SizedBox(height: 28),
                const Text('Don’t have your words?', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                const Text(
                  'You can start fresh with a new key. Older messages won’t open on this phone.',
                  style: TextStyle(color: HakiColors.textMuted, height: 1.4),
                ),
                const SizedBox(height: 10),
                GlassButton(label: 'Start fresh on this phone', onPressed: _busy ? null : _startFresh),
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: _busy ? null : () => context.read<SessionCubit>().logout(),
                    child: const Text('Sign out', style: TextStyle(color: HakiColors.textMuted)),
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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/haki_theme.dart';
import '../../../core/widgets/glass.dart';
import '../view_model/session_cubit.dart';
import 'recovery_phrase_panel.dart';
import 'package:chat_mobile/core/theme/haki_icons.dart';

enum _Status { checking, ok, mismatch, missing }

/// Profile › Recovery words. Verifies the saved words actually rebuild this phone's key
/// before showing them, so nobody relies on a backup that can't restore anything.
class RecoveryPhraseView extends StatefulWidget {
  const RecoveryPhraseView({super.key});

  @override
  State<RecoveryPhraseView> createState() => _RecoveryPhraseViewState();
}

class _RecoveryPhraseViewState extends State<RecoveryPhraseView> {
  _Status _status = _Status.checking;
  String? _mnemonic;
  bool _rotating = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final session = context.read<SessionCubit>();
    final username = session.me!.username;
    final mnemonic = await session.crypto.getMnemonic(username);
    if (mnemonic == null) {
      if (mounted) setState(() => _status = _Status.missing);
      return;
    }
    final ok = await session.crypto.mnemonicMatchesKey(username, mnemonic);
    if (ok) await session.markRecoveryPhraseViewed();
    if (mounted) {
      setState(() {
        _mnemonic = mnemonic;
        _status = ok ? _Status.ok : _Status.mismatch;
      });
    }
  }

  Future<void> _rotate() async {
    final sure = await confirmAction(
      context,
      title: 'Create new recovery words?',
      message:
          'Haki will make a new encryption key from 12 new words. Messages sent to your old key can’t be decrypted afterwards, on this phone or any other.',
      action: 'Create new words',
    );
    if (!sure || !mounted) return;
    setState(() => _rotating = true);
    final mnemonic = await context.read<SessionCubit>().createNewRecoveryPhrase();
    if (!mounted) return;
    setState(() {
      _rotating = false;
      _mnemonic = mnemonic;
      _status = _Status.ok;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const AuroraBackground(height: 320, colors: [HakiColors.teal, HakiColors.blue, HakiColors.violet]),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: GlassIconButton(icon: HakiIcons.arrowLeft, tooltip: 'Back', onPressed: () => Navigator.pop(context)),
                ),
                const SizedBox(height: 24),
                Text('Recovery words', style: HakiText.display(42)),
                const SizedBox(height: 10),
                const Text(
                  'With these 12 words you can restore your account and read your messages on a new phone. Never share them.',
                  style: TextStyle(color: HakiColors.textMuted, height: 1.4),
                ),
                const SizedBox(height: 24),
                ...switch (_status) {
                  _Status.checking => [
                    const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    const SizedBox(height: 12),
                    const Center(child: Text('Checking your words match your key…', style: TextStyle(color: HakiColors.textMuted))),
                  ],
                  _Status.ok => [RecoveryPhrasePanel(mnemonic: _mnemonic!)],
                  _Status.mismatch || _Status.missing => [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: HakiColors.danger.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Text(
                        _status == _Status.missing
                            ? 'This phone has no recovery words saved, so your account can’t be restored elsewhere yet.'
                            : 'The words saved for this account don’t match its encryption key (accounts made before this update were affected). They can’t restore your account.',
                        style: const TextStyle(color: HakiColors.dangerText, height: 1.4, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 16),
                    LimeButton(label: 'Create new recovery words', busy: _rotating, onPressed: _rotate),
                  ],
                },
              ],
            ),
          ),
        ],
      ),
    );
  }
}

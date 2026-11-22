import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/haki_theme.dart';
import '../../../core/widgets/glass.dart';
import '../view_model/session_cubit.dart';
import 'recovery_phrase_panel.dart';
import 'package:chat_mobile/core/theme/haki_icons.dart';

/// Shown once after sign-up: the user must acknowledge their 12 words.
class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key, required this.mnemonic});
  final String mnemonic;

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  bool _acknowledged = false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Stack(
          children: [
            const AuroraBackground(height: 360, colors: [HakiColors.teal, HakiColors.blue, HakiColors.violet]),
            SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
                children: [
                  Text('Your 12 words', style: HakiText.display(44)),
                  const SizedBox(height: 10),
                  Text(
                    'They are your account. Lose your phone and these words are the only way back in. Write them on paper and keep them somewhere safe.',
                    style: TextStyle(fontSize: 15, height: 1.45, color: Colors.white.withValues(alpha: 0.75)),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: HakiColors.danger.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Row(
                      children: [
                        Icon(HakiIcons.warning, color: HakiColors.dangerText),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Never share them. Anyone with these words can read your messages.',
                            style: TextStyle(color: HakiColors.dangerText, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  RecoveryPhrasePanel(mnemonic: widget.mnemonic),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    value: _acknowledged,
                    onChanged: (v) => setState(() => _acknowledged = v ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    activeColor: HakiColors.lime,
                    checkColor: HakiColors.onLime,
                    title: const Text('I’ve written my 12 words down somewhere safe'),
                  ),
                  const SizedBox(height: 12),
                  LimeButton(
                    label: 'Enter Haki',
                    icon: HakiIcons.arrowRight,
                    onPressed: _acknowledged ? () => context.read<SessionCubit>().completeOnboarding() : null,
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

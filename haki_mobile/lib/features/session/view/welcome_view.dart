import 'package:flutter/material.dart';

import '../../../core/theme/haki_theme.dart';
import '../../../core/utils/platform.dart';
import '../../../core/widgets/glass.dart';
import '../../../models/user_model.dart';
import 'auth_view.dart';
import '../../profile/view/security_views.dart';
import 'package:chat_mobile/core/theme/haki_icons.dart';

class WelcomeView extends StatelessWidget {
  const WelcomeView({super.key});

  void _open(BuildContext context, AuthMode mode) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => AuthView(mode: mode)));

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).width > 900) return _WideWelcome(open: (m) => _open(context, m));
    return Scaffold(
      body: Stack(
        children: [
          const AuroraBackground(
            height: 900,
            fadeStart: 0.4,
            colors: [HakiColors.violet, HakiColors.blue, HakiColors.pink],
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Text('haki', style: HakiText.display(26)),
                      const SizedBox(width: 10),
                      const Glass(
                        radius: 14,
                        tint: 0.12,
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(HakiIcons.lockFill, size: 12),
                            SizedBox(width: 5),
                            Text('End-to-end', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Expanded(child: _FloatingCards()),
                  Text.rich(
                    TextSpan(
                      text: 'Say anything.\n',
                      children: [
                        TextSpan(
                          text: 'Only they hear it.',
                          style: HakiText.display(44, color: HakiColors.lime),
                        ),
                      ],
                    ),
                    style: HakiText.display(44),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Your account lives in 12 words on your phone. No phone number, no tracking, no one in between.',
                    style: TextStyle(fontSize: 16, height: 1.45, color: Colors.white.withValues(alpha: 0.72)),
                  ),
                  const SizedBox(height: 24),
                  LimeButton(
                    label: 'Get started',
                    icon: HakiIcons.arrowRight,
                    onPressed: () => _open(context, AuthMode.signUp),
                  ),
                  const SizedBox(height: 12),
                  GlassButton(label: 'Restore with my 12 words', onPressed: () => _open(context, AuthMode.restore)),
                  const SizedBox(height: 6),
                  Center(
                    child: TextButton(
                      onPressed: () =>
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const LinkThisDeviceView())),
                      child: const Text(
                        'Link to my phone',
                        style: TextStyle(color: HakiColors.lime, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  Center(
                    child: TextButton(
                      onPressed: () => _open(context, AuthMode.signIn),
                      child: Text.rich(
                        TextSpan(
                          text: 'Have an account? ',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.65)),
                          children: const [
                            TextSpan(
                              text: 'Sign in',
                              style: TextStyle(color: HakiColors.lime, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
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

/// Computers and browsers: linking to your phone comes first, with the code already showing.
class _WideWelcome extends StatelessWidget {
  const _WideWelcome({required this.open});

  final void Function(AuthMode) open;

  @override
  Widget build(BuildContext context) {
    final where = Device.web ? 'in your browser' : 'on this ${Device.name}';
    Widget step(int n, String text) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Text('$n', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: const TextStyle(height: 1.35, color: HakiColors.textMuted)),
          ),
        ],
      ),
    );
    return Scaffold(
      body: Stack(
        children: [
          const AuroraBackground(
            height: 1100,
            fadeStart: 0.45,
            colors: [HakiColors.violet, HakiColors.blue, HakiColors.pink],
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(48, 28, 48, 28),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('haki', style: HakiText.display(30)),
                        const Expanded(child: _FloatingCards()),
                        Text.rich(
                          TextSpan(
                            text: 'Say anything.\n',
                            children: [
                              TextSpan(
                                text: 'Only they hear it.',
                                style: HakiText.display(56, color: HakiColors.lime),
                              ),
                            ],
                          ),
                          style: HakiText.display(56),
                        ),
                        const SizedBox(height: 14),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: Text(
                            'Your chats, end-to-end encrypted $where. Your phone hands this device its keys directly; the server never sees them.',
                            style: TextStyle(fontSize: 17, height: 1.45, color: Colors.white.withValues(alpha: 0.72)),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                  const SizedBox(width: 48),
                  SizedBox(
                    width: 420,
                    child: Center(
                      child: SingleChildScrollView(
                        child: Glass(
                          radius: 32,
                          tint: 0.08,
                          padding: const EdgeInsets.fromLTRB(28, 28, 28, 18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text('Link to my phone', style: HakiText.display(26)),
                              const SizedBox(height: 16),
                              step(1, 'Open Haki on your phone'),
                              step(2, 'Go to You → Devices → Link a device'),
                              step(3, 'Scan this code, and check the numbers match'),
                              const SizedBox(height: 14),
                              const LinkPanel(qrSize: 190),
                              const SizedBox(height: 14),
                              Divider(color: Colors.white.withValues(alpha: 0.08)),
                              Wrap(
                                alignment: WrapAlignment.center,
                                children: [
                                  TextButton(
                                    onPressed: () => open(AuthMode.signIn),
                                    child: const Text('Sign in with password'),
                                  ),
                                  TextButton(
                                    onPressed: () => open(AuthMode.restore),
                                    child: const Text('Use my 12 words'),
                                  ),
                                  TextButton(
                                    onPressed: () => open(AuthMode.signUp),
                                    child: const Text(
                                      'New here? Create an account',
                                      style: TextStyle(color: HakiColors.lime),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
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

/// Decorative chat chips floating over the aurora.
class _FloatingCards extends StatelessWidget {
  const _FloatingCards();

  @override
  Widget build(BuildContext context) {
    Widget card(int id, String name, String text, double angle, Alignment align, {bool badge = false}) {
      return Align(
        alignment: align,
        child: Transform.rotate(
          angle: angle,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Glass(
                radius: 24,
                tint: 0.12,
                padding: const EdgeInsets.fromLTRB(10, 10, 16, 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AuraAvatar(
                      user: UserModel(id: id, username: name),
                      size: 40,
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        Text(text, style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.85))),
                      ],
                    ),
                  ],
                ),
              ),
              if (badge)
                Positioned(
                  right: -8,
                  bottom: -12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(color: HakiColors.lime, borderRadius: BorderRadius.circular(13)),
                    child: const Text(
                      'Encrypted',
                      style: TextStyle(color: HakiColors.onLime, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return ExcludeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Stack(
          children: [
            card(0, 'Layla', 'Only you can read this', -0.09, const Alignment(-0.8, -0.8)),
            card(1, 'Omar', 'Voice message · 0:42', 0.07, const Alignment(0.85, -0.05), badge: true),
            card(2, 'Nour', 'See you Friday', -0.035, const Alignment(-0.55, 0.75)),
          ],
        ),
      ),
    );
  }
}

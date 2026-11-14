import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/haki_theme.dart';
import '../../../core/widgets/glass.dart';
import '../../../core/widgets/qr_scanner_view.dart';
import '../view_model/session_cubit.dart';
import 'package:chat_mobile/core/theme/haki_icons.dart';

enum AuthMode { signIn, signUp, restore }

class AuthView extends StatefulWidget {
  const AuthView({super.key, required this.mode});
  final AuthMode mode;

  @override
  State<AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends State<AuthView> {
  final _form = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _email = TextEditingController();
  final _displayName = TextEditingController();
  final _bio = TextEditingController();
  final _phrase = TextEditingController();
  final _code = TextEditingController();
  final _invite = TextEditingController();
  String? _avatarPath;
  bool _needCode = false; // two-step login is on for this account
  String _signup = 'open'; // 'invite' shows the invite-code field
  bool _busy = false;
  bool _showPassword = false;

  AuthMode get mode => widget.mode;

  @override
  void initState() {
    super.initState();
    if (mode == AuthMode.signUp) {
      context.read<SessionCubit>().api.signupMode().then((m) {
        if (mounted) setState(() => _signup = m);
      });
    }
  }

  @override
  void dispose() {
    for (final c in [_username, _password, _email, _displayName, _bio, _phrase, _code, _invite]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final session = context.read<SessionCubit>();
    final username = _username.text.trim();
    final code = _needCode ? _code.text.trim() : null;
    final error = switch (mode) {
      AuthMode.signIn => await session.login(username, _password.text, code: code),
      AuthMode.restore => await session.restore(username, _password.text, _phrase.text, code: code),
      AuthMode.signUp => await session.register(
        username: username,
        email: _email.text.trim(),
        password: _password.text,
        displayName: _displayName.text.trim(),
        bio: _bio.text.trim(),
        avatarPath: _avatarPath,
        inviteCode: _signup == 'invite' ? _invite.text.trim() : null,
      ),
    };
    if (!mounted) return;
    setState(() => _busy = false);
    if (error == SessionCubit.needsCode) {
      setState(() => _needCode = true);
      return showHakiToast(context, 'Enter the 6-digit code from your authenticator app');
    }
    if (error != null) return showHakiToast(context, error, isError: true);
    // The root swaps to home/onboarding; drop this pushed form
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  Future<void> _scanPhrase() async {
    final value = await QrScannerView.scan(context, title: 'Scan recovery QR');
    if (value != null) _phrase.text = value;
  }

  String? _required(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;

  @override
  Widget build(BuildContext context) {
    final (title, subtitle, cta) = switch (mode) {
      AuthMode.signIn => ('Welcome back', 'Sign in to pick up where you left off.', 'Sign in'),
      AuthMode.signUp => ('Make it yours', 'Pick a name. We’ll create your 12 words next.', 'Create account'),
      AuthMode.restore => ('Restore', 'New phone? Your 12 words bring your keys back.', 'Restore account'),
    };

    return Scaffold(
      body: Stack(
        children: [
          const AuroraBackground(height: 380),
          SafeArea(
            // Computers: a readable column, not a form stretched across the screen
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Form(
                  key: _form,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: GlassIconButton(
                          icon: HakiIcons.arrowLeft,
                          tooltip: 'Back',
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(title, style: HakiText.display(44)),
                      const SizedBox(height: 8),
                      Text(subtitle, style: TextStyle(fontSize: 15, color: Colors.white.withValues(alpha: 0.7))),
                      const SizedBox(height: 28),
                      if (mode == AuthMode.signUp) ...[
                        Center(
                          child: _AvatarPicker(path: _avatarPath, onPicked: (p) => setState(() => _avatarPath = p)),
                        ),
                        const SizedBox(height: 20),
                      ],
                      TextFormField(
                        controller: _username,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          prefixIcon: Icon(HakiIcons.at),
                        ),
                        autocorrect: false,
                        textInputAction: TextInputAction.next,
                        validator: _required,
                      ),
                      if (mode == AuthMode.signUp) ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _displayName,
                          decoration: const InputDecoration(
                            labelText: 'Display name',
                            prefixIcon: Icon(HakiIcons.identificationBadge),
                          ),
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _email,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(HakiIcons.envelopeSimple),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
                          textInputAction: TextInputAction.next,
                          validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                        ),
                      ],
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _password,
                        obscureText: !_showPassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(HakiIcons.lock),
                          suffixIcon: IconButton(
                            tooltip: _showPassword ? 'Hide password' : 'Show password',
                            icon: Icon(_showPassword ? HakiIcons.eyeSlash : HakiIcons.eye),
                            onPressed: () => setState(() => _showPassword = !_showPassword),
                          ),
                        ),
                        validator: (v) => mode == AuthMode.signUp && (v?.length ?? 0) < 8
                            ? 'Use at least 8 characters'
                            : _required(v),
                      ),
                      if (_needCode) ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _code,
                          autofocus: true,
                          keyboardType: TextInputType.number,
                          autofillHints: const [AutofillHints.oneTimeCode],
                          maxLength: 6,
                          style: HakiText.mono(20),
                          decoration: const InputDecoration(
                            labelText: 'Code from your authenticator app',
                            prefixIcon: Icon(HakiIcons.shieldCheck),
                            counterText: '',
                          ),
                          validator: (v) => RegExp(r'^\d{6}$').hasMatch(v?.trim() ?? '') ? null : 'Enter the 6 digits',
                        ),
                      ],
                      if (mode == AuthMode.signUp && _signup == 'invite') ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _invite,
                          textCapitalization: TextCapitalization.characters,
                          autocorrect: false,
                          decoration: const InputDecoration(
                            labelText: 'Invite code',
                            helperText: 'Haki is invite-only right now. Ask a friend for a code.',
                            prefixIcon: Icon(HakiIcons.ticket),
                          ),
                          validator: _required,
                        ),
                      ],
                      if (mode == AuthMode.signUp && _signup == 'closed') ...[
                        const SizedBox(height: 12),
                        const Text('Sign-ups are closed right now.', style: TextStyle(color: HakiColors.dangerText)),
                      ],
                      if (mode == AuthMode.signUp) ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _bio,
                          decoration: const InputDecoration(
                            labelText: 'Short bio (optional)',
                            prefixIcon: Icon(HakiIcons.notePencil),
                          ),
                        ),
                      ],
                      if (mode == AuthMode.restore) ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _phrase,
                          minLines: 3,
                          maxLines: 4,
                          autocorrect: false,
                          style: HakiText.mono(14),
                          decoration: InputDecoration(
                            labelText: '12-word recovery phrase',
                            alignLabelWithHint: true,
                            suffixIcon: IconButton(
                              tooltip: 'Scan recovery QR',
                              icon: const Icon(HakiIcons.scan),
                              onPressed: _scanPhrase,
                            ),
                          ),
                          validator: (v) => (v ?? '').trim().split(RegExp(r'\s+')).length != 12
                              ? 'Enter all 12 words, separated by spaces'
                              : null,
                        ),
                      ],
                      const SizedBox(height: 28),
                      LimeButton(label: cta, busy: _busy, onPressed: _submit),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarPicker extends StatelessWidget {
  const _AvatarPicker({required this.path, required this.onPicked});
  final String? path;
  final ValueChanged<String> onPicked;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Choose profile photo',
      child: GestureDetector(
        onTap: () async {
          final image = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1024);
          if (image != null) onPicked(image.path);
        },
        child: Glass(
          radius: 34,
          tint: 0.1,
          child: SizedBox(
            width: 96,
            height: 96,
            child: path == null
                ? const Icon(HakiIcons.cameraPlus, size: 30)
                : ClipRRect(
                    borderRadius: BorderRadius.circular(34),
                    child: kIsWeb
                        ? Image.network(path!, fit: BoxFit.cover)
                        : Image.file(File(path!), fit: BoxFit.cover),
                  ),
          ),
        ),
      ),
    );
  }
}

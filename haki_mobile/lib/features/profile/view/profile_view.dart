import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/theme/haki_theme.dart';
import '../../../core/widgets/glass.dart';
import '../../../models/user_model.dart';
import '../../conversation/view/safety_number_sheet.dart';
import '../../friends/view_model/friends_cubit.dart';
import '../../session/view/recovery_phrase_view.dart';
import '../../session/view_model/session_cubit.dart';
import '../../session/view_model/session_state.dart';
import 'blocked_users_view.dart';
import 'security_views.dart';
import 'package:chat_mobile/core/theme/haki_icons.dart';

String hakiCode(UserModel me) => 'haki:${me.username}';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  Future<void> _changePhoto(BuildContext context) async {
    final img = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1024);
    if (img == null || !context.mounted) return;
    final ok = await context.read<SessionCubit>().uploadAvatar(img.path);
    if (context.mounted && !ok) showHakiToast(context, 'Couldn’t update photo', isError: true);
  }

  Future<void> _signOut(BuildContext context, bool viewedPhrase) async {
    final session = context.read<SessionCubit>();
    if (!viewedPhrase) {
      final goBackUp = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Back up first?'),
          content: const Text(
            'You haven’t checked your recovery words. Without them you can’t read your messages after signing back in on another phone.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Sign out anyway')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('See my words', style: TextStyle(color: HakiColors.lime)),
            ),
          ],
        ),
      );
      if (goBackUp == null || !context.mounted) return;
      if (goBackUp) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const RecoveryPhraseView()));
        return;
      }
    }
    await session.logout();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionCubit>().state;
    final me = session.me!;
    final viewedPhrase = session is SessionAuthenticated && session.hasViewedRecoveryPhrase;
    final blockedCount = context.select((FriendsCubit c) => c.state.blocked.length);

    return Stack(
      children: [
        const AuroraBackground(height: 380, colors: [HakiColors.teal, HakiColors.blue, HakiColors.violet]),
        SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 28, 16, 140),
            children: [
              Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AuraAvatar(user: me, size: 108, radius: 38),
                    Positioned(
                      right: -6,
                      bottom: -6,
                      child: IconButton(
                        tooltip: 'Change photo',
                        onPressed: () => _changePhoto(context),
                        style: IconButton.styleFrom(
                          backgroundColor: HakiColors.lime,
                          foregroundColor: HakiColors.onLime,
                          side: const BorderSide(color: HakiColors.ink, width: 3),
                        ),
                        icon: const Icon(HakiIcons.camera, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(me.name, textAlign: TextAlign.center, style: HakiText.display(32)),
              const SizedBox(height: 4),
              FutureBuilder(
                future: context.read<SessionCubit>().myHandle(),
                builder: (context, snap) => Text(
                  snap.data == null ? 'No username yet' : '@${snap.data}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.65)),
                ),
              ),
              if (me.bio?.isNotEmpty ?? false) ...[
                const SizedBox(height: 8),
                Text(me.bio!, textAlign: TextAlign.center, style: const TextStyle(color: HakiColors.textMuted)),
              ],
              const SizedBox(height: 14),
              Center(
                child: Wrap(
                  spacing: 8,
                  children: [
                    _Chip(
                      icon: HakiIcons.circleFill,
                      iconColor: HakiColors.lime,
                      label: (me.statusMessage?.isNotEmpty ?? false) ? me.statusMessage! : 'Set a status',
                      onTap: () => _EditSheet.status(context, me),
                    ),
                    _Chip(icon: HakiIcons.pencilSimple, label: 'Edit profile', onTap: () => _EditSheet.profile(context, me)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Bento grid
              // Fixed height: IntrinsicHeight can't measure the QR (it uses a LayoutBuilder)
              SizedBox(
                height: 250,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: _HakiCodeCard(me: me)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _Tile(
                              glass: true,
                              top: Text('12', style: HakiText.display(28, color: viewedPhrase ? HakiColors.lime : HakiColors.dangerText)),
                              title: 'Recovery words',
                              subtitle: viewedPhrase ? 'Checked' : 'Not backed up yet',
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecoveryPhraseView())),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: _Tile(
                              glass: true,
                              top: const Icon(HakiIcons.fingerprint, color: Color(0xFFB9A8FF)),
                              title: 'Key fingerprint',
                              subtitle: 'Compare with friends',
                              onTap: () => SafetyNumberSheet.show(context, me: me),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              FutureBuilder(
                future: context.read<SessionCubit>().myHandle(),
                builder: (context, snap) => _Tile(
                  title: 'Username',
                  subtitle: snap.data == null
                      ? 'Not set · let friends find you without your email'
                      : '@${snap.data} · tap to change or remove',
                  onTap: () => _HandleSheet.show(context, snap.data),
                ),
              ),
              const SizedBox(height: 10),
              _Tile(
                title: 'Birthday',
                subtitle: me.birthday == null ? 'Not shared · friends get a reminder if you add it' : '${_birthdayLabel(me.birthday!)} · only friends see it',
                onTap: () => _pickBirthday(context, me.birthday),
              ),
              const SizedBox(height: 10),
              _Tile(
                title: 'Devices',
                subtitle: 'Where you’re signed in · link a tablet or computer',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DevicesView())),
              ),
              const SizedBox(height: 10),
              _Tile(
                title: 'Two-step login',
                subtitle: 'Ask for a code from an authenticator app at sign-in',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TwoStepView())),
              ),
              const SizedBox(height: 10),
              _Tile(
                title: 'Blocked',
                subtitle: blockedCount == 1 ? '1 person' : '$blockedCount people',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BlockedUsersView())),
              ),
              const SizedBox(height: 18),
              TextButton(
                onPressed: () => _signOut(context, viewedPhrase),
                style: TextButton.styleFrom(foregroundColor: HakiColors.dangerText, minimumSize: const Size.fromHeight(48)),
                child: const Text('Sign out', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

const _monthNames = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

String _birthdayLabel(String mmdd) => '${int.parse(mmdd.substring(3))} ${_monthNames[int.parse(mmdd.substring(0, 2)) - 1]}';

/// Day and month only: the year is never stored.
Future<void> _pickBirthday(BuildContext context, String? current) async {
  final session = context.read<SessionCubit>();
  if (current != null) {
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Birthday'),
        content: Text('Friends see ${_birthdayLabel(current)}.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, 'remove'), child: const Text('Stop sharing', style: TextStyle(color: HakiColors.dangerText))),
          TextButton(onPressed: () => Navigator.pop(ctx, 'change'), child: const Text('Change')),
        ],
      ),
    );
    if (choice == null) return;
    if (choice == 'remove') {
      final ok = await session.setBirthday(null);
      if (context.mounted) showHakiToast(context, ok ? 'Birthday removed' : 'Couldn’t save', isError: !ok);
      return;
    }
  }
  if (!context.mounted) return;
  final picked = await showDatePicker(
    context: context,
    helpText: 'Your birthday (year isn’t saved)',
    initialDate: current == null ? DateTime(2000, 1, 1) : DateTime(2000, int.parse(current.substring(0, 2)), int.parse(current.substring(3))),
    firstDate: DateTime(1920),
    lastDate: DateTime.now(),
  );
  if (picked == null) return;
  final mmdd = '${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
  final ok = await session.setBirthday(mmdd);
  if (context.mounted) showHakiToast(context, ok ? 'Birthday saved' : 'Couldn’t save', isError: !ok);
}

/// Choose, change or remove a username. The server keeps only a keyed hash of it.
abstract final class _HandleSheet {
  static Future<void> show(BuildContext context, String? current) => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => _HandleForm(current: current),
  );
}

class _HandleForm extends StatefulWidget {
  const _HandleForm({this.current});
  final String? current;

  @override
  State<_HandleForm> createState() => _HandleFormState();
}

class _HandleFormState extends State<_HandleForm> {
  late final _text = TextEditingController(text: widget.current ?? '');
  String? _error;
  bool _busy = false;
  static final _valid = RegExp(r'^[a-z][a-z0-9_.]{2,23}$');

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  bool get _ok {
    final h = _text.text.trim().toLowerCase();
    return _valid.hasMatch(h) && !h.endsWith('.') && !h.contains('..') && h != widget.current;
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    final error = await context.read<SessionCubit>().setHandle(_text.text);
    if (!mounted) return;
    if (error == null) {
      Navigator.pop(context);
      showHakiToast(context, 'Username saved');
    } else {
      setState(() {
        _error = error;
        _busy = false;
      });
    }
  }

  Future<void> _remove() async {
    final ok = await context.read<SessionCubit>().clearHandle();
    if (!mounted) return;
    Navigator.pop(context);
    showHakiToast(context, ok ? 'Username removed' : 'Couldn’t remove it', isError: !ok);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Username', style: HakiText.display(28)),
              const SizedBox(height: 4),
              const Text(
                'Friends can add you with @username instead of your email. Haki stores only a scrambled version, so it can’t list usernames or tell anyone yours. Change or remove it any time.',
                style: TextStyle(color: HakiColors.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _text,
                autofocus: true,
                autocorrect: false,
                textCapitalization: TextCapitalization.none,
                maxLength: 24,
                onChanged: (_) => setState(() => _error = null),
                decoration: InputDecoration(
                  prefixText: '@',
                  labelText: 'Username',
                  helperText: 'Start with a letter. Letters, numbers, _ and . (3–24).',
                  helperMaxLines: 2,
                  errorText: _error,
                ),
              ),
              const SizedBox(height: 12),
              LimeButton(label: _busy ? 'Saving…' : 'Save', icon: HakiIcons.check, onPressed: _ok && !_busy ? _save : null),
              if (widget.current != null)
                TextButton(
                  onPressed: _busy ? null : _remove,
                  style: TextButton.styleFrom(foregroundColor: HakiColors.dangerText),
                  child: const Text('Remove username'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HakiCodeCard extends StatelessWidget {
  const _HakiCodeCard({required this.me});
  final UserModel me;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: HakiColors.lime,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: () => showModalBottomSheet(
          context: context,
          // Default sheets cap at 9/16 of the screen, which cut off the username
          isScrollControlled: true,
          builder: (_) => SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Your Haki code', style: HakiText.display(30)),
                  const SizedBox(height: 6),
                  const Text(
                    'Friends scan this to add you. It only contains your username.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: HakiColors.textMuted),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(color: HakiColors.lime, borderRadius: BorderRadius.circular(28)),
                    child: QrImageView(
                      data: hakiCode(me),
                      size: 220,
                      eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.circle, color: HakiColors.onLime),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.circle,
                        color: HakiColors.onLime,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('@${me.username}', style: HakiText.mono(16)),
                ],
              ),
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your Haki code', style: HakiText.display(20, color: HakiColors.onLime, weight: FontWeight.w700)),
              const SizedBox(height: 12),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: HakiColors.onLime, borderRadius: BorderRadius.circular(18)),
                  child: QrImageView(
                    data: hakiCode(me),
                    size: 104,
                    padding: EdgeInsets.zero,
                    eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.circle, color: HakiColors.lime),
                    dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.circle, color: HakiColors.lime),
                    semanticsLabel: 'Your Haki code',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Tap to show. Scan to add, no email shared.',
                style: TextStyle(color: HakiColors.onLime, fontSize: 12, height: 1.35),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.title, required this.subtitle, required this.onTap, this.top, this.glass = false});

  final Widget? top;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool glass;

  @override
  Widget build(BuildContext context) {
    final body = InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (top != null) ...[top!, const SizedBox(height: 8)],
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: HakiColors.textMuted)),
                ],
              ),
            ),
            const Icon(HakiIcons.caretRight, color: HakiColors.textMuted),
          ],
        ),
      ),
    );
    return glass
        ? Glass(child: Material(type: MaterialType.transparency, child: body))
        : Material(color: HakiColors.surface, borderRadius: BorderRadius.circular(28), child: body);
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label, required this.onTap, this.iconColor});
  final IconData icon;
  final Color? iconColor;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: 20,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: iconColor != null ? 9 : 15, color: iconColor),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 180),
                child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom-sheet editors for profile fields.
class _EditSheet {
  static Future<void> profile(BuildContext context, UserModel me) => _show(
    context,
    title: 'Edit profile',
    fields: [('Display name', me.displayName ?? ''), ('Bio', me.bio ?? '')],
    onSave: (v) => context.read<SessionCubit>().updateProfile(displayName: v[0], bio: v[1]),
  );

  static Future<void> status(BuildContext context, UserModel me) => _show(
    context,
    title: 'Status',
    fields: [('What are you up to?', me.statusMessage ?? '')],
    maxLength: 100,
    onSave: (v) => context.read<SessionCubit>().updateStatus(v[0]),
  );

  static Future<void> _show(
    BuildContext context, {
    required String title,
    required List<(String, String)> fields,
    required Future<bool> Function(List<String>) onSave,
    int? maxLength,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _EditForm(title: title, fields: fields, onSave: onSave, maxLength: maxLength, host: context),
    );
  }
}

/// Owns its controllers so they're disposed with the sheet, after the close animation —
/// disposing them when the sheet's future completed crashed the still-visible fields.
class _EditForm extends StatefulWidget {
  const _EditForm({required this.title, required this.fields, required this.onSave, required this.host, this.maxLength});
  final String title;
  final List<(String, String)> fields;
  final Future<bool> Function(List<String>) onSave;
  final BuildContext host;
  final int? maxLength;

  @override
  State<_EditForm> createState() => _EditFormState();
}

class _EditFormState extends State<_EditForm> {
  late final _controllers = [for (final f in widget.fields) TextEditingController(text: f.$2)];

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.viewInsetsOf(context).bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.title, style: HakiText.display(28)),
          const SizedBox(height: 16),
          for (var i = 0; i < widget.fields.length; i++) ...[
            TextField(
              controller: _controllers[i],
              maxLength: widget.maxLength,
              autofocus: i == 0,
              decoration: InputDecoration(labelText: widget.fields[i].$1),
            ),
            const SizedBox(height: 12),
          ],
          LimeButton(
            label: 'Save',
            onPressed: () async {
              final ok = await widget.onSave(_controllers.map((c) => c.text.trim()).toList());
              if (!mounted) return;
              Navigator.pop(this.context);
              final host = widget.host;
              if (!ok && host.mounted) showHakiToast(host, 'Couldn’t save', isError: true);
            },
          ),
        ],
      ),
    );
  }
}

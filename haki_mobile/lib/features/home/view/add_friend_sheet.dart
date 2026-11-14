import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/haki_theme.dart';
import '../../../core/widgets/glass.dart';
import '../../../core/widgets/qr_scanner_view.dart';
import '../../friends/view_model/friends_cubit.dart';

/// Add by scanning a Haki code (QR = `haki:<username>`) or typing an email / username.
class AddFriendSheet extends StatefulWidget {
  const AddFriendSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => BlocProvider.value(value: context.read<FriendsCubit>(), child: const AddFriendSheet()),
  );

  @override
  State<AddFriendSheet> createState() => _AddFriendSheetState();
}

class _AddFriendSheetState extends State<AddFriendSheet> {
  final _input = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _send([String? value]) async {
    setState(() => _busy = true);
    final error = await context.read<FriendsCubit>().sendRequest(value ?? _input.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (error != null) return showHakiToast(context, error, isError: true);
    Navigator.pop(context);
    showHakiToast(context, 'Friend request sent');
  }

  Future<void> _scan() async {
    final value = await QrScannerView.scan(context, title: 'Scan a Haki code');
    if (value == null || !mounted) return;
    if (!value.startsWith('haki:')) {
      return showHakiToast(context, 'That’s not a Haki code', isError: true);
    }
    await _send(value);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.viewInsetsOf(context).bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Add a friend', style: HakiText.display(30)),
          const SizedBox(height: 6),
          const Text(
            'Scanning their Haki code is the private way: no email needed.',
            style: TextStyle(color: HakiColors.textMuted),
          ),
          const SizedBox(height: 20),
          LimeButton(label: 'Scan Haki code', icon: Icons.qr_code_scanner_rounded, onPressed: _busy ? null : _scan),
          const SizedBox(height: 20),
          Row(
            children: [
              const Expanded(child: Divider(color: HakiColors.surfaceHigh)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('or', style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
              ),
              const Expanded(child: Divider(color: HakiColors.surfaceHigh)),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _input,
            autocorrect: false,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _send(),
            decoration: const InputDecoration(
              labelText: 'Email, @username or Haki code',
              prefixIcon: Icon(Icons.alternate_email_rounded),
            ),
          ),
          const SizedBox(height: 12),
          GlassButton(label: _busy ? 'Sending…' : 'Send request', onPressed: _busy ? null : _send),
        ],
      ),
    );
  }
}

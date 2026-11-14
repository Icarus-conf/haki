import 'dart:async';
import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/theme/haki_theme.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/glass.dart';
import '../../../core/widgets/qr_scanner_view.dart';
import '../../../services/api_service.dart';
import '../../../services/crypto_service.dart';
import '../../session/view_model/session_cubit.dart';

/// Devices signed in to this account, with Remove, and "Link a device".
class DevicesView extends StatefulWidget {
  const DevicesView({super.key});

  @override
  State<DevicesView> createState() => _DevicesViewState();
}

class _DevicesViewState extends State<DevicesView> {
  List<Map<String, dynamic>>? _list;
  late final _api = context.read<ApiService>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final l = await _api.sessions();
      if (mounted) setState(() => _list = l);
    } catch (e) {
      if (mounted) showHakiToast(context, e.toString(), isError: true);
    }
  }

  Future<void> _remove(Map<String, dynamic> d) async {
    final sure = await confirmAction(
      context,
      title: 'Remove ${d['name']}?',
      message: 'It’s signed out right away. It still knows your key, so if it was lost, also make new recovery words.',
      action: 'Remove',
    );
    if (!sure) return;
    try {
      await _api.removeSession(d['id'] as String);
      await _load();
      if (mounted) showHakiToast(context, '${d['name']} removed');
    } catch (e) {
      if (mounted) showHakiToast(context, e.toString(), isError: true);
    }
  }

  Future<void> _link() async {
    final ok = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const ApproveLinkView()));
    if (ok == true) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final list = _list;
    return Scaffold(
      appBar: AppBar(title: const Text('Devices')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            const Text(
              'Haki works on several devices at once with the same key. Remove any you don’t recognise.',
              style: TextStyle(color: HakiColors.textMuted, height: 1.4),
            ),
            const SizedBox(height: 16),
            LimeButton(label: 'Link a device', icon: Icons.qr_code_scanner_rounded, onPressed: _link),
            const SizedBox(height: 20),
            if (list == null)
              const Center(
                child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()),
              )
            else
              for (final d in list)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: HakiColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    child: ListTile(
                      contentPadding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
                      leading: Icon(
                        d['platform'] == 'web'
                            ? Icons.language_rounded
                            : d['platform'] == 'macos'
                            ? Icons.laptop_mac_rounded
                            : Icons.smartphone_rounded,
                        color: d['current'] == true ? HakiColors.lime : null,
                      ),
                      title: Text(d['current'] == true ? '${d['name']} · this device' : '${d['name']}'),
                      subtitle: Text(
                        '${d['kind'] == 'linked' ? 'Linked' : 'Signed in'} ${relativeTime(DateTime.parse(d['createdAt']).toLocal())}'
                        ' · active ${relativeTime(DateTime.parse(d['lastSeenAt']).toLocal())}',
                        style: const TextStyle(fontSize: 12, color: HakiColors.textMuted),
                      ),
                      trailing: d['current'] == true
                          ? null
                          : IconButton(
                              tooltip: 'Remove ${d['name']}',
                              icon: const Icon(Icons.logout_rounded, color: HakiColors.dangerText),
                              onPressed: () => _remove(d),
                            ),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

/// Phone side of linking: scan (or type) the new device's code, compare digits, approve.
class ApproveLinkView extends StatefulWidget {
  const ApproveLinkView({super.key});

  @override
  State<ApproveLinkView> createState() => _ApproveLinkViewState();
}

class _ApproveLinkViewState extends State<ApproveLinkView> {
  final _code = TextEditingController();
  Map<String, dynamic>? _peek; // the new device: pub, name
  String? _check;
  bool _busy = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    final v = await QrScannerView.scan(context, title: 'Scan the code on the new device');
    // QR: haki-link:<code>:<pub>
    if (v == null || !v.startsWith('haki-link:')) return;
    final parts = v.split(':');
    _code.text = parts[1];
    await _lookUp(expectedPub: parts.length > 2 ? parts.sublist(2).join(':') : null);
  }

  Future<void> _lookUp({String? expectedPub}) async {
    setState(() => _busy = true);
    try {
      final p = await context.read<ApiService>().linkPeek(_code.text.trim());
      // From a QR we know the key the device showed; the server must hand us that same key
      if (expectedPub != null && expectedPub != p['pub']) throw 'This code doesn’t match the device. Try again.';
      final check = await CryptoService.linkCheck(p['pub'] as String);
      if (mounted) {
        setState(() {
          _peek = p;
          _check = check;
        });
      }
    } catch (e) {
      if (mounted) showHakiToast(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _approve() async {
    setState(() => _busy = true);
    final session = context.read<SessionCubit>();
    final crypto = context.read<CryptoService>();
    final api = context.read<ApiService>();
    try {
      final me = session.me!;
      final key = await crypto.exportPrivateKey(me.username);
      if (key == null) throw 'This phone has no key to share';
      final payload = jsonEncode({'privateKey': key, 'mnemonic': await crypto.getMnemonic(me.username)});
      final (sealed, myPub) = await CryptoService.sealForLink(payload, _peek!['pub'] as String);
      await api.linkApprove(_code.text.trim(), sealed, myPub);
      if (!mounted) return;
      showHakiToast(context, '${_peek!['name']} is linked');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showHakiToast(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final peek = _peek;
    return Scaffold(
      appBar: AppBar(title: const Text('Link a device')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          if (peek == null) ...[
            const Text(
              'On the new device, open Haki and tap “Link to my phone”. Then scan its code, or type the 8 letters under it.',
              style: TextStyle(color: HakiColors.textMuted, height: 1.4),
            ),
            const SizedBox(height: 20),
            LimeButton(label: 'Scan code', icon: Icons.qr_code_scanner_rounded, onPressed: _busy ? null : _scan),
            const SizedBox(height: 20),
            TextField(
              controller: _code,
              textCapitalization: TextCapitalization.characters,
              autocorrect: false,
              maxLength: 8,
              style: HakiText.mono(22),
              decoration: const InputDecoration(labelText: 'Or type the code'),
              onChanged: (_) => setState(() {}),
            ),
            GlassButton(label: 'Continue', onPressed: _busy || _code.text.trim().length != 8 ? null : () => _lookUp()),
          ] else ...[
            Text('Link ${peek['name']}?', style: HakiText.display(30)),
            const SizedBox(height: 8),
            const Text(
              'Check that the new device shows these same digits. If they differ, stop: someone may be in between.',
              style: TextStyle(color: HakiColors.textMuted, height: 1.4),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(_check ?? '', style: HakiText.mono(40, color: HakiColors.lime)),
            ),
            const SizedBox(height: 24),
            const Text(
              'The device gets your encryption key, sealed so only it can open it. It can read your chats and send as you until you remove it.',
              style: TextStyle(color: HakiColors.textMuted, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 20),
            LimeButton(label: 'Digits match, link it', busy: _busy, onPressed: _approve),
            const SizedBox(height: 8),
            GlassButton(label: 'Cancel', onPressed: () => Navigator.pop(context, false)),
          ],
        ],
      ),
    );
  }
}

/// New-device side: show a code, wait for the phone to approve, then open the sealed key.
class LinkThisDeviceView extends StatelessWidget {
  const LinkThisDeviceView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Link to my phone')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: const [
          Text(
            'On your phone: You → Devices → Link a device, then scan this code. No password or words needed.',
            style: TextStyle(color: HakiColors.textMuted, height: 1.4),
          ),
          SizedBox(height: 24),
          LinkPanel(),
        ],
      ),
    );
  }
}

/// The new device's side of linking: a QR + code for the phone, then waits for approval.
/// Used full screen on phones and inline on the computer welcome screen.
class LinkPanel extends StatefulWidget {
  const LinkPanel({super.key, this.qrSize = 220});

  final double qrSize;

  @override
  State<LinkPanel> createState() => _LinkPanelState();
}

class _LinkPanelState extends State<LinkPanel> {
  SimpleKeyPair? _keys;
  String? _pub, _code, _secret, _check, _error;
  Timer? _poll;
  bool _finishing = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    _poll?.cancel();
    setState(() {
      _code = null;
      _error = null;
    });
    try {
      final (kp, pub) = await CryptoService.linkKeyPair();
      if (!mounted) return;
      final res = await context.read<ApiService>().linkStart(pub);
      final check = await CryptoService.linkCheck(pub);
      if (!mounted) return;
      setState(() {
        _keys = kp;
        _pub = pub;
        _code = res['code'] as String;
        _secret = res['secret'] as String;
        _check = check;
      });
      _poll = Timer.periodic(const Duration(seconds: 2), (_) => _checkApproved());
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _checkApproved() async {
    if (_finishing) return;
    try {
      final res = await context.read<ApiService>().linkPoll(_code!, _secret!);
      if (res['status'] != 'approved' || !mounted) return;
      _finishing = true;
      _poll?.cancel();
      setState(() {});
      final payload = await CryptoService.openLink(res['sealed'] as String, _keys!, res['pub'] as String);
      if (!mounted) return;
      final error = await context.read<SessionCubit>().finishLink(
        token: res['access_token'] as String,
        username: res['username'] as String,
        payload: jsonDecode(payload) as Map<String, dynamic>,
      );
      if (!mounted) return;
      if (error != null) {
        setState(() {
          _error = error;
          _finishing = false;
        });
      } else {
        Navigator.of(context).popUntil((r) => r.isFirst);
      }
    } catch (e) {
      _poll?.cancel();
      if (mounted) {
        setState(() {
          _error = e.toString();
          _finishing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final code = _code;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_error != null) ...[
          Text(_error!, style: const TextStyle(color: HakiColors.dangerText)),
          const SizedBox(height: 12),
          LimeButton(label: 'Make a new code', onPressed: _start),
        ] else if (code == null || _finishing)
          SizedBox(
            height: widget.qrSize + 140,
            child: const Center(child: CircularProgressIndicator()),
          )
        else ...[
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
              child: QrImageView(data: 'haki-link:$code:$_pub', size: widget.qrSize),
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: Tooltip(
              message: 'Copy',
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: code));
                  showHakiToast(context, 'Code copied');
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  child: Text('${code.substring(0, 4)} ${code.substring(4)}', style: HakiText.mono(30)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Center(
            child: Text('Your phone should show', style: TextStyle(color: HakiColors.textMuted)),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(_check ?? '', style: HakiText.mono(36, color: HakiColors.lime)),
          ),
          const SizedBox(height: 18),
          const Center(
            child: Text(
              'Waiting for your phone… The code works for 5 minutes.',
              textAlign: TextAlign.center,
              style: TextStyle(color: HakiColors.textMuted, fontSize: 13),
            ),
          ),
        ],
      ],
    );
  }
}

/// Two-step login with an authenticator app (codes change every 30 seconds).
class TwoStepView extends StatefulWidget {
  const TwoStepView({super.key});

  @override
  State<TwoStepView> createState() => _TwoStepViewState();
}

class _TwoStepViewState extends State<TwoStepView> {
  late final _api = context.read<ApiService>();
  final _code = TextEditingController();
  bool? _enabled;
  Map<String, dynamic>? _setup; // secret + otpauth link while turning it on
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _api
        .twoStepEnabled()
        .then((v) {
          if (mounted) setState(() => _enabled = v);
        })
        .catchError((Object e) {
          if (mounted) showHakiToast(context, e.toString(), isError: true);
        });
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action, String done) async {
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) showHakiToast(context, done);
    } catch (e) {
      if (mounted) showHakiToast(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final setup = _setup;
    final codeField = TextField(
      controller: _code,
      keyboardType: TextInputType.number,
      maxLength: 6,
      style: HakiText.mono(24),
      decoration: const InputDecoration(labelText: '6-digit code', counterText: ''),
      onChanged: (_) => setState(() {}),
    );
    final codeOk = RegExp(r'^\d{6}$').hasMatch(_code.text.trim());

    return Scaffold(
      appBar: AppBar(title: const Text('Two-step login')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          const Text(
            'Signing in on a new device will need your password and a code from an authenticator app '
            '(1Password, Google Authenticator, Apple Passwords…). Linking from your phone doesn’t need it.',
            style: TextStyle(color: HakiColors.textMuted, height: 1.4),
          ),
          const SizedBox(height: 20),
          if (_enabled == null)
            const Center(child: CircularProgressIndicator())
          else if (_enabled!) ...[
            const Row(
              children: [
                Icon(Icons.verified_user_rounded, color: HakiColors.lime),
                SizedBox(width: 8),
                Text('On', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17)),
              ],
            ),
            const SizedBox(height: 16),
            const Text('To turn it off, enter a current code.'),
            const SizedBox(height: 8),
            codeField,
            const SizedBox(height: 12),
            GlassButton(
              label: 'Turn off',
              onPressed: _busy || !codeOk
                  ? null
                  : () => _run(() async {
                      await _api.twoStepDisable(_code.text.trim());
                      setState(() {
                        _enabled = false;
                        _setup = null;
                      });
                      _code.clear();
                    }, 'Two-step login is off'),
            ),
          ] else if (setup == null)
            LimeButton(
              label: 'Turn on',
              icon: Icons.shield_rounded,
              busy: _busy,
              onPressed: () => _run(() async {
                final s = await _api.twoStepSetup();
                setState(() => _setup = s);
              }, 'Add Haki to your authenticator app'),
            )
          else ...[
            const Text('1. Scan this with your authenticator app, or tap the key to copy it.'),
            const SizedBox(height: 14),
            Center(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                child: QrImageView(data: setup['uri'] as String, size: 190),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: setup['secret'] as String));
                  showHakiToast(context, 'Key copied');
                },
                child: Text(
                  (setup['secret'] as String).replaceAllMapped(RegExp(r'.{4}'), (m) => '${m[0]} ').trim(),
                  textAlign: TextAlign.center,
                  style: HakiText.mono(15, color: HakiColors.lime),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('2. Enter the code it shows.'),
            const SizedBox(height: 8),
            codeField,
            const SizedBox(height: 12),
            LimeButton(
              label: 'Turn on',
              busy: _busy,
              onPressed: !codeOk
                  ? null
                  : () => _run(() async {
                      await _api.twoStepEnable(_code.text.trim());
                      setState(() {
                        _enabled = true;
                        _setup = null;
                      });
                      _code.clear();
                    }, 'Two-step login is on'),
            ),
          ],
        ],
      ),
    );
  }
}

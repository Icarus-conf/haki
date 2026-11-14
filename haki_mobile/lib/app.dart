import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';

import 'core/theme/haki_theme.dart';
import 'core/widgets/glass.dart';
import 'features/call/view/call_view.dart';
import 'features/call/view/group_call_view.dart';
import 'features/call/view_model/call_cubit.dart';
import 'features/call/view_model/group_call_cubit.dart';
import 'features/friends/view_model/friends_state.dart';
import 'features/settings/view_model/settings_cubit.dart';
import 'features/friends/view_model/friends_cubit.dart';
import 'features/home/view/responsive_home.dart';
import 'features/session/view/onboarding_view.dart';
import 'features/session/view/unlock_view.dart';
import 'features/session/view/welcome_view.dart';
import 'features/session/view_model/session_cubit.dart';
import 'features/session/view_model/session_state.dart';
import 'features/stories/view_model/stories_cubit.dart';
import 'features/conversation/view/conversation_view.dart';
import 'services/api_service.dart';
import 'services/chat_service.dart';
import 'services/crypto_service.dart';
import 'services/native_calls.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'services/push_service.dart';

final navigatorKey = GlobalKey<NavigatorState>();

class HakiApp extends StatefulWidget {
  const HakiApp({super.key});

  @override
  State<HakiApp> createState() => _HakiAppState();
}

class _HakiAppState extends State<HakiApp> {
  bool _splashDone = false;
  StreamSubscription<String>? _systemMessages;
  StreamSubscription? _mentions;
  StreamSubscription? _storyLoves;
  StreamSubscription? _nativeCalls;
  late final AppLifecycleListener _lifecycle;
  Timer? _backupTimer;
  final Map<int, String> _checkedKeys = {}; // friend id -> key string already checked this run

  @override
  void initState() {
    super.initState();
    final chat = context.read<ChatService>();
    // Tell the server when Haki is on screen, so it pushes only when you're away
    _lifecycle = AppLifecycleListener(
      // show/hide, not inactive: the photo picker or Control Center shouldn't count as away
      onShow: () => chat.emit('app_state', {'foreground': true}),
      onHide: () => chat.emit('app_state', {'foreground': false}),
    );
    context.read<PushService>().onOpen = _openFromPush;
    context.read<SettingsCubit>().onChanged = _scheduleBackup;
    // Answering or declining on the phone's own call screen (CallKit / Android)
    final calls = context.read<CallCubit>();
    _nativeCalls = NativeCalls.events.listen((e) {
      switch (e) {
        case CallEventActionCallAccept():
          if (calls.state.phase == CallPhase.incoming) calls.accept();
        case CallEventActionCallDecline():
          if (calls.state.phase == CallPhase.incoming) calls.decline();
        case CallEventActionCallEnded():
          if (calls.state.phase != CallPhase.idle && calls.state.phase != CallPhase.ended) calls.hangUp();
        default:
          break;
      }
    });
    // Admin broadcasts from the dashboard
    _systemMessages = context.read<ChatService>().systemMessages.listen(
      (m) => showTopToast(navigatorKey.currentState?.overlay, m, duration: const Duration(seconds: 6)),
    );
    // Someone wrote @you in the Lounge
    _mentions = context
        .read<ChatService>()
        .on('mention')
        .listen(
          (d) => showTopToast(
            navigatorKey.currentState?.overlay,
            '${d['from']} mentioned you in the Lounge: ${d['text']}',
          ),
        );
    _storyLoves = context.read<ChatService>().on('story_liked').listen((d) {
      if (!mounted) return;
      final who = context.read<FriendsCubit>().state.byId(d['userId'] as int)?.name ?? 'A friend';
      showTopToast(navigatorKey.currentState?.overlay, '$who loved your story ❤️');
    });
  }

  /// A tapped notification: open that chat once the chat list has loaded.
  Future<void> _openFromPush(Map<String, dynamic> chat) async {
    final friends = context.read<FriendsCubit>();
    final ready = friends.state.isLoading
        ? await friends.stream
              .firstWhere((s) => !s.isLoading)
              .timeout(const Duration(seconds: 10), onTimeout: () => friends.state)
        : friends.state;
    final nav = navigatorKey.currentState;
    if (nav == null) return;
    nav.popUntil((r) => r.isFirst);
    Widget? screen;
    if (chat['g'] != null) {
      final g = ready.groupById(chat['g'] as int);
      if (g != null) screen = ConversationView(group: g);
    } else if (chat['u'] != null) {
      final f = ready.byId(chat['u'] as int);
      if (f != null) {
        friends.openChat(f.id);
        screen = ConversationView(recipient: f);
      }
    } else if (chat['lounge'] != null) {
      screen = const ConversationView();
    }
    if (screen != null) nav.push(MaterialPageRoute(builder: (_) => screen!));
  }

  // ===== Sealed backup of this phone's private settings (notes, locks, checked keys, folders) =====
  void _scheduleBackup() {
    _backupTimer?.cancel();
    _backupTimer = Timer(const Duration(seconds: 2), _uploadBackup);
  }

  Future<void> _uploadBackup() async {
    final me = context.read<SessionCubit>().state.readyUser;
    final key = me?.publicKey;
    if (me == null || key == null) return;
    final api = context.read<ApiService>();
    final json = jsonEncode(context.read<SettingsCubit>().exportBackup());
    final sealed = await context.read<CryptoService>().encryptFor(json, {'me': key});
    try {
      await api.putBackup(sealed);
    } catch (_) {
      /* offline: next change retries */
    }
  }

  /// New phone or linked device: bring back what the other phone had, then re-upload the merge.
  Future<void> _restoreBackup(String username) async {
    final sealed = await context.read<ApiService>().getBackup();
    if (sealed == null || !mounted) return;
    final json = await context.read<CryptoService>().decrypt(sealed, username, preferKey: 'me');
    try {
      if (!mounted) return;
      await context.read<SettingsCubit>().importBackup(jsonDecode(json) as Map<String, dynamic>);
      _scheduleBackup();
    } catch (_) {
      /* sealed to an older key: nothing to restore */
    }
  }

  /// Trust on first use: remember each friend's key, warn when it changes.
  Future<void> _checkKeys(FriendsState s) async {
    final settings = context.read<SettingsCubit>();
    for (final f in s.friends) {
      final key = f.publicKey;
      if (key == null || _checkedKeys[f.id] == key) continue;
      _checkedKeys[f.id] = key;
      final fp = await CryptoService.keyFingerprint(key);
      if (fp != null && await settings.checkKey(f.id, fp)) {
        showTopToast(
          navigatorKey.currentState?.overlay,
          '${f.name}’s safety number changed. They may have a new phone. Check it in your chat.',
          duration: const Duration(seconds: 6),
          maxLines: 3,
        );
      }
    }
  }

  @override
  void dispose() {
    _backupTimer?.cancel();
    _nativeCalls?.cancel();
    _systemMessages?.cancel();
    _mentions?.cancel();
    _storyLoves?.cancel();
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // Start/stop the per-user ViewModels when the signed-in user changes
        BlocListener<SessionCubit, SessionState>(
          // readyUser: only once keys are ready (not while a new phone is still locked)
          listenWhen: (a, b) => a.readyUser?.id != b.readyUser?.id,
          listener: (context, state) {
            final me = state.readyUser;
            if (me != null) {
              context.read<FriendsCubit>().start(me);
              _restoreBackup(me.username);
              context.read<StoriesCubit>().load();
              final api = context.read<ApiService>();
              context.read<PushService>().start().then((_) => NativeCalls.registerVoip(api));
            } else {
              context.read<FriendsCubit>().stop();
              _checkedKeys.clear();
              context.read<StoriesCubit>().clear();
              navigatorKey.currentState?.popUntil((r) => r.isFirst);
            }
          },
        ),
        BlocListener<FriendsCubit, FriendsState>(
          listenWhen: (a, b) => a.friends != b.friends,
          listener: (context, s) => _checkKeys(s),
        ),
        // Someone started a call in one of my groups
        BlocListener<GroupCallCubit, GroupCallState>(
          listenWhen: (a, b) => a.ringing != b.ringing,
          listener: (context, s) {
            // Joined, or the call ended: the ring notice goes away
            if (s.ringing == null) return hideTopToast();
            final g = context.read<FriendsCubit>().state.groupById(s.ringing!);
            final me = context.read<SessionCubit>().state.readyUser;
            if (g == null || me == null) return;
            showTopToast(
              navigatorKey.currentState?.overlay,
              '📞 Group call in ${g.name}',
              duration: const Duration(seconds: 25),
              action: 'Join',
              onAction: () {
                final nav = navigatorKey.currentState;
                if (nav != null) GroupCallView.open(nav.context, g, me);
              },
            );
          },
        ),
        // Not on screen: ring with the phone's own call UI. Call over: take it down.
        BlocListener<CallCubit, CallState>(
          listenWhen: (a, b) => a.phase != b.phase,
          listener: (context, s) {
            if (s.phase == CallPhase.incoming && WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
              final name = context.read<FriendsCubit>().state.byId(s.peerId!)?.name ?? 'Haki';
              NativeCalls.showIncoming(peerId: s.peerId!, name: name, video: s.video);
            }
            if (s.phase == CallPhase.ended) NativeCalls.end();
          },
        ),
        // Incoming call from anywhere in the app
        BlocListener<CallCubit, CallState>(
          listenWhen: (a, b) => a.phase != b.phase && b.phase == CallPhase.incoming,
          listener: (context, state) =>
              navigatorKey.currentState?.push(MaterialPageRoute(builder: (_) => CallView(peerId: state.peerId!))),
        ),
      ],
      child: MaterialApp(
        title: 'Haki',
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey,
        theme: buildHakiTheme(),
        home: BlocBuilder<SessionCubit, SessionState>(
          buildWhen: (a, b) => a.runtimeType != b.runtimeType,
          // The splash plays once to the end, then crossfades into wherever the session landed
          builder: (context, state) => AnimatedSwitcher(
            duration: const Duration(milliseconds: 450),
            child: switch (state) {
              _ when !_splashDone => _Splash(
                key: const ValueKey('splash'),
                onDone: () => setState(() => _splashDone = true),
              ),
              SessionInitializing() => _Splash(key: const ValueKey('splash'), onDone: () {}),
              SessionUnauthenticated() => const WelcomeView(),
              SessionOnboarding(:final mnemonic) => OnboardingView(mnemonic: mnemonic),
              SessionNeedsRecovery(:final me) => UnlockView(name: me.name),
              SessionAuthenticated() => const ResponsiveHome(),
            },
          ),
        ),
      ),
    );
  }
}

class _Splash extends StatefulWidget {
  const _Splash({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<_Splash> createState() => _SplashState();
}

/// The key-h traces itself, fills, turns like a key and clicks; the wordmark lands on the click.
class _SplashState extends State<_Splash> with TickerProviderStateMixin {
  late final _mark = AnimationController(vsync: this);
  late final _word = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));

  @override
  void initState() {
    super.initState();
    _mark.addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onDone();
    });
    // The key clicks into place at ~frame 76 of 132
    _mark.addListener(() {
      if (_mark.value > .54 && _word.status == AnimationStatus.dismissed) _word.forward();
    });
  }

  void _start(LottieComposition c) {
    if (MediaQuery.of(context).disableAnimations) {
      _mark.value = 1; // reduced motion: show the finished mark, no tracing or turning
      _word.value = 1;
      Future.delayed(const Duration(milliseconds: 500), widget.onDone);
      return;
    }
    _mark
      ..duration = c.duration
      ..forward();
  }

  @override
  void dispose() {
    _mark.dispose();
    _word.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final word = CurvedAnimation(parent: _word, curve: const Cubic(0, .65, .51, .99));
    return Scaffold(
      body: Stack(
        children: [
          const AuroraBackground(height: 900, fadeStart: 0.5),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Lottie.asset('assets/lottie/splash.json', controller: _mark, width: 220, height: 220, onLoaded: _start),
                const SizedBox(height: 4),
                AnimatedBuilder(
                  animation: word,
                  builder: (context, child) => Opacity(
                    opacity: word.value,
                    child: Transform.translate(offset: Offset(0, 14 * (1 - word.value)), child: child),
                  ),
                  child: Column(
                    children: [
                      Text('haki', style: HakiText.display(44)),
                      const SizedBox(height: 6),
                      Text(
                        'End-to-end encrypted',
                        style: TextStyle(fontSize: 13, letterSpacing: .4, color: Colors.white.withValues(alpha: .55)),
                      ),
                    ],
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

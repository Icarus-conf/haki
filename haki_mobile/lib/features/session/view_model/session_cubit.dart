import 'dart:developer' as dev;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../models/user_model.dart';
import '../../../services/api_service.dart';
import '../../../services/chat_service.dart';
import '../../../services/crypto_service.dart';
import '../../../services/push_service.dart';
import 'session_state.dart';

/// Auth, key setup and the signed-in user's profile.
/// Methods that the UI awaits return `null` on success or an error message.
class SessionCubit extends Cubit<SessionState> {
  SessionCubit({required this.api, required this.chat, required this.crypto, this.push})
    : super(const SessionState.initializing());

  final ApiService api;
  final ChatService chat;
  final CryptoService crypto;
  final PushService? push;

  UserModel? get me => state.me;

  Future<void> tryAutoLogin() async {
    if (await api.getToken() == null) return emit(const SessionState.unauthenticated());
    final (me, needsWords) = await _initApp();
    if (me == null) return emit(const SessionState.unauthenticated());
    if (needsWords) return emit(SessionState.needsRecovery(me: me));
    emit(
      SessionState.authenticated(
        me: me,
        hasViewedRecoveryPhrase: await crypto.hasViewedRecoveryPhrase(me.username),
      ),
    );
  }

  /// Returned by [login] when the account has two-step login on and no [code] was given.
  static const needsCode = '__two_step__';

  Future<String?> login(String username, String password, {String? code}) async {
    final error = await _signIn(username, password, code: code);
    if (error != null) return error;
    final (me, needsWords) = await _initApp();
    if (me == null) return 'Could not load your account';
    if (needsWords) {
      emit(SessionState.needsRecovery(me: me));
      return null;
    }
    emit(
      SessionState.authenticated(
        me: me,
        hasViewedRecoveryPhrase: await crypto.hasViewedRecoveryPhrase(me.username),
      ),
    );
    return null;
  }

  /// Sign in on a new device and rebuild the key pair from the 12 words.
  Future<String?> restore(String username, String password, String mnemonic, {String? code}) async {
    final words = mnemonic.trim().split(RegExp(r'\s+'));
    if (words.length != 12) return 'Your recovery phrase must be exactly 12 words';
    final error = await _signIn(username, password, code: code);
    if (error != null) return error;
    final phrase = words.join(' ');
    final mismatch = await _wordsMismatch(phrase);
    if (mismatch != null) {
      await api.clearToken(); // stay signed out: don't leave a half-restored session
      return mismatch;
    }
    await crypto.storeMnemonic(username, phrase);
    final (me, _) = await _initApp(mnemonic: phrase);
    if (me == null) return 'Could not restore your account';
    await crypto.markRecoveryPhraseViewed(me.username);
    emit(SessionState.authenticated(me: me, hasViewedRecoveryPhrase: true));
    return null;
  }

  Future<String?> register({
    required String username,
    required String email,
    required String password,
    String? displayName,
    String? bio,
    String? avatarPath,
    String? inviteCode,
  }) async {
    final res = await api.register(username, email, password, inviteCode: inviteCode);
    if (res['id'] == null) return (res['message'] ?? 'Registration failed').toString();

    final error = await _signIn(username, password);
    if (error != null) return error;

    // Generate the phrase first so the key pair is derived from it — otherwise the
    // words shown to the user could never restore this account's key.
    final mnemonic = await crypto.generateMnemonic();
    await crypto.storeMnemonic(username, mnemonic);
    var (me, _) = await _initApp(mnemonic: mnemonic);
    if (me == null) return 'Registered, but sign-in failed';

    me =
        await api.updateProfile(
          displayName: (displayName?.isNotEmpty ?? false) ? displayName : username,
          bio: (bio?.isNotEmpty ?? false) ? bio : null,
        ) ??
        me;
    if (avatarPath != null) {
      await api.uploadAvatar(avatarPath);
      me = await api.getMe() ?? me;
    }
    emit(SessionState.onboarding(me: me, mnemonic: mnemonic));
    return null;
  }

  Future<void> completeOnboarding() async {
    final me = state.me;
    if (me == null) return;
    await crypto.markRecoveryPhraseViewed(me.username);
    emit(SessionState.authenticated(me: me, hasViewedRecoveryPhrase: true));
  }

  Future<void> markRecoveryPhraseViewed() async {
    final s = state;
    if (s is! SessionAuthenticated) return;
    await crypto.markRecoveryPhraseViewed(s.me.username);
    emit(s.copyWith(hasViewedRecoveryPhrase: true));
  }

  /// Second phone: rebuild the account's existing key from the 12 words.
  Future<String?> unlockWithWords(String mnemonic) async {
    final s = state;
    if (s is! SessionNeedsRecovery) return null;
    final words = mnemonic.trim().split(RegExp(r'\s+'));
    if (words.length != 12) return 'Your recovery phrase must be exactly 12 words';
    final phrase = words.join(' ');
    final mismatch = await _wordsMismatch(phrase);
    if (mismatch != null) return mismatch;
    await crypto.storeMnemonic(s.me.username, phrase);
    final (me, _) = await _initApp(mnemonic: phrase);
    if (me == null) return 'Could not unlock your account';
    await crypto.markRecoveryPhraseViewed(me.username);
    emit(SessionState.authenticated(me: me, hasViewedRecoveryPhrase: true));
    return null;
  }

  /// Second phone without working words: new key + new words. Older messages and the
  /// other phone stop being readable, so the UI asks first.
  Future<void> startFreshOnThisPhone() async {
    final s = state;
    if (s is! SessionNeedsRecovery) return;
    final (mnemonic, pubKey) = await crypto.createNewRecoveryPhrase(s.me.username);
    final me = await api.updateProfile(publicKey: pubKey) ?? s.me;
    chat.connect((await api.getToken())!);
    emit(SessionState.onboarding(me: me, mnemonic: mnemonic));
  }

  /// Null when [phrase] recreates the key the server has for this account (or it has none).
  Future<String?> _wordsMismatch(String phrase) async {
    final serverKey = (await api.getMe())?.publicKey;
    if (serverKey == null) return null;
    final fromWords = await crypto.publicKeyFromWords(phrase);
    return CryptoService.sameKey(fromWords, serverKey)
        ? null
        : 'Those words don’t match this account. Check each word and try again.';
  }

  /// Replaces this account's key with one derived from fresh words and publishes it.
  Future<String?> createNewRecoveryPhrase() async {
    final me = state.me;
    if (me == null) return null;
    final (mnemonic, pubKey) = await crypto.createNewRecoveryPhrase(me.username);
    final updated = await api.updateProfile(publicKey: pubKey);
    if (updated != null) _replaceMe(updated);
    await markRecoveryPhraseViewed();
    return mnemonic;
  }

  Future<bool> updateProfile({String? displayName, String? bio}) async {
    final updated = await api.updateProfile(displayName: displayName, bio: bio);
    if (updated == null) return false;
    _replaceMe(updated);
    return true;
  }

  Future<bool> updateStatus(String status) async {
    final updated = await api.updateStatus(status);
    if (updated == null) return false;
    _replaceMe(updated);
    return true;
  }

  Future<bool> uploadAvatar(String path) async {
    if (await api.uploadAvatar(path) == null) return false;
    final updated = await api.getMe();
    if (updated != null) _replaceMe(updated);
    return true;
  }

  /// My username, decrypted from the copy sealed to my own key (null if none / unreadable).
  Future<String?> myHandle() async {
    final m = state.me;
    if (m?.handleSealed == null) return null;
    final h = await crypto.decrypt(m!.handleSealed!, m.username, preferKey: 'me');
    return CryptoService.undecryptable.contains(h) || h.startsWith('[') || h.startsWith('{') ? null : h;
  }

  Future<String?> setHandle(String raw) async {
    final m = state.me;
    final handle = raw.trim().toLowerCase().replaceFirst(RegExp(r'^@'), '');
    if (m?.publicKey == null) return 'Your encryption key isn’t ready yet';
    final sealed = await crypto.encryptFor(handle, {'me': m!.publicKey!});
    final error = await api.setHandle(handle, sealed);
    if (error == null) _replaceMe(m.copyWith(handleSealed: sealed));
    return error;
  }

  Future<bool> clearHandle() async {
    final m = state.me;
    if (m == null || !await api.clearHandle()) return false;
    _replaceMe(m.copyWith(handleSealed: null));
    return true;
  }

  Future<bool> setBirthday(String? mmdd) async {
    final updated = await api.updateProfile(birthday: mmdd ?? '');
    if (updated == null) return false;
    _replaceMe(updated);
    return true;
  }

  /// This device was linked from a signed-in phone, which sent the account key sealed to us.
  Future<String?> finishLink({required String token, required String username, required Map<String, dynamic> payload}) async {
    final key = payload['privateKey'] as String?;
    if (key == null) return 'The other phone didn’t send a key';
    await api.saveToken(token);
    await crypto.importPrivateKey(username, key);
    final words = payload['mnemonic'] as String?;
    if (words != null) await crypto.storeMnemonic(username, words);
    await crypto.markRecoveryPhraseViewed(username);
    final (me, needsWords) = await _initApp();
    if (me == null || needsWords) return 'Couldn’t finish linking';
    emit(SessionState.authenticated(me: me, hasViewedRecoveryPhrase: true));
    return null;
  }

  Future<void> logout() async {
    await push?.stop(); // while still signed in, so the server accepts it
    await api.clearToken();
    chat.disconnect();
    emit(const SessionState.unauthenticated());
  }

  void _replaceMe(UserModel me) {
    final s = state;
    if (s is SessionAuthenticated) emit(s.copyWith(me: me));
    if (s is SessionOnboarding) emit(s.copyWith(me: me));
  }

  Future<String?> _signIn(String username, String password, {String? code}) async {
    try {
      final res = await api.login(username, password, code: code);
      if (res['access_token'] != null) return null;
      if (res['twoFactor'] == true) return code == null ? needsCode : (res['message'] ?? 'That code didn’t work').toString();
      final msg = res['message'];
      if (msg is String && msg.isNotEmpty && msg != 'Unauthorized') return msg;
      return 'Wrong username or password';
    } catch (e) {
      dev.log('Login failed: $e', name: 'SessionCubit');
      return 'Can’t reach the server';
    }
  }

  /// Loads the profile, prepares the E2EE key pair, syncs the public key and opens the socket.
  /// Returns needsWords = true instead of touching keys when the account already has a key
  /// but this phone doesn't: generating a new one here used to replace the key on the server
  /// and silently cut off the user's other phone.
  Future<(UserModel?, bool needsWords)> _initApp({String? mnemonic}) async {
    try {
      var me = await api.getMe();
      if (me == null) return (null, false);
      if (mnemonic == null && me.publicKey != null && !await crypto.hasLocalKey(me.username)) {
        return (me, true);
      }
      final pubKey = await crypto.initKeys(me.username, mnemonic: mnemonic);
      me = await api.updateProfile(publicKey: pubKey) ?? me;
      chat.connect((await api.getToken())!);
      return (me, false);
    } catch (e) {
      dev.log('Init failed: $e', name: 'SessionCubit', error: e);
      return (null, false);
    }
  }
}

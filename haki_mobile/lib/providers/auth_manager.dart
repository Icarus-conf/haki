import 'dart:developer' as dev;

import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/chat_service.dart';
import '../services/crypto_service.dart';

/// Manages authentication, user initialization, and onboarding state
class AuthManager extends ChangeNotifier {
  final ApiService _api;
  final ChatService _chat;
  final CryptoService _crypto;

  UserModel? _me;
  bool _isAppInitialized = false;
  bool _isLoading = false;
  bool _hasViewedRecoveryPhrase = false;
  bool _needsOnboarding = false;
  String? _currentMnemonic;

  AuthManager({required ApiService api, required ChatService chat, required CryptoService crypto})
    : _api = api,
      _chat = chat,
      _crypto = crypto;

  // Getters
  UserModel? get me => _me;
  bool get isAppInitialized => _isAppInitialized;
  bool get isLoading => _isLoading;
  bool get hasViewedRecoveryPhrase => _hasViewedRecoveryPhrase;
  bool get needsOnboarding => _needsOnboarding;
  String? get currentMnemonic => _currentMnemonic;
  ApiService get api => _api;
  CryptoService get crypto => _crypto;

  // Setters
  void setNeedsOnboarding(bool value) {
    _needsOnboarding = value;
    notifyListeners();
  }

  void setCurrentMnemonic(String? mnemonic) {
    _currentMnemonic = mnemonic;
    notifyListeners();
  }

  void setMe(UserModel? user) {
    _me = user;
    notifyListeners();
  }

  /// Login with username and password
  Future<bool> login(
    String username,
    String password, {
    String? mnemonic,
    bool isRegistration = false,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _api.login(username, password);
      if (res['access_token'] != null) {
        // Check if user has viewed recovery phrase (existing user login)
        if (mnemonic == null) {
          _hasViewedRecoveryPhrase = await _crypto.hasViewedRecoveryPhrase(username);
        }

        // If mnemonic is provided, it's a restore operation
        if (mnemonic != null) {
          await _crypto.storeMnemonic(username, mnemonic);
        }

        // Ensure needsOnboarding is false for logins (unless it's a registration flow)
        if (!isRegistration) {
          _needsOnboarding = false;
        }

        final success = await initApp(mnemonic: mnemonic);
        if (success) {
          _isAppInitialized = true;
        }
        return success;
      }
    } catch (e) {
      dev.log(e.toString(), name: 'AuthManager');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  /// Try to auto-login with stored token
  Future<bool> tryAutoLogin() async {
    final token = await _api.getToken();
    if (token != null) {
      final success = await initApp();
      _isAppInitialized = true;
      notifyListeners();
      return success;
    }
    _isAppInitialized = true;
    notifyListeners();
    return false;
  }

  /// Initialize the app after authentication
  Future<bool> initApp({String? mnemonic}) async {
    try {
      _me = await _api.getMe();
      if (_me != null) {
        // E2EE Key Init (with optional mnemonic for restoration)
        final pubKey = await _crypto.initKeys(_me!.username, mnemonic: mnemonic);

        // Always sync public key with server on init to handle stale keys on server
        _me = await _api.updateProfile(publicKey: pubKey);

        // Check if user has viewed recovery phrase
        _hasViewedRecoveryPhrase = await _crypto.hasViewedRecoveryPhrase(_me!.username);

        // Small delay to allow friends' apps to also sync their keys
        await Future.delayed(const Duration(milliseconds: 500));

        final token = await _api.getToken();
        _chat.connect(token!);

        dev.log('App initialization completed successfully', name: 'AuthManager');
        notifyListeners();
        return true;
      }
    } catch (e) {
      dev.log('Auto-login failed: $e', name: 'AuthManager', error: e);
      _me = null;
    }
    return false;
  }

  /// Update user profile
  Future<bool> updateProfile({String? displayName, String? bio}) async {
    final updatedUser = await _api.updateProfile(displayName: displayName, bio: bio);
    if (updatedUser != null) {
      _me = updatedUser;
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Upload user avatar
  Future<String?> uploadAvatar(String filePath) async {
    final avatarUrl = await _api.uploadAvatar(filePath);
    if (avatarUrl != null && _me != null) {
      _me = await _api.getMe();
      notifyListeners();
    }
    return avatarUrl;
  }

  /// Logout user
  Future<void> logout() async {
    await _api.clearToken();
    _chat.disconnect();
    _me = null;
    _isAppInitialized = true; // Show login view immediately
    notifyListeners();
  }
}

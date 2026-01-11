import 'package:flutter/material.dart';

import '../models/user_model.dart';

/// Manages UI-related state like theme, search, wallpaper, and pinned users
class UIStateManager extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  final Set<int> _pinnedUserIds = {};
  String _searchQuery = '';
  String? _chatWallpaper;

  // Getters
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  String get searchQuery => _searchQuery;
  String? get chatWallpaper => _chatWallpaper;
  List<int> get pinnedUserIds => _pinnedUserIds.toList();

  /// Toggle between light and dark theme
  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  /// Toggle pin status for a user
  void togglePinUser(int userId) {
    if (_pinnedUserIds.contains(userId)) {
      _pinnedUserIds.remove(userId);
    } else {
      _pinnedUserIds.add(userId);
    }
    notifyListeners();
  }

  /// Update search query
  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Update chat wallpaper
  void updateChatWallpaper(String? path) {
    _chatWallpaper = path;
    notifyListeners();
  }

  /// Get filtered and sorted users based on search and pinned status
  List<UserModel> getFilteredUsers(List<UserModel> users) {
    List<UserModel> result = users;

    // Search filter
    if (_searchQuery.isNotEmpty) {
      result = result.where((u) {
        final name = (u.displayName ?? u.username).toLowerCase();
        return name.contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Sort by pinned first, then by display name
    result.sort((a, b) {
      final aPinned = _pinnedUserIds.contains(a.id);
      final bPinned = _pinnedUserIds.contains(b.id);
      if (aPinned && !bPinned) return -1;
      if (!aPinned && bPinned) return 1;
      return (a.displayName ?? a.username).compareTo(b.displayName ?? b.username);
    });

    return result;
  }

  /// Clear UI state
  void clear() {
    _searchQuery = '';
    // Keep theme and wallpaper preferences
  }
}

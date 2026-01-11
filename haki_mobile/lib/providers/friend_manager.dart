import 'dart:developer' as dev;

import 'package:flutter/material.dart';

import '../models/friend_request_model.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/chat_service.dart';

/// Manages friends, friend requests, and online status
class FriendManager extends ChangeNotifier {
  final ApiService _api;
  final ChatService _chat;

  List<UserModel> _users = [];
  List<int> _onlineUserIds = [];
  List<FriendRequestModel> _requests = [];

  FriendManager({required ApiService api, required ChatService chat}) : _api = api, _chat = chat;

  // Getters
  List<UserModel> get users => _users;
  List<int> get onlineUserIds => _onlineUserIds;
  List<FriendRequestModel> get requests => _requests;

  /// Get a specific user by ID
  UserModel? getUserById(int userId) {
    try {
      return _users.firstWhere((u) => u.id == userId);
    } catch (_) {
      return null;
    }
  }

  /// Setup friend-related listeners
  void setupListeners() {
    // Online Users
    _chat.onlineUsers.listen((ids) {
      _onlineUserIds = ids;
      notifyListeners();
    });

    // Friend Requests
    _chat.friendRequests.listen((data) {
      // Refresh both lists to be safe (handles new requests and acceptances)
      fetchRequests();
      fetchFriends();
    });

    // Status Messages
    _chat.socket?.on('user:status', (data) {
      final userId = data['userId'];
      final statusMessage = data['statusMessage'];

      // Update user's status in the users list
      final index = _users.indexWhere((f) => f.id == userId);
      if (index != -1) {
        _users[index] = UserModel(
          id: _users[index].id,
          username: _users[index].username,
          email: _users[index].email,
          displayName: _users[index].displayName,
          bio: _users[index].bio,
          avatarUrl: _users[index].avatarUrl,
          publicKey: _users[index].publicKey,
          statusMessage: statusMessage,
        );
        notifyListeners();
      }
    });
  }

  /// Fetch friends list from server
  Future<void> fetchFriends() async {
    final List<UserModel> serverFriends = await _api.getFriends();
    _users = serverFriends;
    notifyListeners();
  }

  /// Fetch friend requests from server
  Future<void> fetchRequests() async {
    final List data = await _api.getFriendRequests();
    _requests = data.map((r) => FriendRequestModel.fromJson(r)).toList();
    notifyListeners();
  }

  /// Send a friend request
  Future<bool> sendFriendRequest(String email) async {
    try {
      dev.log('Sending friend request to: $email', name: 'FriendManager');
      final success = await _api.sendFriendRequest(email);
      dev.log('Friend request result: $success', name: 'FriendManager');
      if (success) {
        await fetchRequests(); // Refresh the requests list
      }
      return success;
    } catch (e) {
      dev.log('Error in sendFriendRequest: $e', name: 'FriendManager', error: e);
      rethrow;
    }
  }

  /// Accept a friend request
  Future<bool> acceptRequest(int requestId) async {
    final success = await _api.acceptFriendRequest(requestId);
    if (success) {
      await fetchRequests();
      await fetchFriends();
    }
    return success;
  }

  /// Decline a friend request
  Future<bool> declineRequest(int requestId) async {
    final success = await _api.declineFriendRequest(requestId);
    if (success) await fetchRequests();
    return success;
  }

  /// Remove a friend
  Future<bool> removeFriend(int id) async {
    final success = await _api.removeFriend(id);
    if (success) {
      await fetchFriends();
    }
    return success;
  }

  /// Clear all data
  void clear() {
    _users = [];
    _onlineUserIds = [];
    _requests = [];
  }
}

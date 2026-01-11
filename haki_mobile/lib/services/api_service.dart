import 'dart:convert';
import 'dart:developer' as dev;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../models/message_model.dart';
import '../models/user_model.dart';

class ApiService {
  static String baseUrl = 'http://192.168.1.64:3000';
  final _storage = const FlutterSecureStorage();

  Future<String?> getToken() => _storage.read(key: 'token');
  Future<void> clearToken() => _storage.delete(key: 'token');

  Map<String, String> _headers(String? token) => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  // Auth
  Future<Map<String, dynamic>> login(String username, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _headers(null),
      body: jsonEncode({'username': username, 'password': password}),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 || res.statusCode == 201) {
      await _storage.write(key: 'token', value: data['access_token']);
    }
    return data;
  }

  Future<Map<String, dynamic>> register(String username, String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: _headers(null),
      body: jsonEncode({'username': username, 'email': email, 'password': password}),
    );
    return jsonDecode(res.body);
  }

  // Users
  Future<UserModel?> getMe() async {
    final token = await getToken();
    final res = await http.get(Uri.parse('$baseUrl/users/me'), headers: _headers(token));
    if (res.statusCode == 200) {
      return UserModel.fromJson(jsonDecode(res.body));
    }
    return null;
  }

  Future<List<UserModel>> getFriends() async {
    final token = await getToken();
    final res = await http.get(Uri.parse('$baseUrl/users/friends'), headers: _headers(token));
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((u) => UserModel.fromJson(u)).toList();
    }
    return [];
  }

  Future<bool> sendFriendRequest(String email) async {
    dev.log('Sending friend request to: $email', name: 'ApiService');
    final token = await getToken();
    final url = Uri.parse('$baseUrl/users/friends/requests');

    dev.log('Sending request to: $url', name: 'ApiService');
    dev.log(
      'Using token: ${token != null ? 'Token present' : 'No token found'}',
      name: 'ApiService',
    );

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode({'email': email}),
      );

      dev.log(
        'Friend request response: ${response.statusCode} - ${response.body}',
        name: 'ApiService',
        error: response.statusCode != 200 && response.statusCode != 201
            ? 'Unexpected status code'
            : null,
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e, stackTrace) {
      dev.log(
        'Error sending friend request: $e',
        name: 'ApiService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<List<dynamic>> getFriendRequests() async {
    dev.log('Fetching friend requests', name: 'ApiService');
    final token = await getToken();
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/users/friends/requests'),
        headers: _headers(token),
      );
      dev.log('Fetched ${jsonDecode(res.body).length} friend requests', name: 'ApiService');
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      return [];
    } catch (e) {
      dev.log('Error fetching friend requests: $e', name: 'ApiService', error: e);
      rethrow;
    }
  }

  Future<bool> acceptFriendRequest(int requestId) async {
    dev.log('Accepting friend request: $requestId', name: 'ApiService');
    final token = await getToken();
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/users/friends/requests/$requestId/accept'),
        headers: _headers(token),
      );
      dev.log('Accept request response: ${res.statusCode} - ${res.body}', name: 'ApiService');
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      dev.log('Error accepting friend request: $e', name: 'ApiService', error: e);
      rethrow;
    }
  }

  Future<bool> declineFriendRequest(int requestId) async {
    dev.log('Declining friend request: $requestId', name: 'ApiService');
    final token = await getToken();
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/users/friends/requests/$requestId/decline'),
        headers: _headers(token),
      );
      dev.log('Decline request response: ${res.statusCode} - ${res.body}', name: 'ApiService');
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      dev.log('Error declining friend request: $e', name: 'ApiService', error: e);
      rethrow;
    }
  }

  Future<bool> removeFriend(int friendId) async {
    final token = await getToken();
    final res = await http.post(
      Uri.parse('$baseUrl/users/friends/remove'),
      headers: _headers(token),
      body: jsonEncode({'friendId': friendId}),
    );
    return res.statusCode == 200 || res.statusCode == 201;
  }

  // Block/Unblock
  Future<bool> blockUser(int userId) async {
    final token = await getToken();
    final res = await http.post(
      Uri.parse('$baseUrl/users/block'),
      headers: _headers(token),
      body: jsonEncode({'userId': userId}),
    );
    return res.statusCode == 200 || res.statusCode == 201;
  }

  Future<bool> unblockUser(int userId) async {
    final token = await getToken();
    final res = await http.post(
      Uri.parse('$baseUrl/users/unblock'),
      headers: _headers(token),
      body: jsonEncode({'userId': userId}),
    );
    return res.statusCode == 200 || res.statusCode == 201;
  }

  Future<List<UserModel>> getBlockedUsers() async {
    final token = await getToken();
    final res = await http.get(Uri.parse('$baseUrl/users/blocked'), headers: _headers(token));
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((u) => UserModel.fromJson(u)).toList();
    }
    return [];
  }

  Future<UserModel?> updateProfile({String? displayName, String? bio, String? publicKey}) async {
    final token = await getToken();
    final res = await http.patch(
      Uri.parse('$baseUrl/users/profile'),
      headers: _headers(token),
      body: jsonEncode({
        if (displayName != null) 'displayName': displayName,
        if (bio != null) 'bio': bio,
        if (publicKey != null) 'publicKey': publicKey,
      }),
    );
    if (res.statusCode == 200) {
      return UserModel.fromJson(jsonDecode(res.body));
    }
    return null;
  }

  Future<UserModel?> updateStatus(String statusMessage) async {
    final token = await getToken();
    final res = await http.patch(
      Uri.parse('$baseUrl/users/status'),
      headers: _headers(token),
      body: jsonEncode({'statusMessage': statusMessage}),
    );
    if (res.statusCode == 200) {
      return UserModel.fromJson(jsonDecode(res.body));
    }
    return null;
  }

  Future<String?> uploadAvatar(String filePath) async {
    final token = await getToken();
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/users/avatar'));
    request.headers.addAll(_headers(token));
    request.files.add(await http.MultipartFile.fromPath('file', filePath));

    var res = await request.send();
    if (res.statusCode == 201 || res.statusCode == 200) {
      var responseData = await res.stream.bytesToString();
      return jsonDecode(responseData)['avatarUrl'];
    }
    return null;
  }

  Future<String?> uploadAttachment(String filePath) async {
    final token = await getToken();
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/users/upload'));
    request.headers.addAll(_headers(token));
    request.files.add(await http.MultipartFile.fromPath('file', filePath));

    var res = await request.send();
    if (res.statusCode == 201 || res.statusCode == 200) {
      var responseData = await res.stream.bytesToString();
      return jsonDecode(responseData)['attachmentUrl'];
    }
    return null;
  }

  // Stories
  Future<List<dynamic>> getActiveStories() async {
    final token = await getToken();
    final res = await http.get(Uri.parse('$baseUrl/stories/active'), headers: _headers(token));
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    return [];
  }

  Future<Map<String, dynamic>?> uploadStory(String filePath, {String type = 'image'}) async {
    final token = await getToken();
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/stories'));
    request.headers.addAll(_headers(token));
    request.fields['type'] = type;
    request.files.add(await http.MultipartFile.fromPath('file', filePath));

    var res = await request.send();
    if (res.statusCode == 201 || res.statusCode == 200) {
      var responseData = await res.stream.bytesToString();
      return jsonDecode(responseData);
    }
    return null;
  }

  // Shared Media
  Future<List<MessageModel>> getSharedMedia(int recipientId) async {
    final token = await getToken();
    final res = await http.get(
      Uri.parse('$baseUrl/messages/shared-media/$recipientId'),
      headers: _headers(token),
    );
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((m) => MessageModel.fromJson(m)).toList();
    }
    return [];
  }
}

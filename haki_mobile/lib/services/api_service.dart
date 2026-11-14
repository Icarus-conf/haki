import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:http/http.dart' as http;

import '../core/utils/platform.dart';
import '../models/group_model.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import 'secure_storage.dart';

class ApiService {
  /// Set per build: `flutter run --dart-define=API_URL=http://192.168.1.6:3000` for a real phone.
  /// The default reaches the Docker stack from the iOS simulator / desktop.
  static const String baseUrl = String.fromEnvironment('API_URL', defaultValue: 'http://localhost:3000');
  final _storage = secureStorage;

  Future<String?> getToken() => _storage.read(key: 'token');
  Future<void> saveToken(String token) => _storage.write(key: 'token', value: token);

  /// How this device appears in Devices on your other phones.
  static String get deviceName => Device.name;
  static String get platform => Device.id;
  Future<void> clearToken() => _storage.delete(key: 'token');

  /// A picked file for upload. On the web the "path" is a blob: URL, so read it as bytes.
  static Future<http.MultipartFile> _filePart(String path) async => kIsWeb
      ? http.MultipartFile.fromBytes('file', await XFile(path).readAsBytes(), filename: 'upload')
      : http.MultipartFile.fromPath('file', path);

  Map<String, String> _headers(String? token) => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  // Auth
  /// With two-step login on, the first try answers `twoFactor: true`; send [code] the second time.
  Future<Map<String, dynamic>> login(String username, String password, {String? code}) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _headers(null),
      body: jsonEncode({
        'username': username,
        'password': password,
        'code': ?code,
        'deviceName': deviceName,
        'platform': platform,
      }),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 || res.statusCode == 201) {
      await _storage.write(key: 'token', value: data['access_token']);
    }
    return data;
  }

  Future<Map<String, dynamic>> register(
    String username,
    String email,
    String password, {
    String? inviteCode,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: _headers(null),
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
        'inviteCode': ?inviteCode,
      }),
    );
    return jsonDecode(res.body);
  }

  /// 'open', 'invite' (a code is needed) or 'closed'.
  Future<String> signupMode() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/auth/signup'));
      return (jsonDecode(res.body)['mode'] ?? 'open').toString();
    } catch (_) {
      return 'open';
    }
  }

  // ===== Devices, two-step login, linking =====
  Future<dynamic> _send(String method, String path, [Map<String, dynamic>? body]) async {
    final req = http.Request(method, Uri.parse('$baseUrl$path'))..headers.addAll(_headers(await getToken()));
    if (body != null) req.body = jsonEncode(body);
    final res = await http.Response.fromStream(await req.send());
    if (res.statusCode >= 300) throw ApiError(_errorOf(res, 'Something went wrong'));
    return res.body.isEmpty ? null : jsonDecode(res.body);
  }

  Future<List<Map<String, dynamic>>> sessions() async =>
      [for (final s in await _send('GET', '/auth/sessions') as List) Map<String, dynamic>.from(s)];
  Future<void> removeSession(String id) => _send('DELETE', '/auth/sessions/$id');

  Future<bool> twoStepEnabled() async => (await _send('GET', '/auth/2fa'))['enabled'] == true;
  Future<Map<String, dynamic>> twoStepSetup() async => Map<String, dynamic>.from(await _send('POST', '/auth/2fa/setup'));
  Future<void> twoStepEnable(String code) => _send('POST', '/auth/2fa/enable', {'code': code});
  Future<void> twoStepDisable(String code) => _send('POST', '/auth/2fa/disable', {'code': code});

  /// New device: ask for a link code. Public; [pub] is this device's one-time key.
  Future<Map<String, dynamic>> linkStart(String pub) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/link'),
      headers: _headers(null),
      body: jsonEncode({'pub': pub, 'name': Device.ios ? 'iPad or iPhone' : deviceName, 'platform': platform}),
    );
    if (res.statusCode >= 300) throw ApiError(_errorOf(res, 'Couldn’t start linking'));
    return Map<String, dynamic>.from(jsonDecode(res.body));
  }

  Future<Map<String, dynamic>> linkPoll(String code, String secret) async {
    final res = await http.get(Uri.parse('$baseUrl/auth/link/$code?secret=$secret'));
    if (res.statusCode >= 300) throw ApiError(_errorOf(res, 'This code expired'));
    return Map<String, dynamic>.from(jsonDecode(res.body));
  }

  Future<Map<String, dynamic>> linkPeek(String code) async =>
      Map<String, dynamic>.from(await _send('GET', '/auth/link/${Uri.encodeComponent(code)}/peek'));
  Future<void> linkApprove(String code, String sealed, String pub) =>
      _send('POST', '/auth/link/${Uri.encodeComponent(code)}/approve', {'sealed': sealed, 'pub': pub});

  /// Sealed app-data backup (notes, locks, checked keys). The server can't read it.
  Future<String?> getBackup() async {
    try {
      return (await _send('GET', '/users/me/backup'))['sealed'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<void> putBackup(String sealed) => _send('PUT', '/users/me/backup', {'sealed': sealed});

  // Users
  Future<UserModel?> getMe() async {
    final token = await getToken();
    final res = await http.get(
      Uri.parse('$baseUrl/users/me'),
      headers: _headers(token),
    );
    if (res.statusCode == 200) {
      return UserModel.fromJson(jsonDecode(res.body));
    }
    return null;
  }

  Future<List<UserModel>> getFriends() async {
    final token = await getToken();
    final res = await http.get(
      Uri.parse('$baseUrl/users/friends'),
      headers: _headers(token),
    );
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((u) => UserModel.fromJson(u)).toList();
    }
    return [];
  }

  /// [identifier] is an email or a username (from a scanned Haki code).
  /// Returns null on success, otherwise the server's error message.
  Future<String?> sendFriendRequest(String identifier) async {
    final token = await getToken();
    final res = await http.post(
      Uri.parse('$baseUrl/users/friends/requests'),
      headers: _headers(token),
      body: jsonEncode(identifier.contains('@') ? {'email': identifier} : {'username': identifier}),
    );
    if (res.statusCode == 200 || res.statusCode == 201) return null;
    try {
      return (jsonDecode(res.body)['message'] ?? 'Could not send request').toString();
    } catch (_) {
      return 'Could not send request';
    }
  }

  static String _errorOf(http.Response res, String fallback) {
    try {
      final m = jsonDecode(res.body)['message'];
      return (m is List ? m.join(', ') : m ?? fallback).toString();
    } catch (_) {
      return fallback;
    }
  }

  /// Sets my username. Only a keyed hash reaches the server's lookup; [sealed] is the name
  /// encrypted to my own key so my other phones can show it.
  Future<String?> setHandle(String handle, String sealed) async {
    final res = await http.put(
      Uri.parse('$baseUrl/users/me/handle'),
      headers: _headers(await getToken()),
      body: jsonEncode({'handle': handle, 'sealed': sealed}),
    );
    return res.statusCode == 200 ? null : _errorOf(res, 'Couldn’t save the username');
  }

  Future<bool> clearHandle() async {
    final res = await http.delete(Uri.parse('$baseUrl/users/me/handle'), headers: _headers(await getToken()));
    return res.statusCode == 200;
  }

  Future<String?> reportMessage({required int messageId, required String reason, String? note, String? content}) async {
    final res = await http.post(
      Uri.parse('$baseUrl/reports'),
      headers: _headers(await getToken()),
      body: jsonEncode({'messageId': messageId, 'reason': reason, 'note': ?note, 'content': ?content}),
    );
    return res.statusCode == 201 || res.statusCode == 200 ? null : _errorOf(res, 'Couldn’t send the report');
  }

  Future<List<dynamic>> getFriendRequests() async {
    dev.log('Fetching friend requests', name: 'ApiService');
    final token = await getToken();
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/users/friends/requests'),
        headers: _headers(token),
      );
      dev.log(
        'Fetched ${jsonDecode(res.body).length} friend requests',
        name: 'ApiService',
      );
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      return [];
    } catch (e) {
      dev.log(
        'Error fetching friend requests: $e',
        name: 'ApiService',
        error: e,
      );
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
      dev.log(
        'Accept request response: ${res.statusCode} - ${res.body}',
        name: 'ApiService',
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      dev.log(
        'Error accepting friend request: $e',
        name: 'ApiService',
        error: e,
      );
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
      dev.log(
        'Decline request response: ${res.statusCode} - ${res.body}',
        name: 'ApiService',
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      dev.log(
        'Error declining friend request: $e',
        name: 'ApiService',
        error: e,
      );
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
    final res = await http.get(
      Uri.parse('$baseUrl/users/blocked'),
      headers: _headers(token),
    );
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((u) => UserModel.fromJson(u)).toList();
    }
    return [];
  }

  Future<UserModel?> updateProfile({
    String? displayName,
    String? bio,
    String? publicKey,
    String? birthday, // 'MM-DD', or '' to remove it
  }) async {
    final token = await getToken();
    final res = await http.patch(
      Uri.parse('$baseUrl/users/profile'),
      headers: _headers(token),
      body: jsonEncode({
        if (displayName != null) 'displayName': displayName,
        if (bio != null) 'bio': bio,
        if (publicKey != null) 'publicKey': publicKey,
        if (birthday != null) 'birthday': birthday.isEmpty ? null : birthday,
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
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/users/avatar'),
    );
    request.headers.addAll(_headers(token));
    request.files.add(await _filePart(filePath));

    var res = await request.send();
    if (res.statusCode == 201 || res.statusCode == 200) {
      var responseData = await res.stream.bytesToString();
      return jsonDecode(responseData)['avatarUrl'];
    }
    return null;
  }

  Future<String?> uploadAttachment(String filePath) async =>
      uploadBytes(await XFile(filePath).readAsBytes(), filePath.split('/').last);

  Future<String?> uploadBytes(Uint8List bytes, String name) async {
    final token = await getToken();
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/users/upload'),
    );
    request.headers.addAll(_headers(token));
    request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: name));

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
    final res = await http.get(
      Uri.parse('$baseUrl/stories/active'),
      headers: _headers(token),
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    return [];
  }

  Future<Map<String, dynamic>?> uploadStory(
    String filePath, {
    String type = 'image',
  }) async {
    final token = await getToken();
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/stories'));
    request.headers.addAll(_headers(token));
    request.fields['type'] = type;
    request.files.add(await _filePart(filePath));

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

  // Groups
  Future<List<GroupModel>> getGroups() async {
    final res = await http.get(Uri.parse('$baseUrl/groups'), headers: _headers(await getToken()));
    if (res.statusCode != 200) return [];
    return [for (final g in jsonDecode(res.body) as List) GroupModel.fromJson(Map<String, dynamic>.from(g))];
  }

  /// Returns the group, or an error message from the server.
  Future<(GroupModel?, String?)> createGroup(String name, List<int> memberIds) =>
      _groupCall(() async => http.post(
        Uri.parse('$baseUrl/groups'),
        headers: _headers(await getToken()),
        body: jsonEncode({'name': name, 'memberIds': memberIds}),
      ));

  Future<(GroupModel?, String?)> addGroupMembers(int groupId, List<int> memberIds) =>
      _groupCall(() async => http.post(
        Uri.parse('$baseUrl/groups/$groupId/members'),
        headers: _headers(await getToken()),
        body: jsonEncode({'memberIds': memberIds}),
      ));

  Future<bool> leaveGroup(int groupId) async {
    final res = await http.delete(Uri.parse('$baseUrl/groups/$groupId/members/me'), headers: _headers(await getToken()));
    return res.statusCode == 200;
  }

  Future<(GroupModel?, String?)> _groupCall(Future<http.Response> Function() call) async {
    try {
      final res = await call();
      final body = jsonDecode(res.body);
      if (res.statusCode == 200 || res.statusCode == 201) return (GroupModel.fromJson(body), null);
      final msg = body['message'];
      return (null, (msg is List ? msg.join(', ') : msg ?? 'Something went wrong').toString());
    } catch (_) {
      return (null, 'Can’t reach the server');
    }
  }

  // Story views and loves
  Future<void> markStorySeen(int storyId) async {
    await http.post(Uri.parse('$baseUrl/stories/$storyId/view'), headers: _headers(await getToken()));
  }

  Future<bool> likeStory(int storyId, bool liked) async {
    final res = await http.post(
      Uri.parse('$baseUrl/stories/$storyId/like'),
      headers: _headers(await getToken()),
      body: jsonEncode({'liked': liked}),
    );
    return res.statusCode == 200 || res.statusCode == 201;
  }

  /// Owner only: who saw the story and who loved it.
  Future<List<({UserModel user, bool liked})>> storyViewers(int storyId) async {
    final res = await http.get(Uri.parse('$baseUrl/stories/$storyId/viewers'), headers: _headers(await getToken()));
    if (res.statusCode != 200) return [];
    return [
      for (final v in jsonDecode(res.body) as List)
        (user: UserModel.fromJson(Map<String, dynamic>.from(v['user'])), liked: v['liked'] == true),
    ];
  }

  // Push notifications
  /// [platform]: 'ios' (alerts), 'voip' (CallKit ringing) or 'android' (FCM).
  Future<void> registerPushToken(String token, {String platform = 'ios'}) async {
    await http.post(
      Uri.parse('$baseUrl/push/devices'),
      headers: _headers(await getToken()),
      body: jsonEncode({'token': token, 'platform': platform}),
    );
  }

  Future<void> unregisterPushToken(String token) async {
    await http.post(
      Uri.parse('$baseUrl/push/devices/remove'),
      headers: _headers(await getToken()),
      body: jsonEncode({'token': token}),
    );
  }
}

class ApiError implements Exception {
  ApiError(this.message);
  final String message;
  @override
  String toString() => message;
}

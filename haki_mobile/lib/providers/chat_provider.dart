import 'package:flutter/material.dart';

import '../models/friend_request_model.dart';
import '../models/message_model.dart';
import '../models/story_model.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/chat_service.dart';
import '../services/crypto_service.dart';
import '../services/webrtc_service.dart';
import 'auth_manager.dart';
import 'call_manager.dart';
import 'friend_manager.dart';
import 'message_manager.dart';
import 'story_manager.dart';
import 'ui_state_manager.dart';

/// Main provider that orchestrates all sub-managers
/// This is the single point of access for the UI layer
class ChatProvider extends ChangeNotifier {
  // Services
  final ApiService _api = ApiService();
  final ChatService _chat = ChatService();
  final CryptoService _crypto = CryptoService();
  late final WebRTCService _webrtc;

  // Managers
  late final AuthManager _authManager;
  late final MessageManager _messageManager;
  late final FriendManager _friendManager;
  late final CallManager _callManager;
  late final StoryManager _storyManager;
  late final UIStateManager _uiStateManager;

  ChatProvider() {
    _webrtc = WebRTCService(_chat);

    // Initialize managers
    _authManager = AuthManager(api: _api, chat: _chat, crypto: _crypto);
    _messageManager = MessageManager(
      api: _api,
      chat: _chat,
      crypto: _crypto,
      getMeCallback: () => _authManager.me,
    );
    _friendManager = FriendManager(api: _api, chat: _chat);
    _callManager = CallManager(chat: _chat, webrtc: _webrtc);
    _storyManager = StoryManager(api: _api);
    _uiStateManager = UIStateManager();

    // Listen to manager changes and propagate to UI
    _authManager.addListener(_onManagerChanged);
    _messageManager.addListener(_onManagerChanged);
    _friendManager.addListener(_onManagerChanged);
    _callManager.addListener(_onManagerChanged);
    _storyManager.addListener(_onManagerChanged);
    _uiStateManager.addListener(_onManagerChanged);
  }

  void _onManagerChanged() {
    notifyListeners();
  }

  // ============================================================================
  // AUTH MANAGER DELEGATES
  // ============================================================================

  UserModel? get me => _authManager.me;
  bool get isAppInitialized => _authManager.isAppInitialized;
  bool get isLoading => _authManager.isLoading || _storyManager.isLoading;
  bool get hasViewedRecoveryPhrase => _authManager.hasViewedRecoveryPhrase;
  bool get needsOnboarding => _authManager.needsOnboarding;
  String? get currentMnemonic => _authManager.currentMnemonic;
  ApiService get api => _api;
  CryptoService get crypto => _crypto;
  ChatService get chat => _chat;

  void setNeedsOnboarding(bool value) => _authManager.setNeedsOnboarding(value);
  void setCurrentMnemonic(String? mnemonic) => _authManager.setCurrentMnemonic(mnemonic);

  Future<bool> login(
    String username,
    String password, {
    String? mnemonic,
    bool isRegistration = false,
  }) async {
    // CRITICAL: Setup listeners BEFORE login/connection
    // so they're ready when socket connects
    _setupAllListeners();

    final success = await _authManager.login(
      username,
      password,
      mnemonic: mnemonic,
      isRegistration: isRegistration,
    );

    if (success) {
      await _fetchInitialData();
    }

    return success;
  }

  Future<bool> tryAutoLogin() async {
    // CRITICAL: Setup listeners BEFORE auto-login/connection
    // so they're ready when socket connects
    _setupAllListeners();

    final success = await _authManager.tryAutoLogin();
    if (success) {
      await _callManager.init();
      await _fetchInitialData();
    }
    return success;
  }

  Future<bool> updateProfile({String? displayName, String? bio}) =>
      _authManager.updateProfile(displayName: displayName, bio: bio);

  Future<String?> uploadAvatar(String filePath) => _authManager.uploadAvatar(filePath);

  Future<void> logout() async {
    await _authManager.logout();
    _messageManager.clear();
    _friendManager.clear();
    _callManager.clear();
    _storyManager.clear();
    _uiStateManager.clear();
  }

  // ============================================================================
  // MESSAGE MANAGER DELEGATES
  // ============================================================================

  List<MessageModel> get messages => _messageManager.messages;
  bool get isHistoryLoading => _messageManager.isHistoryLoading;
  bool get isRecipientTyping => _messageManager.isRecipientTyping;

  UserModel? get activeRecipient {
    final recipient = _messageManager.activeRecipient;
    if (recipient == null) return null;
    // Try to get updated user data from friend manager
    return _friendManager.getUserById(recipient.id) ?? recipient;
  }

  void selectRecipient(UserModel? user) => _messageManager.selectRecipient(user);
  void sendTypingNotification(bool isTyping) => _messageManager.sendTypingNotification(isTyping);

  Future<void> sendMessage(
    String text, {
    String? attachmentPath,
    int? replyToMessageId,
    String? replyToSender,
    String? replyToMessage,
  }) => _messageManager.sendMessage(
    text,
    attachmentPath: attachmentPath,
    replyToMessageId: replyToMessageId,
    replyToSender: replyToSender,
    replyToMessage: replyToMessage,
  );

  void deleteMessageLocally(MessageModel message) => _messageManager.deleteMessageLocally(message);

  void undoDelete(MessageModel message) => _messageManager.undoDelete(message);

  Future<String?> uploadAttachment(String filePath) => _messageManager.uploadAttachment(filePath);

  // ============================================================================
  // FRIEND MANAGER DELEGATES
  // ============================================================================

  List<UserModel> get users => _friendManager.users;
  List<int> get onlineUserIds => _friendManager.onlineUserIds;
  List<FriendRequestModel> get requests => _friendManager.requests;

  Future<void> fetchFriends() => _friendManager.fetchFriends();
  Future<void> fetchRequests() => _friendManager.fetchRequests();

  Future<bool> sendFriendRequest(String email) => _friendManager.sendFriendRequest(email);

  Future<bool> acceptRequest(int requestId) => _friendManager.acceptRequest(requestId);

  Future<bool> declineRequest(int requestId) => _friendManager.declineRequest(requestId);

  Future<bool> removeFriend(int id) async {
    final success = await _friendManager.removeFriend(id);
    if (success && activeRecipient?.id == id) {
      selectRecipient(null); // Back to global
    }
    return success;
  }

  // ============================================================================
  // CALL MANAGER DELEGATES
  // ============================================================================

  bool get isCallIncoming => _callManager.isCallIncoming;
  int? get incomingCallUserId => _callManager.incomingCallUserId;
  dynamic get incomingCallOffer => _callManager.incomingCallOffer;
  String get callStatus => _callManager.callStatus;
  bool get isSpeakerOn => _callManager.isSpeakerOn;

  Future<void> startCall(int userId) => _callManager.startCall(userId);
  Future<void> acceptCall() => _callManager.acceptCall();
  void declineCall() => _callManager.declineCall();
  void endCall() => _callManager.endCall(activeRecipient?.id);
  void toggleSpeaker() => _callManager.toggleSpeaker();

  // ============================================================================
  // STORY MANAGER DELEGATES
  // ============================================================================

  List<StoryModel> get stories => _storyManager.stories;

  Future<void> fetchStories() => _storyManager.fetchStories();
  Future<bool> postStory(String filePath) => _storyManager.postStory(filePath);

  // ============================================================================
  // UI STATE MANAGER DELEGATES
  // ============================================================================

  ThemeMode get themeMode => _uiStateManager.themeMode;
  bool get isDarkMode => _uiStateManager.isDarkMode;
  String get searchQuery => _uiStateManager.searchQuery;
  String? get chatWallpaper => _uiStateManager.chatWallpaper;
  List<int> get pinnedUserIds => _uiStateManager.pinnedUserIds;

  void toggleTheme() => _uiStateManager.toggleTheme();
  void togglePinUser(int userId) => _uiStateManager.togglePinUser(userId);
  void updateSearchQuery(String query) => _uiStateManager.updateSearchQuery(query);
  void updateChatWallpaper(String? path) => _uiStateManager.updateChatWallpaper(path);

  List<UserModel> get filteredUsers => _uiStateManager.getFilteredUsers(users);

  // ============================================================================
  // PRIVATE HELPER METHODS
  // ============================================================================

  Future<void> _setupAllListeners() async {
    _messageManager.setupListeners();
    _friendManager.setupListeners();
    _callManager.setupListeners(() => activeRecipient?.id);
  }

  Future<void> _fetchInitialData() async {
    await Future.wait([
      _friendManager.fetchFriends(),
      _friendManager.fetchRequests(),
      _storyManager.fetchStories(),
    ]);
  }

  Future<void> refreshData() async {
    await _fetchInitialData();
  }

  // ============================================================================
  // LIFECYCLE
  // ============================================================================

  @override
  void dispose() {
    _authManager.removeListener(_onManagerChanged);
    _messageManager.removeListener(_onManagerChanged);
    _friendManager.removeListener(_onManagerChanged);
    _callManager.removeListener(_onManagerChanged);
    _storyManager.removeListener(_onManagerChanged);
    _uiStateManager.removeListener(_onManagerChanged);

    _authManager.dispose();
    _messageManager.dispose();
    _friendManager.dispose();
    _callManager.dispose();
    _storyManager.dispose();
    _uiStateManager.dispose();

    _chat.dispose();
    super.dispose();
  }
}

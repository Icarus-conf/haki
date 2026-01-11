# ChatProvider Quick Reference Guide

## 📋 Table of Contents

- [Authentication](#authentication)
- [Messaging](#messaging)
- [Friends](#friends)
- [Calls](#calls)
- [Stories](#stories)
- [UI State](#ui-state)

---

## 🔐 Authentication

### Login

```dart
final success = await provider.login(
  username,
  password,
  mnemonic: optionalMnemonic,  // For account recovery
  isRegistration: false,
);
```

### Auto-Login

```dart
final success = await provider.tryAutoLogin();
```

### Update Profile

```dart
await provider.updateProfile(
  displayName: 'John Doe',
  bio: 'Flutter Developer',
);
```

### Upload Avatar

```dart
final avatarUrl = await provider.uploadAvatar(filePath);
```

### Logout

```dart
await provider.logout();
```

### Get Current User

```dart
final user = provider.me;
final username = provider.me?.username;
```

---

## 💬 Messaging

### Select Chat Recipient

```dart
// Private chat
provider.selectRecipient(user);

// Global chat
provider.selectRecipient(null);
```

### Send Message

```dart
// Text only
await provider.sendMessage('Hello!');

// With attachment
await provider.sendMessage(
  'Check this out!',
  attachmentPath: '/path/to/image.jpg',
);
```

### Delete Message (with undo)

```dart
// Delete (5 second undo window)
provider.deleteMessageLocally(message);

// Undo deletion
provider.undoDelete(message);
```

### Typing Indicator

```dart
// Start typing
provider.sendTypingNotification(true);

// Stop typing
provider.sendTypingNotification(false);

// Check if recipient is typing
if (provider.isRecipientTyping) {
  // Show typing indicator
}
```

### Get Messages

```dart
final messages = provider.messages;
final isLoading = provider.isHistoryLoading;
```

---

## 👥 Friends

### Fetch Friends

```dart
await provider.fetchFriends();
final friends = provider.users;
```

### Send Friend Request

```dart
final success = await provider.sendFriendRequest('friend@example.com');
```

### Manage Friend Requests

```dart
// Fetch requests
await provider.fetchRequests();
final requests = provider.requests;

// Accept request
await provider.acceptRequest(requestId);

// Decline request
await provider.declineRequest(requestId);
```

### Remove Friend

```dart
await provider.removeFriend(userId);
```

### Online Status

```dart
final onlineIds = provider.onlineUserIds;
final isOnline = onlineIds.contains(userId);
```

---

## 📞 Calls

### Start Call

```dart
await provider.startCall(userId);
```

### Handle Incoming Call

```dart
if (provider.isCallIncoming) {
  final callerId = provider.incomingCallUserId;
  
  // Accept
  await provider.acceptCall();
  
  // Or decline
  provider.declineCall();
}
```

### End Call

```dart
provider.endCall();
```

### Toggle Speaker

```dart
provider.toggleSpeaker();
final isSpeakerOn = provider.isSpeakerOn;
```

### Call Status

```dart
final status = provider.callStatus;
// Possible values: 'Idle', 'Dialing...', 'Incoming Call...', 
//                  'Connecting...', 'Connected', 'Failed', 
//                  'Disconnected', 'Ended'
```

---

## 📸 Stories

### Fetch Stories

```dart
await provider.fetchStories();
final stories = provider.stories;
```

### Post Story

```dart
final success = await provider.postStory(imagePath);
```

---

## 🎨 UI State

### Theme Management

```dart
// Toggle theme
provider.toggleTheme();

// Check current theme
final isDark = provider.isDarkMode;
final themeMode = provider.themeMode;
```

### Search

```dart
// Update search query
provider.updateSearchQuery('John');

// Get filtered users
final filteredUsers = provider.filteredUsers;
```

### Pin Users

```dart
// Toggle pin
provider.togglePinUser(userId);

// Get pinned users
final pinnedIds = provider.pinnedUserIds;
```

### Chat Wallpaper

```dart
provider.updateChatWallpaper('/path/to/wallpaper.jpg');
final wallpaper = provider.chatWallpaper;
```

---

## 🔄 Common Patterns

### Refresh All Data

```dart
await provider.refreshData();
// Fetches friends, requests, and stories
```

### Check Loading State

```dart
if (provider.isLoading) {
  // Show loading indicator
}
```

### Listen to Changes

```dart
// Using Provider package
Consumer<ChatProvider>(
  builder: (context, provider, child) {
    return Text(provider.me?.username ?? 'Guest');
  },
)

// Or with context
final provider = Provider.of<ChatProvider>(context);
```

---

## 🏗️ Manager Architecture

If you need to extend functionality, here's which manager to modify:

| Feature | Manager | File |
|---------|---------|------|
| Login, Profile, Keys | `AuthManager` | `auth_manager.dart` |
| Messages, Chat History | `MessageManager` | `message_manager.dart` |
| Friends, Requests | `FriendManager` | `friend_manager.dart` |
| Voice/Video Calls | `CallManager` | `call_manager.dart` |
| Stories | `StoryManager` | `story_manager.dart` |
| Theme, Search, UI | `UIStateManager` | `ui_state_manager.dart` |

---

## 🐛 Debugging Tips

### Enable Logging

Each manager uses `dart:developer` logging:

```dart
import 'dart:developer' as dev;

// Logs are tagged by manager name
// Filter in console: "AuthManager", "MessageManager", etc.
```

### Common Issues

**Messages not appearing?**

- Check `provider.isHistoryLoading`
- Verify `provider.activeRecipient` is set correctly
- Check encryption keys are synced

**Friend request not working?**

- Verify email is correct
- Check network connection
- Review `FriendManager` logs

**Call not connecting?**

- Check WebRTC permissions
- Verify both users are online
- Review `CallManager` logs

---

## 📚 Additional Resources

- See `REFACTORING_SUMMARY.md` for architecture details
- Each manager file has inline documentation
- Check service layer for low-level API details

---

**Last Updated:** 2026-01-10
**Version:** 2.0 (Refactored Architecture)

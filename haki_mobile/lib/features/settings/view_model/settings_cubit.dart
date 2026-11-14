import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../services/secure_storage.dart';

part 'settings_cubit.freezed.dart';

/// A user-made chat folder. Chats are keyed `u:friendId` or `g:groupId`.
/// Kept on this phone only: the server never learns how you organise your chats.
class ChatFolder {
  const ChatFolder({required this.name, this.chats = const {}});
  final String name;
  final Set<String> chats;

  static String userKey(int id) => 'u:$id';
  static String groupKey(int id) => 'g:$id';

  Map<String, dynamic> toJson() => {'name': name, 'chats': chats.toList()};
  factory ChatFolder.fromJson(Map<String, dynamic> j) =>
      ChatFolder(name: j['name'] as String, chats: {for (final c in j['chats'] as List? ?? const []) '$c'});
}

@freezed
abstract class SettingsState with _$SettingsState {
  const factory SettingsState({
    @Default({}) Set<int> pinnedIds,
    @Default([]) List<ChatFolder> folders,

    /// Chats (ChatFolder keys) that need Face ID / passcode to open. Hidden from the list.
    @Default({}) Set<String> lockedChats,

    /// Private notes about contacts (friend id -> text). Only on your phones and in your sealed backup.
    @Default({}) Map<int, String> notes,

    /// Each friend's key as first seen (friend id -> fingerprint). A different key later is a warning.
    @Default({}) Map<int, String> keyPins,

    /// Friends whose key changed since it was pinned, until you look at the new safety number.
    @Default({}) Set<int> keyChanged,
  }) = _SettingsState;
}

/// Device-local preferences. Pinned chats and folders survive restarts.
class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit({FlutterSecureStorage storage = secureStorage})
    : _storage = storage,
      super(const SettingsState());

  final FlutterSecureStorage _storage;
  static const _pinnedKey = 'pinned_ids';
  static const _foldersKey = 'chat_folders';
  static const _lockedKey = 'locked_chats';
  static const _extraKey = 'settings_extra'; // notes, key pins, key-changed flags

  /// Called after every change, so the sealed backup can be refreshed.
  void Function()? onChanged;

  Future<void> load() async {
    final pinned = await _storage.read(key: _pinnedKey);
    final folders = await _storage.read(key: _foldersKey);
    final locked = await _storage.read(key: _lockedKey);
    final extra = await _storage.read(key: _extraKey);
    if (extra != null) _applyExtra(jsonDecode(extra) as Map<String, dynamic>);
    emit(state.copyWith(
      lockedChats: locked == null ? state.lockedChats : {for (final c in jsonDecode(locked) as List) '$c'},
      pinnedIds: pinned == null ? state.pinnedIds : (jsonDecode(pinned) as List).cast<int>().toSet(),
      folders: folders == null
          ? state.folders
          : [for (final f in jsonDecode(folders) as List) ChatFolder.fromJson(Map<String, dynamic>.from(f))],
    ));
  }

  Future<void> togglePin(int userId) async {
    final ids = {...state.pinnedIds};
    ids.contains(userId) ? ids.remove(userId) : ids.add(userId);
    emit(state.copyWith(pinnedIds: ids));
    await _storage.write(key: _pinnedKey, value: jsonEncode(ids.toList()));
    onChanged?.call();
  }

  /// Creates [name] (if new) holding [chat], or toggles [chat] in an existing folder.
  Future<void> toggleInFolder(String name, String chat) async {
    final folders = [...state.folders];
    final i = folders.indexWhere((f) => f.name == name);
    if (i == -1) {
      folders.add(ChatFolder(name: name, chats: {chat}));
    } else {
      final chats = {...folders[i].chats};
      chats.contains(chat) ? chats.remove(chat) : chats.add(chat);
      folders[i] = ChatFolder(name: name, chats: chats);
    }
    await _saveFolders(folders);
  }

  Future<void> toggleLock(String chat) async {
    final locked = {...state.lockedChats};
    locked.contains(chat) ? locked.remove(chat) : locked.add(chat);
    emit(state.copyWith(lockedChats: locked));
    await _storage.write(key: _lockedKey, value: jsonEncode(locked.toList()));
    onChanged?.call();
  }

  Future<void> setNote(int friendId, String text) async {
    final notes = {...state.notes};
    text.trim().isEmpty ? notes.remove(friendId) : notes[friendId] = text.trim();
    emit(state.copyWith(notes: notes));
    await _saveExtra();
  }

  /// Trust on first use: remembers a friend's key fingerprint, and flags it when it later differs.
  /// Returns true when the key changed from the pinned one.
  Future<bool> checkKey(int friendId, String fingerprint) async {
    final pinned = state.keyPins[friendId];
    if (pinned == fingerprint) return false;
    final changed = pinned != null;
    emit(state.copyWith(
      keyPins: {...state.keyPins, friendId: fingerprint},
      keyChanged: changed ? {...state.keyChanged, friendId} : state.keyChanged,
    ));
    await _saveExtra();
    return changed;
  }

  /// The user looked at the new safety number.
  Future<void> acknowledgeKey(int friendId) async {
    if (!state.keyChanged.contains(friendId)) return;
    emit(state.copyWith(keyChanged: {...state.keyChanged}..remove(friendId)));
    await _saveExtra();
  }

  void _applyExtra(Map<String, dynamic> j) {
    Map<int, String> ints(dynamic m) => {for (final e in (m as Map? ?? {}).entries) int.parse('${e.key}'): '${e.value}'};
    emit(state.copyWith(
      notes: ints(j['notes']),
      keyPins: ints(j['keyPins']),
      keyChanged: {for (final i in j['keyChanged'] as List? ?? const []) i as int},
    ));
  }

  Future<void> _saveExtra() async {
    await _storage.write(key: _extraKey, value: jsonEncode(_extraJson()));
    onChanged?.call();
  }

  Map<String, dynamic> _extraJson() => {
    'notes': {for (final e in state.notes.entries) '${e.key}': e.value},
    'keyPins': {for (final e in state.keyPins.entries) '${e.key}': e.value},
    'keyChanged': state.keyChanged.toList(),
  };

  /// Everything worth keeping when you move phones, as JSON (sealed to your key before upload).
  Map<String, dynamic> exportBackup() => {
    'v': 1,
    'pinned': state.pinnedIds.toList(),
    'folders': [for (final f in state.folders) f.toJson()],
    'locked': state.lockedChats.toList(),
    ..._extraJson(),
  };

  /// Merges a backup into this phone. What's already here wins, so nothing local is lost.
  Future<void> importBackup(Map<String, dynamic> b) async {
    final mine = exportBackup();
    _applyExtra({
      'notes': {...(b['notes'] as Map? ?? {}), ...mine['notes'] as Map},
      'keyPins': {...(b['keyPins'] as Map? ?? {}), ...mine['keyPins'] as Map},
      'keyChanged': {...(b['keyChanged'] as List? ?? const []), ...mine['keyChanged'] as List}.toList(),
    });
    final folders = [...state.folders];
    for (final f in b['folders'] as List? ?? const []) {
      final folder = ChatFolder.fromJson(Map<String, dynamic>.from(f));
      if (!folders.any((x) => x.name == folder.name)) folders.add(folder);
    }
    emit(state.copyWith(
      pinnedIds: {...state.pinnedIds, for (final i in b['pinned'] as List? ?? const []) i as int},
      lockedChats: {...state.lockedChats, for (final c in b['locked'] as List? ?? const []) '$c'},
      folders: folders,
    ));
    await _storage.write(key: _pinnedKey, value: jsonEncode(state.pinnedIds.toList()));
    await _storage.write(key: _lockedKey, value: jsonEncode(state.lockedChats.toList()));
    await _storage.write(key: _foldersKey, value: jsonEncode([for (final f in state.folders) f.toJson()]));
    await _storage.write(key: _extraKey, value: jsonEncode(_extraJson()));
  }

  Future<void> deleteFolder(String name) => _saveFolders(state.folders.where((f) => f.name != name).toList());

  Future<void> _saveFolders(List<ChatFolder> folders) async {
    emit(state.copyWith(folders: folders));
    await _storage.write(key: _foldersKey, value: jsonEncode([for (final f in folders) f.toJson()]));
    onChanged?.call();
  }
}

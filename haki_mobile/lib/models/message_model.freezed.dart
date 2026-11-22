// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'message_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MessageModel {

 int? get id; String get sender; String get username; int get senderId; String? get avatarUrl; String get message; String? get attachmentUrl; DateTime get timestamp; int? get recipientId; int? get groupId; String? get tempId; bool get isSending; bool get isRead; String? get mediaIv; Map<String, dynamic>? get mediaKeys; String? get attachmentType; List<ReactionModel> get reactions; int? get replyToMessageId; String? get replyToSender; String? get replyToMessage;/// Decrypted from the message itself (see MessageEnvelope); never fetched by the reader.
 LinkPreview? get linkPreview; bool get forwarded; DateTime? get editedAt; bool get pinned; PollData? get poll; StoryRef? get storyRef; String? get sticker; int? get durationSec;/// userId → chosen option numbers (the server can count, not read, the poll).
 Map<int, List<int>> get pollVotes;/// Set while a scheduled message waits on the server.
 DateTime? get scheduledAt;/// Disappearing messages: the server deletes it at this time.
 DateTime? get expiresAt;/// View once (private chats): the file is deleted once the recipient opens it.
 bool get viewOnce; DateTime? get viewedAt;/// Name and size of a shared video or document (from the encrypted body).
 FileMeta? get file;
/// Create a copy of MessageModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MessageModelCopyWith<MessageModel> get copyWith => _$MessageModelCopyWithImpl<MessageModel>(this as MessageModel, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as MessageModel;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MessageModel&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.sender, _this.sender) || other.sender == _this.sender)&&(identical(other.username, _this.username) || other.username == _this.username)&&(identical(other.senderId, _this.senderId) || other.senderId == _this.senderId)&&(identical(other.avatarUrl, _this.avatarUrl) || other.avatarUrl == _this.avatarUrl)&&(identical(other.message, _this.message) || other.message == _this.message)&&(identical(other.attachmentUrl, _this.attachmentUrl) || other.attachmentUrl == _this.attachmentUrl)&&(identical(other.timestamp, _this.timestamp) || other.timestamp == _this.timestamp)&&(identical(other.recipientId, _this.recipientId) || other.recipientId == _this.recipientId)&&(identical(other.groupId, _this.groupId) || other.groupId == _this.groupId)&&(identical(other.tempId, _this.tempId) || other.tempId == _this.tempId)&&(identical(other.isSending, _this.isSending) || other.isSending == _this.isSending)&&(identical(other.isRead, _this.isRead) || other.isRead == _this.isRead)&&(identical(other.mediaIv, _this.mediaIv) || other.mediaIv == _this.mediaIv)&&const DeepCollectionEquality().equals(other.mediaKeys, _this.mediaKeys)&&(identical(other.attachmentType, _this.attachmentType) || other.attachmentType == _this.attachmentType)&&const DeepCollectionEquality().equals(other.reactions, _this.reactions)&&(identical(other.replyToMessageId, _this.replyToMessageId) || other.replyToMessageId == _this.replyToMessageId)&&(identical(other.replyToSender, _this.replyToSender) || other.replyToSender == _this.replyToSender)&&(identical(other.replyToMessage, _this.replyToMessage) || other.replyToMessage == _this.replyToMessage)&&(identical(other.linkPreview, _this.linkPreview) || other.linkPreview == _this.linkPreview)&&(identical(other.forwarded, _this.forwarded) || other.forwarded == _this.forwarded)&&(identical(other.editedAt, _this.editedAt) || other.editedAt == _this.editedAt)&&(identical(other.pinned, _this.pinned) || other.pinned == _this.pinned)&&(identical(other.poll, _this.poll) || other.poll == _this.poll)&&(identical(other.storyRef, _this.storyRef) || other.storyRef == _this.storyRef)&&(identical(other.sticker, _this.sticker) || other.sticker == _this.sticker)&&(identical(other.durationSec, _this.durationSec) || other.durationSec == _this.durationSec)&&const DeepCollectionEquality().equals(other.pollVotes, _this.pollVotes)&&(identical(other.scheduledAt, _this.scheduledAt) || other.scheduledAt == _this.scheduledAt)&&(identical(other.expiresAt, _this.expiresAt) || other.expiresAt == _this.expiresAt)&&(identical(other.viewOnce, _this.viewOnce) || other.viewOnce == _this.viewOnce)&&(identical(other.viewedAt, _this.viewedAt) || other.viewedAt == _this.viewedAt)&&(identical(other.file, _this.file) || other.file == _this.file));
}


@override
int get hashCode {
  final _this = this as MessageModel;
  return Object.hashAll([runtimeType,_this.id,_this.sender,_this.username,_this.senderId,_this.avatarUrl,_this.message,_this.attachmentUrl,_this.timestamp,_this.recipientId,_this.groupId,_this.tempId,_this.isSending,_this.isRead,_this.mediaIv,const DeepCollectionEquality().hash(_this.mediaKeys),_this.attachmentType,const DeepCollectionEquality().hash(_this.reactions),_this.replyToMessageId,_this.replyToSender,_this.replyToMessage,_this.linkPreview,_this.forwarded,_this.editedAt,_this.pinned,_this.poll,_this.storyRef,_this.sticker,_this.durationSec,const DeepCollectionEquality().hash(_this.pollVotes),_this.scheduledAt,_this.expiresAt,_this.viewOnce,_this.viewedAt,_this.file]);
}

@override
String toString() {
  final _this = this as MessageModel;
  return 'MessageModel(id: ${_this.id}, sender: ${_this.sender}, username: ${_this.username}, senderId: ${_this.senderId}, avatarUrl: ${_this.avatarUrl}, message: ${_this.message}, attachmentUrl: ${_this.attachmentUrl}, timestamp: ${_this.timestamp}, recipientId: ${_this.recipientId}, groupId: ${_this.groupId}, tempId: ${_this.tempId}, isSending: ${_this.isSending}, isRead: ${_this.isRead}, mediaIv: ${_this.mediaIv}, mediaKeys: ${_this.mediaKeys}, attachmentType: ${_this.attachmentType}, reactions: ${_this.reactions}, replyToMessageId: ${_this.replyToMessageId}, replyToSender: ${_this.replyToSender}, replyToMessage: ${_this.replyToMessage}, linkPreview: ${_this.linkPreview}, forwarded: ${_this.forwarded}, editedAt: ${_this.editedAt}, pinned: ${_this.pinned}, poll: ${_this.poll}, storyRef: ${_this.storyRef}, sticker: ${_this.sticker}, durationSec: ${_this.durationSec}, pollVotes: ${_this.pollVotes}, scheduledAt: ${_this.scheduledAt}, expiresAt: ${_this.expiresAt}, viewOnce: ${_this.viewOnce}, viewedAt: ${_this.viewedAt}, file: ${_this.file})';
}


}

/// @nodoc
abstract mixin class $MessageModelCopyWith<$Res>  {
  factory $MessageModelCopyWith(MessageModel value, $Res Function(MessageModel) _then) = _$MessageModelCopyWithImpl;
@useResult
$Res call({
 int? id, String sender, String username, int senderId, String? avatarUrl, String message, String? attachmentUrl, DateTime timestamp, int? recipientId, int? groupId, String? tempId, bool isSending, bool isRead, String? mediaIv, Map<String, dynamic>? mediaKeys, String? attachmentType, List<ReactionModel> reactions, int? replyToMessageId, String? replyToSender, String? replyToMessage, LinkPreview? linkPreview, bool forwarded, DateTime? editedAt, bool pinned, PollData? poll, StoryRef? storyRef, String? sticker, int? durationSec, Map<int, List<int>> pollVotes, DateTime? scheduledAt, DateTime? expiresAt, bool viewOnce, DateTime? viewedAt, FileMeta? file
});


$LinkPreviewCopyWith<$Res>? get linkPreview;

}
/// @nodoc
class _$MessageModelCopyWithImpl<$Res>
    implements $MessageModelCopyWith<$Res> {
  _$MessageModelCopyWithImpl(this._self, this._then);

  final MessageModel _self;
  final $Res Function(MessageModel) _then;

/// Create a copy of MessageModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? sender = null,Object? username = null,Object? senderId = null,Object? avatarUrl = freezed,Object? message = null,Object? attachmentUrl = freezed,Object? timestamp = null,Object? recipientId = freezed,Object? groupId = freezed,Object? tempId = freezed,Object? isSending = null,Object? isRead = null,Object? mediaIv = freezed,Object? mediaKeys = freezed,Object? attachmentType = freezed,Object? reactions = null,Object? replyToMessageId = freezed,Object? replyToSender = freezed,Object? replyToMessage = freezed,Object? linkPreview = freezed,Object? forwarded = null,Object? editedAt = freezed,Object? pinned = null,Object? poll = freezed,Object? storyRef = freezed,Object? sticker = freezed,Object? durationSec = freezed,Object? pollVotes = null,Object? scheduledAt = freezed,Object? expiresAt = freezed,Object? viewOnce = null,Object? viewedAt = freezed,Object? file = freezed,}) {
  return _then(MessageModel(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,sender: null == sender ? _self.sender : sender // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,senderId: null == senderId ? _self.senderId : senderId // ignore: cast_nullable_to_non_nullable
as int,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,attachmentUrl: freezed == attachmentUrl ? _self.attachmentUrl : attachmentUrl // ignore: cast_nullable_to_non_nullable
as String?,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,recipientId: freezed == recipientId ? _self.recipientId : recipientId // ignore: cast_nullable_to_non_nullable
as int?,groupId: freezed == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as int?,tempId: freezed == tempId ? _self.tempId : tempId // ignore: cast_nullable_to_non_nullable
as String?,isSending: null == isSending ? _self.isSending : isSending // ignore: cast_nullable_to_non_nullable
as bool,isRead: null == isRead ? _self.isRead : isRead // ignore: cast_nullable_to_non_nullable
as bool,mediaIv: freezed == mediaIv ? _self.mediaIv : mediaIv // ignore: cast_nullable_to_non_nullable
as String?,mediaKeys: freezed == mediaKeys ? _self.mediaKeys : mediaKeys // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,attachmentType: freezed == attachmentType ? _self.attachmentType : attachmentType // ignore: cast_nullable_to_non_nullable
as String?,reactions: null == reactions ? _self.reactions : reactions // ignore: cast_nullable_to_non_nullable
as List<ReactionModel>,replyToMessageId: freezed == replyToMessageId ? _self.replyToMessageId : replyToMessageId // ignore: cast_nullable_to_non_nullable
as int?,replyToSender: freezed == replyToSender ? _self.replyToSender : replyToSender // ignore: cast_nullable_to_non_nullable
as String?,replyToMessage: freezed == replyToMessage ? _self.replyToMessage : replyToMessage // ignore: cast_nullable_to_non_nullable
as String?,linkPreview: freezed == linkPreview ? _self.linkPreview : linkPreview // ignore: cast_nullable_to_non_nullable
as LinkPreview?,forwarded: null == forwarded ? _self.forwarded : forwarded // ignore: cast_nullable_to_non_nullable
as bool,editedAt: freezed == editedAt ? _self.editedAt : editedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,pinned: null == pinned ? _self.pinned : pinned // ignore: cast_nullable_to_non_nullable
as bool,poll: freezed == poll ? _self.poll : poll // ignore: cast_nullable_to_non_nullable
as PollData?,storyRef: freezed == storyRef ? _self.storyRef : storyRef // ignore: cast_nullable_to_non_nullable
as StoryRef?,sticker: freezed == sticker ? _self.sticker : sticker // ignore: cast_nullable_to_non_nullable
as String?,durationSec: freezed == durationSec ? _self.durationSec : durationSec // ignore: cast_nullable_to_non_nullable
as int?,pollVotes: null == pollVotes ? _self.pollVotes : pollVotes // ignore: cast_nullable_to_non_nullable
as Map<int, List<int>>,scheduledAt: freezed == scheduledAt ? _self.scheduledAt : scheduledAt // ignore: cast_nullable_to_non_nullable
as DateTime?,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,viewOnce: null == viewOnce ? _self.viewOnce : viewOnce // ignore: cast_nullable_to_non_nullable
as bool,viewedAt: freezed == viewedAt ? _self.viewedAt : viewedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,file: freezed == file ? _self.file : file // ignore: cast_nullable_to_non_nullable
as FileMeta?,
  ));
}
/// Create a copy of MessageModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LinkPreviewCopyWith<$Res>? get linkPreview {
    if (_self.linkPreview == null) {
    return null;
  }

  return $LinkPreviewCopyWith<$Res>(_self.linkPreview!, (value) {
    return _then(_self.copyWith(linkPreview: value));
  });
}
}


/// Adds pattern-matching-related methods to [MessageModel].
extension MessageModelPatterns on MessageModel {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MessageModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MessageModel() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MessageModel value)  $default,){
final _that = this;
switch (_that) {
case _MessageModel():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MessageModel value)?  $default,){
final _that = this;
switch (_that) {
case _MessageModel() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? id,  String sender,  String username,  int senderId,  String? avatarUrl,  String message,  String? attachmentUrl,  DateTime timestamp,  int? recipientId,  int? groupId,  String? tempId,  bool isSending,  bool isRead,  String? mediaIv,  Map<String, dynamic>? mediaKeys,  String? attachmentType,  List<ReactionModel> reactions,  int? replyToMessageId,  String? replyToSender,  String? replyToMessage,  LinkPreview? linkPreview,  bool forwarded,  DateTime? editedAt,  bool pinned,  PollData? poll,  StoryRef? storyRef,  String? sticker,  int? durationSec,  Map<int, List<int>> pollVotes,  DateTime? scheduledAt,  DateTime? expiresAt,  bool viewOnce,  DateTime? viewedAt,  FileMeta? file)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MessageModel() when $default != null:
return $default(_that.id,_that.sender,_that.username,_that.senderId,_that.avatarUrl,_that.message,_that.attachmentUrl,_that.timestamp,_that.recipientId,_that.groupId,_that.tempId,_that.isSending,_that.isRead,_that.mediaIv,_that.mediaKeys,_that.attachmentType,_that.reactions,_that.replyToMessageId,_that.replyToSender,_that.replyToMessage,_that.linkPreview,_that.forwarded,_that.editedAt,_that.pinned,_that.poll,_that.storyRef,_that.sticker,_that.durationSec,_that.pollVotes,_that.scheduledAt,_that.expiresAt,_that.viewOnce,_that.viewedAt,_that.file);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? id,  String sender,  String username,  int senderId,  String? avatarUrl,  String message,  String? attachmentUrl,  DateTime timestamp,  int? recipientId,  int? groupId,  String? tempId,  bool isSending,  bool isRead,  String? mediaIv,  Map<String, dynamic>? mediaKeys,  String? attachmentType,  List<ReactionModel> reactions,  int? replyToMessageId,  String? replyToSender,  String? replyToMessage,  LinkPreview? linkPreview,  bool forwarded,  DateTime? editedAt,  bool pinned,  PollData? poll,  StoryRef? storyRef,  String? sticker,  int? durationSec,  Map<int, List<int>> pollVotes,  DateTime? scheduledAt,  DateTime? expiresAt,  bool viewOnce,  DateTime? viewedAt,  FileMeta? file)  $default,) {final _that = this;
switch (_that) {
case _MessageModel():
return $default(_that.id,_that.sender,_that.username,_that.senderId,_that.avatarUrl,_that.message,_that.attachmentUrl,_that.timestamp,_that.recipientId,_that.groupId,_that.tempId,_that.isSending,_that.isRead,_that.mediaIv,_that.mediaKeys,_that.attachmentType,_that.reactions,_that.replyToMessageId,_that.replyToSender,_that.replyToMessage,_that.linkPreview,_that.forwarded,_that.editedAt,_that.pinned,_that.poll,_that.storyRef,_that.sticker,_that.durationSec,_that.pollVotes,_that.scheduledAt,_that.expiresAt,_that.viewOnce,_that.viewedAt,_that.file);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? id,  String sender,  String username,  int senderId,  String? avatarUrl,  String message,  String? attachmentUrl,  DateTime timestamp,  int? recipientId,  int? groupId,  String? tempId,  bool isSending,  bool isRead,  String? mediaIv,  Map<String, dynamic>? mediaKeys,  String? attachmentType,  List<ReactionModel> reactions,  int? replyToMessageId,  String? replyToSender,  String? replyToMessage,  LinkPreview? linkPreview,  bool forwarded,  DateTime? editedAt,  bool pinned,  PollData? poll,  StoryRef? storyRef,  String? sticker,  int? durationSec,  Map<int, List<int>> pollVotes,  DateTime? scheduledAt,  DateTime? expiresAt,  bool viewOnce,  DateTime? viewedAt,  FileMeta? file)?  $default,) {final _that = this;
switch (_that) {
case _MessageModel() when $default != null:
return $default(_that.id,_that.sender,_that.username,_that.senderId,_that.avatarUrl,_that.message,_that.attachmentUrl,_that.timestamp,_that.recipientId,_that.groupId,_that.tempId,_that.isSending,_that.isRead,_that.mediaIv,_that.mediaKeys,_that.attachmentType,_that.reactions,_that.replyToMessageId,_that.replyToSender,_that.replyToMessage,_that.linkPreview,_that.forwarded,_that.editedAt,_that.pinned,_that.poll,_that.storyRef,_that.sticker,_that.durationSec,_that.pollVotes,_that.scheduledAt,_that.expiresAt,_that.viewOnce,_that.viewedAt,_that.file);case _:
  return null;

}
}

}

/// @nodoc


class _MessageModel extends MessageModel {
  const _MessageModel({this.id, required this.sender, required this.username, required this.senderId, this.avatarUrl, required this.message, this.attachmentUrl, required this.timestamp, this.recipientId, this.groupId, this.tempId, this.isSending = false, this.isRead = false, this.mediaIv,  Map<String, dynamic>? mediaKeys, this.attachmentType,  List<ReactionModel> reactions = const [], this.replyToMessageId, this.replyToSender, this.replyToMessage, this.linkPreview, this.forwarded = false, this.editedAt, this.pinned = false, this.poll, this.storyRef, this.sticker, this.durationSec,  Map<int, List<int>> pollVotes = const {}, this.scheduledAt, this.expiresAt, this.viewOnce = false, this.viewedAt, this.file}): _mediaKeys = mediaKeys,_reactions = reactions,_pollVotes = pollVotes,super._();
  

@override final  int? id;
@override final  String sender;
@override final  String username;
@override final  int senderId;
@override final  String? avatarUrl;
@override final  String message;
@override final  String? attachmentUrl;
@override final  DateTime timestamp;
@override final  int? recipientId;
@override final  int? groupId;
@override final  String? tempId;
@override@JsonKey() final  bool isSending;
@override@JsonKey() final  bool isRead;
@override final  String? mediaIv;
 final  Map<String, dynamic>? _mediaKeys;
@override Map<String, dynamic>? get mediaKeys {
  final value = _mediaKeys;
  if (value == null) return null;
  if (_mediaKeys is EqualUnmodifiableMapView) return _mediaKeys;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override final  String? attachmentType;
 final  List<ReactionModel> _reactions;
@override@JsonKey() List<ReactionModel> get reactions {
  if (_reactions is EqualUnmodifiableListView) return _reactions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_reactions);
}

@override final  int? replyToMessageId;
@override final  String? replyToSender;
@override final  String? replyToMessage;
/// Decrypted from the message itself (see MessageEnvelope); never fetched by the reader.
@override final  LinkPreview? linkPreview;
@override@JsonKey() final  bool forwarded;
@override final  DateTime? editedAt;
@override@JsonKey() final  bool pinned;
@override final  PollData? poll;
@override final  StoryRef? storyRef;
@override final  String? sticker;
@override final  int? durationSec;
/// userId → chosen option numbers (the server can count, not read, the poll).
 final  Map<int, List<int>> _pollVotes;
/// userId → chosen option numbers (the server can count, not read, the poll).
@override@JsonKey() Map<int, List<int>> get pollVotes {
  if (_pollVotes is EqualUnmodifiableMapView) return _pollVotes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_pollVotes);
}

/// Set while a scheduled message waits on the server.
@override final  DateTime? scheduledAt;
/// Disappearing messages: the server deletes it at this time.
@override final  DateTime? expiresAt;
/// View once (private chats): the file is deleted once the recipient opens it.
@override@JsonKey() final  bool viewOnce;
@override final  DateTime? viewedAt;
/// Name and size of a shared video or document (from the encrypted body).
@override final  FileMeta? file;

/// Create a copy of MessageModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MessageModelCopyWith<_MessageModel> get copyWith => __$MessageModelCopyWithImpl<_MessageModel>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MessageModel&&(identical(other.id, id) || other.id == id)&&(identical(other.sender, sender) || other.sender == sender)&&(identical(other.username, username) || other.username == username)&&(identical(other.senderId, senderId) || other.senderId == senderId)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.message, message) || other.message == message)&&(identical(other.attachmentUrl, attachmentUrl) || other.attachmentUrl == attachmentUrl)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.recipientId, recipientId) || other.recipientId == recipientId)&&(identical(other.groupId, groupId) || other.groupId == groupId)&&(identical(other.tempId, tempId) || other.tempId == tempId)&&(identical(other.isSending, isSending) || other.isSending == isSending)&&(identical(other.isRead, isRead) || other.isRead == isRead)&&(identical(other.mediaIv, mediaIv) || other.mediaIv == mediaIv)&&const DeepCollectionEquality().equals(other.mediaKeys, _mediaKeys)&&(identical(other.attachmentType, attachmentType) || other.attachmentType == attachmentType)&&const DeepCollectionEquality().equals(other.reactions, _reactions)&&(identical(other.replyToMessageId, replyToMessageId) || other.replyToMessageId == replyToMessageId)&&(identical(other.replyToSender, replyToSender) || other.replyToSender == replyToSender)&&(identical(other.replyToMessage, replyToMessage) || other.replyToMessage == replyToMessage)&&(identical(other.linkPreview, linkPreview) || other.linkPreview == linkPreview)&&(identical(other.forwarded, forwarded) || other.forwarded == forwarded)&&(identical(other.editedAt, editedAt) || other.editedAt == editedAt)&&(identical(other.pinned, pinned) || other.pinned == pinned)&&(identical(other.poll, poll) || other.poll == poll)&&(identical(other.storyRef, storyRef) || other.storyRef == storyRef)&&(identical(other.sticker, sticker) || other.sticker == sticker)&&(identical(other.durationSec, durationSec) || other.durationSec == durationSec)&&const DeepCollectionEquality().equals(other.pollVotes, _pollVotes)&&(identical(other.scheduledAt, scheduledAt) || other.scheduledAt == scheduledAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.viewOnce, viewOnce) || other.viewOnce == viewOnce)&&(identical(other.viewedAt, viewedAt) || other.viewedAt == viewedAt)&&(identical(other.file, file) || other.file == file));
}


@override
int get hashCode {
    return Object.hashAll([runtimeType,id,sender,username,senderId,avatarUrl,message,attachmentUrl,timestamp,recipientId,groupId,tempId,isSending,isRead,mediaIv,const DeepCollectionEquality().hash(_mediaKeys),attachmentType,const DeepCollectionEquality().hash(_reactions),replyToMessageId,replyToSender,replyToMessage,linkPreview,forwarded,editedAt,pinned,poll,storyRef,sticker,durationSec,const DeepCollectionEquality().hash(_pollVotes),scheduledAt,expiresAt,viewOnce,viewedAt,file]);
}

@override
String toString() {
    return 'MessageModel(id: $id, sender: $sender, username: $username, senderId: $senderId, avatarUrl: $avatarUrl, message: $message, attachmentUrl: $attachmentUrl, timestamp: $timestamp, recipientId: $recipientId, groupId: $groupId, tempId: $tempId, isSending: $isSending, isRead: $isRead, mediaIv: $mediaIv, mediaKeys: $mediaKeys, attachmentType: $attachmentType, reactions: $reactions, replyToMessageId: $replyToMessageId, replyToSender: $replyToSender, replyToMessage: $replyToMessage, linkPreview: $linkPreview, forwarded: $forwarded, editedAt: $editedAt, pinned: $pinned, poll: $poll, storyRef: $storyRef, sticker: $sticker, durationSec: $durationSec, pollVotes: $pollVotes, scheduledAt: $scheduledAt, expiresAt: $expiresAt, viewOnce: $viewOnce, viewedAt: $viewedAt, file: $file)';
}


}

/// @nodoc
abstract mixin class _$MessageModelCopyWith<$Res> implements $MessageModelCopyWith<$Res> {
  factory _$MessageModelCopyWith(_MessageModel value, $Res Function(_MessageModel) _then) = __$MessageModelCopyWithImpl;
@override @useResult
$Res call({
 int? id, String sender, String username, int senderId, String? avatarUrl, String message, String? attachmentUrl, DateTime timestamp, int? recipientId, int? groupId, String? tempId, bool isSending, bool isRead, String? mediaIv, Map<String, dynamic>? mediaKeys, String? attachmentType, List<ReactionModel> reactions, int? replyToMessageId, String? replyToSender, String? replyToMessage, LinkPreview? linkPreview, bool forwarded, DateTime? editedAt, bool pinned, PollData? poll, StoryRef? storyRef, String? sticker, int? durationSec, Map<int, List<int>> pollVotes, DateTime? scheduledAt, DateTime? expiresAt, bool viewOnce, DateTime? viewedAt, FileMeta? file
});


@override $LinkPreviewCopyWith<$Res>? get linkPreview;

}
/// @nodoc
class __$MessageModelCopyWithImpl<$Res>
    implements _$MessageModelCopyWith<$Res> {
  __$MessageModelCopyWithImpl(this._self, this._then);

  final _MessageModel _self;
  final $Res Function(_MessageModel) _then;

/// Create a copy of MessageModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? sender = null,Object? username = null,Object? senderId = null,Object? avatarUrl = freezed,Object? message = null,Object? attachmentUrl = freezed,Object? timestamp = null,Object? recipientId = freezed,Object? groupId = freezed,Object? tempId = freezed,Object? isSending = null,Object? isRead = null,Object? mediaIv = freezed,Object? mediaKeys = freezed,Object? attachmentType = freezed,Object? reactions = null,Object? replyToMessageId = freezed,Object? replyToSender = freezed,Object? replyToMessage = freezed,Object? linkPreview = freezed,Object? forwarded = null,Object? editedAt = freezed,Object? pinned = null,Object? poll = freezed,Object? storyRef = freezed,Object? sticker = freezed,Object? durationSec = freezed,Object? pollVotes = null,Object? scheduledAt = freezed,Object? expiresAt = freezed,Object? viewOnce = null,Object? viewedAt = freezed,Object? file = freezed,}) {
  return _then(_MessageModel(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,sender: null == sender ? _self.sender : sender // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,senderId: null == senderId ? _self.senderId : senderId // ignore: cast_nullable_to_non_nullable
as int,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,attachmentUrl: freezed == attachmentUrl ? _self.attachmentUrl : attachmentUrl // ignore: cast_nullable_to_non_nullable
as String?,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,recipientId: freezed == recipientId ? _self.recipientId : recipientId // ignore: cast_nullable_to_non_nullable
as int?,groupId: freezed == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as int?,tempId: freezed == tempId ? _self.tempId : tempId // ignore: cast_nullable_to_non_nullable
as String?,isSending: null == isSending ? _self.isSending : isSending // ignore: cast_nullable_to_non_nullable
as bool,isRead: null == isRead ? _self.isRead : isRead // ignore: cast_nullable_to_non_nullable
as bool,mediaIv: freezed == mediaIv ? _self.mediaIv : mediaIv // ignore: cast_nullable_to_non_nullable
as String?,mediaKeys: freezed == mediaKeys ? _self._mediaKeys : mediaKeys // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,attachmentType: freezed == attachmentType ? _self.attachmentType : attachmentType // ignore: cast_nullable_to_non_nullable
as String?,reactions: null == reactions ? _self._reactions : reactions // ignore: cast_nullable_to_non_nullable
as List<ReactionModel>,replyToMessageId: freezed == replyToMessageId ? _self.replyToMessageId : replyToMessageId // ignore: cast_nullable_to_non_nullable
as int?,replyToSender: freezed == replyToSender ? _self.replyToSender : replyToSender // ignore: cast_nullable_to_non_nullable
as String?,replyToMessage: freezed == replyToMessage ? _self.replyToMessage : replyToMessage // ignore: cast_nullable_to_non_nullable
as String?,linkPreview: freezed == linkPreview ? _self.linkPreview : linkPreview // ignore: cast_nullable_to_non_nullable
as LinkPreview?,forwarded: null == forwarded ? _self.forwarded : forwarded // ignore: cast_nullable_to_non_nullable
as bool,editedAt: freezed == editedAt ? _self.editedAt : editedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,pinned: null == pinned ? _self.pinned : pinned // ignore: cast_nullable_to_non_nullable
as bool,poll: freezed == poll ? _self.poll : poll // ignore: cast_nullable_to_non_nullable
as PollData?,storyRef: freezed == storyRef ? _self.storyRef : storyRef // ignore: cast_nullable_to_non_nullable
as StoryRef?,sticker: freezed == sticker ? _self.sticker : sticker // ignore: cast_nullable_to_non_nullable
as String?,durationSec: freezed == durationSec ? _self.durationSec : durationSec // ignore: cast_nullable_to_non_nullable
as int?,pollVotes: null == pollVotes ? _self._pollVotes : pollVotes // ignore: cast_nullable_to_non_nullable
as Map<int, List<int>>,scheduledAt: freezed == scheduledAt ? _self.scheduledAt : scheduledAt // ignore: cast_nullable_to_non_nullable
as DateTime?,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,viewOnce: null == viewOnce ? _self.viewOnce : viewOnce // ignore: cast_nullable_to_non_nullable
as bool,viewedAt: freezed == viewedAt ? _self.viewedAt : viewedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,file: freezed == file ? _self.file : file // ignore: cast_nullable_to_non_nullable
as FileMeta?,
  ));
}

/// Create a copy of MessageModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LinkPreviewCopyWith<$Res>? get linkPreview {
    if (_self.linkPreview == null) {
    return null;
  }

  return $LinkPreviewCopyWith<$Res>(_self.linkPreview!, (value) {
    return _then(_self.copyWith(linkPreview: value));
  });
}
}

// dart format on

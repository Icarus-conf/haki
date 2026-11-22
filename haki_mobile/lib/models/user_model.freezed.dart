// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LastMessage {

 String get content; DateTime get timestamp; int get senderId; String? get attachmentType;
/// Create a copy of LastMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LastMessageCopyWith<LastMessage> get copyWith => _$LastMessageCopyWithImpl<LastMessage>(this as LastMessage, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as LastMessage;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LastMessage&&(identical(other.content, _this.content) || other.content == _this.content)&&(identical(other.timestamp, _this.timestamp) || other.timestamp == _this.timestamp)&&(identical(other.senderId, _this.senderId) || other.senderId == _this.senderId)&&(identical(other.attachmentType, _this.attachmentType) || other.attachmentType == _this.attachmentType));
}


@override
int get hashCode {
  final _this = this as LastMessage;
  return Object.hash(runtimeType,_this.content,_this.timestamp,_this.senderId,_this.attachmentType);
}

@override
String toString() {
  final _this = this as LastMessage;
  return 'LastMessage(content: ${_this.content}, timestamp: ${_this.timestamp}, senderId: ${_this.senderId}, attachmentType: ${_this.attachmentType})';
}


}

/// @nodoc
abstract mixin class $LastMessageCopyWith<$Res>  {
  factory $LastMessageCopyWith(LastMessage value, $Res Function(LastMessage) _then) = _$LastMessageCopyWithImpl;
@useResult
$Res call({
 String content, DateTime timestamp, int senderId, String? attachmentType
});




}
/// @nodoc
class _$LastMessageCopyWithImpl<$Res>
    implements $LastMessageCopyWith<$Res> {
  _$LastMessageCopyWithImpl(this._self, this._then);

  final LastMessage _self;
  final $Res Function(LastMessage) _then;

/// Create a copy of LastMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? content = null,Object? timestamp = null,Object? senderId = null,Object? attachmentType = freezed,}) {
  return _then(LastMessage(
content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,senderId: null == senderId ? _self.senderId : senderId // ignore: cast_nullable_to_non_nullable
as int,attachmentType: freezed == attachmentType ? _self.attachmentType : attachmentType // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [LastMessage].
extension LastMessagePatterns on LastMessage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LastMessage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LastMessage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LastMessage value)  $default,){
final _that = this;
switch (_that) {
case _LastMessage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LastMessage value)?  $default,){
final _that = this;
switch (_that) {
case _LastMessage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String content,  DateTime timestamp,  int senderId,  String? attachmentType)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LastMessage() when $default != null:
return $default(_that.content,_that.timestamp,_that.senderId,_that.attachmentType);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String content,  DateTime timestamp,  int senderId,  String? attachmentType)  $default,) {final _that = this;
switch (_that) {
case _LastMessage():
return $default(_that.content,_that.timestamp,_that.senderId,_that.attachmentType);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String content,  DateTime timestamp,  int senderId,  String? attachmentType)?  $default,) {final _that = this;
switch (_that) {
case _LastMessage() when $default != null:
return $default(_that.content,_that.timestamp,_that.senderId,_that.attachmentType);case _:
  return null;

}
}

}

/// @nodoc


class _LastMessage implements LastMessage {
  const _LastMessage({required this.content, required this.timestamp, required this.senderId, this.attachmentType});
  

@override final  String content;
@override final  DateTime timestamp;
@override final  int senderId;
@override final  String? attachmentType;

/// Create a copy of LastMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LastMessageCopyWith<_LastMessage> get copyWith => __$LastMessageCopyWithImpl<_LastMessage>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _LastMessage&&(identical(other.content, content) || other.content == content)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.senderId, senderId) || other.senderId == senderId)&&(identical(other.attachmentType, attachmentType) || other.attachmentType == attachmentType));
}


@override
int get hashCode {
    return Object.hash(runtimeType,content,timestamp,senderId,attachmentType);
}

@override
String toString() {
    return 'LastMessage(content: $content, timestamp: $timestamp, senderId: $senderId, attachmentType: $attachmentType)';
}


}

/// @nodoc
abstract mixin class _$LastMessageCopyWith<$Res> implements $LastMessageCopyWith<$Res> {
  factory _$LastMessageCopyWith(_LastMessage value, $Res Function(_LastMessage) _then) = __$LastMessageCopyWithImpl;
@override @useResult
$Res call({
 String content, DateTime timestamp, int senderId, String? attachmentType
});




}
/// @nodoc
class __$LastMessageCopyWithImpl<$Res>
    implements _$LastMessageCopyWith<$Res> {
  __$LastMessageCopyWithImpl(this._self, this._then);

  final _LastMessage _self;
  final $Res Function(_LastMessage) _then;

/// Create a copy of LastMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? content = null,Object? timestamp = null,Object? senderId = null,Object? attachmentType = freezed,}) {
  return _then(_LastMessage(
content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,senderId: null == senderId ? _self.senderId : senderId // ignore: cast_nullable_to_non_nullable
as int,attachmentType: freezed == attachmentType ? _self.attachmentType : attachmentType // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$UserModel {

 int get id; String get username; String? get email; String? get displayName; String? get bio; String? get avatarUrl; String? get publicKey; String? get statusMessage;/// My own username, sealed to my key (only set on /users/me).
 String? get handleSealed;/// 'MM-DD' if they chose to share it with friends.
 String? get birthday; int get unreadCount; LastMessage? get lastMessage;
/// Create a copy of UserModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserModelCopyWith<UserModel> get copyWith => _$UserModelCopyWithImpl<UserModel>(this as UserModel, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as UserModel;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserModel&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.username, _this.username) || other.username == _this.username)&&(identical(other.email, _this.email) || other.email == _this.email)&&(identical(other.displayName, _this.displayName) || other.displayName == _this.displayName)&&(identical(other.bio, _this.bio) || other.bio == _this.bio)&&(identical(other.avatarUrl, _this.avatarUrl) || other.avatarUrl == _this.avatarUrl)&&(identical(other.publicKey, _this.publicKey) || other.publicKey == _this.publicKey)&&(identical(other.statusMessage, _this.statusMessage) || other.statusMessage == _this.statusMessage)&&(identical(other.handleSealed, _this.handleSealed) || other.handleSealed == _this.handleSealed)&&(identical(other.birthday, _this.birthday) || other.birthday == _this.birthday)&&(identical(other.unreadCount, _this.unreadCount) || other.unreadCount == _this.unreadCount)&&(identical(other.lastMessage, _this.lastMessage) || other.lastMessage == _this.lastMessage));
}


@override
int get hashCode {
  final _this = this as UserModel;
  return Object.hash(runtimeType,_this.id,_this.username,_this.email,_this.displayName,_this.bio,_this.avatarUrl,_this.publicKey,_this.statusMessage,_this.handleSealed,_this.birthday,_this.unreadCount,_this.lastMessage);
}

@override
String toString() {
  final _this = this as UserModel;
  return 'UserModel(id: ${_this.id}, username: ${_this.username}, email: ${_this.email}, displayName: ${_this.displayName}, bio: ${_this.bio}, avatarUrl: ${_this.avatarUrl}, publicKey: ${_this.publicKey}, statusMessage: ${_this.statusMessage}, handleSealed: ${_this.handleSealed}, birthday: ${_this.birthday}, unreadCount: ${_this.unreadCount}, lastMessage: ${_this.lastMessage})';
}


}

/// @nodoc
abstract mixin class $UserModelCopyWith<$Res>  {
  factory $UserModelCopyWith(UserModel value, $Res Function(UserModel) _then) = _$UserModelCopyWithImpl;
@useResult
$Res call({
 int id, String username, String? email, String? displayName, String? bio, String? avatarUrl, String? publicKey, String? statusMessage, String? handleSealed, String? birthday, int unreadCount, LastMessage? lastMessage
});


$LastMessageCopyWith<$Res>? get lastMessage;

}
/// @nodoc
class _$UserModelCopyWithImpl<$Res>
    implements $UserModelCopyWith<$Res> {
  _$UserModelCopyWithImpl(this._self, this._then);

  final UserModel _self;
  final $Res Function(UserModel) _then;

/// Create a copy of UserModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? username = null,Object? email = freezed,Object? displayName = freezed,Object? bio = freezed,Object? avatarUrl = freezed,Object? publicKey = freezed,Object? statusMessage = freezed,Object? handleSealed = freezed,Object? birthday = freezed,Object? unreadCount = null,Object? lastMessage = freezed,}) {
  return _then(UserModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,bio: freezed == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String?,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,publicKey: freezed == publicKey ? _self.publicKey : publicKey // ignore: cast_nullable_to_non_nullable
as String?,statusMessage: freezed == statusMessage ? _self.statusMessage : statusMessage // ignore: cast_nullable_to_non_nullable
as String?,handleSealed: freezed == handleSealed ? _self.handleSealed : handleSealed // ignore: cast_nullable_to_non_nullable
as String?,birthday: freezed == birthday ? _self.birthday : birthday // ignore: cast_nullable_to_non_nullable
as String?,unreadCount: null == unreadCount ? _self.unreadCount : unreadCount // ignore: cast_nullable_to_non_nullable
as int,lastMessage: freezed == lastMessage ? _self.lastMessage : lastMessage // ignore: cast_nullable_to_non_nullable
as LastMessage?,
  ));
}
/// Create a copy of UserModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LastMessageCopyWith<$Res>? get lastMessage {
    if (_self.lastMessage == null) {
    return null;
  }

  return $LastMessageCopyWith<$Res>(_self.lastMessage!, (value) {
    return _then(_self.copyWith(lastMessage: value));
  });
}
}


/// Adds pattern-matching-related methods to [UserModel].
extension UserModelPatterns on UserModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserModel value)  $default,){
final _that = this;
switch (_that) {
case _UserModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserModel value)?  $default,){
final _that = this;
switch (_that) {
case _UserModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String username,  String? email,  String? displayName,  String? bio,  String? avatarUrl,  String? publicKey,  String? statusMessage,  String? handleSealed,  String? birthday,  int unreadCount,  LastMessage? lastMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserModel() when $default != null:
return $default(_that.id,_that.username,_that.email,_that.displayName,_that.bio,_that.avatarUrl,_that.publicKey,_that.statusMessage,_that.handleSealed,_that.birthday,_that.unreadCount,_that.lastMessage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String username,  String? email,  String? displayName,  String? bio,  String? avatarUrl,  String? publicKey,  String? statusMessage,  String? handleSealed,  String? birthday,  int unreadCount,  LastMessage? lastMessage)  $default,) {final _that = this;
switch (_that) {
case _UserModel():
return $default(_that.id,_that.username,_that.email,_that.displayName,_that.bio,_that.avatarUrl,_that.publicKey,_that.statusMessage,_that.handleSealed,_that.birthday,_that.unreadCount,_that.lastMessage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String username,  String? email,  String? displayName,  String? bio,  String? avatarUrl,  String? publicKey,  String? statusMessage,  String? handleSealed,  String? birthday,  int unreadCount,  LastMessage? lastMessage)?  $default,) {final _that = this;
switch (_that) {
case _UserModel() when $default != null:
return $default(_that.id,_that.username,_that.email,_that.displayName,_that.bio,_that.avatarUrl,_that.publicKey,_that.statusMessage,_that.handleSealed,_that.birthday,_that.unreadCount,_that.lastMessage);case _:
  return null;

}
}

}

/// @nodoc


class _UserModel extends UserModel {
  const _UserModel({required this.id, required this.username, this.email, this.displayName, this.bio, this.avatarUrl, this.publicKey, this.statusMessage, this.handleSealed, this.birthday, this.unreadCount = 0, this.lastMessage}): super._();
  

@override final  int id;
@override final  String username;
@override final  String? email;
@override final  String? displayName;
@override final  String? bio;
@override final  String? avatarUrl;
@override final  String? publicKey;
@override final  String? statusMessage;
/// My own username, sealed to my key (only set on /users/me).
@override final  String? handleSealed;
/// 'MM-DD' if they chose to share it with friends.
@override final  String? birthday;
@override@JsonKey() final  int unreadCount;
@override final  LastMessage? lastMessage;

/// Create a copy of UserModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserModelCopyWith<_UserModel> get copyWith => __$UserModelCopyWithImpl<_UserModel>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserModel&&(identical(other.id, id) || other.id == id)&&(identical(other.username, username) || other.username == username)&&(identical(other.email, email) || other.email == email)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.bio, bio) || other.bio == bio)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.publicKey, publicKey) || other.publicKey == publicKey)&&(identical(other.statusMessage, statusMessage) || other.statusMessage == statusMessage)&&(identical(other.handleSealed, handleSealed) || other.handleSealed == handleSealed)&&(identical(other.birthday, birthday) || other.birthday == birthday)&&(identical(other.unreadCount, unreadCount) || other.unreadCount == unreadCount)&&(identical(other.lastMessage, lastMessage) || other.lastMessage == lastMessage));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,username,email,displayName,bio,avatarUrl,publicKey,statusMessage,handleSealed,birthday,unreadCount,lastMessage);
}

@override
String toString() {
    return 'UserModel(id: $id, username: $username, email: $email, displayName: $displayName, bio: $bio, avatarUrl: $avatarUrl, publicKey: $publicKey, statusMessage: $statusMessage, handleSealed: $handleSealed, birthday: $birthday, unreadCount: $unreadCount, lastMessage: $lastMessage)';
}


}

/// @nodoc
abstract mixin class _$UserModelCopyWith<$Res> implements $UserModelCopyWith<$Res> {
  factory _$UserModelCopyWith(_UserModel value, $Res Function(_UserModel) _then) = __$UserModelCopyWithImpl;
@override @useResult
$Res call({
 int id, String username, String? email, String? displayName, String? bio, String? avatarUrl, String? publicKey, String? statusMessage, String? handleSealed, String? birthday, int unreadCount, LastMessage? lastMessage
});


@override $LastMessageCopyWith<$Res>? get lastMessage;

}
/// @nodoc
class __$UserModelCopyWithImpl<$Res>
    implements _$UserModelCopyWith<$Res> {
  __$UserModelCopyWithImpl(this._self, this._then);

  final _UserModel _self;
  final $Res Function(_UserModel) _then;

/// Create a copy of UserModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? username = null,Object? email = freezed,Object? displayName = freezed,Object? bio = freezed,Object? avatarUrl = freezed,Object? publicKey = freezed,Object? statusMessage = freezed,Object? handleSealed = freezed,Object? birthday = freezed,Object? unreadCount = null,Object? lastMessage = freezed,}) {
  return _then(_UserModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,bio: freezed == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String?,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,publicKey: freezed == publicKey ? _self.publicKey : publicKey // ignore: cast_nullable_to_non_nullable
as String?,statusMessage: freezed == statusMessage ? _self.statusMessage : statusMessage // ignore: cast_nullable_to_non_nullable
as String?,handleSealed: freezed == handleSealed ? _self.handleSealed : handleSealed // ignore: cast_nullable_to_non_nullable
as String?,birthday: freezed == birthday ? _self.birthday : birthday // ignore: cast_nullable_to_non_nullable
as String?,unreadCount: null == unreadCount ? _self.unreadCount : unreadCount // ignore: cast_nullable_to_non_nullable
as int,lastMessage: freezed == lastMessage ? _self.lastMessage : lastMessage // ignore: cast_nullable_to_non_nullable
as LastMessage?,
  ));
}

/// Create a copy of UserModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LastMessageCopyWith<$Res>? get lastMessage {
    if (_self.lastMessage == null) {
    return null;
  }

  return $LastMessageCopyWith<$Res>(_self.lastMessage!, (value) {
    return _then(_self.copyWith(lastMessage: value));
  });
}
}

// dart format on

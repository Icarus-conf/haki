// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'friends_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$FriendsState {

/// Sorted by most recent message first.
 List<UserModel> get friends; List<FriendRequestModel> get requests; List<UserModel> get blocked; Set<int> get onlineIds;/// Decrypted one-line preview of each friend's last message.
 Map<int, String> get previews; Set<int> get typingIds; bool get isLoading; int? get activeChatId;/// Encrypted group chats, most recent first; previews keyed by group id.
 List<GroupModel> get groups; Map<int, String> get groupPreviews; int? get activeGroupId;
/// Create a copy of FriendsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FriendsStateCopyWith<FriendsState> get copyWith => _$FriendsStateCopyWithImpl<FriendsState>(this as FriendsState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as FriendsState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FriendsState&&const DeepCollectionEquality().equals(other.friends, _this.friends)&&const DeepCollectionEquality().equals(other.requests, _this.requests)&&const DeepCollectionEquality().equals(other.blocked, _this.blocked)&&const DeepCollectionEquality().equals(other.onlineIds, _this.onlineIds)&&const DeepCollectionEquality().equals(other.previews, _this.previews)&&const DeepCollectionEquality().equals(other.typingIds, _this.typingIds)&&(identical(other.isLoading, _this.isLoading) || other.isLoading == _this.isLoading)&&(identical(other.activeChatId, _this.activeChatId) || other.activeChatId == _this.activeChatId)&&const DeepCollectionEquality().equals(other.groups, _this.groups)&&const DeepCollectionEquality().equals(other.groupPreviews, _this.groupPreviews)&&(identical(other.activeGroupId, _this.activeGroupId) || other.activeGroupId == _this.activeGroupId));
}


@override
int get hashCode {
  final _this = this as FriendsState;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.friends),const DeepCollectionEquality().hash(_this.requests),const DeepCollectionEquality().hash(_this.blocked),const DeepCollectionEquality().hash(_this.onlineIds),const DeepCollectionEquality().hash(_this.previews),const DeepCollectionEquality().hash(_this.typingIds),_this.isLoading,_this.activeChatId,const DeepCollectionEquality().hash(_this.groups),const DeepCollectionEquality().hash(_this.groupPreviews),_this.activeGroupId);
}

@override
String toString() {
  final _this = this as FriendsState;
  return 'FriendsState(friends: ${_this.friends}, requests: ${_this.requests}, blocked: ${_this.blocked}, onlineIds: ${_this.onlineIds}, previews: ${_this.previews}, typingIds: ${_this.typingIds}, isLoading: ${_this.isLoading}, activeChatId: ${_this.activeChatId}, groups: ${_this.groups}, groupPreviews: ${_this.groupPreviews}, activeGroupId: ${_this.activeGroupId})';
}


}

/// @nodoc
abstract mixin class $FriendsStateCopyWith<$Res>  {
  factory $FriendsStateCopyWith(FriendsState value, $Res Function(FriendsState) _then) = _$FriendsStateCopyWithImpl;
@useResult
$Res call({
 List<UserModel> friends, List<FriendRequestModel> requests, List<UserModel> blocked, Set<int> onlineIds, Map<int, String> previews, Set<int> typingIds, bool isLoading, int? activeChatId, List<GroupModel> groups, Map<int, String> groupPreviews, int? activeGroupId
});




}
/// @nodoc
class _$FriendsStateCopyWithImpl<$Res>
    implements $FriendsStateCopyWith<$Res> {
  _$FriendsStateCopyWithImpl(this._self, this._then);

  final FriendsState _self;
  final $Res Function(FriendsState) _then;

/// Create a copy of FriendsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? friends = null,Object? requests = null,Object? blocked = null,Object? onlineIds = null,Object? previews = null,Object? typingIds = null,Object? isLoading = null,Object? activeChatId = freezed,Object? groups = null,Object? groupPreviews = null,Object? activeGroupId = freezed,}) {
  return _then(FriendsState(
friends: null == friends ? _self.friends : friends // ignore: cast_nullable_to_non_nullable
as List<UserModel>,requests: null == requests ? _self.requests : requests // ignore: cast_nullable_to_non_nullable
as List<FriendRequestModel>,blocked: null == blocked ? _self.blocked : blocked // ignore: cast_nullable_to_non_nullable
as List<UserModel>,onlineIds: null == onlineIds ? _self.onlineIds : onlineIds // ignore: cast_nullable_to_non_nullable
as Set<int>,previews: null == previews ? _self.previews : previews // ignore: cast_nullable_to_non_nullable
as Map<int, String>,typingIds: null == typingIds ? _self.typingIds : typingIds // ignore: cast_nullable_to_non_nullable
as Set<int>,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,activeChatId: freezed == activeChatId ? _self.activeChatId : activeChatId // ignore: cast_nullable_to_non_nullable
as int?,groups: null == groups ? _self.groups : groups // ignore: cast_nullable_to_non_nullable
as List<GroupModel>,groupPreviews: null == groupPreviews ? _self.groupPreviews : groupPreviews // ignore: cast_nullable_to_non_nullable
as Map<int, String>,activeGroupId: freezed == activeGroupId ? _self.activeGroupId : activeGroupId // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [FriendsState].
extension FriendsStatePatterns on FriendsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FriendsState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FriendsState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FriendsState value)  $default,){
final _that = this;
switch (_that) {
case _FriendsState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FriendsState value)?  $default,){
final _that = this;
switch (_that) {
case _FriendsState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<UserModel> friends,  List<FriendRequestModel> requests,  List<UserModel> blocked,  Set<int> onlineIds,  Map<int, String> previews,  Set<int> typingIds,  bool isLoading,  int? activeChatId,  List<GroupModel> groups,  Map<int, String> groupPreviews,  int? activeGroupId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FriendsState() when $default != null:
return $default(_that.friends,_that.requests,_that.blocked,_that.onlineIds,_that.previews,_that.typingIds,_that.isLoading,_that.activeChatId,_that.groups,_that.groupPreviews,_that.activeGroupId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<UserModel> friends,  List<FriendRequestModel> requests,  List<UserModel> blocked,  Set<int> onlineIds,  Map<int, String> previews,  Set<int> typingIds,  bool isLoading,  int? activeChatId,  List<GroupModel> groups,  Map<int, String> groupPreviews,  int? activeGroupId)  $default,) {final _that = this;
switch (_that) {
case _FriendsState():
return $default(_that.friends,_that.requests,_that.blocked,_that.onlineIds,_that.previews,_that.typingIds,_that.isLoading,_that.activeChatId,_that.groups,_that.groupPreviews,_that.activeGroupId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<UserModel> friends,  List<FriendRequestModel> requests,  List<UserModel> blocked,  Set<int> onlineIds,  Map<int, String> previews,  Set<int> typingIds,  bool isLoading,  int? activeChatId,  List<GroupModel> groups,  Map<int, String> groupPreviews,  int? activeGroupId)?  $default,) {final _that = this;
switch (_that) {
case _FriendsState() when $default != null:
return $default(_that.friends,_that.requests,_that.blocked,_that.onlineIds,_that.previews,_that.typingIds,_that.isLoading,_that.activeChatId,_that.groups,_that.groupPreviews,_that.activeGroupId);case _:
  return null;

}
}

}

/// @nodoc


class _FriendsState extends FriendsState {
  const _FriendsState({ List<UserModel> friends = const [],  List<FriendRequestModel> requests = const [],  List<UserModel> blocked = const [],  Set<int> onlineIds = const {},  Map<int, String> previews = const {},  Set<int> typingIds = const {}, this.isLoading = true, this.activeChatId,  List<GroupModel> groups = const [],  Map<int, String> groupPreviews = const {}, this.activeGroupId}): _friends = friends,_requests = requests,_blocked = blocked,_onlineIds = onlineIds,_previews = previews,_typingIds = typingIds,_groups = groups,_groupPreviews = groupPreviews,super._();
  

/// Sorted by most recent message first.
 final  List<UserModel> _friends;
/// Sorted by most recent message first.
@override@JsonKey() List<UserModel> get friends {
  if (_friends is EqualUnmodifiableListView) return _friends;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_friends);
}

 final  List<FriendRequestModel> _requests;
@override@JsonKey() List<FriendRequestModel> get requests {
  if (_requests is EqualUnmodifiableListView) return _requests;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_requests);
}

 final  List<UserModel> _blocked;
@override@JsonKey() List<UserModel> get blocked {
  if (_blocked is EqualUnmodifiableListView) return _blocked;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_blocked);
}

 final  Set<int> _onlineIds;
@override@JsonKey() Set<int> get onlineIds {
  if (_onlineIds is EqualUnmodifiableSetView) return _onlineIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_onlineIds);
}

/// Decrypted one-line preview of each friend's last message.
 final  Map<int, String> _previews;
/// Decrypted one-line preview of each friend's last message.
@override@JsonKey() Map<int, String> get previews {
  if (_previews is EqualUnmodifiableMapView) return _previews;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_previews);
}

 final  Set<int> _typingIds;
@override@JsonKey() Set<int> get typingIds {
  if (_typingIds is EqualUnmodifiableSetView) return _typingIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_typingIds);
}

@override@JsonKey() final  bool isLoading;
@override final  int? activeChatId;
/// Encrypted group chats, most recent first; previews keyed by group id.
 final  List<GroupModel> _groups;
/// Encrypted group chats, most recent first; previews keyed by group id.
@override@JsonKey() List<GroupModel> get groups {
  if (_groups is EqualUnmodifiableListView) return _groups;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_groups);
}

 final  Map<int, String> _groupPreviews;
@override@JsonKey() Map<int, String> get groupPreviews {
  if (_groupPreviews is EqualUnmodifiableMapView) return _groupPreviews;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_groupPreviews);
}

@override final  int? activeGroupId;

/// Create a copy of FriendsState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FriendsStateCopyWith<_FriendsState> get copyWith => __$FriendsStateCopyWithImpl<_FriendsState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _FriendsState&&const DeepCollectionEquality().equals(other.friends, _friends)&&const DeepCollectionEquality().equals(other.requests, _requests)&&const DeepCollectionEquality().equals(other.blocked, _blocked)&&const DeepCollectionEquality().equals(other.onlineIds, _onlineIds)&&const DeepCollectionEquality().equals(other.previews, _previews)&&const DeepCollectionEquality().equals(other.typingIds, _typingIds)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.activeChatId, activeChatId) || other.activeChatId == activeChatId)&&const DeepCollectionEquality().equals(other.groups, _groups)&&const DeepCollectionEquality().equals(other.groupPreviews, _groupPreviews)&&(identical(other.activeGroupId, activeGroupId) || other.activeGroupId == activeGroupId));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_friends),const DeepCollectionEquality().hash(_requests),const DeepCollectionEquality().hash(_blocked),const DeepCollectionEquality().hash(_onlineIds),const DeepCollectionEquality().hash(_previews),const DeepCollectionEquality().hash(_typingIds),isLoading,activeChatId,const DeepCollectionEquality().hash(_groups),const DeepCollectionEquality().hash(_groupPreviews),activeGroupId);
}

@override
String toString() {
    return 'FriendsState(friends: $friends, requests: $requests, blocked: $blocked, onlineIds: $onlineIds, previews: $previews, typingIds: $typingIds, isLoading: $isLoading, activeChatId: $activeChatId, groups: $groups, groupPreviews: $groupPreviews, activeGroupId: $activeGroupId)';
}


}

/// @nodoc
abstract mixin class _$FriendsStateCopyWith<$Res> implements $FriendsStateCopyWith<$Res> {
  factory _$FriendsStateCopyWith(_FriendsState value, $Res Function(_FriendsState) _then) = __$FriendsStateCopyWithImpl;
@override @useResult
$Res call({
 List<UserModel> friends, List<FriendRequestModel> requests, List<UserModel> blocked, Set<int> onlineIds, Map<int, String> previews, Set<int> typingIds, bool isLoading, int? activeChatId, List<GroupModel> groups, Map<int, String> groupPreviews, int? activeGroupId
});




}
/// @nodoc
class __$FriendsStateCopyWithImpl<$Res>
    implements _$FriendsStateCopyWith<$Res> {
  __$FriendsStateCopyWithImpl(this._self, this._then);

  final _FriendsState _self;
  final $Res Function(_FriendsState) _then;

/// Create a copy of FriendsState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? friends = null,Object? requests = null,Object? blocked = null,Object? onlineIds = null,Object? previews = null,Object? typingIds = null,Object? isLoading = null,Object? activeChatId = freezed,Object? groups = null,Object? groupPreviews = null,Object? activeGroupId = freezed,}) {
  return _then(_FriendsState(
friends: null == friends ? _self._friends : friends // ignore: cast_nullable_to_non_nullable
as List<UserModel>,requests: null == requests ? _self._requests : requests // ignore: cast_nullable_to_non_nullable
as List<FriendRequestModel>,blocked: null == blocked ? _self._blocked : blocked // ignore: cast_nullable_to_non_nullable
as List<UserModel>,onlineIds: null == onlineIds ? _self._onlineIds : onlineIds // ignore: cast_nullable_to_non_nullable
as Set<int>,previews: null == previews ? _self._previews : previews // ignore: cast_nullable_to_non_nullable
as Map<int, String>,typingIds: null == typingIds ? _self._typingIds : typingIds // ignore: cast_nullable_to_non_nullable
as Set<int>,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,activeChatId: freezed == activeChatId ? _self.activeChatId : activeChatId // ignore: cast_nullable_to_non_nullable
as int?,groups: null == groups ? _self._groups : groups // ignore: cast_nullable_to_non_nullable
as List<GroupModel>,groupPreviews: null == groupPreviews ? _self._groupPreviews : groupPreviews // ignore: cast_nullable_to_non_nullable
as Map<int, String>,activeGroupId: freezed == activeGroupId ? _self.activeGroupId : activeGroupId // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on

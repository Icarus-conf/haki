// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'settings_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SettingsState {

 Set<int> get pinnedIds; List<ChatFolder> get folders;/// Chats (ChatFolder keys) that need Face ID / passcode to open. Hidden from the list.
 Set<String> get lockedChats;/// Private notes about contacts (friend id -> text). Only on your phones and in your sealed backup.
 Map<int, String> get notes;/// Each friend's key as first seen (friend id -> fingerprint). A different key later is a warning.
 Map<int, String> get keyPins;/// Friends whose key changed since it was pinned, until you look at the new safety number.
 Set<int> get keyChanged;
/// Create a copy of SettingsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SettingsStateCopyWith<SettingsState> get copyWith => _$SettingsStateCopyWithImpl<SettingsState>(this as SettingsState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SettingsState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SettingsState&&const DeepCollectionEquality().equals(other.pinnedIds, _this.pinnedIds)&&const DeepCollectionEquality().equals(other.folders, _this.folders)&&const DeepCollectionEquality().equals(other.lockedChats, _this.lockedChats)&&const DeepCollectionEquality().equals(other.notes, _this.notes)&&const DeepCollectionEquality().equals(other.keyPins, _this.keyPins)&&const DeepCollectionEquality().equals(other.keyChanged, _this.keyChanged));
}


@override
int get hashCode {
  final _this = this as SettingsState;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.pinnedIds),const DeepCollectionEquality().hash(_this.folders),const DeepCollectionEquality().hash(_this.lockedChats),const DeepCollectionEquality().hash(_this.notes),const DeepCollectionEquality().hash(_this.keyPins),const DeepCollectionEquality().hash(_this.keyChanged));
}

@override
String toString() {
  final _this = this as SettingsState;
  return 'SettingsState(pinnedIds: ${_this.pinnedIds}, folders: ${_this.folders}, lockedChats: ${_this.lockedChats}, notes: ${_this.notes}, keyPins: ${_this.keyPins}, keyChanged: ${_this.keyChanged})';
}


}

/// @nodoc
abstract mixin class $SettingsStateCopyWith<$Res>  {
  factory $SettingsStateCopyWith(SettingsState value, $Res Function(SettingsState) _then) = _$SettingsStateCopyWithImpl;
@useResult
$Res call({
 Set<int> pinnedIds, List<ChatFolder> folders, Set<String> lockedChats, Map<int, String> notes, Map<int, String> keyPins, Set<int> keyChanged
});




}
/// @nodoc
class _$SettingsStateCopyWithImpl<$Res>
    implements $SettingsStateCopyWith<$Res> {
  _$SettingsStateCopyWithImpl(this._self, this._then);

  final SettingsState _self;
  final $Res Function(SettingsState) _then;

/// Create a copy of SettingsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? pinnedIds = null,Object? folders = null,Object? lockedChats = null,Object? notes = null,Object? keyPins = null,Object? keyChanged = null,}) {
  return _then(SettingsState(
pinnedIds: null == pinnedIds ? _self.pinnedIds : pinnedIds // ignore: cast_nullable_to_non_nullable
as Set<int>,folders: null == folders ? _self.folders : folders // ignore: cast_nullable_to_non_nullable
as List<ChatFolder>,lockedChats: null == lockedChats ? _self.lockedChats : lockedChats // ignore: cast_nullable_to_non_nullable
as Set<String>,notes: null == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as Map<int, String>,keyPins: null == keyPins ? _self.keyPins : keyPins // ignore: cast_nullable_to_non_nullable
as Map<int, String>,keyChanged: null == keyChanged ? _self.keyChanged : keyChanged // ignore: cast_nullable_to_non_nullable
as Set<int>,
  ));
}

}


/// Adds pattern-matching-related methods to [SettingsState].
extension SettingsStatePatterns on SettingsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SettingsState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SettingsState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SettingsState value)  $default,){
final _that = this;
switch (_that) {
case _SettingsState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SettingsState value)?  $default,){
final _that = this;
switch (_that) {
case _SettingsState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Set<int> pinnedIds,  List<ChatFolder> folders,  Set<String> lockedChats,  Map<int, String> notes,  Map<int, String> keyPins,  Set<int> keyChanged)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SettingsState() when $default != null:
return $default(_that.pinnedIds,_that.folders,_that.lockedChats,_that.notes,_that.keyPins,_that.keyChanged);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Set<int> pinnedIds,  List<ChatFolder> folders,  Set<String> lockedChats,  Map<int, String> notes,  Map<int, String> keyPins,  Set<int> keyChanged)  $default,) {final _that = this;
switch (_that) {
case _SettingsState():
return $default(_that.pinnedIds,_that.folders,_that.lockedChats,_that.notes,_that.keyPins,_that.keyChanged);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Set<int> pinnedIds,  List<ChatFolder> folders,  Set<String> lockedChats,  Map<int, String> notes,  Map<int, String> keyPins,  Set<int> keyChanged)?  $default,) {final _that = this;
switch (_that) {
case _SettingsState() when $default != null:
return $default(_that.pinnedIds,_that.folders,_that.lockedChats,_that.notes,_that.keyPins,_that.keyChanged);case _:
  return null;

}
}

}

/// @nodoc


class _SettingsState implements SettingsState {
  const _SettingsState({ Set<int> pinnedIds = const {},  List<ChatFolder> folders = const [],  Set<String> lockedChats = const {},  Map<int, String> notes = const {},  Map<int, String> keyPins = const {},  Set<int> keyChanged = const {}}): _pinnedIds = pinnedIds,_folders = folders,_lockedChats = lockedChats,_notes = notes,_keyPins = keyPins,_keyChanged = keyChanged;
  

 final  Set<int> _pinnedIds;
@override@JsonKey() Set<int> get pinnedIds {
  if (_pinnedIds is EqualUnmodifiableSetView) return _pinnedIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_pinnedIds);
}

 final  List<ChatFolder> _folders;
@override@JsonKey() List<ChatFolder> get folders {
  if (_folders is EqualUnmodifiableListView) return _folders;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_folders);
}

/// Chats (ChatFolder keys) that need Face ID / passcode to open. Hidden from the list.
 final  Set<String> _lockedChats;
/// Chats (ChatFolder keys) that need Face ID / passcode to open. Hidden from the list.
@override@JsonKey() Set<String> get lockedChats {
  if (_lockedChats is EqualUnmodifiableSetView) return _lockedChats;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_lockedChats);
}

/// Private notes about contacts (friend id -> text). Only on your phones and in your sealed backup.
 final  Map<int, String> _notes;
/// Private notes about contacts (friend id -> text). Only on your phones and in your sealed backup.
@override@JsonKey() Map<int, String> get notes {
  if (_notes is EqualUnmodifiableMapView) return _notes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_notes);
}

/// Each friend's key as first seen (friend id -> fingerprint). A different key later is a warning.
 final  Map<int, String> _keyPins;
/// Each friend's key as first seen (friend id -> fingerprint). A different key later is a warning.
@override@JsonKey() Map<int, String> get keyPins {
  if (_keyPins is EqualUnmodifiableMapView) return _keyPins;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_keyPins);
}

/// Friends whose key changed since it was pinned, until you look at the new safety number.
 final  Set<int> _keyChanged;
/// Friends whose key changed since it was pinned, until you look at the new safety number.
@override@JsonKey() Set<int> get keyChanged {
  if (_keyChanged is EqualUnmodifiableSetView) return _keyChanged;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_keyChanged);
}


/// Create a copy of SettingsState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SettingsStateCopyWith<_SettingsState> get copyWith => __$SettingsStateCopyWithImpl<_SettingsState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SettingsState&&const DeepCollectionEquality().equals(other.pinnedIds, _pinnedIds)&&const DeepCollectionEquality().equals(other.folders, _folders)&&const DeepCollectionEquality().equals(other.lockedChats, _lockedChats)&&const DeepCollectionEquality().equals(other.notes, _notes)&&const DeepCollectionEquality().equals(other.keyPins, _keyPins)&&const DeepCollectionEquality().equals(other.keyChanged, _keyChanged));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_pinnedIds),const DeepCollectionEquality().hash(_folders),const DeepCollectionEquality().hash(_lockedChats),const DeepCollectionEquality().hash(_notes),const DeepCollectionEquality().hash(_keyPins),const DeepCollectionEquality().hash(_keyChanged));
}

@override
String toString() {
    return 'SettingsState(pinnedIds: $pinnedIds, folders: $folders, lockedChats: $lockedChats, notes: $notes, keyPins: $keyPins, keyChanged: $keyChanged)';
}


}

/// @nodoc
abstract mixin class _$SettingsStateCopyWith<$Res> implements $SettingsStateCopyWith<$Res> {
  factory _$SettingsStateCopyWith(_SettingsState value, $Res Function(_SettingsState) _then) = __$SettingsStateCopyWithImpl;
@override @useResult
$Res call({
 Set<int> pinnedIds, List<ChatFolder> folders, Set<String> lockedChats, Map<int, String> notes, Map<int, String> keyPins, Set<int> keyChanged
});




}
/// @nodoc
class __$SettingsStateCopyWithImpl<$Res>
    implements _$SettingsStateCopyWith<$Res> {
  __$SettingsStateCopyWithImpl(this._self, this._then);

  final _SettingsState _self;
  final $Res Function(_SettingsState) _then;

/// Create a copy of SettingsState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? pinnedIds = null,Object? folders = null,Object? lockedChats = null,Object? notes = null,Object? keyPins = null,Object? keyChanged = null,}) {
  return _then(_SettingsState(
pinnedIds: null == pinnedIds ? _self._pinnedIds : pinnedIds // ignore: cast_nullable_to_non_nullable
as Set<int>,folders: null == folders ? _self._folders : folders // ignore: cast_nullable_to_non_nullable
as List<ChatFolder>,lockedChats: null == lockedChats ? _self._lockedChats : lockedChats // ignore: cast_nullable_to_non_nullable
as Set<String>,notes: null == notes ? _self._notes : notes // ignore: cast_nullable_to_non_nullable
as Map<int, String>,keyPins: null == keyPins ? _self._keyPins : keyPins // ignore: cast_nullable_to_non_nullable
as Map<int, String>,keyChanged: null == keyChanged ? _self._keyChanged : keyChanged // ignore: cast_nullable_to_non_nullable
as Set<int>,
  ));
}


}

// dart format on

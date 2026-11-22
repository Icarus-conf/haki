// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'group_call_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$GroupCallState {

/// Calls running in my groups: group id -> who is in it (from the server).
 Map<int, List<int>> get active;/// The group call I'm in (or joining).
 int? get groupId; bool get video; bool get muted; bool get cameraOff; bool get speakerOn;/// Remote audio/video per person, and my own camera (null on voice calls).
 Map<int, MediaStream> get streams; MediaStream? get local;/// A call someone just started in one of my groups (shown as a banner until answered).
 int? get ringing; String? get error;
/// Create a copy of GroupCallState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GroupCallStateCopyWith<GroupCallState> get copyWith => _$GroupCallStateCopyWithImpl<GroupCallState>(this as GroupCallState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as GroupCallState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GroupCallState&&const DeepCollectionEquality().equals(other.active, _this.active)&&(identical(other.groupId, _this.groupId) || other.groupId == _this.groupId)&&(identical(other.video, _this.video) || other.video == _this.video)&&(identical(other.muted, _this.muted) || other.muted == _this.muted)&&(identical(other.cameraOff, _this.cameraOff) || other.cameraOff == _this.cameraOff)&&(identical(other.speakerOn, _this.speakerOn) || other.speakerOn == _this.speakerOn)&&const DeepCollectionEquality().equals(other.streams, _this.streams)&&(identical(other.local, _this.local) || other.local == _this.local)&&(identical(other.ringing, _this.ringing) || other.ringing == _this.ringing)&&(identical(other.error, _this.error) || other.error == _this.error));
}


@override
int get hashCode {
  final _this = this as GroupCallState;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.active),_this.groupId,_this.video,_this.muted,_this.cameraOff,_this.speakerOn,const DeepCollectionEquality().hash(_this.streams),_this.local,_this.ringing,_this.error);
}

@override
String toString() {
  final _this = this as GroupCallState;
  return 'GroupCallState(active: ${_this.active}, groupId: ${_this.groupId}, video: ${_this.video}, muted: ${_this.muted}, cameraOff: ${_this.cameraOff}, speakerOn: ${_this.speakerOn}, streams: ${_this.streams}, local: ${_this.local}, ringing: ${_this.ringing}, error: ${_this.error})';
}


}

/// @nodoc
abstract mixin class $GroupCallStateCopyWith<$Res>  {
  factory $GroupCallStateCopyWith(GroupCallState value, $Res Function(GroupCallState) _then) = _$GroupCallStateCopyWithImpl;
@useResult
$Res call({
 Map<int, List<int>> active, int? groupId, bool video, bool muted, bool cameraOff, bool speakerOn, Map<int, MediaStream> streams, MediaStream? local, int? ringing, String? error
});




}
/// @nodoc
class _$GroupCallStateCopyWithImpl<$Res>
    implements $GroupCallStateCopyWith<$Res> {
  _$GroupCallStateCopyWithImpl(this._self, this._then);

  final GroupCallState _self;
  final $Res Function(GroupCallState) _then;

/// Create a copy of GroupCallState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? active = null,Object? groupId = freezed,Object? video = null,Object? muted = null,Object? cameraOff = null,Object? speakerOn = null,Object? streams = null,Object? local = freezed,Object? ringing = freezed,Object? error = freezed,}) {
  return _then(GroupCallState(
active: null == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as Map<int, List<int>>,groupId: freezed == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as int?,video: null == video ? _self.video : video // ignore: cast_nullable_to_non_nullable
as bool,muted: null == muted ? _self.muted : muted // ignore: cast_nullable_to_non_nullable
as bool,cameraOff: null == cameraOff ? _self.cameraOff : cameraOff // ignore: cast_nullable_to_non_nullable
as bool,speakerOn: null == speakerOn ? _self.speakerOn : speakerOn // ignore: cast_nullable_to_non_nullable
as bool,streams: null == streams ? _self.streams : streams // ignore: cast_nullable_to_non_nullable
as Map<int, MediaStream>,local: freezed == local ? _self.local : local // ignore: cast_nullable_to_non_nullable
as MediaStream?,ringing: freezed == ringing ? _self.ringing : ringing // ignore: cast_nullable_to_non_nullable
as int?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [GroupCallState].
extension GroupCallStatePatterns on GroupCallState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GroupCallState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GroupCallState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GroupCallState value)  $default,){
final _that = this;
switch (_that) {
case _GroupCallState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GroupCallState value)?  $default,){
final _that = this;
switch (_that) {
case _GroupCallState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Map<int, List<int>> active,  int? groupId,  bool video,  bool muted,  bool cameraOff,  bool speakerOn,  Map<int, MediaStream> streams,  MediaStream? local,  int? ringing,  String? error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GroupCallState() when $default != null:
return $default(_that.active,_that.groupId,_that.video,_that.muted,_that.cameraOff,_that.speakerOn,_that.streams,_that.local,_that.ringing,_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Map<int, List<int>> active,  int? groupId,  bool video,  bool muted,  bool cameraOff,  bool speakerOn,  Map<int, MediaStream> streams,  MediaStream? local,  int? ringing,  String? error)  $default,) {final _that = this;
switch (_that) {
case _GroupCallState():
return $default(_that.active,_that.groupId,_that.video,_that.muted,_that.cameraOff,_that.speakerOn,_that.streams,_that.local,_that.ringing,_that.error);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Map<int, List<int>> active,  int? groupId,  bool video,  bool muted,  bool cameraOff,  bool speakerOn,  Map<int, MediaStream> streams,  MediaStream? local,  int? ringing,  String? error)?  $default,) {final _that = this;
switch (_that) {
case _GroupCallState() when $default != null:
return $default(_that.active,_that.groupId,_that.video,_that.muted,_that.cameraOff,_that.speakerOn,_that.streams,_that.local,_that.ringing,_that.error);case _:
  return null;

}
}

}

/// @nodoc


class _GroupCallState extends GroupCallState {
  const _GroupCallState({ Map<int, List<int>> active = const {}, this.groupId, this.video = false, this.muted = false, this.cameraOff = false, this.speakerOn = true,  Map<int, MediaStream> streams = const {}, this.local, this.ringing, this.error}): _active = active,_streams = streams,super._();
  

/// Calls running in my groups: group id -> who is in it (from the server).
 final  Map<int, List<int>> _active;
/// Calls running in my groups: group id -> who is in it (from the server).
@override@JsonKey() Map<int, List<int>> get active {
  if (_active is EqualUnmodifiableMapView) return _active;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_active);
}

/// The group call I'm in (or joining).
@override final  int? groupId;
@override@JsonKey() final  bool video;
@override@JsonKey() final  bool muted;
@override@JsonKey() final  bool cameraOff;
@override@JsonKey() final  bool speakerOn;
/// Remote audio/video per person, and my own camera (null on voice calls).
 final  Map<int, MediaStream> _streams;
/// Remote audio/video per person, and my own camera (null on voice calls).
@override@JsonKey() Map<int, MediaStream> get streams {
  if (_streams is EqualUnmodifiableMapView) return _streams;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_streams);
}

@override final  MediaStream? local;
/// A call someone just started in one of my groups (shown as a banner until answered).
@override final  int? ringing;
@override final  String? error;

/// Create a copy of GroupCallState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GroupCallStateCopyWith<_GroupCallState> get copyWith => __$GroupCallStateCopyWithImpl<_GroupCallState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _GroupCallState&&const DeepCollectionEquality().equals(other.active, _active)&&(identical(other.groupId, groupId) || other.groupId == groupId)&&(identical(other.video, video) || other.video == video)&&(identical(other.muted, muted) || other.muted == muted)&&(identical(other.cameraOff, cameraOff) || other.cameraOff == cameraOff)&&(identical(other.speakerOn, speakerOn) || other.speakerOn == speakerOn)&&const DeepCollectionEquality().equals(other.streams, _streams)&&(identical(other.local, local) || other.local == local)&&(identical(other.ringing, ringing) || other.ringing == ringing)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_active),groupId,video,muted,cameraOff,speakerOn,const DeepCollectionEquality().hash(_streams),local,ringing,error);
}

@override
String toString() {
    return 'GroupCallState(active: $active, groupId: $groupId, video: $video, muted: $muted, cameraOff: $cameraOff, speakerOn: $speakerOn, streams: $streams, local: $local, ringing: $ringing, error: $error)';
}


}

/// @nodoc
abstract mixin class _$GroupCallStateCopyWith<$Res> implements $GroupCallStateCopyWith<$Res> {
  factory _$GroupCallStateCopyWith(_GroupCallState value, $Res Function(_GroupCallState) _then) = __$GroupCallStateCopyWithImpl;
@override @useResult
$Res call({
 Map<int, List<int>> active, int? groupId, bool video, bool muted, bool cameraOff, bool speakerOn, Map<int, MediaStream> streams, MediaStream? local, int? ringing, String? error
});




}
/// @nodoc
class __$GroupCallStateCopyWithImpl<$Res>
    implements _$GroupCallStateCopyWith<$Res> {
  __$GroupCallStateCopyWithImpl(this._self, this._then);

  final _GroupCallState _self;
  final $Res Function(_GroupCallState) _then;

/// Create a copy of GroupCallState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? active = null,Object? groupId = freezed,Object? video = null,Object? muted = null,Object? cameraOff = null,Object? speakerOn = null,Object? streams = null,Object? local = freezed,Object? ringing = freezed,Object? error = freezed,}) {
  return _then(_GroupCallState(
active: null == active ? _self._active : active // ignore: cast_nullable_to_non_nullable
as Map<int, List<int>>,groupId: freezed == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as int?,video: null == video ? _self.video : video // ignore: cast_nullable_to_non_nullable
as bool,muted: null == muted ? _self.muted : muted // ignore: cast_nullable_to_non_nullable
as bool,cameraOff: null == cameraOff ? _self.cameraOff : cameraOff // ignore: cast_nullable_to_non_nullable
as bool,speakerOn: null == speakerOn ? _self.speakerOn : speakerOn // ignore: cast_nullable_to_non_nullable
as bool,streams: null == streams ? _self._streams : streams // ignore: cast_nullable_to_non_nullable
as Map<int, MediaStream>,local: freezed == local ? _self.local : local // ignore: cast_nullable_to_non_nullable
as MediaStream?,ringing: freezed == ringing ? _self.ringing : ringing // ignore: cast_nullable_to_non_nullable
as int?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on

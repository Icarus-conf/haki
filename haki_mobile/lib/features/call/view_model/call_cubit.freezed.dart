// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'call_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CallState {

 CallPhase get phase; int? get peerId; bool get video; bool get cameraOff; bool get speakerOn; bool get muted; DateTime? get connectedAt; String? get endReason;
/// Create a copy of CallState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CallStateCopyWith<CallState> get copyWith => _$CallStateCopyWithImpl<CallState>(this as CallState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CallState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CallState&&(identical(other.phase, _this.phase) || other.phase == _this.phase)&&(identical(other.peerId, _this.peerId) || other.peerId == _this.peerId)&&(identical(other.video, _this.video) || other.video == _this.video)&&(identical(other.cameraOff, _this.cameraOff) || other.cameraOff == _this.cameraOff)&&(identical(other.speakerOn, _this.speakerOn) || other.speakerOn == _this.speakerOn)&&(identical(other.muted, _this.muted) || other.muted == _this.muted)&&(identical(other.connectedAt, _this.connectedAt) || other.connectedAt == _this.connectedAt)&&(identical(other.endReason, _this.endReason) || other.endReason == _this.endReason));
}


@override
int get hashCode {
  final _this = this as CallState;
  return Object.hash(runtimeType,_this.phase,_this.peerId,_this.video,_this.cameraOff,_this.speakerOn,_this.muted,_this.connectedAt,_this.endReason);
}

@override
String toString() {
  final _this = this as CallState;
  return 'CallState(phase: ${_this.phase}, peerId: ${_this.peerId}, video: ${_this.video}, cameraOff: ${_this.cameraOff}, speakerOn: ${_this.speakerOn}, muted: ${_this.muted}, connectedAt: ${_this.connectedAt}, endReason: ${_this.endReason})';
}


}

/// @nodoc
abstract mixin class $CallStateCopyWith<$Res>  {
  factory $CallStateCopyWith(CallState value, $Res Function(CallState) _then) = _$CallStateCopyWithImpl;
@useResult
$Res call({
 CallPhase phase, int? peerId, bool video, bool cameraOff, bool speakerOn, bool muted, DateTime? connectedAt, String? endReason
});




}
/// @nodoc
class _$CallStateCopyWithImpl<$Res>
    implements $CallStateCopyWith<$Res> {
  _$CallStateCopyWithImpl(this._self, this._then);

  final CallState _self;
  final $Res Function(CallState) _then;

/// Create a copy of CallState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? phase = null,Object? peerId = freezed,Object? video = null,Object? cameraOff = null,Object? speakerOn = null,Object? muted = null,Object? connectedAt = freezed,Object? endReason = freezed,}) {
  return _then(CallState(
phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as CallPhase,peerId: freezed == peerId ? _self.peerId : peerId // ignore: cast_nullable_to_non_nullable
as int?,video: null == video ? _self.video : video // ignore: cast_nullable_to_non_nullable
as bool,cameraOff: null == cameraOff ? _self.cameraOff : cameraOff // ignore: cast_nullable_to_non_nullable
as bool,speakerOn: null == speakerOn ? _self.speakerOn : speakerOn // ignore: cast_nullable_to_non_nullable
as bool,muted: null == muted ? _self.muted : muted // ignore: cast_nullable_to_non_nullable
as bool,connectedAt: freezed == connectedAt ? _self.connectedAt : connectedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,endReason: freezed == endReason ? _self.endReason : endReason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CallState].
extension CallStatePatterns on CallState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CallState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CallState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CallState value)  $default,){
final _that = this;
switch (_that) {
case _CallState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CallState value)?  $default,){
final _that = this;
switch (_that) {
case _CallState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( CallPhase phase,  int? peerId,  bool video,  bool cameraOff,  bool speakerOn,  bool muted,  DateTime? connectedAt,  String? endReason)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CallState() when $default != null:
return $default(_that.phase,_that.peerId,_that.video,_that.cameraOff,_that.speakerOn,_that.muted,_that.connectedAt,_that.endReason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( CallPhase phase,  int? peerId,  bool video,  bool cameraOff,  bool speakerOn,  bool muted,  DateTime? connectedAt,  String? endReason)  $default,) {final _that = this;
switch (_that) {
case _CallState():
return $default(_that.phase,_that.peerId,_that.video,_that.cameraOff,_that.speakerOn,_that.muted,_that.connectedAt,_that.endReason);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( CallPhase phase,  int? peerId,  bool video,  bool cameraOff,  bool speakerOn,  bool muted,  DateTime? connectedAt,  String? endReason)?  $default,) {final _that = this;
switch (_that) {
case _CallState() when $default != null:
return $default(_that.phase,_that.peerId,_that.video,_that.cameraOff,_that.speakerOn,_that.muted,_that.connectedAt,_that.endReason);case _:
  return null;

}
}

}

/// @nodoc


class _CallState implements CallState {
  const _CallState({this.phase = CallPhase.idle, this.peerId, this.video = false, this.cameraOff = false, this.speakerOn = false, this.muted = false, this.connectedAt, this.endReason});
  

@override@JsonKey() final  CallPhase phase;
@override final  int? peerId;
@override@JsonKey() final  bool video;
@override@JsonKey() final  bool cameraOff;
@override@JsonKey() final  bool speakerOn;
@override@JsonKey() final  bool muted;
@override final  DateTime? connectedAt;
@override final  String? endReason;

/// Create a copy of CallState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CallStateCopyWith<_CallState> get copyWith => __$CallStateCopyWithImpl<_CallState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CallState&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.peerId, peerId) || other.peerId == peerId)&&(identical(other.video, video) || other.video == video)&&(identical(other.cameraOff, cameraOff) || other.cameraOff == cameraOff)&&(identical(other.speakerOn, speakerOn) || other.speakerOn == speakerOn)&&(identical(other.muted, muted) || other.muted == muted)&&(identical(other.connectedAt, connectedAt) || other.connectedAt == connectedAt)&&(identical(other.endReason, endReason) || other.endReason == endReason));
}


@override
int get hashCode {
    return Object.hash(runtimeType,phase,peerId,video,cameraOff,speakerOn,muted,connectedAt,endReason);
}

@override
String toString() {
    return 'CallState(phase: $phase, peerId: $peerId, video: $video, cameraOff: $cameraOff, speakerOn: $speakerOn, muted: $muted, connectedAt: $connectedAt, endReason: $endReason)';
}


}

/// @nodoc
abstract mixin class _$CallStateCopyWith<$Res> implements $CallStateCopyWith<$Res> {
  factory _$CallStateCopyWith(_CallState value, $Res Function(_CallState) _then) = __$CallStateCopyWithImpl;
@override @useResult
$Res call({
 CallPhase phase, int? peerId, bool video, bool cameraOff, bool speakerOn, bool muted, DateTime? connectedAt, String? endReason
});




}
/// @nodoc
class __$CallStateCopyWithImpl<$Res>
    implements _$CallStateCopyWith<$Res> {
  __$CallStateCopyWithImpl(this._self, this._then);

  final _CallState _self;
  final $Res Function(_CallState) _then;

/// Create a copy of CallState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? phase = null,Object? peerId = freezed,Object? video = null,Object? cameraOff = null,Object? speakerOn = null,Object? muted = null,Object? connectedAt = freezed,Object? endReason = freezed,}) {
  return _then(_CallState(
phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as CallPhase,peerId: freezed == peerId ? _self.peerId : peerId // ignore: cast_nullable_to_non_nullable
as int?,video: null == video ? _self.video : video // ignore: cast_nullable_to_non_nullable
as bool,cameraOff: null == cameraOff ? _self.cameraOff : cameraOff // ignore: cast_nullable_to_non_nullable
as bool,speakerOn: null == speakerOn ? _self.speakerOn : speakerOn // ignore: cast_nullable_to_non_nullable
as bool,muted: null == muted ? _self.muted : muted // ignore: cast_nullable_to_non_nullable
as bool,connectedAt: freezed == connectedAt ? _self.connectedAt : connectedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,endReason: freezed == endReason ? _self.endReason : endReason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on

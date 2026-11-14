// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'stories_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$StoriesState {

 List<StoryModel> get stories; bool get isPosting;
/// Create a copy of StoriesState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StoriesStateCopyWith<StoriesState> get copyWith => _$StoriesStateCopyWithImpl<StoriesState>(this as StoriesState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as StoriesState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StoriesState&&const DeepCollectionEquality().equals(other.stories, _this.stories)&&(identical(other.isPosting, _this.isPosting) || other.isPosting == _this.isPosting));
}


@override
int get hashCode {
  final _this = this as StoriesState;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.stories),_this.isPosting);
}

@override
String toString() {
  final _this = this as StoriesState;
  return 'StoriesState(stories: ${_this.stories}, isPosting: ${_this.isPosting})';
}


}

/// @nodoc
abstract mixin class $StoriesStateCopyWith<$Res>  {
  factory $StoriesStateCopyWith(StoriesState value, $Res Function(StoriesState) _then) = _$StoriesStateCopyWithImpl;
@useResult
$Res call({
 List<StoryModel> stories, bool isPosting
});




}
/// @nodoc
class _$StoriesStateCopyWithImpl<$Res>
    implements $StoriesStateCopyWith<$Res> {
  _$StoriesStateCopyWithImpl(this._self, this._then);

  final StoriesState _self;
  final $Res Function(StoriesState) _then;

/// Create a copy of StoriesState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? stories = null,Object? isPosting = null,}) {
  return _then(StoriesState(
stories: null == stories ? _self.stories : stories // ignore: cast_nullable_to_non_nullable
as List<StoryModel>,isPosting: null == isPosting ? _self.isPosting : isPosting // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [StoriesState].
extension StoriesStatePatterns on StoriesState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StoriesState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StoriesState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StoriesState value)  $default,){
final _that = this;
switch (_that) {
case _StoriesState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StoriesState value)?  $default,){
final _that = this;
switch (_that) {
case _StoriesState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<StoryModel> stories,  bool isPosting)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StoriesState() when $default != null:
return $default(_that.stories,_that.isPosting);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<StoryModel> stories,  bool isPosting)  $default,) {final _that = this;
switch (_that) {
case _StoriesState():
return $default(_that.stories,_that.isPosting);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<StoryModel> stories,  bool isPosting)?  $default,) {final _that = this;
switch (_that) {
case _StoriesState() when $default != null:
return $default(_that.stories,_that.isPosting);case _:
  return null;

}
}

}

/// @nodoc


class _StoriesState extends StoriesState {
  const _StoriesState({ List<StoryModel> stories = const [], this.isPosting = false}): _stories = stories,super._();
  

 final  List<StoryModel> _stories;
@override@JsonKey() List<StoryModel> get stories {
  if (_stories is EqualUnmodifiableListView) return _stories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_stories);
}

@override@JsonKey() final  bool isPosting;

/// Create a copy of StoriesState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StoriesStateCopyWith<_StoriesState> get copyWith => __$StoriesStateCopyWithImpl<_StoriesState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _StoriesState&&const DeepCollectionEquality().equals(other.stories, _stories)&&(identical(other.isPosting, isPosting) || other.isPosting == isPosting));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_stories),isPosting);
}

@override
String toString() {
    return 'StoriesState(stories: $stories, isPosting: $isPosting)';
}


}

/// @nodoc
abstract mixin class _$StoriesStateCopyWith<$Res> implements $StoriesStateCopyWith<$Res> {
  factory _$StoriesStateCopyWith(_StoriesState value, $Res Function(_StoriesState) _then) = __$StoriesStateCopyWithImpl;
@override @useResult
$Res call({
 List<StoryModel> stories, bool isPosting
});




}
/// @nodoc
class __$StoriesStateCopyWithImpl<$Res>
    implements _$StoriesStateCopyWith<$Res> {
  __$StoriesStateCopyWithImpl(this._self, this._then);

  final _StoriesState _self;
  final $Res Function(_StoriesState) _then;

/// Create a copy of StoriesState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? stories = null,Object? isPosting = null,}) {
  return _then(_StoriesState(
stories: null == stories ? _self._stories : stories // ignore: cast_nullable_to_non_nullable
as List<StoryModel>,isPosting: null == isPosting ? _self.isPosting : isPosting // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on

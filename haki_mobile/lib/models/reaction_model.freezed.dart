// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reaction_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ReactionModel {

 int get id; String get emoji; int get userId; String get username;
/// Create a copy of ReactionModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReactionModelCopyWith<ReactionModel> get copyWith => _$ReactionModelCopyWithImpl<ReactionModel>(this as ReactionModel, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ReactionModel;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReactionModel&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.emoji, _this.emoji) || other.emoji == _this.emoji)&&(identical(other.userId, _this.userId) || other.userId == _this.userId)&&(identical(other.username, _this.username) || other.username == _this.username));
}


@override
int get hashCode {
  final _this = this as ReactionModel;
  return Object.hash(runtimeType,_this.id,_this.emoji,_this.userId,_this.username);
}

@override
String toString() {
  final _this = this as ReactionModel;
  return 'ReactionModel(id: ${_this.id}, emoji: ${_this.emoji}, userId: ${_this.userId}, username: ${_this.username})';
}


}

/// @nodoc
abstract mixin class $ReactionModelCopyWith<$Res>  {
  factory $ReactionModelCopyWith(ReactionModel value, $Res Function(ReactionModel) _then) = _$ReactionModelCopyWithImpl;
@useResult
$Res call({
 int id, String emoji, int userId, String username
});




}
/// @nodoc
class _$ReactionModelCopyWithImpl<$Res>
    implements $ReactionModelCopyWith<$Res> {
  _$ReactionModelCopyWithImpl(this._self, this._then);

  final ReactionModel _self;
  final $Res Function(ReactionModel) _then;

/// Create a copy of ReactionModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? emoji = null,Object? userId = null,Object? username = null,}) {
  return _then(ReactionModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,emoji: null == emoji ? _self.emoji : emoji // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as int,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ReactionModel].
extension ReactionModelPatterns on ReactionModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReactionModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReactionModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReactionModel value)  $default,){
final _that = this;
switch (_that) {
case _ReactionModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReactionModel value)?  $default,){
final _that = this;
switch (_that) {
case _ReactionModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String emoji,  int userId,  String username)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReactionModel() when $default != null:
return $default(_that.id,_that.emoji,_that.userId,_that.username);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String emoji,  int userId,  String username)  $default,) {final _that = this;
switch (_that) {
case _ReactionModel():
return $default(_that.id,_that.emoji,_that.userId,_that.username);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String emoji,  int userId,  String username)?  $default,) {final _that = this;
switch (_that) {
case _ReactionModel() when $default != null:
return $default(_that.id,_that.emoji,_that.userId,_that.username);case _:
  return null;

}
}

}

/// @nodoc


class _ReactionModel implements ReactionModel {
  const _ReactionModel({required this.id, required this.emoji, required this.userId, required this.username});
  

@override final  int id;
@override final  String emoji;
@override final  int userId;
@override final  String username;

/// Create a copy of ReactionModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReactionModelCopyWith<_ReactionModel> get copyWith => __$ReactionModelCopyWithImpl<_ReactionModel>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReactionModel&&(identical(other.id, id) || other.id == id)&&(identical(other.emoji, emoji) || other.emoji == emoji)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.username, username) || other.username == username));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,emoji,userId,username);
}

@override
String toString() {
    return 'ReactionModel(id: $id, emoji: $emoji, userId: $userId, username: $username)';
}


}

/// @nodoc
abstract mixin class _$ReactionModelCopyWith<$Res> implements $ReactionModelCopyWith<$Res> {
  factory _$ReactionModelCopyWith(_ReactionModel value, $Res Function(_ReactionModel) _then) = __$ReactionModelCopyWithImpl;
@override @useResult
$Res call({
 int id, String emoji, int userId, String username
});




}
/// @nodoc
class __$ReactionModelCopyWithImpl<$Res>
    implements _$ReactionModelCopyWith<$Res> {
  __$ReactionModelCopyWithImpl(this._self, this._then);

  final _ReactionModel _self;
  final $Res Function(_ReactionModel) _then;

/// Create a copy of ReactionModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? emoji = null,Object? userId = null,Object? username = null,}) {
  return _then(_ReactionModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,emoji: null == emoji ? _self.emoji : emoji // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as int,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on

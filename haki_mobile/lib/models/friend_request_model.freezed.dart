// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'friend_request_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$FriendRequestModel {

 int get id; UserModel get sender; String get status; DateTime get createdAt;
/// Create a copy of FriendRequestModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FriendRequestModelCopyWith<FriendRequestModel> get copyWith => _$FriendRequestModelCopyWithImpl<FriendRequestModel>(this as FriendRequestModel, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as FriendRequestModel;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FriendRequestModel&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.sender, _this.sender) || other.sender == _this.sender)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt));
}


@override
int get hashCode {
  final _this = this as FriendRequestModel;
  return Object.hash(runtimeType,_this.id,_this.sender,_this.status,_this.createdAt);
}

@override
String toString() {
  final _this = this as FriendRequestModel;
  return 'FriendRequestModel(id: ${_this.id}, sender: ${_this.sender}, status: ${_this.status}, createdAt: ${_this.createdAt})';
}


}

/// @nodoc
abstract mixin class $FriendRequestModelCopyWith<$Res>  {
  factory $FriendRequestModelCopyWith(FriendRequestModel value, $Res Function(FriendRequestModel) _then) = _$FriendRequestModelCopyWithImpl;
@useResult
$Res call({
 int id, UserModel sender, String status, DateTime createdAt
});


$UserModelCopyWith<$Res> get sender;

}
/// @nodoc
class _$FriendRequestModelCopyWithImpl<$Res>
    implements $FriendRequestModelCopyWith<$Res> {
  _$FriendRequestModelCopyWithImpl(this._self, this._then);

  final FriendRequestModel _self;
  final $Res Function(FriendRequestModel) _then;

/// Create a copy of FriendRequestModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? sender = null,Object? status = null,Object? createdAt = null,}) {
  return _then(FriendRequestModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,sender: null == sender ? _self.sender : sender // ignore: cast_nullable_to_non_nullable
as UserModel,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}
/// Create a copy of FriendRequestModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserModelCopyWith<$Res> get sender {
  
  return $UserModelCopyWith<$Res>(_self.sender, (value) {
    return _then(_self.copyWith(sender: value));
  });
}
}


/// Adds pattern-matching-related methods to [FriendRequestModel].
extension FriendRequestModelPatterns on FriendRequestModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FriendRequestModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FriendRequestModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FriendRequestModel value)  $default,){
final _that = this;
switch (_that) {
case _FriendRequestModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FriendRequestModel value)?  $default,){
final _that = this;
switch (_that) {
case _FriendRequestModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  UserModel sender,  String status,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FriendRequestModel() when $default != null:
return $default(_that.id,_that.sender,_that.status,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  UserModel sender,  String status,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _FriendRequestModel():
return $default(_that.id,_that.sender,_that.status,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  UserModel sender,  String status,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _FriendRequestModel() when $default != null:
return $default(_that.id,_that.sender,_that.status,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc


class _FriendRequestModel implements FriendRequestModel {
  const _FriendRequestModel({required this.id, required this.sender, required this.status, required this.createdAt});
  

@override final  int id;
@override final  UserModel sender;
@override final  String status;
@override final  DateTime createdAt;

/// Create a copy of FriendRequestModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FriendRequestModelCopyWith<_FriendRequestModel> get copyWith => __$FriendRequestModelCopyWithImpl<_FriendRequestModel>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _FriendRequestModel&&(identical(other.id, id) || other.id == id)&&(identical(other.sender, sender) || other.sender == sender)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,sender,status,createdAt);
}

@override
String toString() {
    return 'FriendRequestModel(id: $id, sender: $sender, status: $status, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$FriendRequestModelCopyWith<$Res> implements $FriendRequestModelCopyWith<$Res> {
  factory _$FriendRequestModelCopyWith(_FriendRequestModel value, $Res Function(_FriendRequestModel) _then) = __$FriendRequestModelCopyWithImpl;
@override @useResult
$Res call({
 int id, UserModel sender, String status, DateTime createdAt
});


@override $UserModelCopyWith<$Res> get sender;

}
/// @nodoc
class __$FriendRequestModelCopyWithImpl<$Res>
    implements _$FriendRequestModelCopyWith<$Res> {
  __$FriendRequestModelCopyWithImpl(this._self, this._then);

  final _FriendRequestModel _self;
  final $Res Function(_FriendRequestModel) _then;

/// Create a copy of FriendRequestModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? sender = null,Object? status = null,Object? createdAt = null,}) {
  return _then(_FriendRequestModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,sender: null == sender ? _self.sender : sender // ignore: cast_nullable_to_non_nullable
as UserModel,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

/// Create a copy of FriendRequestModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserModelCopyWith<$Res> get sender {
  
  return $UserModelCopyWith<$Res>(_self.sender, (value) {
    return _then(_self.copyWith(sender: value));
  });
}
}

// dart format on

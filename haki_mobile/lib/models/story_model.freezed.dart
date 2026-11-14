// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'story_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$StoryModel {

 int get id; int get userId; String get content; String get type; DateTime get createdAt; DateTime get expiresAt; UserModel? get user; bool get seen; bool get liked;/// Only on your own stories.
 int? get viewCount; int? get likeCount;
/// Create a copy of StoryModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StoryModelCopyWith<StoryModel> get copyWith => _$StoryModelCopyWithImpl<StoryModel>(this as StoryModel, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as StoryModel;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StoryModel&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.userId, _this.userId) || other.userId == _this.userId)&&(identical(other.content, _this.content) || other.content == _this.content)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.expiresAt, _this.expiresAt) || other.expiresAt == _this.expiresAt)&&(identical(other.user, _this.user) || other.user == _this.user)&&(identical(other.seen, _this.seen) || other.seen == _this.seen)&&(identical(other.liked, _this.liked) || other.liked == _this.liked)&&(identical(other.viewCount, _this.viewCount) || other.viewCount == _this.viewCount)&&(identical(other.likeCount, _this.likeCount) || other.likeCount == _this.likeCount));
}


@override
int get hashCode {
  final _this = this as StoryModel;
  return Object.hash(runtimeType,_this.id,_this.userId,_this.content,_this.type,_this.createdAt,_this.expiresAt,_this.user,_this.seen,_this.liked,_this.viewCount,_this.likeCount);
}

@override
String toString() {
  final _this = this as StoryModel;
  return 'StoryModel(id: ${_this.id}, userId: ${_this.userId}, content: ${_this.content}, type: ${_this.type}, createdAt: ${_this.createdAt}, expiresAt: ${_this.expiresAt}, user: ${_this.user}, seen: ${_this.seen}, liked: ${_this.liked}, viewCount: ${_this.viewCount}, likeCount: ${_this.likeCount})';
}


}

/// @nodoc
abstract mixin class $StoryModelCopyWith<$Res>  {
  factory $StoryModelCopyWith(StoryModel value, $Res Function(StoryModel) _then) = _$StoryModelCopyWithImpl;
@useResult
$Res call({
 int id, int userId, String content, String type, DateTime createdAt, DateTime expiresAt, UserModel? user, bool seen, bool liked, int? viewCount, int? likeCount
});


$UserModelCopyWith<$Res>? get user;

}
/// @nodoc
class _$StoryModelCopyWithImpl<$Res>
    implements $StoryModelCopyWith<$Res> {
  _$StoryModelCopyWithImpl(this._self, this._then);

  final StoryModel _self;
  final $Res Function(StoryModel) _then;

/// Create a copy of StoryModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? content = null,Object? type = null,Object? createdAt = null,Object? expiresAt = null,Object? user = freezed,Object? seen = null,Object? liked = null,Object? viewCount = freezed,Object? likeCount = freezed,}) {
  return _then(StoryModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as int,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,user: freezed == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as UserModel?,seen: null == seen ? _self.seen : seen // ignore: cast_nullable_to_non_nullable
as bool,liked: null == liked ? _self.liked : liked // ignore: cast_nullable_to_non_nullable
as bool,viewCount: freezed == viewCount ? _self.viewCount : viewCount // ignore: cast_nullable_to_non_nullable
as int?,likeCount: freezed == likeCount ? _self.likeCount : likeCount // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}
/// Create a copy of StoryModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserModelCopyWith<$Res>? get user {
    if (_self.user == null) {
    return null;
  }

  return $UserModelCopyWith<$Res>(_self.user!, (value) {
    return _then(_self.copyWith(user: value));
  });
}
}


/// Adds pattern-matching-related methods to [StoryModel].
extension StoryModelPatterns on StoryModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StoryModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StoryModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StoryModel value)  $default,){
final _that = this;
switch (_that) {
case _StoryModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StoryModel value)?  $default,){
final _that = this;
switch (_that) {
case _StoryModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  int userId,  String content,  String type,  DateTime createdAt,  DateTime expiresAt,  UserModel? user,  bool seen,  bool liked,  int? viewCount,  int? likeCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StoryModel() when $default != null:
return $default(_that.id,_that.userId,_that.content,_that.type,_that.createdAt,_that.expiresAt,_that.user,_that.seen,_that.liked,_that.viewCount,_that.likeCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  int userId,  String content,  String type,  DateTime createdAt,  DateTime expiresAt,  UserModel? user,  bool seen,  bool liked,  int? viewCount,  int? likeCount)  $default,) {final _that = this;
switch (_that) {
case _StoryModel():
return $default(_that.id,_that.userId,_that.content,_that.type,_that.createdAt,_that.expiresAt,_that.user,_that.seen,_that.liked,_that.viewCount,_that.likeCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  int userId,  String content,  String type,  DateTime createdAt,  DateTime expiresAt,  UserModel? user,  bool seen,  bool liked,  int? viewCount,  int? likeCount)?  $default,) {final _that = this;
switch (_that) {
case _StoryModel() when $default != null:
return $default(_that.id,_that.userId,_that.content,_that.type,_that.createdAt,_that.expiresAt,_that.user,_that.seen,_that.liked,_that.viewCount,_that.likeCount);case _:
  return null;

}
}

}

/// @nodoc


class _StoryModel implements StoryModel {
  const _StoryModel({required this.id, required this.userId, required this.content, required this.type, required this.createdAt, required this.expiresAt, this.user, this.seen = false, this.liked = false, this.viewCount, this.likeCount});
  

@override final  int id;
@override final  int userId;
@override final  String content;
@override final  String type;
@override final  DateTime createdAt;
@override final  DateTime expiresAt;
@override final  UserModel? user;
@override@JsonKey() final  bool seen;
@override@JsonKey() final  bool liked;
/// Only on your own stories.
@override final  int? viewCount;
@override final  int? likeCount;

/// Create a copy of StoryModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StoryModelCopyWith<_StoryModel> get copyWith => __$StoryModelCopyWithImpl<_StoryModel>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _StoryModel&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.content, content) || other.content == content)&&(identical(other.type, type) || other.type == type)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.user, user) || other.user == user)&&(identical(other.seen, seen) || other.seen == seen)&&(identical(other.liked, liked) || other.liked == liked)&&(identical(other.viewCount, viewCount) || other.viewCount == viewCount)&&(identical(other.likeCount, likeCount) || other.likeCount == likeCount));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,userId,content,type,createdAt,expiresAt,user,seen,liked,viewCount,likeCount);
}

@override
String toString() {
    return 'StoryModel(id: $id, userId: $userId, content: $content, type: $type, createdAt: $createdAt, expiresAt: $expiresAt, user: $user, seen: $seen, liked: $liked, viewCount: $viewCount, likeCount: $likeCount)';
}


}

/// @nodoc
abstract mixin class _$StoryModelCopyWith<$Res> implements $StoryModelCopyWith<$Res> {
  factory _$StoryModelCopyWith(_StoryModel value, $Res Function(_StoryModel) _then) = __$StoryModelCopyWithImpl;
@override @useResult
$Res call({
 int id, int userId, String content, String type, DateTime createdAt, DateTime expiresAt, UserModel? user, bool seen, bool liked, int? viewCount, int? likeCount
});


@override $UserModelCopyWith<$Res>? get user;

}
/// @nodoc
class __$StoryModelCopyWithImpl<$Res>
    implements _$StoryModelCopyWith<$Res> {
  __$StoryModelCopyWithImpl(this._self, this._then);

  final _StoryModel _self;
  final $Res Function(_StoryModel) _then;

/// Create a copy of StoryModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? content = null,Object? type = null,Object? createdAt = null,Object? expiresAt = null,Object? user = freezed,Object? seen = null,Object? liked = null,Object? viewCount = freezed,Object? likeCount = freezed,}) {
  return _then(_StoryModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as int,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,user: freezed == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as UserModel?,seen: null == seen ? _self.seen : seen // ignore: cast_nullable_to_non_nullable
as bool,liked: null == liked ? _self.liked : liked // ignore: cast_nullable_to_non_nullable
as bool,viewCount: freezed == viewCount ? _self.viewCount : viewCount // ignore: cast_nullable_to_non_nullable
as int?,likeCount: freezed == likeCount ? _self.likeCount : likeCount // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

/// Create a copy of StoryModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserModelCopyWith<$Res>? get user {
    if (_self.user == null) {
    return null;
  }

  return $UserModelCopyWith<$Res>(_self.user!, (value) {
    return _then(_self.copyWith(user: value));
  });
}
}

// dart format on

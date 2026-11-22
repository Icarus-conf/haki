// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'post_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PostMedia {

 String get url; String get iv; String get kind; double get w; double get h; int? get dur;
/// Create a copy of PostMedia
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PostMediaCopyWith<PostMedia> get copyWith => _$PostMediaCopyWithImpl<PostMedia>(this as PostMedia, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PostMedia;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PostMedia&&(identical(other.url, _this.url) || other.url == _this.url)&&(identical(other.iv, _this.iv) || other.iv == _this.iv)&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.w, _this.w) || other.w == _this.w)&&(identical(other.h, _this.h) || other.h == _this.h)&&(identical(other.dur, _this.dur) || other.dur == _this.dur));
}


@override
int get hashCode {
  final _this = this as PostMedia;
  return Object.hash(runtimeType,_this.url,_this.iv,_this.kind,_this.w,_this.h,_this.dur);
}

@override
String toString() {
  final _this = this as PostMedia;
  return 'PostMedia(url: ${_this.url}, iv: ${_this.iv}, kind: ${_this.kind}, w: ${_this.w}, h: ${_this.h}, dur: ${_this.dur})';
}


}

/// @nodoc
abstract mixin class $PostMediaCopyWith<$Res>  {
  factory $PostMediaCopyWith(PostMedia value, $Res Function(PostMedia) _then) = _$PostMediaCopyWithImpl;
@useResult
$Res call({
 String url, String iv, String kind, double w, double h, int? dur
});




}
/// @nodoc
class _$PostMediaCopyWithImpl<$Res>
    implements $PostMediaCopyWith<$Res> {
  _$PostMediaCopyWithImpl(this._self, this._then);

  final PostMedia _self;
  final $Res Function(PostMedia) _then;

/// Create a copy of PostMedia
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? url = null,Object? iv = null,Object? kind = null,Object? w = null,Object? h = null,Object? dur = freezed,}) {
  return _then(PostMedia(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,iv: null == iv ? _self.iv : iv // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,w: null == w ? _self.w : w // ignore: cast_nullable_to_non_nullable
as double,h: null == h ? _self.h : h // ignore: cast_nullable_to_non_nullable
as double,dur: freezed == dur ? _self.dur : dur // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [PostMedia].
extension PostMediaPatterns on PostMedia {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PostMedia value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PostMedia() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PostMedia value)  $default,){
final _that = this;
switch (_that) {
case _PostMedia():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PostMedia value)?  $default,){
final _that = this;
switch (_that) {
case _PostMedia() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String url,  String iv,  String kind,  double w,  double h,  int? dur)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PostMedia() when $default != null:
return $default(_that.url,_that.iv,_that.kind,_that.w,_that.h,_that.dur);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String url,  String iv,  String kind,  double w,  double h,  int? dur)  $default,) {final _that = this;
switch (_that) {
case _PostMedia():
return $default(_that.url,_that.iv,_that.kind,_that.w,_that.h,_that.dur);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String url,  String iv,  String kind,  double w,  double h,  int? dur)?  $default,) {final _that = this;
switch (_that) {
case _PostMedia() when $default != null:
return $default(_that.url,_that.iv,_that.kind,_that.w,_that.h,_that.dur);case _:
  return null;

}
}

}

/// @nodoc


class _PostMedia extends PostMedia {
  const _PostMedia({required this.url, required this.iv, this.kind = 'image', this.w = 1, this.h = 1, this.dur}): super._();
  

@override final  String url;
@override final  String iv;
@override@JsonKey() final  String kind;
@override@JsonKey() final  double w;
@override@JsonKey() final  double h;
@override final  int? dur;

/// Create a copy of PostMedia
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PostMediaCopyWith<_PostMedia> get copyWith => __$PostMediaCopyWithImpl<_PostMedia>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PostMedia&&(identical(other.url, url) || other.url == url)&&(identical(other.iv, iv) || other.iv == iv)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.w, w) || other.w == w)&&(identical(other.h, h) || other.h == h)&&(identical(other.dur, dur) || other.dur == dur));
}


@override
int get hashCode {
    return Object.hash(runtimeType,url,iv,kind,w,h,dur);
}

@override
String toString() {
    return 'PostMedia(url: $url, iv: $iv, kind: $kind, w: $w, h: $h, dur: $dur)';
}


}

/// @nodoc
abstract mixin class _$PostMediaCopyWith<$Res> implements $PostMediaCopyWith<$Res> {
  factory _$PostMediaCopyWith(_PostMedia value, $Res Function(_PostMedia) _then) = __$PostMediaCopyWithImpl;
@override @useResult
$Res call({
 String url, String iv, String kind, double w, double h, int? dur
});




}
/// @nodoc
class __$PostMediaCopyWithImpl<$Res>
    implements _$PostMediaCopyWith<$Res> {
  __$PostMediaCopyWithImpl(this._self, this._then);

  final _PostMedia _self;
  final $Res Function(_PostMedia) _then;

/// Create a copy of PostMedia
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? url = null,Object? iv = null,Object? kind = null,Object? w = null,Object? h = null,Object? dur = freezed,}) {
  return _then(_PostMedia(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,iv: null == iv ? _self.iv : iv // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,w: null == w ? _self.w : w // ignore: cast_nullable_to_non_nullable
as double,h: null == h ? _self.h : h // ignore: cast_nullable_to_non_nullable
as double,dur: freezed == dur ? _self.dur : dur // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

/// @nodoc
mixin _$PostModel {

 int get id; UserModel get author; String get text; List<PostMedia> get media; DateTime get createdAt; List<int> get key; bool get commentsOff; int get commentCount; Map<String, int> get reactions; String? get myReaction;
/// Create a copy of PostModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PostModelCopyWith<PostModel> get copyWith => _$PostModelCopyWithImpl<PostModel>(this as PostModel, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PostModel;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PostModel&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.author, _this.author) || other.author == _this.author)&&(identical(other.text, _this.text) || other.text == _this.text)&&const DeepCollectionEquality().equals(other.media, _this.media)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&const DeepCollectionEquality().equals(other.key, _this.key)&&(identical(other.commentsOff, _this.commentsOff) || other.commentsOff == _this.commentsOff)&&(identical(other.commentCount, _this.commentCount) || other.commentCount == _this.commentCount)&&const DeepCollectionEquality().equals(other.reactions, _this.reactions)&&(identical(other.myReaction, _this.myReaction) || other.myReaction == _this.myReaction));
}


@override
int get hashCode {
  final _this = this as PostModel;
  return Object.hash(runtimeType,_this.id,_this.author,_this.text,const DeepCollectionEquality().hash(_this.media),_this.createdAt,const DeepCollectionEquality().hash(_this.key),_this.commentsOff,_this.commentCount,const DeepCollectionEquality().hash(_this.reactions),_this.myReaction);
}

@override
String toString() {
  final _this = this as PostModel;
  return 'PostModel(id: ${_this.id}, author: ${_this.author}, text: ${_this.text}, media: ${_this.media}, createdAt: ${_this.createdAt}, key: ${_this.key}, commentsOff: ${_this.commentsOff}, commentCount: ${_this.commentCount}, reactions: ${_this.reactions}, myReaction: ${_this.myReaction})';
}


}

/// @nodoc
abstract mixin class $PostModelCopyWith<$Res>  {
  factory $PostModelCopyWith(PostModel value, $Res Function(PostModel) _then) = _$PostModelCopyWithImpl;
@useResult
$Res call({
 int id, UserModel author, String text, List<PostMedia> media, DateTime createdAt, List<int> key, bool commentsOff, int commentCount, Map<String, int> reactions, String? myReaction
});


$UserModelCopyWith<$Res> get author;

}
/// @nodoc
class _$PostModelCopyWithImpl<$Res>
    implements $PostModelCopyWith<$Res> {
  _$PostModelCopyWithImpl(this._self, this._then);

  final PostModel _self;
  final $Res Function(PostModel) _then;

/// Create a copy of PostModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? author = null,Object? text = null,Object? media = null,Object? createdAt = null,Object? key = null,Object? commentsOff = null,Object? commentCount = null,Object? reactions = null,Object? myReaction = freezed,}) {
  return _then(PostModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,author: null == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as UserModel,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,media: null == media ? _self.media : media // ignore: cast_nullable_to_non_nullable
as List<PostMedia>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as List<int>,commentsOff: null == commentsOff ? _self.commentsOff : commentsOff // ignore: cast_nullable_to_non_nullable
as bool,commentCount: null == commentCount ? _self.commentCount : commentCount // ignore: cast_nullable_to_non_nullable
as int,reactions: null == reactions ? _self.reactions : reactions // ignore: cast_nullable_to_non_nullable
as Map<String, int>,myReaction: freezed == myReaction ? _self.myReaction : myReaction // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of PostModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserModelCopyWith<$Res> get author {
  
  return $UserModelCopyWith<$Res>(_self.author, (value) {
    return _then(_self.copyWith(author: value));
  });
}
}


/// Adds pattern-matching-related methods to [PostModel].
extension PostModelPatterns on PostModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PostModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PostModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PostModel value)  $default,){
final _that = this;
switch (_that) {
case _PostModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PostModel value)?  $default,){
final _that = this;
switch (_that) {
case _PostModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  UserModel author,  String text,  List<PostMedia> media,  DateTime createdAt,  List<int> key,  bool commentsOff,  int commentCount,  Map<String, int> reactions,  String? myReaction)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PostModel() when $default != null:
return $default(_that.id,_that.author,_that.text,_that.media,_that.createdAt,_that.key,_that.commentsOff,_that.commentCount,_that.reactions,_that.myReaction);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  UserModel author,  String text,  List<PostMedia> media,  DateTime createdAt,  List<int> key,  bool commentsOff,  int commentCount,  Map<String, int> reactions,  String? myReaction)  $default,) {final _that = this;
switch (_that) {
case _PostModel():
return $default(_that.id,_that.author,_that.text,_that.media,_that.createdAt,_that.key,_that.commentsOff,_that.commentCount,_that.reactions,_that.myReaction);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  UserModel author,  String text,  List<PostMedia> media,  DateTime createdAt,  List<int> key,  bool commentsOff,  int commentCount,  Map<String, int> reactions,  String? myReaction)?  $default,) {final _that = this;
switch (_that) {
case _PostModel() when $default != null:
return $default(_that.id,_that.author,_that.text,_that.media,_that.createdAt,_that.key,_that.commentsOff,_that.commentCount,_that.reactions,_that.myReaction);case _:
  return null;

}
}

}

/// @nodoc


class _PostModel extends PostModel {
  const _PostModel({required this.id, required this.author, required this.text, required  List<PostMedia> media, required this.createdAt, required  List<int> key, this.commentsOff = false, this.commentCount = 0,  Map<String, int> reactions = const {}, this.myReaction}): _media = media,_key = key,_reactions = reactions,super._();
  

@override final  int id;
@override final  UserModel author;
@override final  String text;
 final  List<PostMedia> _media;
@override List<PostMedia> get media {
  if (_media is EqualUnmodifiableListView) return _media;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_media);
}

@override final  DateTime createdAt;
 final  List<int> _key;
@override List<int> get key {
  if (_key is EqualUnmodifiableListView) return _key;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_key);
}

@override@JsonKey() final  bool commentsOff;
@override@JsonKey() final  int commentCount;
 final  Map<String, int> _reactions;
@override@JsonKey() Map<String, int> get reactions {
  if (_reactions is EqualUnmodifiableMapView) return _reactions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_reactions);
}

@override final  String? myReaction;

/// Create a copy of PostModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PostModelCopyWith<_PostModel> get copyWith => __$PostModelCopyWithImpl<_PostModel>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PostModel&&(identical(other.id, id) || other.id == id)&&(identical(other.author, author) || other.author == author)&&(identical(other.text, text) || other.text == text)&&const DeepCollectionEquality().equals(other.media, _media)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&const DeepCollectionEquality().equals(other.key, _key)&&(identical(other.commentsOff, commentsOff) || other.commentsOff == commentsOff)&&(identical(other.commentCount, commentCount) || other.commentCount == commentCount)&&const DeepCollectionEquality().equals(other.reactions, _reactions)&&(identical(other.myReaction, myReaction) || other.myReaction == myReaction));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,author,text,const DeepCollectionEquality().hash(_media),createdAt,const DeepCollectionEquality().hash(_key),commentsOff,commentCount,const DeepCollectionEquality().hash(_reactions),myReaction);
}

@override
String toString() {
    return 'PostModel(id: $id, author: $author, text: $text, media: $media, createdAt: $createdAt, key: $key, commentsOff: $commentsOff, commentCount: $commentCount, reactions: $reactions, myReaction: $myReaction)';
}


}

/// @nodoc
abstract mixin class _$PostModelCopyWith<$Res> implements $PostModelCopyWith<$Res> {
  factory _$PostModelCopyWith(_PostModel value, $Res Function(_PostModel) _then) = __$PostModelCopyWithImpl;
@override @useResult
$Res call({
 int id, UserModel author, String text, List<PostMedia> media, DateTime createdAt, List<int> key, bool commentsOff, int commentCount, Map<String, int> reactions, String? myReaction
});


@override $UserModelCopyWith<$Res> get author;

}
/// @nodoc
class __$PostModelCopyWithImpl<$Res>
    implements _$PostModelCopyWith<$Res> {
  __$PostModelCopyWithImpl(this._self, this._then);

  final _PostModel _self;
  final $Res Function(_PostModel) _then;

/// Create a copy of PostModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? author = null,Object? text = null,Object? media = null,Object? createdAt = null,Object? key = null,Object? commentsOff = null,Object? commentCount = null,Object? reactions = null,Object? myReaction = freezed,}) {
  return _then(_PostModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,author: null == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as UserModel,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,media: null == media ? _self._media : media // ignore: cast_nullable_to_non_nullable
as List<PostMedia>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,key: null == key ? _self._key : key // ignore: cast_nullable_to_non_nullable
as List<int>,commentsOff: null == commentsOff ? _self.commentsOff : commentsOff // ignore: cast_nullable_to_non_nullable
as bool,commentCount: null == commentCount ? _self.commentCount : commentCount // ignore: cast_nullable_to_non_nullable
as int,reactions: null == reactions ? _self._reactions : reactions // ignore: cast_nullable_to_non_nullable
as Map<String, int>,myReaction: freezed == myReaction ? _self.myReaction : myReaction // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of PostModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserModelCopyWith<$Res> get author {
  
  return $UserModelCopyWith<$Res>(_self.author, (value) {
    return _then(_self.copyWith(author: value));
  });
}
}

/// @nodoc
mixin _$PostComment {

 int get id; UserModel get author; String get text; DateTime get createdAt; int? get parentId;
/// Create a copy of PostComment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PostCommentCopyWith<PostComment> get copyWith => _$PostCommentCopyWithImpl<PostComment>(this as PostComment, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PostComment;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PostComment&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.author, _this.author) || other.author == _this.author)&&(identical(other.text, _this.text) || other.text == _this.text)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.parentId, _this.parentId) || other.parentId == _this.parentId));
}


@override
int get hashCode {
  final _this = this as PostComment;
  return Object.hash(runtimeType,_this.id,_this.author,_this.text,_this.createdAt,_this.parentId);
}

@override
String toString() {
  final _this = this as PostComment;
  return 'PostComment(id: ${_this.id}, author: ${_this.author}, text: ${_this.text}, createdAt: ${_this.createdAt}, parentId: ${_this.parentId})';
}


}

/// @nodoc
abstract mixin class $PostCommentCopyWith<$Res>  {
  factory $PostCommentCopyWith(PostComment value, $Res Function(PostComment) _then) = _$PostCommentCopyWithImpl;
@useResult
$Res call({
 int id, UserModel author, String text, DateTime createdAt, int? parentId
});


$UserModelCopyWith<$Res> get author;

}
/// @nodoc
class _$PostCommentCopyWithImpl<$Res>
    implements $PostCommentCopyWith<$Res> {
  _$PostCommentCopyWithImpl(this._self, this._then);

  final PostComment _self;
  final $Res Function(PostComment) _then;

/// Create a copy of PostComment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? author = null,Object? text = null,Object? createdAt = null,Object? parentId = freezed,}) {
  return _then(PostComment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,author: null == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as UserModel,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,parentId: freezed == parentId ? _self.parentId : parentId // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}
/// Create a copy of PostComment
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserModelCopyWith<$Res> get author {
  
  return $UserModelCopyWith<$Res>(_self.author, (value) {
    return _then(_self.copyWith(author: value));
  });
}
}


/// Adds pattern-matching-related methods to [PostComment].
extension PostCommentPatterns on PostComment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PostComment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PostComment() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PostComment value)  $default,){
final _that = this;
switch (_that) {
case _PostComment():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PostComment value)?  $default,){
final _that = this;
switch (_that) {
case _PostComment() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  UserModel author,  String text,  DateTime createdAt,  int? parentId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PostComment() when $default != null:
return $default(_that.id,_that.author,_that.text,_that.createdAt,_that.parentId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  UserModel author,  String text,  DateTime createdAt,  int? parentId)  $default,) {final _that = this;
switch (_that) {
case _PostComment():
return $default(_that.id,_that.author,_that.text,_that.createdAt,_that.parentId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  UserModel author,  String text,  DateTime createdAt,  int? parentId)?  $default,) {final _that = this;
switch (_that) {
case _PostComment() when $default != null:
return $default(_that.id,_that.author,_that.text,_that.createdAt,_that.parentId);case _:
  return null;

}
}

}

/// @nodoc


class _PostComment implements PostComment {
  const _PostComment({required this.id, required this.author, required this.text, required this.createdAt, this.parentId});
  

@override final  int id;
@override final  UserModel author;
@override final  String text;
@override final  DateTime createdAt;
@override final  int? parentId;

/// Create a copy of PostComment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PostCommentCopyWith<_PostComment> get copyWith => __$PostCommentCopyWithImpl<_PostComment>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PostComment&&(identical(other.id, id) || other.id == id)&&(identical(other.author, author) || other.author == author)&&(identical(other.text, text) || other.text == text)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.parentId, parentId) || other.parentId == parentId));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,author,text,createdAt,parentId);
}

@override
String toString() {
    return 'PostComment(id: $id, author: $author, text: $text, createdAt: $createdAt, parentId: $parentId)';
}


}

/// @nodoc
abstract mixin class _$PostCommentCopyWith<$Res> implements $PostCommentCopyWith<$Res> {
  factory _$PostCommentCopyWith(_PostComment value, $Res Function(_PostComment) _then) = __$PostCommentCopyWithImpl;
@override @useResult
$Res call({
 int id, UserModel author, String text, DateTime createdAt, int? parentId
});


@override $UserModelCopyWith<$Res> get author;

}
/// @nodoc
class __$PostCommentCopyWithImpl<$Res>
    implements _$PostCommentCopyWith<$Res> {
  __$PostCommentCopyWithImpl(this._self, this._then);

  final _PostComment _self;
  final $Res Function(_PostComment) _then;

/// Create a copy of PostComment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? author = null,Object? text = null,Object? createdAt = null,Object? parentId = freezed,}) {
  return _then(_PostComment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,author: null == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as UserModel,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,parentId: freezed == parentId ? _self.parentId : parentId // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

/// Create a copy of PostComment
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserModelCopyWith<$Res> get author {
  
  return $UserModelCopyWith<$Res>(_self.author, (value) {
    return _then(_self.copyWith(author: value));
  });
}
}

// dart format on

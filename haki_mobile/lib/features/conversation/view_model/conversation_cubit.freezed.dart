// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'conversation_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ConversationState {

 List<MessageModel> get messages; List<MessageModel> get pinned;/// My messages waiting to be sent later (only I see these).
 List<MessageModel> get scheduled; bool get isLoading;/// People typing right now (one in a DM, any member in a group).
 Set<int> get typingIds;/// Search text; empty = not searching. Matching happens here on the phone.
 String get query; bool get searchingOlder;/// One-shot error for a toast; the view clears nothing, it just listens for changes.
 String? get error;/// One-shot info toast (e.g. "Ana turned on disappearing messages").
 String? get notice;/// Disappearing-message timer for this chat, in seconds (0 = off).
 int get disappearSeconds;/// Groups: how far each member has read (user id -> last message id read).
 Map<int, int> get readers;
/// Create a copy of ConversationState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConversationStateCopyWith<ConversationState> get copyWith => _$ConversationStateCopyWithImpl<ConversationState>(this as ConversationState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ConversationState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConversationState&&const DeepCollectionEquality().equals(other.messages, _this.messages)&&const DeepCollectionEquality().equals(other.pinned, _this.pinned)&&const DeepCollectionEquality().equals(other.scheduled, _this.scheduled)&&(identical(other.isLoading, _this.isLoading) || other.isLoading == _this.isLoading)&&const DeepCollectionEquality().equals(other.typingIds, _this.typingIds)&&(identical(other.query, _this.query) || other.query == _this.query)&&(identical(other.searchingOlder, _this.searchingOlder) || other.searchingOlder == _this.searchingOlder)&&(identical(other.error, _this.error) || other.error == _this.error)&&(identical(other.notice, _this.notice) || other.notice == _this.notice)&&(identical(other.disappearSeconds, _this.disappearSeconds) || other.disappearSeconds == _this.disappearSeconds)&&const DeepCollectionEquality().equals(other.readers, _this.readers));
}


@override
int get hashCode {
  final _this = this as ConversationState;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.messages),const DeepCollectionEquality().hash(_this.pinned),const DeepCollectionEquality().hash(_this.scheduled),_this.isLoading,const DeepCollectionEquality().hash(_this.typingIds),_this.query,_this.searchingOlder,_this.error,_this.notice,_this.disappearSeconds,const DeepCollectionEquality().hash(_this.readers));
}

@override
String toString() {
  final _this = this as ConversationState;
  return 'ConversationState(messages: ${_this.messages}, pinned: ${_this.pinned}, scheduled: ${_this.scheduled}, isLoading: ${_this.isLoading}, typingIds: ${_this.typingIds}, query: ${_this.query}, searchingOlder: ${_this.searchingOlder}, error: ${_this.error}, notice: ${_this.notice}, disappearSeconds: ${_this.disappearSeconds}, readers: ${_this.readers})';
}


}

/// @nodoc
abstract mixin class $ConversationStateCopyWith<$Res>  {
  factory $ConversationStateCopyWith(ConversationState value, $Res Function(ConversationState) _then) = _$ConversationStateCopyWithImpl;
@useResult
$Res call({
 List<MessageModel> messages, List<MessageModel> pinned, List<MessageModel> scheduled, bool isLoading, Set<int> typingIds, String query, bool searchingOlder, String? error, String? notice, int disappearSeconds, Map<int, int> readers
});




}
/// @nodoc
class _$ConversationStateCopyWithImpl<$Res>
    implements $ConversationStateCopyWith<$Res> {
  _$ConversationStateCopyWithImpl(this._self, this._then);

  final ConversationState _self;
  final $Res Function(ConversationState) _then;

/// Create a copy of ConversationState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? messages = null,Object? pinned = null,Object? scheduled = null,Object? isLoading = null,Object? typingIds = null,Object? query = null,Object? searchingOlder = null,Object? error = freezed,Object? notice = freezed,Object? disappearSeconds = null,Object? readers = null,}) {
  return _then(ConversationState(
messages: null == messages ? _self.messages : messages // ignore: cast_nullable_to_non_nullable
as List<MessageModel>,pinned: null == pinned ? _self.pinned : pinned // ignore: cast_nullable_to_non_nullable
as List<MessageModel>,scheduled: null == scheduled ? _self.scheduled : scheduled // ignore: cast_nullable_to_non_nullable
as List<MessageModel>,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,typingIds: null == typingIds ? _self.typingIds : typingIds // ignore: cast_nullable_to_non_nullable
as Set<int>,query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,searchingOlder: null == searchingOlder ? _self.searchingOlder : searchingOlder // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,notice: freezed == notice ? _self.notice : notice // ignore: cast_nullable_to_non_nullable
as String?,disappearSeconds: null == disappearSeconds ? _self.disappearSeconds : disappearSeconds // ignore: cast_nullable_to_non_nullable
as int,readers: null == readers ? _self.readers : readers // ignore: cast_nullable_to_non_nullable
as Map<int, int>,
  ));
}

}


/// Adds pattern-matching-related methods to [ConversationState].
extension ConversationStatePatterns on ConversationState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ConversationState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ConversationState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ConversationState value)  $default,){
final _that = this;
switch (_that) {
case _ConversationState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ConversationState value)?  $default,){
final _that = this;
switch (_that) {
case _ConversationState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<MessageModel> messages,  List<MessageModel> pinned,  List<MessageModel> scheduled,  bool isLoading,  Set<int> typingIds,  String query,  bool searchingOlder,  String? error,  String? notice,  int disappearSeconds,  Map<int, int> readers)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ConversationState() when $default != null:
return $default(_that.messages,_that.pinned,_that.scheduled,_that.isLoading,_that.typingIds,_that.query,_that.searchingOlder,_that.error,_that.notice,_that.disappearSeconds,_that.readers);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<MessageModel> messages,  List<MessageModel> pinned,  List<MessageModel> scheduled,  bool isLoading,  Set<int> typingIds,  String query,  bool searchingOlder,  String? error,  String? notice,  int disappearSeconds,  Map<int, int> readers)  $default,) {final _that = this;
switch (_that) {
case _ConversationState():
return $default(_that.messages,_that.pinned,_that.scheduled,_that.isLoading,_that.typingIds,_that.query,_that.searchingOlder,_that.error,_that.notice,_that.disappearSeconds,_that.readers);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<MessageModel> messages,  List<MessageModel> pinned,  List<MessageModel> scheduled,  bool isLoading,  Set<int> typingIds,  String query,  bool searchingOlder,  String? error,  String? notice,  int disappearSeconds,  Map<int, int> readers)?  $default,) {final _that = this;
switch (_that) {
case _ConversationState() when $default != null:
return $default(_that.messages,_that.pinned,_that.scheduled,_that.isLoading,_that.typingIds,_that.query,_that.searchingOlder,_that.error,_that.notice,_that.disappearSeconds,_that.readers);case _:
  return null;

}
}

}

/// @nodoc


class _ConversationState extends ConversationState {
  const _ConversationState({ List<MessageModel> messages = const [],  List<MessageModel> pinned = const [],  List<MessageModel> scheduled = const [], this.isLoading = true,  Set<int> typingIds = const {}, this.query = '', this.searchingOlder = false, this.error, this.notice, this.disappearSeconds = 0,  Map<int, int> readers = const {}}): _messages = messages,_pinned = pinned,_scheduled = scheduled,_typingIds = typingIds,_readers = readers,super._();
  

 final  List<MessageModel> _messages;
@override@JsonKey() List<MessageModel> get messages {
  if (_messages is EqualUnmodifiableListView) return _messages;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_messages);
}

 final  List<MessageModel> _pinned;
@override@JsonKey() List<MessageModel> get pinned {
  if (_pinned is EqualUnmodifiableListView) return _pinned;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_pinned);
}

/// My messages waiting to be sent later (only I see these).
 final  List<MessageModel> _scheduled;
/// My messages waiting to be sent later (only I see these).
@override@JsonKey() List<MessageModel> get scheduled {
  if (_scheduled is EqualUnmodifiableListView) return _scheduled;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_scheduled);
}

@override@JsonKey() final  bool isLoading;
/// People typing right now (one in a DM, any member in a group).
 final  Set<int> _typingIds;
/// People typing right now (one in a DM, any member in a group).
@override@JsonKey() Set<int> get typingIds {
  if (_typingIds is EqualUnmodifiableSetView) return _typingIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_typingIds);
}

/// Search text; empty = not searching. Matching happens here on the phone.
@override@JsonKey() final  String query;
@override@JsonKey() final  bool searchingOlder;
/// One-shot error for a toast; the view clears nothing, it just listens for changes.
@override final  String? error;
/// One-shot info toast (e.g. "Ana turned on disappearing messages").
@override final  String? notice;
/// Disappearing-message timer for this chat, in seconds (0 = off).
@override@JsonKey() final  int disappearSeconds;
/// Groups: how far each member has read (user id -> last message id read).
 final  Map<int, int> _readers;
/// Groups: how far each member has read (user id -> last message id read).
@override@JsonKey() Map<int, int> get readers {
  if (_readers is EqualUnmodifiableMapView) return _readers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_readers);
}


/// Create a copy of ConversationState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConversationStateCopyWith<_ConversationState> get copyWith => __$ConversationStateCopyWithImpl<_ConversationState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ConversationState&&const DeepCollectionEquality().equals(other.messages, _messages)&&const DeepCollectionEquality().equals(other.pinned, _pinned)&&const DeepCollectionEquality().equals(other.scheduled, _scheduled)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&const DeepCollectionEquality().equals(other.typingIds, _typingIds)&&(identical(other.query, query) || other.query == query)&&(identical(other.searchingOlder, searchingOlder) || other.searchingOlder == searchingOlder)&&(identical(other.error, error) || other.error == error)&&(identical(other.notice, notice) || other.notice == notice)&&(identical(other.disappearSeconds, disappearSeconds) || other.disappearSeconds == disappearSeconds)&&const DeepCollectionEquality().equals(other.readers, _readers));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_messages),const DeepCollectionEquality().hash(_pinned),const DeepCollectionEquality().hash(_scheduled),isLoading,const DeepCollectionEquality().hash(_typingIds),query,searchingOlder,error,notice,disappearSeconds,const DeepCollectionEquality().hash(_readers));
}

@override
String toString() {
    return 'ConversationState(messages: $messages, pinned: $pinned, scheduled: $scheduled, isLoading: $isLoading, typingIds: $typingIds, query: $query, searchingOlder: $searchingOlder, error: $error, notice: $notice, disappearSeconds: $disappearSeconds, readers: $readers)';
}


}

/// @nodoc
abstract mixin class _$ConversationStateCopyWith<$Res> implements $ConversationStateCopyWith<$Res> {
  factory _$ConversationStateCopyWith(_ConversationState value, $Res Function(_ConversationState) _then) = __$ConversationStateCopyWithImpl;
@override @useResult
$Res call({
 List<MessageModel> messages, List<MessageModel> pinned, List<MessageModel> scheduled, bool isLoading, Set<int> typingIds, String query, bool searchingOlder, String? error, String? notice, int disappearSeconds, Map<int, int> readers
});




}
/// @nodoc
class __$ConversationStateCopyWithImpl<$Res>
    implements _$ConversationStateCopyWith<$Res> {
  __$ConversationStateCopyWithImpl(this._self, this._then);

  final _ConversationState _self;
  final $Res Function(_ConversationState) _then;

/// Create a copy of ConversationState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? messages = null,Object? pinned = null,Object? scheduled = null,Object? isLoading = null,Object? typingIds = null,Object? query = null,Object? searchingOlder = null,Object? error = freezed,Object? notice = freezed,Object? disappearSeconds = null,Object? readers = null,}) {
  return _then(_ConversationState(
messages: null == messages ? _self._messages : messages // ignore: cast_nullable_to_non_nullable
as List<MessageModel>,pinned: null == pinned ? _self._pinned : pinned // ignore: cast_nullable_to_non_nullable
as List<MessageModel>,scheduled: null == scheduled ? _self._scheduled : scheduled // ignore: cast_nullable_to_non_nullable
as List<MessageModel>,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,typingIds: null == typingIds ? _self._typingIds : typingIds // ignore: cast_nullable_to_non_nullable
as Set<int>,query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,searchingOlder: null == searchingOlder ? _self.searchingOlder : searchingOlder // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,notice: freezed == notice ? _self.notice : notice // ignore: cast_nullable_to_non_nullable
as String?,disappearSeconds: null == disappearSeconds ? _self.disappearSeconds : disappearSeconds // ignore: cast_nullable_to_non_nullable
as int,readers: null == readers ? _self._readers : readers // ignore: cast_nullable_to_non_nullable
as Map<int, int>,
  ));
}


}

// dart format on

// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'session_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SessionState {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'SessionState()';
}


}

/// @nodoc
class $SessionStateCopyWith<$Res>  {
$SessionStateCopyWith(SessionState _, $Res Function(SessionState) __);
}


/// Adds pattern-matching-related methods to [SessionState].
extension SessionStatePatterns on SessionState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SessionInitializing value)?  initializing,TResult Function( SessionUnauthenticated value)?  unauthenticated,TResult Function( SessionOnboarding value)?  onboarding,TResult Function( SessionNeedsRecovery value)?  needsRecovery,TResult Function( SessionAuthenticated value)?  authenticated,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SessionInitializing() when initializing != null:
return initializing(_that);case SessionUnauthenticated() when unauthenticated != null:
return unauthenticated(_that);case SessionOnboarding() when onboarding != null:
return onboarding(_that);case SessionNeedsRecovery() when needsRecovery != null:
return needsRecovery(_that);case SessionAuthenticated() when authenticated != null:
return authenticated(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SessionInitializing value)  initializing,required TResult Function( SessionUnauthenticated value)  unauthenticated,required TResult Function( SessionOnboarding value)  onboarding,required TResult Function( SessionNeedsRecovery value)  needsRecovery,required TResult Function( SessionAuthenticated value)  authenticated,}){
final _that = this;
switch (_that) {
case SessionInitializing():
return initializing(_that);case SessionUnauthenticated():
return unauthenticated(_that);case SessionOnboarding():
return onboarding(_that);case SessionNeedsRecovery():
return needsRecovery(_that);case SessionAuthenticated():
return authenticated(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SessionInitializing value)?  initializing,TResult? Function( SessionUnauthenticated value)?  unauthenticated,TResult? Function( SessionOnboarding value)?  onboarding,TResult? Function( SessionNeedsRecovery value)?  needsRecovery,TResult? Function( SessionAuthenticated value)?  authenticated,}){
final _that = this;
switch (_that) {
case SessionInitializing() when initializing != null:
return initializing(_that);case SessionUnauthenticated() when unauthenticated != null:
return unauthenticated(_that);case SessionOnboarding() when onboarding != null:
return onboarding(_that);case SessionNeedsRecovery() when needsRecovery != null:
return needsRecovery(_that);case SessionAuthenticated() when authenticated != null:
return authenticated(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initializing,TResult Function()?  unauthenticated,TResult Function( UserModel me,  String mnemonic)?  onboarding,TResult Function( UserModel me)?  needsRecovery,TResult Function( UserModel me,  bool hasViewedRecoveryPhrase)?  authenticated,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SessionInitializing() when initializing != null:
return initializing();case SessionUnauthenticated() when unauthenticated != null:
return unauthenticated();case SessionOnboarding() when onboarding != null:
return onboarding(_that.me,_that.mnemonic);case SessionNeedsRecovery() when needsRecovery != null:
return needsRecovery(_that.me);case SessionAuthenticated() when authenticated != null:
return authenticated(_that.me,_that.hasViewedRecoveryPhrase);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initializing,required TResult Function()  unauthenticated,required TResult Function( UserModel me,  String mnemonic)  onboarding,required TResult Function( UserModel me)  needsRecovery,required TResult Function( UserModel me,  bool hasViewedRecoveryPhrase)  authenticated,}) {final _that = this;
switch (_that) {
case SessionInitializing():
return initializing();case SessionUnauthenticated():
return unauthenticated();case SessionOnboarding():
return onboarding(_that.me,_that.mnemonic);case SessionNeedsRecovery():
return needsRecovery(_that.me);case SessionAuthenticated():
return authenticated(_that.me,_that.hasViewedRecoveryPhrase);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initializing,TResult? Function()?  unauthenticated,TResult? Function( UserModel me,  String mnemonic)?  onboarding,TResult? Function( UserModel me)?  needsRecovery,TResult? Function( UserModel me,  bool hasViewedRecoveryPhrase)?  authenticated,}) {final _that = this;
switch (_that) {
case SessionInitializing() when initializing != null:
return initializing();case SessionUnauthenticated() when unauthenticated != null:
return unauthenticated();case SessionOnboarding() when onboarding != null:
return onboarding(_that.me,_that.mnemonic);case SessionNeedsRecovery() when needsRecovery != null:
return needsRecovery(_that.me);case SessionAuthenticated() when authenticated != null:
return authenticated(_that.me,_that.hasViewedRecoveryPhrase);case _:
  return null;

}
}

}

/// @nodoc


class SessionInitializing extends SessionState {
  const SessionInitializing(): super._();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionInitializing);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'SessionState.initializing()';
}


}




/// @nodoc


class SessionUnauthenticated extends SessionState {
  const SessionUnauthenticated(): super._();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionUnauthenticated);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'SessionState.unauthenticated()';
}


}




/// @nodoc


class SessionOnboarding extends SessionState {
  const SessionOnboarding({required this.me, required this.mnemonic}): super._();
  

 final  UserModel me;
 final  String mnemonic;

/// Create a copy of SessionState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionOnboardingCopyWith<SessionOnboarding> get copyWith => _$SessionOnboardingCopyWithImpl<SessionOnboarding>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionOnboarding&&(identical(other.me, me) || other.me == me)&&(identical(other.mnemonic, mnemonic) || other.mnemonic == mnemonic));
}


@override
int get hashCode {
    return Object.hash(runtimeType,me,mnemonic);
}

@override
String toString() {
    return 'SessionState.onboarding(me: $me, mnemonic: $mnemonic)';
}


}

/// @nodoc
abstract mixin class $SessionOnboardingCopyWith<$Res> implements $SessionStateCopyWith<$Res> {
  factory $SessionOnboardingCopyWith(SessionOnboarding value, $Res Function(SessionOnboarding) _then) = _$SessionOnboardingCopyWithImpl;
@useResult
$Res call({
 UserModel me, String mnemonic
});


$UserModelCopyWith<$Res> get me;

}
/// @nodoc
class _$SessionOnboardingCopyWithImpl<$Res>
    implements $SessionOnboardingCopyWith<$Res> {
  _$SessionOnboardingCopyWithImpl(this._self, this._then);

  final SessionOnboarding _self;
  final $Res Function(SessionOnboarding) _then;

/// Create a copy of SessionState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? me = null,Object? mnemonic = null,}) {
  return _then(SessionOnboarding(
me: null == me ? _self.me : me // ignore: cast_nullable_to_non_nullable
as UserModel,mnemonic: null == mnemonic ? _self.mnemonic : mnemonic // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of SessionState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserModelCopyWith<$Res> get me {
  
  return $UserModelCopyWith<$Res>(_self.me, (value) {
    return _then(_self.copyWith(me: value));
  });
}
}

/// @nodoc


class SessionNeedsRecovery extends SessionState {
  const SessionNeedsRecovery({required this.me}): super._();
  

 final  UserModel me;

/// Create a copy of SessionState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionNeedsRecoveryCopyWith<SessionNeedsRecovery> get copyWith => _$SessionNeedsRecoveryCopyWithImpl<SessionNeedsRecovery>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionNeedsRecovery&&(identical(other.me, me) || other.me == me));
}


@override
int get hashCode {
    return Object.hash(runtimeType,me);
}

@override
String toString() {
    return 'SessionState.needsRecovery(me: $me)';
}


}

/// @nodoc
abstract mixin class $SessionNeedsRecoveryCopyWith<$Res> implements $SessionStateCopyWith<$Res> {
  factory $SessionNeedsRecoveryCopyWith(SessionNeedsRecovery value, $Res Function(SessionNeedsRecovery) _then) = _$SessionNeedsRecoveryCopyWithImpl;
@useResult
$Res call({
 UserModel me
});


$UserModelCopyWith<$Res> get me;

}
/// @nodoc
class _$SessionNeedsRecoveryCopyWithImpl<$Res>
    implements $SessionNeedsRecoveryCopyWith<$Res> {
  _$SessionNeedsRecoveryCopyWithImpl(this._self, this._then);

  final SessionNeedsRecovery _self;
  final $Res Function(SessionNeedsRecovery) _then;

/// Create a copy of SessionState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? me = null,}) {
  return _then(SessionNeedsRecovery(
me: null == me ? _self.me : me // ignore: cast_nullable_to_non_nullable
as UserModel,
  ));
}

/// Create a copy of SessionState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserModelCopyWith<$Res> get me {
  
  return $UserModelCopyWith<$Res>(_self.me, (value) {
    return _then(_self.copyWith(me: value));
  });
}
}

/// @nodoc


class SessionAuthenticated extends SessionState {
  const SessionAuthenticated({required this.me, this.hasViewedRecoveryPhrase = false}): super._();
  

 final  UserModel me;
@JsonKey() final  bool hasViewedRecoveryPhrase;

/// Create a copy of SessionState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionAuthenticatedCopyWith<SessionAuthenticated> get copyWith => _$SessionAuthenticatedCopyWithImpl<SessionAuthenticated>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionAuthenticated&&(identical(other.me, me) || other.me == me)&&(identical(other.hasViewedRecoveryPhrase, hasViewedRecoveryPhrase) || other.hasViewedRecoveryPhrase == hasViewedRecoveryPhrase));
}


@override
int get hashCode {
    return Object.hash(runtimeType,me,hasViewedRecoveryPhrase);
}

@override
String toString() {
    return 'SessionState.authenticated(me: $me, hasViewedRecoveryPhrase: $hasViewedRecoveryPhrase)';
}


}

/// @nodoc
abstract mixin class $SessionAuthenticatedCopyWith<$Res> implements $SessionStateCopyWith<$Res> {
  factory $SessionAuthenticatedCopyWith(SessionAuthenticated value, $Res Function(SessionAuthenticated) _then) = _$SessionAuthenticatedCopyWithImpl;
@useResult
$Res call({
 UserModel me, bool hasViewedRecoveryPhrase
});


$UserModelCopyWith<$Res> get me;

}
/// @nodoc
class _$SessionAuthenticatedCopyWithImpl<$Res>
    implements $SessionAuthenticatedCopyWith<$Res> {
  _$SessionAuthenticatedCopyWithImpl(this._self, this._then);

  final SessionAuthenticated _self;
  final $Res Function(SessionAuthenticated) _then;

/// Create a copy of SessionState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? me = null,Object? hasViewedRecoveryPhrase = null,}) {
  return _then(SessionAuthenticated(
me: null == me ? _self.me : me // ignore: cast_nullable_to_non_nullable
as UserModel,hasViewedRecoveryPhrase: null == hasViewedRecoveryPhrase ? _self.hasViewedRecoveryPhrase : hasViewedRecoveryPhrase // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of SessionState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserModelCopyWith<$Res> get me {
  
  return $UserModelCopyWith<$Res>(_self.me, (value) {
    return _then(_self.copyWith(me: value));
  });
}
}

// dart format on

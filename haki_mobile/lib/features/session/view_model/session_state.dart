import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../models/user_model.dart';

part 'session_state.freezed.dart';

@freezed
sealed class SessionState with _$SessionState {
  const SessionState._();

  const factory SessionState.initializing() = SessionInitializing;
  const factory SessionState.unauthenticated() = SessionUnauthenticated;

  /// Just registered: show the 12 recovery words before entering the app.
  const factory SessionState.onboarding({required UserModel me, required String mnemonic}) =
      SessionOnboarding;

  /// Signed in, but this phone has no copy of the account's key (new or reset phone).
  /// The 12 words recreate it, so every phone of the account can read messages.
  const factory SessionState.needsRecovery({required UserModel me}) = SessionNeedsRecovery;

  const factory SessionState.authenticated({
    required UserModel me,
    @Default(false) bool hasViewedRecoveryPhrase,
  }) = SessionAuthenticated;

  UserModel? get me => switch (this) {
    SessionOnboarding(:final me) || SessionAuthenticated(:final me) || SessionNeedsRecovery(:final me) => me,
    _ => null,
  };

  /// The user once the app can actually read messages (keys ready, socket open).
  UserModel? get readyUser => switch (this) {
    SessionOnboarding(:final me) || SessionAuthenticated(:final me) => me,
    _ => null,
  };
}

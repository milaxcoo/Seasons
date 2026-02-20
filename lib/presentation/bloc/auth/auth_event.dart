part of 'auth_bloc.dart';

// The base abstract class for all authentication-related events.
// Extending Equatable allows for value-based comparisons.
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

// This event is dispatched when the application first starts.
// It signals the BLoC to check if a user is already logged in.
class AppStarted extends AuthEvent {}

// This event is dispatched after the user completes WebView-based authentication.
class LoggedIn extends AuthEvent {
  const LoggedIn();
}

// This event is dispatched when the user taps the "Logout" button.
class LoggedOut extends AuthEvent {}

// Internal event to update the user's display name after async fetch.
class _UpdateUserLogin extends AuthEvent {
  final String userLogin;

  const _UpdateUserLogin(this.userLogin);

  @override
  List<Object> get props => [userLogin];
}

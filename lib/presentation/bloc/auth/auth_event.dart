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

// This event is dispatched when the user taps the "Sign In" button.
// It carries the login and password credentials entered by the user.
class LoggedIn extends AuthEvent {
  final String login;
  final String password;

  const LoggedIn({required this.login, required this.password});

  @override
  List<Object> get props => [login, password];
}

// This event is dispatched when the user taps the "Logout" button.
class LoggedOut extends AuthEvent {}

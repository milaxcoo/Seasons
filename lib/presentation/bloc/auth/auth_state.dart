part of 'auth_bloc.dart';

// The base abstract class for all authentication states.
// Extending Equatable is crucial for the BLoC to efficiently compare
// states and prevent unnecessary UI rebuilds.
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object> get props => [];
}

// The initial state of the BLoC before any events have been processed.
// The UI might show a loading indicator or splash screen in this state.
class AuthInitial extends AuthState {}

// Represents a state where an authentication process (like logging in)
// is currently in progress. The UI should show a loading indicator.
class AuthLoading extends AuthState {}

// Represents a successfully authenticated user.
// It carries the user's login name to be displayed in the UI (e.g., ProfileScreen).
class AuthAuthenticated extends AuthState {
  final String userLogin;

  const AuthAuthenticated({required this.userLogin});

  @override
  List<Object> get props => [userLogin];
}

// Represents a state where the user is not authenticated.
// This is the state after a logout or if no token was found on app start.
// The UI should show the LoginScreen.
class AuthUnauthenticated extends AuthState {}

// Represents a state where an authentication attempt has failed.
// It carries an error message that can be displayed to the user.
class AuthFailure extends AuthState {
  final String error;

  const AuthFailure({required this.error});

  @override
  List<Object> get props => [error];
}

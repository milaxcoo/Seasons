import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:seasons/data/repositories/voting_repository.dart';

// The 'part' directives link this file with its corresponding event and state files.
// This is a common pattern in BLoC to keep the related classes organized
// while allowing them to be part of the same library.
part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final VotingRepository _votingRepository;

  AuthBloc({required VotingRepository votingRepository})
      : _votingRepository = votingRepository,
        super(AuthInitial()) {
    // Register event handlers for each type of AuthEvent.
    // When an event is added to the BLoC, the corresponding handler is executed.
    on<AppStarted>(_onAppStarted);
    on<LoggedIn>(_onLoggedIn);
    on<LoggedOut>(_onLoggedOut);
  }

  // Handler for the AppStarted event.
  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    try {
      // Check if an authentication token is already stored on the device.
      final String? token = await _votingRepository.getAuthToken();

      if (token != null) {
        // If a token exists, the user is considered authenticated.
        final userLogin = await _votingRepository.getUserLogin();
        emit(AuthAuthenticated(userLogin: userLogin));
      } else {
        // If no token is found, the user is unauthenticated.
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      // If any error occurs (e.g., reading from secure storage fails),
      // default to the unauthenticated state.
      emit(AuthUnauthenticated());
    }
  }

  // Handler for the LoggedIn event.
  Future<void> _onLoggedIn(LoggedIn event, Emitter<AuthState> emit) async {
    // Emit the loading state to let the UI know an operation is in progress.
    emit(AuthLoading());
    try {
      // Attempt to log in using the credentials from the event.
      await _votingRepository.login(event.login, event.password);
      final userLogin = await _votingRepository.getUserLogin();
      // On success, emit the authenticated state.
      emit(AuthAuthenticated(userLogin: userLogin));
    } catch (e) {
      // On failure, emit a failure state with the error message.
      emit(AuthFailure(error: e.toString()));
      // After showing the error, revert to the unauthenticated state
      // so the user can see the login form again.
      emit(AuthUnauthenticated());
    }
  }

  // Handler for the LoggedOut event.
  Future<void> _onLoggedOut(LoggedOut event, Emitter<AuthState> emit) async {
    // Tell the repository to clear the stored token.
    await _votingRepository.logout();
    // Emit the unauthenticated state.
    emit(AuthUnauthenticated());
  }
}

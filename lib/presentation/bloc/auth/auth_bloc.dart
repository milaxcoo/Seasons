import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:seasons/core/services/rudn_auth_service.dart';
import 'package:seasons/data/repositories/voting_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final VotingRepository _votingRepository;
  final RudnAuthService _authService;

  AuthBloc({
    required VotingRepository votingRepository,
    RudnAuthService? authService,
  })  : _votingRepository = votingRepository,
        _authService = authService ?? RudnAuthService(),
        super(AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<LoggedIn>(_onLoggedIn);
    on<LoggedOut>(_onLoggedOut);
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    final bool hasToken = await _authService.isAuthenticated();
    if (hasToken) {
      // For now, we don't have a way to get the user login from the cookie easily
      // without making an API call. For this MVP, we will assume if cookie is there,
      // we are authenticated. The user login string can be fetched if needed or mocked.

      // Attempt to get user login or just use a placeholder if appropriate,
      // but Repository might not have it yet.
      // Let's assume the repository can get it or we just set a default.
      final userLogin = await _votingRepository.getUserLogin() ?? "RUDN User";
      emit(AuthAuthenticated(userLogin: userLogin));
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLoggedIn(LoggedIn event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      // The secure cookie is already saved by the UI (RudnWebviewScreen) before calling this.
      // Now we fetch the real name
      final userLogin = await _votingRepository.getUserLogin() ?? "RUDN User";
      emit(AuthAuthenticated(userLogin: userLogin));
    } catch (e) {
      emit(AuthFailure(error: e.toString()));
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLoggedOut(LoggedOut event, Emitter<AuthState> emit) async {
    try {
      await _authService.logout();
      await _votingRepository.logout();
    } catch (_) {
      // Ignore logout errors
    }
    emit(AuthUnauthenticated());
  }
}

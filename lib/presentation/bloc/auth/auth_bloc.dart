import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/repositories/voting_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final VotingRepository _votingRepository;

  AuthBloc({required VotingRepository votingRepository})
      : _votingRepository = votingRepository,
        super(AuthInitial()) {
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<LoginRequested>(_onLoginRequested);
    on<LogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onCheckAuthStatus(
      CheckAuthStatus event, Emitter<AuthState> emit) async {
    // Check for a stored token on app startup
    final token = await _votingRepository.getAuthToken();
    if (token!= null) {
      final userLogin = await _votingRepository.getUserLogin();
      emit(AuthAuthenticated(userLogin: userLogin));
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLoginRequested(
      LoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _votingRepository.login(event.login, event.password);
      final userLogin = await _votingRepository.getUserLogin();
      emit(AuthAuthenticated(userLogin: userLogin));
    } catch (e) {
      emit(AuthFailure(error: e.toString()));
      // Revert to unauthenticated state after failure
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLogoutRequested(
      LogoutRequested event, Emitter<AuthState> emit) async {
    await _votingRepository.logout();
    emit(AuthUnauthenticated());
  }
}
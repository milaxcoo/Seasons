import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:seasons/data/repositories/voting_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final VotingRepository _votingRepository;

  AuthBloc({required VotingRepository votingRepository})
      : _votingRepository = votingRepository,
        super(AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<LoggedIn>(_onLoggedIn);
    on<LoggedOut>(_onLoggedOut);
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    final bool hasToken = await _votingRepository.getAuthToken() != null;
    if (hasToken) {
      // FIXED: Получаем userLogin, который теперь может быть null.
      final userLogin = await _votingRepository.getUserLogin();
      
      // FIXED: Добавляем проверку на null.
      if (userLogin != null) {
        emit(AuthAuthenticated(userLogin: userLogin));
      } else {
        // Если токен есть, а логина нет - что-то не так, считаем пользователя неавторизованным.
        emit(AuthUnauthenticated());
      }
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLoggedIn(LoggedIn event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _votingRepository.login(event.login, event.password);
      final userLogin = await _votingRepository.getUserLogin();
      
      // FIXED: Здесь тоже добавляем проверку на null.
      if (userLogin != null) {
        emit(AuthAuthenticated(userLogin: userLogin));
      } else {
        throw Exception('User login not found after authentication.');
      }
    } catch (e) {
      emit(AuthFailure(error: e.toString()));
      // После ошибки возвращаем в неавторизованное состояние.
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLoggedOut(LoggedOut event, Emitter<AuthState> emit) async {
    await _votingRepository.logout();
    emit(AuthUnauthenticated());
  }
}

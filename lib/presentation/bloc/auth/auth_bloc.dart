import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:seasons/data/repositories/voting_repository.dart';
import 'package:seasons/core/services/error_reporting_service.dart';

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
    on<_UpdateUserLogin>(_onUpdateUserLogin);
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    final bool hasToken = await _votingRepository.getAuthToken() != null;
    if (hasToken) {
      // Authenticate immediately with fallback name
      emit(const AuthAuthenticated(userLogin: 'RUDN User'));

      // Then try to fetch real name (non-blocking)
      try {
        final userLogin = await _votingRepository.getUserLogin();
        if (userLogin != null) {
          add(_UpdateUserLogin(userLogin));
        }
      } catch (e) {
        debugPrint('Failed to fetch user login on start: $e');
        // Keep fallback name — user is still authenticated
      }
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLoggedIn(LoggedIn event, Emitter<AuthState> emit) async {
    ErrorReportingService().reportEvent('auth_bloc_logged_in_received');
    // Cookie is already saved by WebView before popping.
    // No need to re-read it from storage — just authenticate immediately.
    emit(const AuthAuthenticated(userLogin: 'RUDN User'));
    ErrorReportingService().reportEvent('auth_bloc_authenticated_emitted');

    // Fetch real name asynchronously (non-blocking)
    _votingRepository.getUserLogin().then((name) {
      if (name != null) {
        add(_UpdateUserLogin(name));
        ErrorReportingService().reportEvent('auth_bloc_name_fetched', details: {
          'name_length': '${name.length}',
        });
      }
    }).catchError((e) {
      debugPrint('Failed to fetch user login: $e');
      ErrorReportingService().reportEvent('auth_bloc_name_fetch_failed', details: {
        'error': e.toString(),
      });
    });
  }

  void _onUpdateUserLogin(_UpdateUserLogin event, Emitter<AuthState> emit) {
    // Only update if still authenticated
    if (state is AuthAuthenticated) {
      emit(AuthAuthenticated(userLogin: event.userLogin));
    }
  }

  Future<void> _onLoggedOut(LoggedOut event, Emitter<AuthState> emit) async {
    try {
      await _votingRepository.logout();
    } catch (_) {
      // Ignore logout errors - user should be logged out locally regardless
    }
    emit(AuthUnauthenticated());
  }
}

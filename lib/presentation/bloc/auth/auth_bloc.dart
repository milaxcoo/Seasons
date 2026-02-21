import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:seasons/data/repositories/voting_repository.dart';
import 'package:seasons/core/services/error_reporting_service.dart';
import 'package:seasons/core/utils/safe_log.dart';

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
      // Validate the stored cookie by checking with the server
      try {
        final userLogin = await _votingRepository.getUserLogin();
        if (userLogin != null) {
          // Session is valid — user is authenticated
          emit(AuthAuthenticated(userLogin: userLogin));
          ErrorReportingService().reportEvent('app_start_session_valid');
        } else {
          // Server didn't confirm the session — cookie is stale
          try {
            await _votingRepository.logout(); // Clear the stale cookie
          } catch (_) {
            // If backend logout fails, we still clear local auth state.
          }
          emit(AuthUnauthenticated());
          ErrorReportingService().reportEvent('app_start_session_stale');
        }
      } on TimeoutException {
        // Temporary network timeout — assume session may still be valid,
        // do not force logout to avoid unnecessary re-authentication.
        emit(const AuthAuthenticated(userLogin: 'RUDN User'));
        ErrorReportingService().reportEvent('app_start_validation_timeout');

        // Fetch real name asynchronously (non-blocking), similar to _onLoggedIn
        Future<String?>.sync(_votingRepository.getUserLogin).then((name) {
          if (name != null) {
            add(_UpdateUserLogin(name));
            ErrorReportingService()
                .reportEvent('app_start_name_fetched_after_timeout');
          }
        }).catchError((e) {
          debugPrint(
            'Failed to fetch user login after timeout: ${sanitizeObjectForLog(e)}',
          );
          ErrorReportingService().reportEvent(
            'app_start_name_fetch_failed_after_timeout',
            details: {
              'exception_type': e.runtimeType.toString(),
            },
          );
        });
      } catch (e) {
        // Network error — can't validate, clear cookie to be safe
        try {
          await _votingRepository.logout();
        } catch (_) {
          // Local state should still move to unauthenticated.
        }
        emit(AuthUnauthenticated());
        ErrorReportingService()
            .reportEvent('app_start_validation_failed', details: {
          'exception_type': e.runtimeType.toString(),
        });
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
    Future<String?>.sync(_votingRepository.getUserLogin).then((name) {
      if (name != null) {
        add(_UpdateUserLogin(name));
        ErrorReportingService().reportEvent('auth_bloc_name_fetched');
      }
    }).catchError((e) {
      debugPrint('Failed to fetch user login: ${sanitizeObjectForLog(e)}');
      ErrorReportingService()
          .reportEvent('auth_bloc_name_fetch_failed', details: {
        'exception_type': e.runtimeType.toString(),
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

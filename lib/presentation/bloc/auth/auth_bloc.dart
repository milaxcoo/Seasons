import 'dart:async';
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:seasons/core/services/draft_service.dart';
import 'package:seasons/core/services/webview_session_service.dart';
import 'package:seasons/data/repositories/voting_repository.dart';
import 'package:seasons/core/services/error_reporting_service.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  static const int _maxStartupValidationAttempts = 2;
  static const Duration _startupValidationRetryDelay = Duration(
    milliseconds: 250,
  );
  static const int _maxPostLoginValidationAttempts = 2;
  static const Duration _postLoginValidationRetryDelay = Duration(
    milliseconds: 250,
  );

  final VotingRepository _votingRepository;
  final DraftService _draftService;
  final WebViewSessionService _webViewSessionService;

  AuthBloc({
    required VotingRepository votingRepository,
    DraftService? draftService,
    WebViewSessionService? webViewSessionService,
  })  : _draftService = draftService ?? DraftService(),
        _webViewSessionService =
            webViewSessionService ?? WebViewSessionService(),
        _votingRepository = votingRepository,
        super(AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<LoggedIn>(_onLoggedIn);
    on<LoggedOut>(_onLoggedOut);
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    emit(AuthChecking());

    final token = await _votingRepository.getAuthToken();
    final bool hasToken = token != null && token.isNotEmpty;
    if (!hasToken) {
      emit(AuthUnauthenticated());
      return;
    }

    for (var attempt = 1; attempt <= _maxStartupValidationAttempts; attempt++) {
      try {
        final userLogin = await _votingRepository.getUserLogin();
        if (userLogin != null) {
          // Session is valid — user is authenticated
          emit(AuthAuthenticated(userLogin: userLogin));
          ErrorReportingService().reportEvent('app_start_session_valid');
          return;
        }

        await _clearSessionAndEmitUnauthenticated(emit);
        ErrorReportingService().reportEvent('app_start_session_invalid');
        return;
      } on SessionValidationException catch (e) {
        final shouldRetry = attempt < _maxStartupValidationAttempts;
        ErrorReportingService().reportEvent(
          'app_start_validation_transient',
          details: {
            'attempt': '$attempt',
            'will_retry': '$shouldRetry',
            'exception_type': e.runtimeType.toString(),
          },
        );
        if (shouldRetry) {
          await Future<void>.delayed(_startupValidationRetryDelay);
          continue;
        }
      } on TimeoutException catch (e) {
        final shouldRetry = attempt < _maxStartupValidationAttempts;
        ErrorReportingService().reportEvent(
          'app_start_validation_transient',
          details: {
            'attempt': '$attempt',
            'will_retry': '$shouldRetry',
            'exception_type': e.runtimeType.toString(),
          },
        );
        if (shouldRetry) {
          await Future<void>.delayed(_startupValidationRetryDelay);
          continue;
        }
      } on SocketException catch (e) {
        final shouldRetry = attempt < _maxStartupValidationAttempts;
        ErrorReportingService().reportEvent(
          'app_start_validation_transient',
          details: {
            'attempt': '$attempt',
            'will_retry': '$shouldRetry',
            'exception_type': e.runtimeType.toString(),
          },
        );
        if (shouldRetry) {
          await Future<void>.delayed(_startupValidationRetryDelay);
          continue;
        }
      } catch (e) {
        final shouldRetry = attempt < _maxStartupValidationAttempts;
        ErrorReportingService().reportEvent(
          'app_start_validation_transient',
          details: {
            'attempt': '$attempt',
            'will_retry': '$shouldRetry',
            'exception_type': e.runtimeType.toString(),
          },
        );
        if (shouldRetry) {
          await Future<void>.delayed(_startupValidationRetryDelay);
          continue;
        }
      }
    }

    // On repeated transient failures, keep cookie untouched but require explicit login.
    emit(AuthUnauthenticated());
    ErrorReportingService().reportEvent('app_start_validation_fallback_unauth');
  }

  Future<void> _clearSessionAndEmitUnauthenticated(
    Emitter<AuthState> emit,
  ) async {
    try {
      await _votingRepository.logout();
    } catch (_) {
      // If backend/local logout cleanup fails, state must still be unauthenticated.
    }

    try {
      await _webViewSessionService.clearOnLogout();
    } catch (_) {
      // WebView session cleanup should not block invalidation transitions.
    }

    try {
      await _draftService.clearAllDrafts();
    } catch (_) {
      // Draft cleanup should not block logout/invalidation transitions.
    }

    emit(AuthUnauthenticated());
  }

  Future<void> _onLoggedIn(LoggedIn event, Emitter<AuthState> emit) async {
    ErrorReportingService().reportEvent('auth_bloc_logged_in_received');
    emit(AuthChecking());

    for (var attempt = 1;
        attempt <= _maxPostLoginValidationAttempts;
        attempt++) {
      try {
        final userLogin = await _votingRepository.getUserLogin();
        if (userLogin != null && userLogin.isNotEmpty) {
          emit(AuthAuthenticated(userLogin: userLogin));
          ErrorReportingService().reportEvent(
            'auth_bloc_authenticated_emitted',
          );
          return;
        }

        await _clearSessionAndEmitUnauthenticated(emit);
        emit(
          const AuthFailure(
            error: 'Login session could not be validated. Please try again.',
          ),
        );
        ErrorReportingService().reportEvent('auth_bloc_validation_failed');
        return;
      } on UnauthorizedSessionException catch (e) {
        await _clearSessionAndEmitUnauthenticated(emit);
        emit(
          const AuthFailure(
            error: 'Login session expired. Please sign in again.',
          ),
        );
        ErrorReportingService().reportEvent(
          'auth_bloc_validation_failed',
          details: {'exception_type': e.runtimeType.toString()},
        );
        return;
      } on SessionValidationException catch (e) {
        final shouldRetry = attempt < _maxPostLoginValidationAttempts;
        if (!shouldRetry) break;
        ErrorReportingService().reportEvent(
          'auth_bloc_validation_transient',
          details: {
            'attempt': '$attempt',
            'exception_type': e.runtimeType.toString(),
          },
        );
        await Future<void>.delayed(_postLoginValidationRetryDelay);
      } on TimeoutException catch (e) {
        final shouldRetry = attempt < _maxPostLoginValidationAttempts;
        if (!shouldRetry) break;
        ErrorReportingService().reportEvent(
          'auth_bloc_validation_transient',
          details: {
            'attempt': '$attempt',
            'exception_type': e.runtimeType.toString(),
          },
        );
        await Future<void>.delayed(_postLoginValidationRetryDelay);
      } on SocketException catch (e) {
        final shouldRetry = attempt < _maxPostLoginValidationAttempts;
        if (!shouldRetry) break;
        ErrorReportingService().reportEvent(
          'auth_bloc_validation_transient',
          details: {
            'attempt': '$attempt',
            'exception_type': e.runtimeType.toString(),
          },
        );
        await Future<void>.delayed(_postLoginValidationRetryDelay);
      } catch (e) {
        final shouldRetry = attempt < _maxPostLoginValidationAttempts;
        if (!shouldRetry) break;
        ErrorReportingService().reportEvent(
          'auth_bloc_validation_transient',
          details: {
            'attempt': '$attempt',
            'exception_type': e.runtimeType.toString(),
          },
        );
        await Future<void>.delayed(_postLoginValidationRetryDelay);
      }
    }

    await _clearSessionAndEmitUnauthenticated(emit);
    emit(
      const AuthFailure(
        error:
            'Unable to validate login session. Check connection and try again.',
      ),
    );
    ErrorReportingService().reportEvent('auth_bloc_validation_fallback_unauth');
  }

  Future<void> _onLoggedOut(LoggedOut event, Emitter<AuthState> emit) async {
    bool logoutInvocationFailed = false;
    try {
      await _votingRepository.logout();
    } catch (_) {
      logoutInvocationFailed = true;
    }

    try {
      final tokenAfterLogout = await _votingRepository.getAuthToken();
      final hasTokenAfterLogout =
          tokenAfterLogout != null && tokenAfterLogout.isNotEmpty;
      if (hasTokenAfterLogout) {
        emit(
          const AuthFailure(
            error:
                'Could not clear local session. Please try logging out again.',
          ),
        );
        return;
      }
    } catch (_) {
      emit(
        const AuthFailure(error: 'Could not verify logout. Please try again.'),
      );
      return;
    }

    if (logoutInvocationFailed) {
      emit(
        const AuthFailure(
          error: 'Logout did not complete cleanly. Please try again.',
        ),
      );
      return;
    }

    try {
      await _webViewSessionService.clearOnLogout();
    } catch (_) {
      // WebView session cleanup should not block logout transitions.
    }

    try {
      await _draftService.clearAllDrafts();
    } catch (_) {
      // Draft cleanup should not block logout transitions.
    }
    emit(AuthUnauthenticated());
  }
}

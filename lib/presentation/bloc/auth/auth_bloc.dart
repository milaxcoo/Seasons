import 'dart:async';
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:seasons/core/services/draft_service.dart';
import 'package:seasons/data/repositories/voting_repository.dart';
import 'package:seasons/core/services/error_reporting_service.dart';
import 'package:seasons/core/utils/safe_log.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final VotingRepository _votingRepository;
  final DraftService _draftService;

  AuthBloc({
    required VotingRepository votingRepository,
    DraftService? draftService,
  })  : _draftService = draftService ?? DraftService(),
        _votingRepository = votingRepository,
        super(AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<LoggedIn>(_onLoggedIn);
    on<LoggedOut>(_onLoggedOut);
    on<_UpdateUserLogin>(_onUpdateUserLogin);
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    final token = await _votingRepository.getAuthToken();
    final bool hasToken = token != null && token.isNotEmpty;
    if (hasToken) {
      // Validate the stored cookie by checking with the server
      try {
        final userLogin = await _votingRepository.getUserLogin();
        if (userLogin != null) {
          // Session is valid — user is authenticated
          emit(AuthAuthenticated(userLogin: userLogin));
          ErrorReportingService().reportEvent('app_start_session_valid');
        } else {
          await _clearSessionAndEmitUnauthenticated(emit);
          ErrorReportingService().reportEvent('app_start_session_invalid');
        }
      } on SessionValidationException catch (e) {
        _handleTransientValidationFailure(emit, e);
      } on TimeoutException catch (e) {
        _handleTransientValidationFailure(emit, e);
      } on SocketException catch (e) {
        _handleTransientValidationFailure(emit, e);
      } catch (e) {
        _handleTransientValidationFailure(emit, e);
      }
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _clearSessionAndEmitUnauthenticated(
      Emitter<AuthState> emit) async {
    try {
      await _votingRepository.logout();
    } catch (_) {
      // If backend/local logout cleanup fails, state must still be unauthenticated.
    }

    try {
      await _draftService.clearAllDrafts();
    } catch (_) {
      // Draft cleanup should not block logout/invalidation transitions.
    }

    emit(AuthUnauthenticated());
  }

  void _handleTransientValidationFailure(
      Emitter<AuthState> emit, Object error) {
    // Keep session on transient failures to avoid forcing unnecessary relogin.
    emit(const AuthAuthenticated(userLogin: 'RUDN User'));
    ErrorReportingService().reportEvent(
      'app_start_validation_transient',
      details: {
        'exception_type': error.runtimeType.toString(),
      },
    );

    _refreshUserNameAfterTransientFailure();
  }

  void _refreshUserNameAfterTransientFailure() {
    // Fetch real name asynchronously (non-blocking), same UX as login timeout path.
    Future<String?>.sync(_votingRepository.getUserLogin).then((name) {
      if (name != null) {
        add(_UpdateUserLogin(name));
        ErrorReportingService().reportEvent(
          'app_start_name_fetched_after_transient',
        );
      }
    }).catchError((e) {
      debugPrint(
        'Failed to fetch user login after transient validation error: ${sanitizeObjectForLog(e)}',
      );
      ErrorReportingService().reportEvent(
        'app_start_name_fetch_failed_after_transient',
        details: {
          'exception_type': e.runtimeType.toString(),
        },
      );
    });
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
    await _clearSessionAndEmitUnauthenticated(emit);
  }
}

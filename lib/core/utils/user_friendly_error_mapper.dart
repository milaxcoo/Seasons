import 'package:seasons/l10n/app_localizations.dart';

enum UserErrorContext { generic, registration, voteSubmit, dataLoad, auth }

class UserFriendlyErrorMapper {
  static String toMessage(
    AppLocalizations l10n,
    Object? error, {
    UserErrorContext context = UserErrorContext.generic,
  }) {
    final raw = error?.toString() ?? '';
    final normalized = raw.toLowerCase();

    if (isAlreadyVotedError(raw)) {
      return l10n.alreadyVotedError;
    }
    if (_isSessionExpired(normalized)) {
      return l10n.sessionExpiredReLogin;
    }
    if (_isTimeout(normalized)) {
      return l10n.timeoutError;
    }
    if (_isNetwork(normalized)) {
      return l10n.networkError;
    }
    if (_isServerUnavailable(normalized)) {
      return l10n.serverUnavailable;
    }

    switch (context) {
      case UserErrorContext.registration:
        return l10n.registrationFailed;
      case UserErrorContext.voteSubmit:
        return l10n.voteSubmitFailed;
      case UserErrorContext.dataLoad:
        return l10n.dataLoadFailed;
      case UserErrorContext.auth:
        return l10n.unexpectedError;
      case UserErrorContext.generic:
        return l10n.genericError;
    }
  }

  static bool isAlreadyVotedError(Object? error) {
    final normalized = (error?.toString() ?? '').toLowerCase();
    return normalized.contains('already voted') ||
        normalized.contains('already_voted') ||
        normalized.contains('уже проголос');
  }

  static bool isAuthInvalidAction(String? action) {
    return (action ?? '').toLowerCase().trim() == 'auth_invalid';
  }

  static bool _isSessionExpired(String normalized) {
    return normalized.contains('sessionvalidationexception') ||
        normalized.contains('auth_invalid') ||
        normalized.contains('session expired') ||
        normalized.contains('missing auth cookie') ||
        normalized.contains('unauthorized') ||
        normalized.contains('forbidden') ||
        normalized.contains('401') ||
        normalized.contains('403');
  }

  static bool _isTimeout(String normalized) {
    return normalized.contains('timeoutexception') ||
        normalized.contains('timed out') ||
        normalized.contains('timeout');
  }

  static bool _isNetwork(String normalized) {
    return normalized.contains('socketexception') ||
        normalized.contains('failed host lookup') ||
        normalized.contains('network') ||
        normalized.contains('connection');
  }

  static bool _isServerUnavailable(String normalized) {
    return normalized.contains('500') ||
        normalized.contains('502') ||
        normalized.contains('503') ||
        normalized.contains('504') ||
        normalized.contains('server error') ||
        normalized.contains('service unavailable');
  }
}

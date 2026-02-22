import 'package:seasons/presentation/bloc/auth/auth_bloc.dart';

enum AuthBackgroundServiceAction {
  none,
  start,
  stop,
}

AuthBackgroundServiceAction backgroundServiceActionForAuthTransition({
  required AuthState previous,
  required AuthState current,
}) {
  final isStartTransition =
      previous is! AuthAuthenticated && current is AuthAuthenticated;
  if (isStartTransition) {
    return AuthBackgroundServiceAction.start;
  }

  final isStopTransition =
      previous is AuthAuthenticated && current is AuthUnauthenticated;
  if (isStopTransition) {
    return AuthBackgroundServiceAction.stop;
  }

  return AuthBackgroundServiceAction.none;
}

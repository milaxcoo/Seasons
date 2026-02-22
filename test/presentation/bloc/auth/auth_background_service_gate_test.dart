import 'package:flutter_test/flutter_test.dart';
import 'package:seasons/presentation/bloc/auth/auth_background_service_gate.dart';
import 'package:seasons/presentation/bloc/auth/auth_bloc.dart';

void main() {
  group('backgroundServiceActionForAuthTransition', () {
    test('returns start on unauthenticated to authenticated transition', () {
      final action = backgroundServiceActionForAuthTransition(
        previous: AuthUnauthenticated(),
        current: const AuthAuthenticated(userLogin: 'user'),
      );

      expect(action, AuthBackgroundServiceAction.start);
    });

    test('returns stop on authenticated to unauthenticated transition', () {
      final action = backgroundServiceActionForAuthTransition(
        previous: const AuthAuthenticated(userLogin: 'user'),
        current: AuthUnauthenticated(),
      );

      expect(action, AuthBackgroundServiceAction.stop);
    });

    test('returns none on initial to unauthenticated transition', () {
      final action = backgroundServiceActionForAuthTransition(
        previous: AuthInitial(),
        current: AuthUnauthenticated(),
      );

      expect(action, AuthBackgroundServiceAction.none);
    });

    test('returns none on checking to unauthenticated transition', () {
      final action = backgroundServiceActionForAuthTransition(
        previous: AuthChecking(),
        current: AuthUnauthenticated(),
      );

      expect(action, AuthBackgroundServiceAction.none);
    });

    test('returns start on checking to authenticated transition', () {
      final action = backgroundServiceActionForAuthTransition(
        previous: AuthChecking(),
        current: const AuthAuthenticated(userLogin: 'actual'),
      );

      expect(action, AuthBackgroundServiceAction.start);
    });

    test('returns none on authenticated to authenticated transition', () {
      final action = backgroundServiceActionForAuthTransition(
        previous: const AuthAuthenticated(userLogin: 'placeholder'),
        current: const AuthAuthenticated(userLogin: 'actual'),
      );

      expect(action, AuthBackgroundServiceAction.none);
    });
  });
}

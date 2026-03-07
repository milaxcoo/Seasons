import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seasons/main.dart';
import 'package:seasons/presentation/bloc/auth/auth_bloc.dart';
import 'package:seasons/presentation/screens/home_screen.dart';
import 'package:seasons/presentation/screens/login_screen.dart';

void main() {
  test('authScreenKeyForState maps checking states to loader key', () {
    expect(authScreenKeyForState(AuthInitial()), 'auth-checking');
    expect(authScreenKeyForState(AuthChecking()), 'auth-checking');
  });

  test('authScreenKeyForState maps authenticated state to home key', () {
    expect(
      authScreenKeyForState(const AuthAuthenticated(userLogin: 'test')),
      'auth-home',
    );
  });

  test('authScreenKeyForState maps unauthenticated state to login key', () {
    expect(authScreenKeyForState(AuthUnauthenticated()), 'auth-login');
  });

  test(
    'authScreenForState maps authenticated state to HomeScreen with auth-home key',
    () {
      final widget = authScreenForState(
        const AuthAuthenticated(userLogin: 'test'),
      );
      expect(widget, isA<HomeScreen>());
      expect(widget.key, const ValueKey('auth-home'));
    },
  );

  test(
    'authScreenForState maps unauthenticated state to LoginScreen with auth-login key',
    () {
      final widget = authScreenForState(AuthUnauthenticated());
      expect(widget, isA<LoginScreen>());
      expect(widget.key, const ValueKey('auth-login'));
    },
  );

  test(
    'shouldStartBackgroundServiceForState only starts for authenticated',
    () {
      expect(shouldStartBackgroundServiceForState(AuthInitial()), isFalse);
      expect(shouldStartBackgroundServiceForState(AuthChecking()), isFalse);
      expect(
        shouldStartBackgroundServiceForState(AuthUnauthenticated()),
        isFalse,
      );
      expect(
        shouldStartBackgroundServiceForState(
          const AuthAuthenticated(userLogin: 'test'),
        ),
        isTrue,
      );
    },
  );

  test(
    'backgroundServiceTransitionReasonForState returns expected reasons',
    () {
      expect(
        backgroundServiceTransitionReasonForState(
          const AuthAuthenticated(userLogin: 'test'),
        ),
        'auth_transition:not_authenticated->authenticated',
      );
      expect(
        backgroundServiceTransitionReasonForState(AuthUnauthenticated()),
        'auth_transition:authenticated->AuthUnauthenticated',
      );
      expect(
        backgroundServiceTransitionReasonForState(
          const AuthFailure(error: 'session'),
        ),
        'auth_transition:authenticated->AuthFailure',
      );
    },
  );
}

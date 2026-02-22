import 'package:flutter_test/flutter_test.dart';
import 'package:seasons/main.dart';
import 'package:seasons/presentation/bloc/auth/auth_bloc.dart';

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
}

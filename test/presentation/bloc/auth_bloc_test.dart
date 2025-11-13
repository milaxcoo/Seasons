import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:seasons/data/repositories/voting_repository.dart';
import 'package:seasons/presentation/bloc/auth/auth_bloc.dart';

// A mock class for the repository, allowing us to control its behavior.
class MockVotingRepository extends Mock implements VotingRepository {}

void main() {
  // Group all tests related to the AuthBloc.
  group('AuthBloc', () {
    late VotingRepository mockVotingRepository;
    late AuthBloc authBloc;

    // setUp is called before each individual test.
    setUp(() {
      mockVotingRepository = MockVotingRepository();
      authBloc = AuthBloc(votingRepository: mockVotingRepository);
    });

    // Clean up after each test
    tearDown(() {
      authBloc.close();
    });

    // A simple test to ensure the initial state is correct.
    test('initial state is AuthInitial', () {
      expect(authBloc.state, equals(AuthInitial()));
    });

    group('AppStarted', () {
      // Test case for when the user is already logged in (token exists).
      blocTest<AuthBloc, AuthState>(
        'emits [AuthAuthenticated] when token and userLogin are found',
        build: () {
          when(() => mockVotingRepository.getAuthToken()).thenAnswer((_) async => 'some_token');
          when(() => mockVotingRepository.getUserLogin()).thenAnswer((_) async => 'testuser');
          return authBloc;
        },
        act: (bloc) => bloc.add(AppStarted()),
        expect: () => [const AuthAuthenticated(userLogin: 'testuser')],
        verify: (_) {
          verify(() => mockVotingRepository.getAuthToken()).called(1);
          verify(() => mockVotingRepository.getUserLogin()).called(1);
        },
      );

      // Test case for when the user is not logged in (no token).
      blocTest<AuthBloc, AuthState>(
        'emits [AuthUnauthenticated] when token is not found',
        build: () {
          when(() => mockVotingRepository.getAuthToken()).thenAnswer((_) async => null);
          return authBloc;
        },
        act: (bloc) => bloc.add(AppStarted()),
        expect: () => [AuthUnauthenticated()],
        verify: (_) {
          verify(() => mockVotingRepository.getAuthToken()).called(1);
          verifyNever(() => mockVotingRepository.getUserLogin());
        },
      );

      // Test case when token exists but userLogin is null
      blocTest<AuthBloc, AuthState>(
        'emits [AuthUnauthenticated] when token exists but userLogin is null',
        build: () {
          when(() => mockVotingRepository.getAuthToken()).thenAnswer((_) async => 'some_token');
          when(() => mockVotingRepository.getUserLogin()).thenAnswer((_) async => null);
          return authBloc;
        },
        act: (bloc) => bloc.add(AppStarted()),
        expect: () => [AuthUnauthenticated()],
        verify: (_) {
          verify(() => mockVotingRepository.getAuthToken()).called(1);
          verify(() => mockVotingRepository.getUserLogin()).called(1);
        },
      );
    });

    group('LoggedIn', () {
      // Test case for a successful login.
      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthAuthenticated] for a successful login',
        build: () {
          when(() => mockVotingRepository.login('user', 'pass')).thenAnswer((_) async => 'some_token');
          when(() => mockVotingRepository.getUserLogin()).thenAnswer((_) async => 'user');
          return authBloc;
        },
        act: (bloc) => bloc.add(const LoggedIn(login: 'user', password: 'pass')),
        expect: () => [
          AuthLoading(),
          const AuthAuthenticated(userLogin: 'user'),
        ],
        verify: (_) {
          verify(() => mockVotingRepository.login('user', 'pass')).called(1);
          verify(() => mockVotingRepository.getUserLogin()).called(1);
        },
      );

      // Test case for a failed login.
      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthFailure, AuthUnauthenticated] for a failed login',
        build: () {
          when(() => mockVotingRepository.login(any(), any())).thenThrow(Exception('Login failed'));
          return authBloc;
        },
        act: (bloc) => bloc.add(const LoggedIn(login: 'user', password: 'pass')),
        expect: () => [
          AuthLoading(),
          isA<AuthFailure>().having((s) => s.error, 'error', contains('Login failed')),
          AuthUnauthenticated(),
        ],
        verify: (_) {
          verify(() => mockVotingRepository.login('user', 'pass')).called(1);
        },
      );

      // Test case when login succeeds but userLogin is null
      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthFailure, AuthUnauthenticated] when login succeeds but userLogin is null',
        build: () {
          when(() => mockVotingRepository.login('user', 'pass')).thenAnswer((_) async => 'some_token');
          when(() => mockVotingRepository.getUserLogin()).thenAnswer((_) async => null);
          return authBloc;
        },
        act: (bloc) => bloc.add(const LoggedIn(login: 'user', password: 'pass')),
        expect: () => [
          AuthLoading(),
          isA<AuthFailure>().having((s) => s.error, 'error', contains('User login not found')),
          AuthUnauthenticated(),
        ],
      );

      // Test case with invalid credentials
      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthFailure, AuthUnauthenticated] for invalid credentials',
        build: () {
          when(() => mockVotingRepository.login('wrong', 'wrong'))
              .thenThrow(Exception('Invalid credentials'));
          return authBloc;
        },
        act: (bloc) => bloc.add(const LoggedIn(login: 'wrong', password: 'wrong')),
        expect: () => [
          AuthLoading(),
          isA<AuthFailure>().having((s) => s.error, 'error', contains('Invalid credentials')),
          AuthUnauthenticated(),
        ],
      );
    });

    group('LoggedOut', () {
      // Test case for logging out.
      blocTest<AuthBloc, AuthState>(
        'emits [AuthUnauthenticated] when LoggedOut is added',
        build: () {
          when(() => mockVotingRepository.logout()).thenAnswer((_) async {});
          return authBloc;
        },
        act: (bloc) => bloc.add(LoggedOut()),
        expect: () => [AuthUnauthenticated()],
        verify: (_) {
          verify(() => mockVotingRepository.logout()).called(1);
        },
      );

      // Test case when logout throws an error (should still emit unauthenticated)
      blocTest<AuthBloc, AuthState>(
        'emits [AuthUnauthenticated] even when logout throws an error',
        build: () {
          when(() => mockVotingRepository.logout()).thenThrow(Exception('Logout error'));
          return authBloc;
        },
        act: (bloc) => bloc.add(LoggedOut()),
        expect: () => [AuthUnauthenticated()],
      );
    });

    group('State Transitions', () {
      // Test multiple login attempts
      blocTest<AuthBloc, AuthState>(
        'handles multiple login attempts correctly',
        build: () {
          when(() => mockVotingRepository.login(any(), any())).thenAnswer((_) async => 'token');
          when(() => mockVotingRepository.getUserLogin()).thenAnswer((_) async => 'testuser');
          return authBloc;
        },
        act: (bloc) {
          bloc.add(const LoggedIn(login: 'user1', password: 'pass1'));
          bloc.add(const LoggedIn(login: 'user2', password: 'pass2'));
        },
        skip: 2, // Skip first login
        expect: () => [
          AuthLoading(),
          const AuthAuthenticated(userLogin: 'testuser'),
        ],
      );

      // Test login followed by logout
      blocTest<AuthBloc, AuthState>(
        'handles login followed by logout correctly',
        build: () {
          when(() => mockVotingRepository.login(any(), any())).thenAnswer((_) async => 'token');
          when(() => mockVotingRepository.getUserLogin()).thenAnswer((_) async => 'testuser');
          when(() => mockVotingRepository.logout()).thenAnswer((_) async {});
          return authBloc;
        },
        act: (bloc) {
          bloc.add(const LoggedIn(login: 'user', password: 'pass'));
          bloc.add(LoggedOut());
        },
        expect: () => [
          AuthLoading(),
          const AuthAuthenticated(userLogin: 'testuser'),
          AuthUnauthenticated(),
        ],
      );
    });
  });
}

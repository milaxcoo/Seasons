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
      // FIXED: Corrected the variable name to match the declaration.
      mockVotingRepository = MockVotingRepository();
      authBloc = AuthBloc(votingRepository: mockVotingRepository);
    });

    // A simple test to ensure the initial state is correct.
    test('initial state is AuthInitial', () {
      expect(authBloc.state, equals(AuthInitial()));
    });

    group('AppStarted', () {
      // Test case for when the user is already logged in (token exists).
      blocTest<AuthBloc, AuthState>(
        'emits [AuthAuthenticated] when token is found',
        // Arrange: Set up the mock repository to return a token.
        build: () {
          when(() => mockVotingRepository.getAuthToken()).thenAnswer((_) async => 'some_token');
          when(() => mockVotingRepository.getUserLogin()).thenAnswer((_) async => 'testuser');
          return authBloc;
        },
        // Act: Add the AppStarted event.
        act: (bloc) => bloc.add(AppStarted()),
        // Assert: Expect the BLoC to emit the AuthAuthenticated state.
        expect: () => [const AuthAuthenticated(userLogin: 'testuser')],
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
        // Assert: Expect a loading state, followed by the authenticated state.
        expect: () => [
          AuthLoading(),
          const AuthAuthenticated(userLogin: 'user'),
        ],
      );

      // Test case for a failed login.
      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthFailure, AuthUnauthenticated] for a failed login',
        build: () {
          // Arrange: Make the repository throw an error.
          when(() => mockVotingRepository.login(any(), any())).thenThrow(Exception('Login failed'));
          return authBloc;
        },
        act: (bloc) => bloc.add(const LoggedIn(login: 'user', password: 'pass')),
        // Assert: Expect loading, then failure, then back to the unauthenticated state.
        expect: () => [
          AuthLoading(),
          isA<AuthFailure>(),
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
      );
    });
  });
}

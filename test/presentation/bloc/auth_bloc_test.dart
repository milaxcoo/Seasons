import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:seasons/data/repositories/voting_repository.dart';
import 'package:seasons/presentation/bloc/auth/auth_bloc.dart';

class MockVotingRepository extends Mock implements VotingRepository {}

void main() {
  group('AuthBloc', () {
    late VotingRepository mockVotingRepository;
    late AuthBloc authBloc;

    setUp(() {
      mockVotingRepository = MockVotingRepository();
      authBloc = AuthBloc(votingRepository: mockVotingRepository);
    });

    tearDown(() {
      authBloc.close();
    });

    test('initial state is AuthInitial', () {
      expect(authBloc.state, equals(AuthInitial()));
    });

    group('AppStarted', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthAuthenticated] when token and userLogin are found',
        build: () {
          when(() => mockVotingRepository.getAuthToken())
              .thenAnswer((_) async => 'some_token');
          when(() => mockVotingRepository.getUserLogin())
              .thenAnswer((_) async => 'testuser');
          return authBloc;
        },
        act: (bloc) => bloc.add(AppStarted()),
        expect: () => [const AuthAuthenticated(userLogin: 'testuser')],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthUnauthenticated] when token is not found',
        build: () {
          when(() => mockVotingRepository.getAuthToken())
              .thenAnswer((_) async => null);
          return authBloc;
        },
        act: (bloc) => bloc.add(AppStarted()),
        expect: () => [AuthUnauthenticated()],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthUnauthenticated] and clears stale session when userLogin is null',
        build: () {
          when(() => mockVotingRepository.getAuthToken())
              .thenAnswer((_) async => 'some_token');
          when(() => mockVotingRepository.getUserLogin())
              .thenAnswer((_) async => null);
          when(() => mockVotingRepository.logout()).thenAnswer((_) async {});
          return authBloc;
        },
        act: (bloc) => bloc.add(AppStarted()),
        expect: () => [AuthUnauthenticated()],
        verify: (_) {
          verify(() => mockVotingRepository.logout()).called(1);
        },
      );
    });

    group('LoggedIn', () {
      blocTest<AuthBloc, AuthState>(
        'emits placeholder auth state first, then resolved user name',
        build: () {
          when(() => mockVotingRepository.getUserLogin())
              .thenAnswer((_) async => 'user');
          return authBloc;
        },
        act: (bloc) =>
            bloc.add(const LoggedIn(login: 'user', password: 'pass')),
        expect: () => const [
          AuthAuthenticated(userLogin: 'RUDN User'),
          AuthAuthenticated(userLogin: 'user'),
        ],
        verify: (_) {
          verifyNever(() => mockVotingRepository.login(any(), any()));
          verify(() => mockVotingRepository.getUserLogin()).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits only placeholder auth state when resolved user name is null',
        build: () {
          when(() => mockVotingRepository.getUserLogin())
              .thenAnswer((_) async => null);
          return authBloc;
        },
        act: (bloc) =>
            bloc.add(const LoggedIn(login: 'user', password: 'pass')),
        expect: () => const [
          AuthAuthenticated(userLogin: 'RUDN User'),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits only placeholder auth state when name lookup throws',
        build: () {
          when(() => mockVotingRepository.getUserLogin())
              .thenThrow(Exception('Lookup failed'));
          return authBloc;
        },
        act: (bloc) =>
            bloc.add(const LoggedIn(login: 'user', password: 'pass')),
        expect: () => const [
          AuthAuthenticated(userLogin: 'RUDN User'),
        ],
      );
    });

    group('LoggedOut', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthUnauthenticated] when LoggedOut is added',
        build: () {
          when(() => mockVotingRepository.logout()).thenAnswer((_) async {});
          return authBloc;
        },
        act: (bloc) => bloc.add(LoggedOut()),
        expect: () => [AuthUnauthenticated()],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthUnauthenticated] even when logout throws',
        build: () {
          when(() => mockVotingRepository.logout())
              .thenThrow(Exception('Logout error'));
          return authBloc;
        },
        act: (bloc) => bloc.add(LoggedOut()),
        expect: () => [AuthUnauthenticated()],
      );
    });

    blocTest<AuthBloc, AuthState>(
      'handles login followed by logout',
      build: () {
        when(() => mockVotingRepository.getUserLogin())
            .thenAnswer((_) async => 'testuser');
        when(() => mockVotingRepository.logout()).thenAnswer((_) async {});
        return authBloc;
      },
      act: (bloc) async {
        bloc.add(const LoggedIn(login: 'user', password: 'pass'));
        await Future<void>.delayed(const Duration(milliseconds: 20));
        bloc.add(LoggedOut());
      },
      expect: () => [
        const AuthAuthenticated(userLogin: 'RUDN User'),
        const AuthAuthenticated(userLogin: 'testuser'),
        AuthUnauthenticated(),
      ],
    );
  });
}

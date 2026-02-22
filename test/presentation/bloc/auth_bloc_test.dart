import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:seasons/core/services/draft_service.dart';
import 'package:seasons/data/repositories/voting_repository.dart';
import 'package:seasons/presentation/bloc/auth/auth_bloc.dart';

class MockVotingRepository extends Mock implements VotingRepository {}

class MockDraftService extends Mock implements DraftService {}

void main() {
  group('AuthBloc', () {
    late VotingRepository mockVotingRepository;
    late DraftService mockDraftService;
    late AuthBloc authBloc;

    setUp(() {
      mockVotingRepository = MockVotingRepository();
      mockDraftService = MockDraftService();
      when(() => mockDraftService.clearAllDrafts()).thenAnswer((_) async {});
      authBloc = AuthBloc(
        votingRepository: mockVotingRepository,
        draftService: mockDraftService,
      );
    });

    tearDown(() {
      authBloc.close();
    });

    test('initial state is AuthInitial', () {
      expect(authBloc.state, equals(AuthInitial()));
    });

    group('AppStarted', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthChecking, AuthAuthenticated] when token and userLogin are found',
        build: () {
          when(() => mockVotingRepository.getAuthToken())
              .thenAnswer((_) async => 'some_token');
          when(() => mockVotingRepository.getUserLogin())
              .thenAnswer((_) async => 'testuser');
          return authBloc;
        },
        act: (bloc) => bloc.add(AppStarted()),
        expect: () => [
          AuthChecking(),
          const AuthAuthenticated(userLogin: 'testuser'),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthChecking, AuthUnauthenticated] when token is not found',
        build: () {
          when(() => mockVotingRepository.getAuthToken())
              .thenAnswer((_) async => null);
          return authBloc;
        },
        act: (bloc) => bloc.add(AppStarted()),
        expect: () => [AuthChecking(), AuthUnauthenticated()],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthChecking, AuthUnauthenticated] and clears stale session when userLogin is null',
        build: () {
          when(() => mockVotingRepository.getAuthToken())
              .thenAnswer((_) async => 'some_token');
          when(() => mockVotingRepository.getUserLogin())
              .thenAnswer((_) async => null);
          when(() => mockVotingRepository.logout()).thenAnswer((_) async {});
          return authBloc;
        },
        act: (bloc) => bloc.add(AppStarted()),
        expect: () => [AuthChecking(), AuthUnauthenticated()],
        verify: (_) {
          verify(() => mockVotingRepository.logout()).called(1);
          verify(() => mockDraftService.clearAllDrafts()).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthChecking, AuthUnauthenticated] when getUserLogin times out and does not call logout',
        build: () {
          when(() => mockVotingRepository.getAuthToken())
              .thenAnswer((_) async => 'some_token');
          // Both startup validation attempts time out.
          when(() => mockVotingRepository.getUserLogin())
              .thenThrow(TimeoutException('timed out'));
          return authBloc;
        },
        act: (bloc) => bloc.add(AppStarted()),
        wait: const Duration(milliseconds: 300),
        expect: () => [AuthChecking(), AuthUnauthenticated()],
        verify: (_) {
          verifyNever(() => mockVotingRepository.logout());
          verifyNever(() => mockDraftService.clearAllDrafts());
          verify(() => mockVotingRepository.getUserLogin()).called(2);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthChecking, AuthUnauthenticated] when transient validation fails repeatedly',
        build: () {
          when(() => mockVotingRepository.getAuthToken())
              .thenAnswer((_) async => 'some_token');
          when(() => mockVotingRepository.getUserLogin()).thenThrow(
            const SessionValidationException.transientNetwork(),
          );
          return authBloc;
        },
        act: (bloc) => bloc.add(AppStarted()),
        wait: const Duration(milliseconds: 300),
        expect: () => [AuthChecking(), AuthUnauthenticated()],
        verify: (_) {
          verifyNever(() => mockVotingRepository.logout());
          verifyNever(() => mockDraftService.clearAllDrafts());
          verify(() => mockVotingRepository.getUserLogin()).called(2);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'retries once and emits authenticated when getUserLogin times out then succeeds',
        build: () {
          when(() => mockVotingRepository.getAuthToken())
              .thenAnswer((_) async => 'some_token');
          int callCount = 0;
          when(() => mockVotingRepository.getUserLogin()).thenAnswer((_) async {
            callCount++;
            if (callCount == 1) throw TimeoutException('timed out');
            return 'actual_user';
          });
          return authBloc;
        },
        act: (bloc) => bloc.add(AppStarted()),
        wait: const Duration(milliseconds: 300),
        expect: () => [
          AuthChecking(),
          const AuthAuthenticated(userLogin: 'actual_user'),
        ],
        verify: (_) {
          verifyNever(() => mockVotingRepository.logout());
          verify(() => mockVotingRepository.getUserLogin()).called(2);
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
        act: (bloc) => bloc.add(const LoggedIn()),
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
        act: (bloc) => bloc.add(const LoggedIn()),
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
        act: (bloc) => bloc.add(const LoggedIn()),
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
        verify: (_) {
          verify(() => mockDraftService.clearAllDrafts()).called(1);
        },
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
        verify: (_) {
          verify(() => mockDraftService.clearAllDrafts()).called(1);
        },
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
        bloc.add(const LoggedIn());
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

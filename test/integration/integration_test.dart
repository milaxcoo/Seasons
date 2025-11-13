import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:seasons/data/models/voting_event.dart';
import 'package:seasons/data/repositories/voting_repository.dart';
import 'package:seasons/presentation/bloc/auth/auth_bloc.dart';
import 'package:seasons/presentation/bloc/voting/voting_bloc.dart';
import 'package:seasons/presentation/bloc/voting/voting_event.dart';
import 'package:seasons/presentation/bloc/voting/voting_state.dart';

class MockVotingRepository extends Mock implements VotingRepository {}

void main() {
  group('Integration Tests - Auth and Voting Flow', () {
    late MockVotingRepository mockRepository;
    late AuthBloc authBloc;
    late VotingBloc votingBloc;

    setUp(() {
      mockRepository = MockVotingRepository();
      authBloc = AuthBloc(votingRepository: mockRepository);
      votingBloc = VotingBloc(votingRepository: mockRepository);
    });

    tearDown(() {
      authBloc.close();
      votingBloc.close();
    });

    setUpAll(() {
      registerFallbackValue(const VotingEvent(
        id: 'test',
        title: 'Test',
        description: 'Test',
        status: VotingStatus.active,
        isRegistered: false,
        questions: [],
        hasVoted: false,
        results: [],
      ));
      registerFallbackValue(<String, String>{});
    });

    test('Complete user flow: login -> fetch events -> logout', () async {
      // Arrange
      when(() => mockRepository.login('user', 'pass'))
          .thenAnswer((_) async => 'token');
      when(() => mockRepository.getUserLogin())
          .thenAnswer((_) async => 'user');
      when(() => mockRepository.getEventsByStatus(VotingStatus.registration))
          .thenAnswer((_) async => [
                VotingEvent(
                  id: 'event-01',
                  title: 'Test Event',
                  description: 'Description',
                  status: VotingStatus.registration,
                  isRegistered: false,
                  questions: const [],
                  hasVoted: false,
                  results: const [],
                ),
              ]);
      when(() => mockRepository.logout()).thenAnswer((_) async {});

      // Act & Assert - Login
      authBloc.add(const LoggedIn(login: 'user', password: 'pass'));
      await expectLater(
        authBloc.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          isA<AuthAuthenticated>(),
        ]),
      );

      // Act & Assert - Fetch Events
      votingBloc.add(const FetchEventsByStatus(status: VotingStatus.registration));
      await expectLater(
        votingBloc.stream,
        emitsInOrder([
          isA<VotingLoadInProgress>(),
          isA<VotingEventsLoadSuccess>(),
        ]),
      );

      // Act & Assert - Logout
      authBloc.add(LoggedOut());
      await expectLater(
        authBloc.stream,
        emits(isA<AuthUnauthenticated>()),
      );

      // Verify all interactions
      verify(() => mockRepository.login('user', 'pass')).called(1);
      verify(() => mockRepository.getUserLogin()).called(1);
      verify(() => mockRepository.getEventsByStatus(VotingStatus.registration))
          .called(1);
      verify(() => mockRepository.logout()).called(1);
    });

    test('Complete voting flow: register -> fetch event -> submit vote', () async {
      // Arrange
      final testEvent = VotingEvent(
        id: 'event-01',
        title: 'Test Event',
        description: 'Description',
        status: VotingStatus.active,
        isRegistered: true,
        questions: const [],
        hasVoted: false,
        results: const [],
      );

      when(() => mockRepository.registerForEvent('event-01'))
          .thenAnswer((_) async {});
      when(() => mockRepository.getEventsByStatus(VotingStatus.active))
          .thenAnswer((_) async => [testEvent]);
      when(() => mockRepository.submitVote(any(), any()))
          .thenAnswer((_) async => true);

      // Act & Assert - Register
      votingBloc.add(const RegisterForEvent(eventId: 'event-01'));
      await expectLater(
        votingBloc.stream,
        emitsInOrder([
          isA<RegistrationInProgress>(),
          isA<RegistrationSuccess>(),
        ]),
      );

      // Act & Assert - Fetch Active Events
      votingBloc.add(const FetchEventsByStatus(status: VotingStatus.active));
      await expectLater(
        votingBloc.stream,
        emitsInOrder([
          isA<VotingLoadInProgress>(),
          isA<VotingEventsLoadSuccess>(),
        ]),
      );

      // Act & Assert - Submit Vote
      votingBloc.add(SubmitVote(event: testEvent, answers: {'q1': 'a1'}));
      await expectLater(
        votingBloc.stream,
        emitsInOrder([
          isA<VotingLoadInProgress>(),
          isA<VotingSubmissionSuccess>(),
        ]),
      );

      // Verify all interactions
      verify(() => mockRepository.registerForEvent('event-01')).called(1);
      verify(() => mockRepository.getEventsByStatus(VotingStatus.active))
          .called(1);
      verify(() => mockRepository.submitVote(any(), any())).called(1);
    });

    test('Error handling: failed login prevents further actions', () async {
      // Arrange
      when(() => mockRepository.login(any(), any()))
          .thenThrow(Exception('Invalid credentials'));

      // Act & Assert - Failed Login
      authBloc.add(const LoggedIn(login: 'wrong', password: 'wrong'));
      await expectLater(
        authBloc.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          isA<AuthFailure>(),
          isA<AuthUnauthenticated>(),
        ]),
      );

      // Verify
      verify(() => mockRepository.login('wrong', 'wrong')).called(1);
      verifyNever(() => mockRepository.getUserLogin());
    });

    test('Error handling: failed registration allows retry', () async {
      // Arrange
      when(() => mockRepository.registerForEvent('event-01'))
          .thenThrow(Exception('Registration failed'));

      // Act & Assert - Failed Registration
      votingBloc.add(const RegisterForEvent(eventId: 'event-01'));
      await expectLater(
        votingBloc.stream,
        emitsInOrder([
          isA<RegistrationInProgress>(),
          isA<RegistrationFailure>(),
        ]),
      );

      // Verify
      verify(() => mockRepository.registerForEvent('event-01')).called(1);
    });

    test('Error handling: failed vote submission shows error', () async {
      // Arrange
      final testEvent = VotingEvent(
        id: 'event-01',
        title: 'Test Event',
        description: 'Description',
        status: VotingStatus.active,
        isRegistered: true,
        questions: const [],
        hasVoted: false,
        results: const [],
      );

      when(() => mockRepository.submitVote(any(), any()))
          .thenThrow(Exception('Submission failed'));

      // Act & Assert - Failed Vote Submission
      votingBloc.add(SubmitVote(event: testEvent, answers: {'q1': 'a1'}));
      await expectLater(
        votingBloc.stream,
        emitsInOrder([
          isA<VotingLoadInProgress>(),
          isA<VotingFailure>(),
        ]),
      );

      // Verify
      verify(() => mockRepository.submitVote(any(), any())).called(1);
    });

    test('Concurrent operations: multiple event fetches', () async {
      // Arrange
      when(() => mockRepository.getEventsByStatus(any()))
          .thenAnswer((_) async => []);

      // Act - Multiple rapid fetches
      votingBloc.add(const FetchEventsByStatus(status: VotingStatus.registration));
      votingBloc.add(const FetchEventsByStatus(status: VotingStatus.active));
      votingBloc.add(const FetchEventsByStatus(status: VotingStatus.completed));

      // Assert - Should handle all requests
      await expectLater(
        votingBloc.stream,
        emitsInOrder([
          isA<VotingLoadInProgress>(),
          isA<VotingEventsLoadSuccess>(),
          isA<VotingLoadInProgress>(),
          isA<VotingEventsLoadSuccess>(),
          isA<VotingLoadInProgress>(),
          isA<VotingEventsLoadSuccess>(),
        ]),
      );

      // Verify all calls were made
      verify(() => mockRepository.getEventsByStatus(any())).called(3);
    });

    test('State persistence: logout does not affect voting bloc', () async {
      // Arrange
      when(() => mockRepository.logout()).thenAnswer((_) async {});
      when(() => mockRepository.getEventsByStatus(any()))
          .thenAnswer((_) async => []);

      // Act - Fetch events while logged in
      votingBloc.add(const FetchEventsByStatus(status: VotingStatus.active));
      await expectLater(
        votingBloc.stream,
        emitsInOrder([
          isA<VotingLoadInProgress>(),
          isA<VotingEventsLoadSuccess>(),
        ]),
      );

      // Act - Logout
      authBloc.add(LoggedOut());
      await expectLater(
        authBloc.stream,
        emits(isA<AuthUnauthenticated>()),
      );

      // Assert - Voting bloc state should remain unchanged
      expect(votingBloc.state, isA<VotingEventsLoadSuccess>());
    });
  });
}

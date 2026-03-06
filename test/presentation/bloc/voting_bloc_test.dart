import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:seasons/data/models/question.dart';
import 'package:seasons/data/models/voting_event.dart' as model;
import 'package:seasons/data/repositories/voting_repository.dart';
import 'package:seasons/core/services/background_service.dart';
import 'package:seasons/presentation/bloc/voting/voting_bloc.dart';
import 'package:seasons/presentation/bloc/voting/voting_connection_status.dart';
import 'package:seasons/presentation/bloc/voting/voting_event.dart';
import 'package:seasons/presentation/bloc/voting/voting_state.dart';

class MockVotingRepository extends Mock implements VotingRepository {}

void main() {
  group('VotingBloc', () {
    late VotingRepository mockVotingRepository;
    late VotingBloc votingBloc;
    late StreamController<Map<String, dynamic>?> mockServiceStreamController;

    setUp(() {
      mockVotingRepository = MockVotingRepository();
      mockServiceStreamController =
          StreamController<Map<String, dynamic>?>.broadcast();
      votingBloc = VotingBloc(
        votingRepository: mockVotingRepository,
        backgroundServiceStream: mockServiceStreamController.stream,
        refreshDebounce: const Duration(milliseconds: 20),
        restoredStatusDuration: const Duration(milliseconds: 40),
      );
    });

    tearDown(() {
      votingBloc.close();
      mockServiceStreamController.close();
    });

    // Register fallback values for custom types
    setUpAll(() {
      registerFallbackValue(const model.VotingEvent(
        id: 'test',
        title: 'Test Event',
        description: 'Test Description',
        status: model.VotingStatus.active,
        isRegistered: false,
        questions: [],
        hasVoted: false,
        results: [],
      ));
      registerFallbackValue(model.VotingStatus.active);
      registerFallbackValue(<String, String>{});
    });

    test('initial state is VotingInitial', () {
      expect(votingBloc.state, equals(VotingInitial()));
    });

    test('emits auth-invalid signal from background updates', () async {
      final completer = Completer<void>();
      final subscription = votingBloc.onAuthInvalid.listen((_) {
        if (!completer.isCompleted) {
          completer.complete();
        }
      });

      mockServiceStreamController.add({'action': 'auth_invalid'});

      await expectLater(
        completer.future,
        completes,
      );
      await subscription.cancel();
    });

    test(
        'emits reconnecting/waiting/syncing/restored lifecycle statuses on reconnect recovery',
        () async {
      when(() => mockVotingRepository.getEventsByStatus(any()))
          .thenAnswer((_) async => []);
      final statuses = <VotingConnectionStatus>[];
      final subscription =
          votingBloc.connectionStatusStream.listen(statuses.add);

      mockServiceStreamController
          .add({'action': BackgroundService.actionConnectionReconnecting});
      mockServiceStreamController
          .add({'action': BackgroundService.actionConnectionWaitingForNetwork});
      mockServiceStreamController
          .add({'action': BackgroundService.actionConnectionConnected});

      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(
        statuses,
        equals([
          VotingConnectionStatus.reconnecting,
          VotingConnectionStatus.waitingForNetwork,
          VotingConnectionStatus.syncing,
          VotingConnectionStatus.restored,
          VotingConnectionStatus.connected,
        ]),
      );
      await subscription.cancel();
    });

    test('dedupes identical connection statuses', () async {
      final statuses = <VotingConnectionStatus>[];
      final subscription =
          votingBloc.connectionStatusStream.listen(statuses.add);

      mockServiceStreamController
          .add({'action': BackgroundService.actionConnectionReconnecting});
      mockServiceStreamController
          .add({'action': BackgroundService.actionConnectionReconnecting});
      mockServiceStreamController
          .add({'action': BackgroundService.actionConnectionWaitingForNetwork});
      mockServiceStreamController
          .add({'action': BackgroundService.actionConnectionWaitingForNetwork});

      await Future<void>.delayed(const Duration(milliseconds: 40));

      expect(
        statuses,
        equals([
          VotingConnectionStatus.reconnecting,
          VotingConnectionStatus.waitingForNetwork,
        ]),
      );
      await subscription.cancel();
    });

    test('coalesces reconnect catch-up refresh into one burst', () async {
      when(() => mockVotingRepository.getEventsByStatus(any()))
          .thenAnswer((_) async => []);

      mockServiceStreamController
          .add({'action': BackgroundService.actionConnectionReconnecting});
      mockServiceStreamController
          .add({'action': BackgroundService.actionConnectionConnected});
      mockServiceStreamController
          .add({'action': BackgroundService.actionConnectionConnected});

      await Future<void>.delayed(const Duration(milliseconds: 150));

      verify(() => mockVotingRepository.getEventsByStatus(any())).called(3);
    });

    test('marks connection disconnected when only part of silent refresh fails',
        () async {
      when(
        () => mockVotingRepository
            .getEventsByStatus(model.VotingStatus.registration),
      ).thenAnswer((_) async => []);
      when(
        () => mockVotingRepository.getEventsByStatus(model.VotingStatus.active),
      ).thenThrow(Exception('temporary failure'));
      when(
        () => mockVotingRepository
            .getEventsByStatus(model.VotingStatus.completed),
      ).thenAnswer((_) async => []);

      final statuses = <VotingConnectionStatus>[];
      final subscription =
          votingBloc.connectionStatusStream.listen(statuses.add);

      votingBloc.add(const RefreshAllEventsSilent());
      await Future<void>.delayed(const Duration(milliseconds: 80));

      expect(statuses, equals([VotingConnectionStatus.disconnected]));
      expect(
        votingBloc.currentConnectionStatus,
        VotingConnectionStatus.disconnected,
      );
      await subscription.cancel();
    });

    group('FetchEventsByStatus', () {
      final testEvents = [
        model.VotingEvent(
          id: 'event-1',
          title: 'Test Event 1',
          description: 'Description 1',
          status: model.VotingStatus.registration,
          registrationEndDate: DateTime(2026, 12, 31),
          votingStartDate: DateTime(2026, 1, 1),
          votingEndDate: DateTime(2026, 1, 31),
          isRegistered: false,
          questions: const [],
          hasVoted: false,
          results: const [],
        ),
        model.VotingEvent(
          id: 'event-2',
          title: 'Test Event 2',
          description: 'Description 2',
          status: model.VotingStatus.registration,
          registrationEndDate: DateTime(2026, 12, 31),
          votingStartDate: DateTime(2026, 1, 1),
          votingEndDate: DateTime(2026, 1, 31),
          isRegistered: true,
          questions: const [],
          hasVoted: false,
          results: const [],
        ),
      ];

      blocTest<VotingBloc, VotingState>(
        'emits [VotingLoadInProgress, VotingEventsLoadSuccess] when events are fetched successfully',
        build: () {
          when(() => mockVotingRepository
                  .getEventsByStatus(model.VotingStatus.registration))
              .thenAnswer((_) async => testEvents);
          return votingBloc;
        },
        act: (bloc) => bloc.add(
            const FetchEventsByStatus(status: model.VotingStatus.registration)),
        expect: () => [
          VotingLoadInProgress(),
          isA<VotingEventsLoadSuccess>()
              .having((s) => s.events, 'events', testEvents)
              .having(
                  (s) => s.status, 'status', model.VotingStatus.registration),
        ],
        verify: (_) {
          verify(() => mockVotingRepository
              .getEventsByStatus(model.VotingStatus.registration)).called(1);
        },
      );

      blocTest<VotingBloc, VotingState>(
        'emits [VotingLoadInProgress, VotingEventsLoadSuccess] with empty list when no events',
        build: () {
          when(() => mockVotingRepository.getEventsByStatus(
              model.VotingStatus.active)).thenAnswer((_) async => []);
          return votingBloc;
        },
        act: (bloc) => bloc
            .add(const FetchEventsByStatus(status: model.VotingStatus.active)),
        expect: () => [
          VotingLoadInProgress(),
          isA<VotingEventsLoadSuccess>()
              .having((s) => s.events, 'events', isEmpty)
              .having((s) => s.status, 'status', model.VotingStatus.active),
        ],
      );

      blocTest<VotingBloc, VotingState>(
        'emits [VotingLoadInProgress, VotingFailure] when fetch fails',
        build: () {
          when(() => mockVotingRepository.getEventsByStatus(any()))
              .thenThrow(Exception('Failed to fetch events'));
          return votingBloc;
        },
        act: (bloc) => bloc.add(
            const FetchEventsByStatus(status: model.VotingStatus.completed)),
        expect: () => [
          VotingLoadInProgress(),
          isA<VotingFailure>().having(
              (s) => s.error, 'error', contains('Failed to fetch events')),
        ],
      );
    });

    group('RegisterForEvent', () {
      blocTest<VotingBloc, VotingState>(
        'emits [RegistrationInProgress, RegistrationSuccess] when registration succeeds',
        build: () {
          when(() => mockVotingRepository.registerForEvent('event-1'))
              .thenAnswer((_) async => {});
          return votingBloc;
        },
        act: (bloc) => bloc.add(const RegisterForEvent(eventId: 'event-1')),
        expect: () => [
          RegistrationInProgress(),
          RegistrationSuccess(),
        ],
        verify: (_) {
          verify(() => mockVotingRepository.registerForEvent('event-1'))
              .called(1);
        },
      );

      blocTest<VotingBloc, VotingState>(
        'emits [RegistrationInProgress, RegistrationFailure] when registration fails',
        build: () {
          when(() => mockVotingRepository.registerForEvent(any()))
              .thenThrow(Exception('Registration failed'));
          return votingBloc;
        },
        act: (bloc) => bloc.add(const RegisterForEvent(eventId: 'event-1')),
        expect: () => [
          RegistrationInProgress(),
          isA<RegistrationFailure>()
              .having((s) => s.error, 'error', contains('Registration failed')),
        ],
      );

      blocTest<VotingBloc, VotingState>(
        'emits [RegistrationInProgress, RegistrationFailure] when user is already registered',
        build: () {
          when(() => mockVotingRepository.registerForEvent(any()))
              .thenThrow(Exception('User already registered'));
          return votingBloc;
        },
        act: (bloc) => bloc.add(const RegisterForEvent(eventId: 'event-1')),
        expect: () => [
          RegistrationInProgress(),
          isA<RegistrationFailure>()
              .having((s) => s.error, 'error', contains('already registered')),
        ],
      );
    });

    group('SubmitVote', () {
      final testEvent = model.VotingEvent(
        id: 'event-1',
        title: 'Test Voting Event',
        description: 'Vote for your favorite',
        status: model.VotingStatus.active,
        isRegistered: true,
        questions: const [
          Question(
            id: 'q1',
            name: 'Question 1',
            subjects: [],
            answers: [],
          ),
        ],
        hasVoted: false,
        results: const [],
      );

      final testAnswers = {'q1': 'answer-1'};

      blocTest<VotingBloc, VotingState>(
        'emits [VotingLoadInProgress, VotingSubmissionSuccess] when vote is submitted successfully',
        build: () {
          when(() => mockVotingRepository.submitVote(any(), any()))
              .thenAnswer((_) async => true);
          return votingBloc;
        },
        act: (bloc) =>
            bloc.add(SubmitVote(event: testEvent, answers: testAnswers)),
        expect: () => [
          VotingLoadInProgress(),
          VotingSubmissionSuccess(),
        ],
        verify: (_) {
          verify(() => mockVotingRepository.submitVote(any(), any())).called(1);
        },
      );

      blocTest<VotingBloc, VotingState>(
        'emits [VotingLoadInProgress, VotingFailure] when repository reports already-voted conflict via false',
        build: () {
          when(() => mockVotingRepository.submitVote(any(), any()))
              .thenAnswer((_) async => false);
          return votingBloc;
        },
        act: (bloc) =>
            bloc.add(SubmitVote(event: testEvent, answers: testAnswers)),
        expect: () => [
          VotingLoadInProgress(),
          isA<VotingFailure>()
              .having((s) => s.error, 'error', contains('already voted')),
        ],
      );

      blocTest<VotingBloc, VotingState>(
        'emits [VotingLoadInProgress, VotingFailure] when vote submission fails',
        build: () {
          when(() => mockVotingRepository.submitVote(any(), any()))
              .thenThrow(Exception('Submission failed'));
          return votingBloc;
        },
        act: (bloc) =>
            bloc.add(SubmitVote(event: testEvent, answers: testAnswers)),
        expect: () => [
          VotingLoadInProgress(),
          isA<VotingFailure>()
              .having((s) => s.error, 'error', contains('Submission failed')),
        ],
      );

      blocTest<VotingBloc, VotingState>(
        'emits [VotingLoadInProgress, VotingFailure] when user already voted',
        build: () {
          when(() => mockVotingRepository.submitVote(any(), any()))
              .thenThrow(Exception('User already voted'));
          return votingBloc;
        },
        act: (bloc) =>
            bloc.add(SubmitVote(event: testEvent, answers: testAnswers)),
        expect: () => [
          VotingLoadInProgress(),
          isA<VotingFailure>()
              .having((s) => s.error, 'error', contains('already voted')),
        ],
      );

      blocTest<VotingBloc, VotingState>(
        'handles empty answers map',
        build: () {
          when(() => mockVotingRepository.submitVote(any(), any()))
              .thenAnswer((_) async => true);
          return votingBloc;
        },
        act: (bloc) => bloc.add(SubmitVote(event: testEvent, answers: {})),
        expect: () => [
          VotingLoadInProgress(),
          VotingSubmissionSuccess(),
        ],
      );
    });

    group('State Transitions', () {
      blocTest<VotingBloc, VotingState>(
        'handles multiple fetch requests correctly',
        build: () {
          when(() => mockVotingRepository.getEventsByStatus(any()))
              .thenAnswer((_) async => []);
          return votingBloc;
        },
        act: (bloc) {
          bloc.add(const FetchEventsByStatus(
              status: model.VotingStatus.registration));
          bloc.add(
              const FetchEventsByStatus(status: model.VotingStatus.active));
        },
        skip: 2, // Skip first fetch
        expect: () => [
          VotingLoadInProgress(),
          isA<VotingEventsLoadSuccess>()
              .having((s) => s.events, 'events', isEmpty)
              .having((s) => s.status, 'status', model.VotingStatus.active),
        ],
      );

      blocTest<VotingBloc, VotingState>(
        'handles register followed by fetch',
        build: () {
          when(() => mockVotingRepository.registerForEvent(any()))
              .thenAnswer((_) async => {});
          when(() => mockVotingRepository.getEventsByStatus(any()))
              .thenAnswer((_) async => []);
          return votingBloc;
        },
        act: (bloc) async {
          bloc.add(const RegisterForEvent(eventId: 'event-1'));
          await Future.delayed(const Duration(
              milliseconds: 100)); // Wait for registration to complete
          bloc.add(const FetchEventsByStatus(
              status: model.VotingStatus.registration));
        },
        expect: () => [
          RegistrationInProgress(),
          RegistrationSuccess(),
          VotingLoadInProgress(),
          isA<VotingEventsLoadSuccess>()
              .having((s) => s.events, 'events', isEmpty)
              .having(
                  (s) => s.status, 'status', model.VotingStatus.registration),
        ],
      );
    });

    group('Unauthorized session handling', () {
      test(
          'fetch emits auth_invalid failure and notifies auth invalid stream',
          () async {
        when(() => mockVotingRepository.getEventsByStatus(any())).thenThrow(
          const UnauthorizedSessionException('expired'),
        );

        final authInvalid = Completer<void>();
        final subscription = votingBloc.onAuthInvalid.listen((_) {
          if (!authInvalid.isCompleted) {
            authInvalid.complete();
          }
        });

        votingBloc.add(
          const FetchEventsByStatus(status: model.VotingStatus.active),
        );

        await expectLater(
          votingBloc.stream,
          emitsInOrder([
            isA<VotingLoadInProgress>(),
            isA<VotingFailure>()
                .having((s) => s.error, 'error', equals('auth_invalid')),
          ]),
        );
        await expectLater(authInvalid.future, completes);
        await subscription.cancel();
      });

      test(
          'register emits auth_invalid failure and notifies auth invalid stream',
          () async {
        when(() => mockVotingRepository.registerForEvent(any())).thenThrow(
          const UnauthorizedSessionException('expired'),
        );

        final authInvalid = Completer<void>();
        final subscription = votingBloc.onAuthInvalid.listen((_) {
          if (!authInvalid.isCompleted) {
            authInvalid.complete();
          }
        });

        votingBloc.add(const RegisterForEvent(eventId: 'event-1'));

        await expectLater(
          votingBloc.stream,
          emitsInOrder([
            isA<RegistrationInProgress>(),
            isA<RegistrationFailure>()
                .having((s) => s.error, 'error', equals('auth_invalid')),
          ]),
        );
        await expectLater(authInvalid.future, completes);
        await subscription.cancel();
      });

      test(
          'submit vote emits auth_invalid failure and notifies auth invalid stream',
          () async {
        const testEvent = model.VotingEvent(
          id: 'event-1',
          title: 'Test Voting Event',
          description: 'Vote for your favorite',
          status: model.VotingStatus.active,
          isRegistered: true,
          questions: [],
          hasVoted: false,
          results: [],
        );

        when(() => mockVotingRepository.submitVote(any(), any())).thenThrow(
          const UnauthorizedSessionException('expired'),
        );

        final authInvalid = Completer<void>();
        final subscription = votingBloc.onAuthInvalid.listen((_) {
          if (!authInvalid.isCompleted) {
            authInvalid.complete();
          }
        });

        votingBloc.add(SubmitVote(event: testEvent, answers: const {}));

        await expectLater(
          votingBloc.stream,
          emitsInOrder([
            isA<VotingLoadInProgress>(),
            isA<VotingFailure>()
                .having((s) => s.error, 'error', equals('auth_invalid')),
          ]),
        );
        await expectLater(authInvalid.future, completes);
        await subscription.cancel();
      });
    });
  });
}

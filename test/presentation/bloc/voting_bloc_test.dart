import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:seasons/data/models/question.dart';
import 'package:seasons/data/models/vote_result.dart';
import 'package:seasons/data/models/voting_event.dart' as model;
import 'package:seasons/data/repositories/voting_repository.dart';
import 'package:seasons/presentation/bloc/voting/voting_bloc.dart';
import 'package:seasons/presentation/bloc/voting/voting_event.dart';
import 'package:seasons/presentation/bloc/voting/voting_state.dart';

class MockVotingRepository extends Mock implements VotingRepository {}

void main() {
  group('VotingBloc', () {
    late VotingRepository mockVotingRepository;
    late VotingBloc votingBloc;

    setUp(() {
      mockVotingRepository = MockVotingRepository();
      votingBloc = VotingBloc(votingRepository: mockVotingRepository);
    });

    tearDown(() {
      votingBloc.close();
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

    group('FetchEventsByStatus', () {
      final testEvents = [
        model.VotingEvent(
          id: 'event-1',
          title: 'Test Event 1',
          description: 'Description 1',
          status: model.VotingStatus.registration,
          registrationEndDate: DateTime(2025, 12, 31),
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
          registrationEndDate: DateTime(2025, 12, 31),
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
          VotingEventsLoadSuccess(events: testEvents),
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
          const VotingEventsLoadSuccess(events: []),
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

    group('FetchResults', () {
      final testResults = [
        const QuestionResult(
          name: 'Best App',
          type: 'yes_no',
          subjectResults: [
            SubjectResult(
              name: 'App A',
              voteCounts: {'За': 10, 'Против': 5},
            ),
            SubjectResult(
              name: 'App B',
              voteCounts: {'За': 8, 'Против': 7},
            ),
          ],
        ),
      ];

      blocTest<VotingBloc, VotingState>(
        'emits [VotingLoadInProgress, VotingResultsLoadSuccess] when results are fetched successfully',
        build: () {
          when(() => mockVotingRepository.getResultsForEvent('event-1'))
              .thenAnswer((_) async => testResults);
          return votingBloc;
        },
        act: (bloc) => bloc.add(const FetchResults(eventId: 'event-1')),
        expect: () => [
          VotingLoadInProgress(),
          VotingResultsLoadSuccess(results: testResults),
        ],
        verify: (_) {
          verify(() => mockVotingRepository.getResultsForEvent('event-1'))
              .called(1);
        },
      );

      blocTest<VotingBloc, VotingState>(
        'emits [VotingLoadInProgress, VotingResultsLoadSuccess] with empty list when no results',
        build: () {
          when(() => mockVotingRepository.getResultsForEvent('event-1'))
              .thenAnswer((_) async => []);
          return votingBloc;
        },
        act: (bloc) => bloc.add(const FetchResults(eventId: 'event-1')),
        expect: () => [
          VotingLoadInProgress(),
          const VotingResultsLoadSuccess(results: []),
        ],
      );

      blocTest<VotingBloc, VotingState>(
        'emits [VotingLoadInProgress, VotingFailure] when fetch results fails',
        build: () {
          when(() => mockVotingRepository.getResultsForEvent(any()))
              .thenThrow(Exception('Failed to fetch results'));
          return votingBloc;
        },
        act: (bloc) => bloc.add(const FetchResults(eventId: 'event-1')),
        expect: () => [
          VotingLoadInProgress(),
          isA<VotingFailure>().having(
              (s) => s.error, 'error', contains('Failed to fetch results')),
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
          const VotingEventsLoadSuccess(events: []),
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
          const VotingEventsLoadSuccess(events: []),
        ],
      );
    });
  });
}

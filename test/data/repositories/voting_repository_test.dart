import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:seasons/data/models/vote_result.dart';
import 'package:seasons/data/models/voting_event.dart';

import '../../mocks.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(VotingEvent(
      id: 'test',
      title: 'Test',
      description: '',
      status: VotingStatus.active,
      registrationEndDate: null,
      votingStartDate: null,
      votingEndDate: null,
      isRegistered: false,
      questions: [],
      hasVoted: false,
      results: [],
    ));
    registerFallbackValue(VotingStatus.active);
  });

  group('VotingRepository', () {
    late MockVotingRepository mockRepository;

    setUp(() {
      mockRepository = MockVotingRepository();
    });

    group('Authentication', () {
      test('login returns token on successful authentication', () async {
        // Arrange
        when(() => mockRepository.login('user', 'pass'))
            .thenAnswer((_) async => 'auth_token_12345');

        // Act
        final result = await mockRepository.login('user', 'pass');

        // Assert
        expect(result, 'auth_token_12345');
        verify(() => mockRepository.login('user', 'pass')).called(1);
      });

      test('login throws exception on failed authentication', () async {
        // Arrange
        when(() => mockRepository.login(any(), any()))
            .thenThrow(Exception('Invalid credentials'));

        // Act & Assert
        expect(
          () => mockRepository.login('wrong', 'wrong'),
          throwsA(isA<Exception>()),
        );
      });

      test('logout completes successfully', () async {
        // Arrange
        when(() => mockRepository.logout()).thenAnswer((_) async {});

        // Act
        await mockRepository.logout();

        // Assert
        verify(() => mockRepository.logout()).called(1);
      });

      test('getAuthToken returns token when authenticated', () async {
        // Arrange
        when(() => mockRepository.getAuthToken())
            .thenAnswer((_) async => 'stored_token');

        // Act
        final result = await mockRepository.getAuthToken();

        // Assert
        expect(result, 'stored_token');
      });

      test('getAuthToken returns null when not authenticated', () async {
        // Arrange
        when(() => mockRepository.getAuthToken()).thenAnswer((_) async => null);

        // Act
        final result = await mockRepository.getAuthToken();

        // Assert
        expect(result, isNull);
      });

      test('getUserLogin returns user login', () async {
        // Arrange
        when(() => mockRepository.getUserLogin())
            .thenAnswer((_) async => 'testuser');

        // Act
        final result = await mockRepository.getUserLogin();

        // Assert
        expect(result, 'testuser');
      });
    });

    group('Events', () {
      test('getEventsByStatus returns list of registration events', () async {
        // Arrange
        final events = [
          VotingEvent(
            id: 'reg-01',
            title: 'Registration Event',
            description: 'Description',
            status: VotingStatus.registration,
            isRegistered: false,
            questions: const [],
            hasVoted: false,
            results: const [],
          ),
        ];
        when(() => mockRepository.getEventsByStatus(VotingStatus.registration))
            .thenAnswer((_) async => events);

        // Act
        final result =
            await mockRepository.getEventsByStatus(VotingStatus.registration);

        // Assert
        expect(result, hasLength(1));
        expect(result[0].status, VotingStatus.registration);
      });

      test('getEventsByStatus returns list of active events', () async {
        // Arrange
        final events = [
          VotingEvent(
            id: 'active-01',
            title: 'Active Event',
            description: 'Description',
            status: VotingStatus.active,
            isRegistered: true,
            questions: const [],
            hasVoted: false,
            results: const [],
          ),
        ];
        when(() => mockRepository.getEventsByStatus(VotingStatus.active))
            .thenAnswer((_) async => events);

        // Act
        final result =
            await mockRepository.getEventsByStatus(VotingStatus.active);

        // Assert
        expect(result, hasLength(1));
        expect(result[0].status, VotingStatus.active);
      });

      test('getEventsByStatus returns list of completed events', () async {
        // Arrange
        final events = [
          VotingEvent(
            id: 'completed-01',
            title: 'Completed Event',
            description: 'Description',
            status: VotingStatus.completed,
            isRegistered: true,
            questions: const [],
            hasVoted: true,
            results: const [],
          ),
        ];
        when(() => mockRepository.getEventsByStatus(VotingStatus.completed))
            .thenAnswer((_) async => events);

        // Act
        final result =
            await mockRepository.getEventsByStatus(VotingStatus.completed);

        // Assert
        expect(result, hasLength(1));
        expect(result[0].status, VotingStatus.completed);
      });

      test('getEventsByStatus returns empty list when no events', () async {
        // Arrange
        when(() => mockRepository.getEventsByStatus(any()))
            .thenAnswer((_) async => []);

        // Act
        final result =
            await mockRepository.getEventsByStatus(VotingStatus.registration);

        // Assert
        expect(result, isEmpty);
      });

      test('getEventsByStatus throws exception on error', () async {
        // Arrange
        when(() => mockRepository.getEventsByStatus(any()))
            .thenThrow(Exception('Failed to fetch events'));

        // Act & Assert
        expect(
          () => mockRepository.getEventsByStatus(VotingStatus.active),
          throwsA(isA<Exception>()),
        );
      });


    });

    group('Registration', () {
      test('registerForEvent completes successfully', () async {
        // Arrange
        when(() => mockRepository.registerForEvent('event-01'))
            .thenAnswer((_) async {});

        // Act
        await mockRepository.registerForEvent('event-01');

        // Assert
        verify(() => mockRepository.registerForEvent('event-01')).called(1);
      });

      test('registerForEvent throws exception when already registered',
          () async {
        // Arrange
        when(() => mockRepository.registerForEvent(any()))
            .thenThrow(Exception('Already registered'));

        // Act & Assert
        expect(
          () => mockRepository.registerForEvent('event-01'),
          throwsA(isA<Exception>()),
        );
      });

      test('registerForEvent throws exception when event is full', () async {
        // Arrange
        when(() => mockRepository.registerForEvent(any()))
            .thenThrow(Exception('Event is full'));

        // Act & Assert
        expect(
          () => mockRepository.registerForEvent('event-01'),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Voting', () {
      test('submitVote returns true on successful submission', () async {
        // Arrange
        final event = VotingEvent(
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
            .thenAnswer((_) async => true);

        // Act
        final result = await mockRepository.submitVote(event, {'q1': 'a1'});

        // Assert
        expect(result, true);
        verify(() => mockRepository.submitVote(any(), any())).called(1);
      });

      test('submitVote throws exception when user already voted', () async {
        // Arrange
        final event = VotingEvent(
          id: 'event-01',
          title: 'Test Event',
          description: 'Description',
          status: VotingStatus.active,
          isRegistered: true,
          questions: const [],
          hasVoted: true,
          results: const [],
        );
        when(() => mockRepository.submitVote(any(), any()))
            .thenThrow(Exception('User already voted'));

        // Act & Assert
        expect(
          () => mockRepository.submitVote(event, {'q1': 'a1'}),
          throwsA(isA<Exception>()),
        );
      });

      test('submitVote throws exception on network error', () async {
        // Arrange
        final event = VotingEvent(
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
            .thenThrow(Exception('Network error'));

        // Act & Assert
        expect(
          () => mockRepository.submitVote(event, {'q1': 'a1'}),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Results', () {
      test('getResultsForEvent returns vote results', () async {
        // Arrange
        final results = [
          const QuestionResult(
            name: 'Best App',
            type: 'yes_no',
            subjectResults: [
              SubjectResult(name: 'App A', voteCounts: {'За': 10, 'Против': 5}),
            ],
          ),
        ];
        when(() => mockRepository.getResultsForEvent('event-01'))
            .thenAnswer((_) async => results);

        // Act
        final result = await mockRepository.getResultsForEvent('event-01');

        // Assert
        expect(result, hasLength(1));
        expect(result[0].name, 'Best App');
        expect(result[0].subjectResults, hasLength(1));
      });

      test('getResultsForEvent returns empty list when no results', () async {
        // Arrange
        when(() => mockRepository.getResultsForEvent(any()))
            .thenAnswer((_) async => []);

        // Act
        final result = await mockRepository.getResultsForEvent('event-01');

        // Assert
        expect(result, isEmpty);
      });

      test('getResultsForEvent throws exception on error', () async {
        // Arrange
        when(() => mockRepository.getResultsForEvent(any()))
            .thenThrow(Exception('Failed to fetch results'));

        // Act & Assert
        expect(
          () => mockRepository.getResultsForEvent('event-01'),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}

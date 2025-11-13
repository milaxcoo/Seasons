import 'package:flutter_test/flutter_test.dart';
import 'package:seasons/data/models/voting_event.dart';

void main() {
  group('VotingEvent', () {
    group('fromJson', () {
      test('parses a basic registration event correctly', () {
        final json = {
          'voting': {
            'id': 'reg-01',
            'name': 'Best Mobile App',
            'description': 'Vote for the best mobile app',
            'status': 'registration',
            'end_registration_at': '2025-12-31T23:59:59',
            'registration_started_at': '2025-01-01T00:00:00',
            'end_voting_at': '2026-01-31T23:59:59',
            'registered': 0,
            'voted': 0,
            'questions': [],
          },
          'status': 'registration',
        };

        final event = VotingEvent.fromJson(json);

        expect(event.id, 'reg-01');
        expect(event.title, 'Best Mobile App');
        expect(event.description, 'Vote for the best mobile app');
        expect(event.status, VotingStatus.registration);
        expect(event.isRegistered, false);
        expect(event.hasVoted, false);
        expect(event.questions, isEmpty);
        expect(event.results, isEmpty);
      });

      test('parses an active event correctly', () {
        final json = {
          'voting': {
            'id': 'active-01',
            'name': 'Best Teacher',
            'description': 'Vote for the best teacher',
            'status': 'active',
            'end_registration_at': '2025-11-30T23:59:59',
            'voting_started_at': '2025-12-01T00:00:00',
            'end_voting_at': '2025-12-31T23:59:59',
            'registered': 1,
            'voted': 0,
            'questions': [],
          },
          'status': 'ongoing',
        };

        final event = VotingEvent.fromJson(json);

        expect(event.id, 'active-01');
        expect(event.status, VotingStatus.active);
        expect(event.isRegistered, true);
        expect(event.hasVoted, false);
      });

      test('parses a completed event correctly', () {
        final json = {
          'voting': {
            'id': 'completed-01',
            'name': 'Best Project',
            'description': 'Vote for the best project',
            'status': 'finished',
            'end_registration_at': '2025-10-31T23:59:59',
            'voting_started_at': '2025-11-01T00:00:00',
            'end_voting_at': '2025-11-30T23:59:59',
            'registered': 1,
            'voted': 1,
            'questions': [],
          },
          'status': 'completed',
        };

        final event = VotingEvent.fromJson(json);

        expect(event.id, 'completed-01');
        expect(event.status, VotingStatus.completed);
        expect(event.isRegistered, true);
        expect(event.hasVoted, true);
      });

      test('handles missing optional fields gracefully', () {
        final json = {
          'voting': {
            'id': 'minimal-01',
            'name': 'Minimal Event',
            'registered': 0,
            'voted': 0,
          },
        };

        final event = VotingEvent.fromJson(json);

        expect(event.id, 'minimal-01');
        expect(event.title, 'Minimal Event');
        expect(event.description, 'Описание отсутствует.');
        expect(event.status, VotingStatus.registration);
        expect(event.registrationEndDate, isNull);
        expect(event.votingStartDate, isNull);
        expect(event.votingEndDate, isNull);
      });

      test('parses questions correctly', () {
        final json = {
          'voting': {
            'id': 'event-with-questions',
            'name': 'Event with Questions',
            'description': 'Test event',
            'registered': 0,
            'voted': 0,
            'questions': [
              {
                'data': {
                  'question': {
                    'id': 'q1',
                    'name': 'Question 1',
                  },
                  'answers': [
                    {'id': 'a1', 'name': 'Answer 1'},
                    {'id': 'a2', 'name': 'Answer 2'},
                  ],
                },
              },
            ],
          },
        };

        final event = VotingEvent.fromJson(json);

        expect(event.questions, hasLength(1));
        expect(event.questions[0].id, 'q1');
        expect(event.questions[0].name, 'Question 1');
        expect(event.questions[0].answers, hasLength(2));
      });

      test('parses results correctly', () {
        final json = {
          'voting': {
            'id': 'event-with-results',
            'name': 'Event with Results',
            'description': 'Test event',
            'registered': 1,
            'voted': 1,
            'questions': [],
          },
          'resultsData': {
            'results': {
              'Best App': {
                'type': 'yes_no',
                'results': {
                  'App A': {
                    'details': {'За': 10, 'Против': 5},
                  },
                  'App B': {
                    'details': {'За': 8, 'Против': 7},
                  },
                },
              },
            },
          },
        };

        final event = VotingEvent.fromJson(json);

        expect(event.results, hasLength(1));
        expect(event.results[0].name, 'Best App');
        expect(event.results[0].type, 'yes_no');
        expect(event.results[0].subjectResults, hasLength(2));
      });

      test('handles date parsing correctly', () {
        final json = {
          'voting': {
            'id': 'date-test',
            'name': 'Date Test',
            'description': 'Testing date parsing',
            'end_registration_at': '2025-12-31T23:59:59',
            'voting_started_at': '2025-01-01T00:00:00',
            'end_voting_at': '2025-01-31T23:59:59',
            'registered': 0,
            'voted': 0,
            'questions': [],
          },
        };

        final event = VotingEvent.fromJson(json);

        // Dates are converted from UTC to local time in the model
        final expectedRegEnd = DateTime.parse('2025-12-31T23:59:59Z').toLocal();
        final expectedVotingStart = DateTime.parse('2025-01-01T00:00:00Z').toLocal();
        final expectedVotingEnd = DateTime.parse('2025-01-31T23:59:59Z').toLocal();

        expect(event.registrationEndDate, isNotNull);
        expect(event.votingStartDate, isNotNull);
        expect(event.votingEndDate, isNotNull);
        expect(event.registrationEndDate!.year, expectedRegEnd.year);
        expect(event.registrationEndDate!.month, expectedRegEnd.month);
        expect(event.registrationEndDate!.day, expectedRegEnd.day);
        expect(event.votingStartDate!.year, expectedVotingStart.year);
        expect(event.votingStartDate!.month, expectedVotingStart.month);
        expect(event.votingStartDate!.day, expectedVotingStart.day);
        expect(event.votingEndDate!.year, expectedVotingEnd.year);
        expect(event.votingEndDate!.month, expectedVotingEnd.month);
        expect(event.votingEndDate!.day, expectedVotingEnd.day);
      });

      test('handles invalid date strings gracefully', () {
        final json = {
          'voting': {
            'id': 'invalid-date',
            'name': 'Invalid Date',
            'description': 'Testing invalid date',
            'end_registration_at': 'invalid-date-string',
            'registered': 0,
            'voted': 0,
            'questions': [],
          },
        };

        final event = VotingEvent.fromJson(json);

        expect(event.registrationEndDate, isNull);
      });

      test('handles empty questions array', () {
        final json = {
          'voting': {
            'id': 'no-questions',
            'name': 'No Questions',
            'description': 'Event without questions',
            'registered': 0,
            'voted': 0,
            'questions': [],
          },
        };

        final event = VotingEvent.fromJson(json);

        expect(event.questions, isEmpty);
      });

      test('handles empty results', () {
        final json = {
          'voting': {
            'id': 'no-results',
            'name': 'No Results',
            'description': 'Event without results',
            'registered': 0,
            'voted': 0,
            'questions': [],
          },
        };

        final event = VotingEvent.fromJson(json);

        expect(event.results, isEmpty);
      });
    });

    group('Equality', () {
      test('two events with same properties are equal', () {
        final event1 = VotingEvent(
          id: 'test-01',
          title: 'Test Event',
          description: 'Description',
          status: VotingStatus.active,
          isRegistered: true,
          questions: const [],
          hasVoted: false,
          results: const [],
        );

        final event2 = VotingEvent(
          id: 'test-01',
          title: 'Test Event',
          description: 'Description',
          status: VotingStatus.active,
          isRegistered: true,
          questions: const [],
          hasVoted: false,
          results: const [],
        );

        expect(event1, equals(event2));
      });

      test('two events with different ids are not equal', () {
        final event1 = VotingEvent(
          id: 'test-01',
          title: 'Test Event',
          description: 'Description',
          status: VotingStatus.active,
          isRegistered: true,
          questions: const [],
          hasVoted: false,
          results: const [],
        );

        final event2 = VotingEvent(
          id: 'test-02',
          title: 'Test Event',
          description: 'Description',
          status: VotingStatus.active,
          isRegistered: true,
          questions: const [],
          hasVoted: false,
          results: const [],
        );

        expect(event1, isNot(equals(event2)));
      });
    });
  });

  group('VotingStatus', () {
    test('has three statuses', () {
      expect(VotingStatus.values, hasLength(3));
      expect(VotingStatus.values, contains(VotingStatus.registration));
      expect(VotingStatus.values, contains(VotingStatus.active));
      expect(VotingStatus.values, contains(VotingStatus.completed));
    });
  });
}

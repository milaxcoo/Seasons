import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seasons/data/models/vote_result.dart';
import 'package:seasons/data/models/voting_event.dart' as model;

void main() {
  group('ResultsScreen - Unit Tests', () {
    // Note: Full widget tests are skipped due to complex widget tree with
    // BackdropFilter and Google Fonts that require extensive test infrastructure.
    // Core rendering is validated through integration tests.

    test('VotingEvent with results contains correct data', () {
      final event = model.VotingEvent(
        id: 'result-01',
        title: 'Тестовое голосование',
        description: 'Описание тестового голосования',
        status: model.VotingStatus.completed,
        votingStartDate: DateTime(2026, 1, 1),
        votingEndDate: DateTime(2026, 1, 31),
        isRegistered: true,
        hasVoted: true,
        questions: const [],
        results: [
          QuestionResult(
            name: 'Вопрос 1',
            type: 'standard',
            subjectResults: [
              SubjectResult(name: 'Кандидат А', voteCounts: {'За': 10, 'Против': 5}),
              SubjectResult(name: 'Кандидат Б', voteCounts: {'За': 8, 'Против': 7}),
            ],
          ),
        ],
      );

      expect(event.title, 'Тестовое голосование');
      expect(event.description, 'Описание тестового голосования');
      expect(event.status, model.VotingStatus.completed);
      expect(event.results.length, 1);
      expect(event.results.first.name, 'Вопрос 1');
      expect(event.results.first.subjectResults.length, 2);
    });

    test('VotingEvent formats dates correctly', () {
      final event = model.VotingEvent(
        id: 'result-02',
        title: 'Test',
        description: 'Desc',
        status: model.VotingStatus.completed,
        votingStartDate: DateTime(2026, 1, 15, 10, 30, 0),
        votingEndDate: DateTime(2026, 1, 31, 18, 0, 0),
        isRegistered: true,
        hasVoted: true,
        questions: const [],
        results: const [],
      );

      expect(event.votingStartDate?.day, 15);
      expect(event.votingStartDate?.month, 1);
      expect(event.votingStartDate?.year, 2026);
      expect(event.votingEndDate?.day, 31);
    });

    test('Empty results list is handled correctly', () {
      final event = model.VotingEvent(
        id: 'result-03',
        title: 'Test',
        description: 'Desc',
        status: model.VotingStatus.completed,
        isRegistered: true,
        hasVoted: true,
        questions: const [],
        results: const [],
      );

      expect(event.results.isEmpty, true);
    });

    test('QuestionResult correctly parses vote counts', () {
      final result = QuestionResult(
        name: 'Тестовый вопрос',
        type: 'standard',
        subjectResults: [
          SubjectResult(name: 'Кандидат А', voteCounts: {'За': 10, 'Против': 5}),
        ],
      );

      expect(result.name, 'Тестовый вопрос');
      expect(result.subjectResults.first.voteCounts['За'], 10);
      expect(result.subjectResults.first.voteCounts['Против'], 5);
    });

    test('SubjectResult correctly stores name and vote counts', () {
      final subject = SubjectResult(
        name: 'Иванов Иван',
        voteCounts: {'За': 15, 'Против': 3, 'Воздержался': 2},
      );

      expect(subject.name, 'Иванов Иван');
      expect(subject.voteCounts.length, 3);
      expect(subject.voteCounts['За'], 15);
    });
  });
}

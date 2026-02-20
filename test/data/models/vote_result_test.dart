import 'package:flutter_test/flutter_test.dart';
import 'package:seasons/data/models/vote_result.dart';

void main() {
  group('SubjectResult', () {
    test('creates a SubjectResult with vote counts', () {
      final result = const SubjectResult(
        name: 'Candidate A',
        voteCounts: {'За': 10, 'Против': 5, 'Воздержался': 2},
      );

      expect(result.name, 'Candidate A');
      expect(result.voteCounts['За'], 10);
      expect(result.voteCounts['Против'], 5);
      expect(result.voteCounts['Воздержался'], 2);
    });

    test('columns getter returns all vote count keys', () {
      final result = const SubjectResult(
        name: 'Candidate B',
        voteCounts: {'За': 15, 'Против': 8},
      );

      final columns = result.columns;

      expect(columns, hasLength(2));
      expect(columns, containsAll(['За', 'Против']));
    });

    test('handles empty vote counts', () {
      final result = const SubjectResult(
        name: 'Candidate C',
        voteCounts: {},
      );

      expect(result.voteCounts, isEmpty);
      expect(result.columns, isEmpty);
    });

    group('Equality', () {
      test('two SubjectResults with same properties are equal', () {
        final result1 = const SubjectResult(
          name: 'Candidate A',
          voteCounts: {'За': 10, 'Против': 5},
        );
        final result2 = const SubjectResult(
          name: 'Candidate A',
          voteCounts: {'За': 10, 'Против': 5},
        );

        expect(result1, equals(result2));
      });

      test('two SubjectResults with different names are not equal', () {
        final result1 = const SubjectResult(
          name: 'Candidate A',
          voteCounts: {'За': 10},
        );
        final result2 = const SubjectResult(
          name: 'Candidate B',
          voteCounts: {'За': 10},
        );

        expect(result1, isNot(equals(result2)));
      });

      test('two SubjectResults with different vote counts are not equal', () {
        final result1 = const SubjectResult(
          name: 'Candidate A',
          voteCounts: {'За': 10},
        );
        final result2 = const SubjectResult(
          name: 'Candidate A',
          voteCounts: {'За': 15},
        );

        expect(result1, isNot(equals(result2)));
      });
    });
  });

  group('QuestionResult', () {
    test('creates a QuestionResult with subject results', () {
      final result = const QuestionResult(
        name: 'Best Teacher',
        type: 'yes_no',
        subjectResults: [
          SubjectResult(name: 'Teacher A', voteCounts: {'За': 10, 'Против': 5}),
          SubjectResult(name: 'Teacher B', voteCounts: {'За': 8, 'Против': 7}),
        ],
      );

      expect(result.name, 'Best Teacher');
      expect(result.type, 'yes_no');
      expect(result.subjectResults, hasLength(2));
    });

    test('allColumns getter returns all unique columns', () {
      final result = const QuestionResult(
        name: 'Best Project',
        type: 'yes_no_abstained',
        subjectResults: [
          SubjectResult(name: 'Project A', voteCounts: {'За': 10, 'Против': 5}),
          SubjectResult(
              name: 'Project B', voteCounts: {'За': 8, 'Воздержался': 3}),
        ],
      );

      final columns = result.allColumns;

      expect(columns, hasLength(3));
      expect(columns, containsAll(['За', 'Против', 'Воздержался']));
    });

    test('handles empty subject results', () {
      final result = const QuestionResult(
        name: 'Empty Question',
        type: 'yes_no',
        subjectResults: [],
      );

      expect(result.subjectResults, isEmpty);
      expect(result.allColumns, isEmpty);
    });

    test('handles multiple_variants type', () {
      final result = const QuestionResult(
        name: 'Favorite Color',
        type: 'multiple_variants',
        subjectResults: [
          SubjectResult(name: 'Red', voteCounts: {'Red': 10}),
          SubjectResult(name: 'Blue', voteCounts: {'Blue': 8}),
          SubjectResult(name: 'Green', voteCounts: {'Green': 5}),
        ],
      );

      expect(result.type, 'multiple_variants');
      expect(result.subjectResults, hasLength(3));
      expect(result.allColumns, containsAll(['Red', 'Blue', 'Green']));
    });

    test('handles subject_oriented type', () {
      final result = const QuestionResult(
        name: 'Department Performance',
        type: 'subject_oriented',
        subjectResults: [
          SubjectResult(
              name: 'Department A', voteCounts: {'За': 20, 'Против': 3}),
          SubjectResult(
              name: 'Department B', voteCounts: {'За': 18, 'Против': 5}),
        ],
      );

      expect(result.type, 'subject_oriented');
      expect(result.subjectResults, hasLength(2));
    });

    group('Equality', () {
      test('two QuestionResults with same properties are equal', () {
        final result1 = const QuestionResult(
          name: 'Question 1',
          type: 'yes_no',
          subjectResults: [],
        );
        final result2 = const QuestionResult(
          name: 'Question 1',
          type: 'yes_no',
          subjectResults: [],
        );

        expect(result1, equals(result2));
      });

      test('two QuestionResults with different names are not equal', () {
        final result1 = const QuestionResult(
          name: 'Question 1',
          type: 'yes_no',
          subjectResults: [],
        );
        final result2 = const QuestionResult(
          name: 'Question 2',
          type: 'yes_no',
          subjectResults: [],
        );

        expect(result1, isNot(equals(result2)));
      });

      test('two QuestionResults with different types are not equal', () {
        final result1 = const QuestionResult(
          name: 'Question 1',
          type: 'yes_no',
          subjectResults: [],
        );
        final result2 = const QuestionResult(
          name: 'Question 1',
          type: 'yes_no_abstained',
          subjectResults: [],
        );

        expect(result1, isNot(equals(result2)));
      });
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:seasons/data/models/nominee.dart';
import 'package:seasons/data/models/question.dart';
import 'package:seasons/data/models/subject.dart';

void main() {
  group('Nominee', () {
    group('fromJson', () {
      test('parses a valid nominee correctly', () {
        final json = {
          'id': 'nom-01',
          'name': 'John Doe',
        };

        final nominee = Nominee.fromJson(json);

        expect(nominee.id, 'nom-01');
        expect(nominee.name, 'John Doe');
      });

      test('handles missing id with default value', () {
        final json = {'name': 'Jane Doe'};

        final nominee = Nominee.fromJson(json);

        expect(nominee.id, 'unknown_id');
        expect(nominee.name, 'Jane Doe');
      });

      test('handles missing name with default value', () {
        final json = {'id': 'nom-02'};

        final nominee = Nominee.fromJson(json);

        expect(nominee.id, 'nom-02');
        expect(nominee.name, 'Без имени');
      });

      test('handles empty json', () {
        final json = <String, dynamic>{};

        final nominee = Nominee.fromJson(json);

        expect(nominee.id, 'unknown_id');
        expect(nominee.name, 'Без имени');
      });
    });

    group('Equality', () {
      test('two nominees with same properties are equal', () {
        final nominee1 = const Nominee(id: 'nom-01', name: 'John Doe');
        final nominee2 = const Nominee(id: 'nom-01', name: 'John Doe');

        expect(nominee1, equals(nominee2));
      });

      test('two nominees with different ids are not equal', () {
        final nominee1 = const Nominee(id: 'nom-01', name: 'John Doe');
        final nominee2 = const Nominee(id: 'nom-02', name: 'John Doe');

        expect(nominee1, isNot(equals(nominee2)));
      });
    });
  });

  group('Subject', () {
    group('fromJson', () {
      test('parses a subject with answers correctly', () {
        final json = {
          'name': 'Best Teacher',
          'answers': [
            {'id': 'ans-01', 'name': 'Teacher A'},
            {'id': 'ans-02', 'name': 'Teacher B'},
          ],
        };

        final subject = Subject.fromJson(json, 'subj-01');

        expect(subject.id, 'subj-01');
        expect(subject.name, 'Best Teacher');
        expect(subject.answers, hasLength(2));
        expect(subject.answers[0].id, 'ans-01');
        expect(subject.answers[0].name, 'Teacher A');
      });

      test('handles missing answers with empty list', () {
        final json = {'name': 'Best Project'};

        final subject = Subject.fromJson(json, 'subj-02');

        expect(subject.id, 'subj-02');
        expect(subject.name, 'Best Project');
        expect(subject.answers, isEmpty);
      });

      test('handles missing name with default value', () {
        final json = {
          'answers': [],
        };

        final subject = Subject.fromJson(json, 'subj-03');

        expect(subject.id, 'subj-03');
        expect(subject.name, 'Без названия');
        expect(subject.answers, isEmpty);
      });
    });

    group('Equality', () {
      test('two subjects with same properties are equal', () {
        final subject1 = const Subject(
          id: 'subj-01',
          name: 'Best Teacher',
          answers: [],
        );
        final subject2 = const Subject(
          id: 'subj-01',
          name: 'Best Teacher',
          answers: [],
        );

        expect(subject1, equals(subject2));
      });

      test('two subjects with different ids are not equal', () {
        final subject1 = const Subject(
          id: 'subj-01',
          name: 'Best Teacher',
          answers: [],
        );
        final subject2 = const Subject(
          id: 'subj-02',
          name: 'Best Teacher',
          answers: [],
        );

        expect(subject1, isNot(equals(subject2)));
      });
    });
  });

  group('Question', () {
    group('fromJson', () {
      test('parses a question with simple answers correctly', () {
        final json = {
          'data': {
            'question': {
              'id': 'q-01',
              'name': 'Who is the best teacher?',
            },
            'answers': [
              {'id': 'ans-01', 'name': 'Teacher A'},
              {'id': 'ans-02', 'name': 'Teacher B'},
            ],
          },
        };

        final question = Question.fromJson(json);

        expect(question.id, 'q-01');
        expect(question.name, 'Who is the best teacher?');
        expect(question.answers, hasLength(2));
        expect(question.subjects, isEmpty);
      });

      test('parses a question with subjects correctly', () {
        final json = {
          'data': {
            'question': {
              'id': 'q-02',
              'name': 'Vote for your favorites',
            },
            'subjects': {
              'subj-01': {
                'name': 'Category 1',
                'answers': [
                  {'id': 'ans-01', 'name': 'Option 1'},
                ],
              },
              'subj-02': {
                'name': 'Category 2',
                'answers': [
                  {'id': 'ans-02', 'name': 'Option 2'},
                ],
              },
            },
          },
        };

        final question = Question.fromJson(json);

        expect(question.id, 'q-02');
        expect(question.name, 'Vote for your favorites');
        expect(question.subjects, hasLength(2));
        expect(question.answers, isEmpty);
      });

      test('handles missing question data with defaults', () {
        final json = {
          'data': {
            'question': {},
          },
        };

        final question = Question.fromJson(json);

        expect(question.id, 'unknown_question_id');
        expect(question.name, 'Без названия');
        expect(question.answers, isEmpty);
        expect(question.subjects, isEmpty);
      });

      test('handles missing data with defaults', () {
        final json = <String, dynamic>{};

        final question = Question.fromJson(json);

        expect(question.id, 'unknown_question_id');
        expect(question.name, 'Без названия');
        expect(question.answers, isEmpty);
        expect(question.subjects, isEmpty);
      });
    });

    group('Equality', () {
      test('two questions with same properties are equal', () {
        final question1 = const Question(
          id: 'q-01',
          name: 'Question 1',
          subjects: [],
          answers: [],
        );
        final question2 = const Question(
          id: 'q-01',
          name: 'Question 1',
          subjects: [],
          answers: [],
        );

        expect(question1, equals(question2));
      });

      test('two questions with different ids are not equal', () {
        final question1 = const Question(
          id: 'q-01',
          name: 'Question 1',
          subjects: [],
          answers: [],
        );
        final question2 = const Question(
          id: 'q-02',
          name: 'Question 1',
          subjects: [],
          answers: [],
        );

        expect(question1, isNot(equals(question2)));
      });
    });
  });
}

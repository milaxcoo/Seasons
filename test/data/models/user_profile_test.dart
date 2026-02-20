import 'package:flutter_test/flutter_test.dart';
import 'package:seasons/data/models/user_profile.dart';

void main() {
  group('UserProfile', () {
    test('constructs with all required fields', () {
      const profile = UserProfile(
        surname: 'Иванов',
        name: 'Иван',
        patronymic: 'Иванович',
        email: 'ivanov@rudn.ru',
        jobTitle: 'Студент',
      );

      expect(profile.surname, 'Иванов');
      expect(profile.name, 'Иван');
      expect(profile.patronymic, 'Иванович');
      expect(profile.email, 'ivanov@rudn.ru');
      expect(profile.jobTitle, 'Студент');
    });

    group('fullName', () {
      test('returns concatenated surname name patronymic', () {
        const profile = UserProfile(
          surname: 'Иванов',
          name: 'Иван',
          patronymic: 'Иванович',
          email: '',
          jobTitle: '',
        );

        expect(profile.fullName, 'Иванов Иван Иванович');
      });

      test('handles empty patronymic', () {
        const profile = UserProfile(
          surname: 'Smith',
          name: 'John',
          patronymic: '',
          email: '',
          jobTitle: '',
        );

        expect(profile.fullName, 'Smith John ');
      });

      test('handles all empty fields', () {
        const profile = UserProfile(
          surname: '',
          name: '',
          patronymic: '',
          email: '',
          jobTitle: '',
        );

        expect(profile.fullName, '  ');
      });
    });

    group('UserProfile.empty()', () {
      test('creates profile with all empty strings', () {
        final profile = UserProfile.empty();

        expect(profile.surname, isEmpty);
        expect(profile.name, isEmpty);
        expect(profile.patronymic, isEmpty);
        expect(profile.email, isEmpty);
        expect(profile.jobTitle, isEmpty);
      });

      test('fullName of empty profile is whitespace only', () {
        final profile = UserProfile.empty();

        expect(profile.fullName.trim(), isEmpty);
      });
    });
  });
}

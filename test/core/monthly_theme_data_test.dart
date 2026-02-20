import 'package:flutter_test/flutter_test.dart';
import 'package:seasons/core/monthly_theme_data.dart';

void main() {
  group('MonthlyTheme', () {
    test('monthlyThemes contains exactly 12 entries', () {
      expect(monthlyThemes.length, 12);
    });

    test('monthlyThemes has entries for all months 1-12', () {
      for (int month = 1; month <= 12; month++) {
        expect(monthlyThemes.containsKey(month), isTrue,
            reason: 'Missing theme for month $month');
      }
    });

    test('every theme has a non-empty imagePath', () {
      for (final entry in monthlyThemes.entries) {
        expect(entry.value.imagePath, isNotEmpty,
            reason: 'Month ${entry.key} has empty imagePath');
        expect(entry.value.imagePath, contains('assets/backgrounds/'),
            reason:
                'Month ${entry.key} imagePath does not point to backgrounds');
      }
    });

    test('every theme has a non-empty poem', () {
      for (final entry in monthlyThemes.entries) {
        expect(entry.value.poem, isNotEmpty,
            reason: 'Month ${entry.key} has empty poem');
      }
    });

    test('every theme has a non-empty author', () {
      for (final entry in monthlyThemes.entries) {
        expect(entry.value.author, isNotEmpty,
            reason: 'Month ${entry.key} has empty author');
      }
    });

    test('all imagePaths end with .jpg', () {
      for (final entry in monthlyThemes.entries) {
        expect(entry.value.imagePath, endsWith('.jpg'),
            reason: 'Month ${entry.key} imagePath does not end with .jpg');
      }
    });
  });
}

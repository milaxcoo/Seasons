import 'package:flutter_test/flutter_test.dart';
import 'package:seasons/core/services/monthly_theme_service.dart';

void main() {
  group('MonthlyThemeService', () {
    test('month-to-asset mapping is correct for all 12 months', () {
      const expectedAssetByMonth = <int, String>{
        1: 'assets/backgrounds/january.jpg',
        2: 'assets/backgrounds/february.jpg',
        3: 'assets/backgrounds/march.jpg',
        4: 'assets/backgrounds/april.jpg',
        5: 'assets/backgrounds/may.jpg',
        6: 'assets/backgrounds/june.jpg',
        7: 'assets/backgrounds/july.jpg',
        8: 'assets/backgrounds/august.jpg',
        9: 'assets/backgrounds/september.jpg',
        10: 'assets/backgrounds/october.jpg',
        11: 'assets/backgrounds/november.jpg',
        12: 'assets/backgrounds/december.jpg',
      };

      for (final entry in expectedAssetByMonth.entries) {
        expect(
          monthlyThemeForMonth(entry.key).imagePath,
          entry.value,
          reason: 'Unexpected asset for month ${entry.key}',
        );
      }
    });

    test('same provider instance returns same asset for login and home', () {
      final service = MonthlyThemeService(
        currentDateProvider: () => DateTime(2026, 7, 14, 10, 30),
      );

      final loginScreenAssetPath = service.backgroundAssetPath;
      final homeScreenAssetPath = service.theme.imagePath;

      expect(loginScreenAssetPath, 'assets/backgrounds/july.jpg');
      expect(homeScreenAssetPath, 'assets/backgrounds/july.jpg');
      expect(loginScreenAssetPath, homeScreenAssetPath);
      expect(service.currentMonth, 7);
    });

    test('normalizeMonthNumber supports out-of-range month values', () {
      expect(normalizeMonthNumber(13), 1);
      expect(normalizeMonthNumber(0), 12);
      expect(normalizeMonthNumber(-1), 11);
    });
  });
}

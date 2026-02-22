import 'package:flutter/foundation.dart';
import 'package:seasons/core/monthly_theme_data.dart';

typedef CurrentDateProvider = DateTime Function();

@visibleForTesting
int normalizeMonthNumber(int month) {
  return ((month - 1) % 12 + 12) % 12 + 1;
}

@visibleForTesting
MonthlyTheme monthlyThemeForMonth(int month) {
  final normalizedMonth = normalizeMonthNumber(month);
  return monthlyThemes[normalizedMonth] ?? monthlyThemes[1]!;
}

class MonthlyThemeService {
  final DateTime sessionDateTime;
  final int currentMonth;
  final MonthlyTheme theme;

  factory MonthlyThemeService({
    CurrentDateProvider? currentDateProvider,
  }) {
    final nowProvider = currentDateProvider ?? DateTime.now;
    final sessionNow = nowProvider().toLocal();
    return MonthlyThemeService._(sessionNow);
  }

  MonthlyThemeService._(this.sessionDateTime)
      : currentMonth = normalizeMonthNumber(sessionDateTime.month),
        theme = monthlyThemeForMonth(sessionDateTime.month);

  String get backgroundAssetPath => theme.imagePath;
}

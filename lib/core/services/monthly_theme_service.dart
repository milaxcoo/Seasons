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
  final CurrentDateProvider _currentDateProvider;
  DateTime _lastResolvedDateTime;
  int _currentMonth;
  MonthlyTheme _theme;

  factory MonthlyThemeService({CurrentDateProvider? currentDateProvider}) {
    final nowProvider = currentDateProvider ?? DateTime.now;
    final initialNow = nowProvider().toLocal();
    return MonthlyThemeService._(nowProvider, initialNow);
  }

  MonthlyThemeService._(this._currentDateProvider, DateTime initialNow)
      : _lastResolvedDateTime = initialNow,
        _currentMonth = normalizeMonthNumber(initialNow.month),
        _theme = monthlyThemeForMonth(normalizeMonthNumber(initialNow.month));

  void _syncThemeIfMonthChanged() {
    final now = _currentDateProvider().toLocal();
    final resolvedMonth = normalizeMonthNumber(now.month);
    if (resolvedMonth == _currentMonth) {
      _lastResolvedDateTime = now;
      return;
    }
    _lastResolvedDateTime = now;
    _currentMonth = resolvedMonth;
    _theme = monthlyThemeForMonth(resolvedMonth);
  }

  DateTime get sessionDateTime {
    _syncThemeIfMonthChanged();
    return _lastResolvedDateTime;
  }

  int get currentMonth {
    _syncThemeIfMonthChanged();
    return _currentMonth;
  }

  MonthlyTheme get theme {
    _syncThemeIfMonthChanged();
    return _theme;
  }

  String get backgroundAssetPath => theme.imagePath;
}

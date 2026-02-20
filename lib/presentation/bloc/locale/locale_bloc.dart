import 'dart:ui';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'locale_event.dart';
import 'locale_state.dart';

class LocaleBloc extends Bloc<LocaleEvent, LocaleState> {
  static const String _localeKey = 'app_locale';
  static const Locale _defaultLocale = Locale('ru');
  static const List<Locale> _supportedLocales = [
    Locale('ru'),
    Locale('en'),
  ];

  LocaleBloc() : super(const LocaleState(_defaultLocale)) {
    on<LoadLocale>(_onLoadLocale);
    on<ChangeLocale>(_onChangeLocale);
  }

  Future<void> _onLoadLocale(
    LoadLocale event,
    Emitter<LocaleState> emit,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final savedLocaleCode = prefs.getString(_localeKey);

    Locale resolvedLocale;

    if (savedLocaleCode != null) {
      // Use saved preference
      resolvedLocale = Locale(savedLocaleCode);
    } else {
      // Get device locale
      final deviceLocale = PlatformDispatcher.instance.locale;

      // Check if device locale is supported
      if (_supportedLocales
          .any((l) => l.languageCode == deviceLocale.languageCode)) {
        resolvedLocale = Locale(deviceLocale.languageCode);
      } else {
        // Fallback to default (Russian)
        resolvedLocale = _defaultLocale;
      }
    }

    emit(LocaleState(resolvedLocale));
  }

  Future<void> _onChangeLocale(
    ChangeLocale event,
    Emitter<LocaleState> emit,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, event.locale.languageCode);
    emit(LocaleState(event.locale));
  }
}

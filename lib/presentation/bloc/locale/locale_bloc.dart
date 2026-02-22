import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'locale_event.dart';
import 'locale_state.dart';

typedef SystemLocaleProvider = Locale Function();
typedef SharedPreferencesFactory = Future<SharedPreferences> Function();

class LocaleBloc extends Bloc<LocaleEvent, LocaleState> {
  static const String _localeKey = 'app_locale';
  static const Locale _defaultLocale = Locale('ru');
  static const Set<String> _supportedLanguageCodes = {'ru', 'en'};

  final SharedPreferencesFactory _sharedPreferencesFactory;
  final SystemLocaleProvider _systemLocaleProvider;

  LocaleBloc({
    SharedPreferencesFactory? sharedPreferencesFactory,
    SystemLocaleProvider? systemLocaleProvider,
  })  : _sharedPreferencesFactory =
            sharedPreferencesFactory ?? SharedPreferences.getInstance,
        _systemLocaleProvider =
            systemLocaleProvider ?? (() => PlatformDispatcher.instance.locale),
        super(const LocaleState(_defaultLocale)) {
    on<LoadLocale>(_onLoadLocale);
    on<ChangeLocale>(_onChangeLocale);
  }

  Future<void> _onLoadLocale(
    LoadLocale event,
    Emitter<LocaleState> emit,
  ) async {
    final prefs = await _sharedPreferencesFactory();
    final savedLocaleCode = prefs.getString(_localeKey);
    final savedLocale = parseSavedLocaleCode(savedLocaleCode);

    if (savedLocale != null) {
      emit(LocaleState(savedLocale));
      return;
    }

    final resolvedLocale =
        resolveDefaultLocaleForSystem(_systemLocaleProvider());
    await prefs.setString(_localeKey, resolvedLocale.languageCode);
    emit(LocaleState(resolvedLocale));
  }

  Future<void> _onChangeLocale(
    ChangeLocale event,
    Emitter<LocaleState> emit,
  ) async {
    final normalizedLocale = normalizeSupportedLocale(event.locale);
    final prefs = await _sharedPreferencesFactory();
    await prefs.setString(_localeKey, normalizedLocale.languageCode);
    emit(LocaleState(normalizedLocale));
  }

  @visibleForTesting
  static Locale? parseSavedLocaleCode(String? localeCode) {
    if (localeCode == null) return null;
    if (!_supportedLanguageCodes.contains(localeCode)) return null;
    return Locale(localeCode);
  }

  @visibleForTesting
  static Locale resolveDefaultLocaleForSystem(Locale systemLocale) {
    final languageCode = systemLocale.languageCode;
    if (languageCode == 'en') return const Locale('en');
    if (languageCode == 'ru') return const Locale('ru');
    return _defaultLocale;
  }

  @visibleForTesting
  static Locale normalizeSupportedLocale(Locale locale) {
    if (_supportedLanguageCodes.contains(locale.languageCode)) {
      return Locale(locale.languageCode);
    }
    return _defaultLocale;
  }
}

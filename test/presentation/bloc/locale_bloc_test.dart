import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seasons/presentation/bloc/locale/locale_bloc.dart';
import 'package:seasons/presentation/bloc/locale/locale_event.dart';
import 'package:seasons/presentation/bloc/locale/locale_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('LocaleBloc default derivation without saved locale', () {
    blocTest<LocaleBloc, LocaleState>(
      "system locale 'en' resolves to app locale 'en' and persists it",
      build: () => LocaleBloc(
        systemLocaleProvider: () => const Locale('en'),
      ),
      act: (bloc) => bloc.add(const LoadLocale()),
      expect: () => [const LocaleState(Locale('en'))],
      verify: (_) async {
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('app_locale'), 'en');
      },
    );

    blocTest<LocaleBloc, LocaleState>(
      "system locale 'ru' resolves to app locale 'ru' and persists it",
      build: () => LocaleBloc(
        systemLocaleProvider: () => const Locale('ru'),
      ),
      act: (bloc) => bloc.add(const LoadLocale()),
      expect: () => [const LocaleState(Locale('ru'))],
      verify: (_) async {
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('app_locale'), 'ru');
      },
    );

    blocTest<LocaleBloc, LocaleState>(
      "unsupported system locale (de) resolves to app locale 'ru' and persists it",
      build: () => LocaleBloc(
        systemLocaleProvider: () => const Locale('de'),
      ),
      act: (bloc) => bloc.add(const LoadLocale()),
      expect: () => [const LocaleState(Locale('ru'))],
      verify: (_) async {
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('app_locale'), 'ru');
      },
    );
  });

  group('LocaleBloc saved locale override', () {
    blocTest<LocaleBloc, LocaleState>(
      "saved locale 'en' overrides system locale 'ru'",
      setUp: () {
        SharedPreferences.setMockInitialValues({'app_locale': 'en'});
      },
      build: () => LocaleBloc(
        systemLocaleProvider: () => const Locale('ru'),
      ),
      act: (bloc) => bloc.add(const LoadLocale()),
      expect: () => [const LocaleState(Locale('en'))],
      verify: (_) async {
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('app_locale'), 'en');
      },
    );

    blocTest<LocaleBloc, LocaleState>(
      "saved locale 'ru' overrides system locale 'en'",
      setUp: () {
        SharedPreferences.setMockInitialValues({'app_locale': 'ru'});
      },
      build: () => LocaleBloc(
        systemLocaleProvider: () => const Locale('en'),
      ),
      act: (bloc) => bloc.add(const LoadLocale()),
      expect: () => [const LocaleState(Locale('ru'))],
      verify: (_) async {
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('app_locale'), 'ru');
      },
    );
  });

  group('LocaleBloc change locale', () {
    blocTest<LocaleBloc, LocaleState>(
      "persist user-selected locale 'en'",
      build: () => LocaleBloc(),
      act: (bloc) => bloc.add(const ChangeLocale(Locale('en'))),
      expect: () => [const LocaleState(Locale('en'))],
      verify: (_) async {
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('app_locale'), 'en');
      },
    );

    blocTest<LocaleBloc, LocaleState>(
      "persist user-selected locale 'ru'",
      build: () => LocaleBloc(),
      act: (bloc) => bloc.add(const ChangeLocale(Locale('ru'))),
      expect: () => [const LocaleState(Locale('ru'))],
      verify: (_) async {
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('app_locale'), 'ru');
      },
    );
  });
}

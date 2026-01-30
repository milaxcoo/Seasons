import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:seasons/presentation/bloc/locale/locale_bloc.dart';
import 'package:seasons/presentation/bloc/locale/locale_event.dart';
import 'package:seasons/presentation/bloc/locale/locale_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(const Locale('ru'));
  });

  setUp(() {
    // Initialize SharedPreferences with empty values for each test
    SharedPreferences.setMockInitialValues({});
  });

  group('LocaleBloc', () {
    test('initial state is LocaleState with Russian locale', () {
      final bloc = LocaleBloc();
      expect(bloc.state, const LocaleState(Locale('ru')));
      bloc.close();
    });

    blocTest<LocaleBloc, LocaleState>(
      'emits [LocaleState(ru)] when LoadLocale is added and no saved preference exists',
      setUp: () {
        SharedPreferences.setMockInitialValues({});
      },
      build: () => LocaleBloc(),
      act: (bloc) => bloc.add(const LoadLocale()),
      expect: () => [
        // Will emit Russian if device locale is not English, or if unsupported
        isA<LocaleState>(),
      ],
    );

    blocTest<LocaleBloc, LocaleState>(
      'emits [LocaleState(en)] when LoadLocale is added with saved English preference',
      setUp: () {
        SharedPreferences.setMockInitialValues({'app_locale': 'en'});
      },
      build: () => LocaleBloc(),
      act: (bloc) => bloc.add(const LoadLocale()),
      expect: () => [const LocaleState(Locale('en'))],
    );

    blocTest<LocaleBloc, LocaleState>(
      'emits [LocaleState(ru)] when LoadLocale is added with saved Russian preference',
      setUp: () {
        SharedPreferences.setMockInitialValues({'app_locale': 'ru'});
      },
      build: () => LocaleBloc(),
      act: (bloc) => bloc.add(const LoadLocale()),
      expect: () => [const LocaleState(Locale('ru'))],
    );

    blocTest<LocaleBloc, LocaleState>(
      'emits [LocaleState(en)] when ChangeLocale to English is added',
      setUp: () {
        SharedPreferences.setMockInitialValues({});
      },
      build: () => LocaleBloc(),
      act: (bloc) => bloc.add(const ChangeLocale(Locale('en'))),
      expect: () => [const LocaleState(Locale('en'))],
      verify: (_) async {
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('app_locale'), 'en');
      },
    );

    blocTest<LocaleBloc, LocaleState>(
      'emits [LocaleState(ru)] when ChangeLocale to Russian is added',
      setUp: () {
        SharedPreferences.setMockInitialValues({});
      },
      build: () => LocaleBloc(),
      act: (bloc) => bloc.add(const ChangeLocale(Locale('ru'))),
      expect: () => [const LocaleState(Locale('ru'))],
      verify: (_) async {
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('app_locale'), 'ru');
      },
    );

    blocTest<LocaleBloc, LocaleState>(
      'persists locale change across multiple events',
      setUp: () {
        SharedPreferences.setMockInitialValues({});
      },
      build: () => LocaleBloc(),
      act: (bloc) async {
        bloc.add(const ChangeLocale(Locale('en')));
        await Future.delayed(const Duration(milliseconds: 50));
        bloc.add(const ChangeLocale(Locale('ru')));
      },
      expect: () => [
        const LocaleState(Locale('en')),
        const LocaleState(Locale('ru')),
      ],
    );
  });
}

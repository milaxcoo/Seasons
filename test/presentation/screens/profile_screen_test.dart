import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:seasons/data/models/user_profile.dart';
import 'package:seasons/data/repositories/voting_repository.dart';
import 'package:seasons/presentation/screens/profile_screen.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:seasons/l10n/app_localizations.dart';

import '../../mocks.dart';

void main() {
  late MockVotingRepository mockRepository;

  setUp(() {
    mockRepository = MockVotingRepository();
  });

  Widget createTestWidget() {
    return RepositoryProvider<VotingRepository>.value(
      value: mockRepository,
      child: const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('ru'), Locale('en')],
        locale: Locale('ru'),
        home: ProfileScreen(),
      ),
    );
  }

  group('ProfileScreen', () {
    testWidgets('renders user profile data when loaded', (tester) async {
      // Arrange
      final testProfile = UserProfile(
        surname: 'Иванов',
        name: 'Иван',
        patronymic: 'Иванович',
        email: 'ivanov@rudn.ru',
        jobTitle: 'Студент',
      );
      when(() => mockRepository.getUserProfile())
          .thenAnswer((_) async => testProfile);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Иванов'), findsOneWidget);
      expect(find.text('Иван'), findsOneWidget);
      expect(find.text('Иванович'), findsOneWidget);
      expect(find.text('ivanov@rudn.ru'), findsOneWidget);
      expect(find.text('Студент'), findsOneWidget);
    });

    testWidgets('renders error message when profile is null', (tester) async {
      // Arrange
      when(() => mockRepository.getUserProfile())
          .thenAnswer((_) async => null);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Не удалось загрузить данные профиля'), findsOneWidget);
    });

    testWidgets('back button pops navigation', (tester) async {
      // Arrange
      when(() => mockRepository.getUserProfile())
          .thenAnswer((_) async => UserProfile(
                surname: 'Test',
                name: 'User',
                patronymic: '',
                email: 'test@test.com',
                jobTitle: 'Tester',
              ));

      // Create a navigator to verify pop behavior
      final navigatorKey = GlobalKey<NavigatorState>();

      await tester.pumpWidget(
        RepositoryProvider<VotingRepository>.value(
          value: mockRepository,
          child: MaterialApp(
            navigatorKey: navigatorKey,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('ru'), Locale('en')],
            locale: const Locale('ru'),
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  ),
                  child: const Text('Go to Profile'),
                ),
              ),
            ),
          ),
        ),
      );

      // Navigate to ProfileScreen
      await tester.tap(find.text('Go to Profile'));
      await tester.pumpAndSettle();

      // Verify we're on ProfileScreen
      expect(find.byType(ProfileScreen), findsOneWidget);

      // Tap back button
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Verify we're back on the original screen
      expect(find.byType(ProfileScreen), findsNothing);
      expect(find.text('Go to Profile'), findsOneWidget);
    });

    testWidgets('renders AppBar with correct title', (tester) async {
      // Arrange
      when(() => mockRepository.getUserProfile())
          .thenAnswer((_) async => UserProfile(
                surname: 'Test',
                name: 'User',
                patronymic: '',
                email: 'test@test.com',
                jobTitle: 'Tester',
              ));

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Данные пользователя'), findsOneWidget);
    });

    testWidgets('dividers are rendered between profile fields', (tester) async {
      // Arrange
      when(() => mockRepository.getUserProfile())
          .thenAnswer((_) async => UserProfile(
                surname: 'Test',
                name: 'User',
                patronymic: 'Patronymic',
                email: 'test@test.com',
                jobTitle: 'Tester',
              ));

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert: Should have 4 dividers between 5 fields
      expect(find.byType(Divider), findsNWidgets(4));
    });
  });
}

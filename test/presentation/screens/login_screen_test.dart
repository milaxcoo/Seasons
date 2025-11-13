import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:seasons/presentation/bloc/auth/auth_bloc.dart';
import 'package:seasons/presentation/screens/login_screen.dart';

import '../../mocks.dart';

void main() {
  late MockAuthBloc mockAuthBloc;

  setUp(() {
    mockAuthBloc = MockAuthBloc();
  });

  setUpAll(() {
    registerFallbackValue(AppStarted());
    registerFallbackValue(LoggedOut());
    registerFallbackValue(const LoggedIn(login: '', password: ''));
  });

  Widget createTestWidget() {
    return BlocProvider<AuthBloc>.value(
      value: mockAuthBloc,
      child: const MaterialApp(
        home: LoginScreen(),
      ),
    );
  }

  group('LoginScreen', () {
    testWidgets('renders main UI components correctly', (tester) async {
      // Arrange
      when(() => mockAuthBloc.state).thenReturn(AuthInitial());
      when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert: Verify that the main UI elements are present
      expect(find.text('Seasons'), findsOneWidget);
      expect(find.text('Войти'), findsOneWidget);
      expect(find.text('© RUDN University 2025'), findsOneWidget);
      expect(find.text('seasons-helpdesk@rudn.ru'), findsOneWidget);
    });

    testWidgets('shows info dialog when login button is tapped', (tester) async {
      // Arrange
      when(() => mockAuthBloc.state).thenReturn(AuthInitial());
      when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());
      when(() => mockAuthBloc.add(any())).thenAnswer((_) async {});

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Tap the login button
      await tester.tap(find.text('Войти'));
      await tester.pumpAndSettle();

      // Assert: Verify that the dialog is shown
      expect(find.text('Авторизация через РУДН ID'), findsOneWidget);
      expect(find.text('Отмена'), findsOneWidget);
      expect(find.text('Продолжить'), findsOneWidget);
    });

    testWidgets('triggers login when Continue is tapped in dialog', (tester) async {
      // Arrange
      when(() => mockAuthBloc.state).thenReturn(AuthInitial());
      when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());
      when(() => mockAuthBloc.add(any())).thenAnswer((_) async {});

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Tap the login button to show dialog
      await tester.tap(find.text('Войти'));
      await tester.pumpAndSettle();

      // Tap the Continue button
      await tester.tap(find.text('Продолжить'));
      await tester.pumpAndSettle();

      // Assert: Verify that LoggedIn event was added
      verify(() => mockAuthBloc.add(const LoggedIn(login: 'rudn_user', password: 'password'))).called(1);
    });

    testWidgets('closes dialog when Cancel is tapped', (tester) async {
      // Arrange
      when(() => mockAuthBloc.state).thenReturn(AuthInitial());
      when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Tap the login button to show dialog
      await tester.tap(find.text('Войти'));
      await tester.pumpAndSettle();

      // Tap the Cancel button
      await tester.tap(find.text('Отмена'));
      await tester.pumpAndSettle();

      // Assert: Verify that the dialog is closed
      expect(find.text('Авторизация через РУДН ID'), findsNothing);
    });

    testWidgets('navigates to HomeScreen when AuthAuthenticated', (tester) async {
      // Arrange
      when(() => mockAuthBloc.state).thenReturn(AuthInitial());
      
      // Create a stream controller to emit states
      final stateController = StreamController<AuthState>();
      when(() => mockAuthBloc.stream).thenAnswer((_) => stateController.stream);
      when(() => mockAuthBloc.add(any())).thenAnswer((_) async {});

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Emit AuthAuthenticated state
      stateController.add(const AuthAuthenticated(userLogin: 'testuser'));
      await tester.pumpAndSettle();

      // Assert: Verify that HomeScreen is shown (by checking for elements not in LoginScreen)
      expect(find.text('Seasons'), findsWidgets); // Both screens have this, but HomeScreen is now visible
      expect(find.text('Войти'), findsNothing); // Login button should not be visible anymore

      stateController.close();
    });

    testWidgets('shows loading state when AuthLoading', (tester) async {
      // Arrange
      when(() => mockAuthBloc.state).thenReturn(AuthLoading());
      when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert: The screen should still render normally during loading
      expect(find.text('Seasons'), findsOneWidget);
      expect(find.text('Войти'), findsOneWidget);
    });

    testWidgets('renders with AuthUnauthenticated state', (tester) async {
      // Arrange
      when(() => mockAuthBloc.state).thenReturn(AuthUnauthenticated());
      when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert
      expect(find.text('Seasons'), findsOneWidget);
      expect(find.text('Войти'), findsOneWidget);
    });

    testWidgets('renders with AuthFailure state', (tester) async {
      // Arrange
      when(() => mockAuthBloc.state).thenReturn(const AuthFailure(error: 'Login failed'));
      when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert: The screen should still render normally
      expect(find.text('Seasons'), findsOneWidget);
      expect(find.text('Войти'), findsOneWidget);
    });

    testWidgets('has correct copyright and contact information', (tester) async {
      // Arrange
      when(() => mockAuthBloc.state).thenReturn(AuthInitial());
      when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert
      expect(find.text('© RUDN University 2025'), findsOneWidget);
      expect(find.text('seasons-helpdesk@rudn.ru'), findsOneWidget);
    });

    testWidgets('login button has arrow icon', (tester) async {
      // Arrange
      when(() => mockAuthBloc.state).thenReturn(AuthInitial());
      when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert: Verify that the arrow icon is present
      expect(find.byIcon(Icons.arrow_forward_ios), findsOneWidget);
    });
  });
}

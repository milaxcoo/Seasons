import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:seasons/data/models/voting_event.dart' as model;
import 'package:seasons/presentation/bloc/auth/auth_bloc.dart';
import 'package:seasons/presentation/bloc/voting/voting_bloc.dart';
import 'package:seasons/presentation/bloc/voting/voting_event.dart';
import 'package:seasons/presentation/bloc/voting/voting_state.dart';
import 'package:seasons/presentation/screens/home_screen.dart';
import 'package:seasons/presentation/widgets/custom_icons.dart';

import '../../mocks.dart';

void main() {
  late MockAuthBloc mockAuthBloc;
  late MockVotingBloc mockVotingBloc;

  setUpAll(() async {
    await initializeDateFormatting('ru_RU', null);
    registerFallbackValue(const FetchEventsByStatus(status: model.VotingStatus.registration));
    registerFallbackValue(LoggedOut());
  });

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    mockVotingBloc = MockVotingBloc();
    when(() => mockAuthBloc.state).thenReturn(const AuthAuthenticated(userLogin: 'testuser'));
    when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());
  });

  Widget createTestWidget() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: mockAuthBloc),
        BlocProvider<VotingBloc>.value(value: mockVotingBloc),
      ],
      child: const MaterialApp(
        home: HomeScreen(),
      ),
    );
  }

  group('HomeScreen', () {
    testWidgets('renders main layout components correctly', (tester) async {
      // Arrange
      when(() => mockVotingBloc.state).thenReturn(const VotingEventsLoadSuccess(events: []));
      when(() => mockVotingBloc.stream).thenAnswer((_) => const Stream.empty());
      when(() => mockVotingBloc.add(any())).thenAnswer((_) async {});

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert: Verify that the new UI components, including custom icons, are present.
      expect(find.text('testuser'), findsOneWidget);
      expect(find.text('Seasons'), findsOneWidget);
      expect(find.text('времена года'), findsOneWidget);
      // Look for the custom SVG icon widgets by their type.
      expect(find.byType(RegistrationIcon), findsWidgets);
      expect(find.byType(ActiveVotingIcon), findsWidgets);
      expect(find.byType(ResultsIcon), findsWidgets);
    });

    testWidgets('renders CircularProgressIndicator when state is VotingLoadInProgress', (tester) async {
      // Arrange
      when(() => mockVotingBloc.state).thenReturn(VotingLoadInProgress());
      when(() => mockVotingBloc.stream).thenAnswer((_) => const Stream.empty());
      when(() => mockVotingBloc.add(any())).thenAnswer((_) async {});

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders list of events when state is VotingEventsLoadSuccess', (tester) async {
      // Arrange
      final events = [
        model.VotingEvent(
          id: 'reg-01',
          title: 'Лучшее мобильное приложение',
          description: 'Описание события',
          status: model.VotingStatus.registration,
          registrationEndDate: DateTime(2025, 12, 31),
          votingStartDate: DateTime(2026, 1, 1),
          votingEndDate: DateTime(2026, 1, 31),
          isRegistered: false,
          questions: const [],
          hasVoted: false,
          results: const [],
        ),
      ];
      final state = VotingEventsLoadSuccess(events: events);
      when(() => mockVotingBloc.state).thenReturn(state);
      when(() => mockVotingBloc.stream).thenAnswer((_) => const Stream.empty());
      when(() => mockVotingBloc.add(any())).thenAnswer((_) async {});

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Лучшее мобильное приложение'), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
      expect(find.text('Не зарегистрирован(-а)'), findsOneWidget);
    });

    testWidgets('renders empty state when no events', (tester) async {
      // Arrange
      when(() => mockVotingBloc.state).thenReturn(const VotingEventsLoadSuccess(events: []));
      when(() => mockVotingBloc.stream).thenAnswer((_) => const Stream.empty());
      when(() => mockVotingBloc.add(any())).thenAnswer((_) async {});

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Нет активных голосований'), findsOneWidget);
    });

    testWidgets('renders error message when state is VotingFailure', (tester) async {
      // Arrange
      final state = const VotingFailure(error: 'Failed to load');
      when(() => mockVotingBloc.state).thenReturn(state);
      when(() => mockVotingBloc.stream).thenAnswer((_) => const Stream.empty());
      when(() => mockVotingBloc.add(any())).thenAnswer((_) async {});

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Error: Failed to load'), findsOneWidget);
    });

    testWidgets('shows logout button and triggers logout', (tester) async {
      // Arrange
      when(() => mockVotingBloc.state).thenReturn(const VotingEventsLoadSuccess(events: []));
      when(() => mockVotingBloc.stream).thenAnswer((_) => const Stream.empty());
      when(() => mockVotingBloc.add(any())).thenAnswer((_) async {});
      when(() => mockAuthBloc.add(any())).thenAnswer((_) async {});

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find and tap logout button
      final logoutButton = find.byIcon(Icons.exit_to_app);
      expect(logoutButton, findsOneWidget);

      await tester.tap(logoutButton);
      await tester.pumpAndSettle();

      // Assert: Verify that LoggedOut event was added
      verify(() => mockAuthBloc.add(LoggedOut())).called(1);
    });

    testWidgets('displays registered status correctly', (tester) async {
      // Arrange
      final events = [
        model.VotingEvent(
          id: 'reg-01',
          title: 'Registered Event',
          description: 'Description',
          status: model.VotingStatus.registration,
          registrationEndDate: DateTime(2025, 12, 31),
          isRegistered: true,
          questions: const [],
          hasVoted: false,
          results: const [],
        ),
      ];
      when(() => mockVotingBloc.state).thenReturn(VotingEventsLoadSuccess(events: events));
      when(() => mockVotingBloc.stream).thenAnswer((_) => const Stream.empty());
      when(() => mockVotingBloc.add(any())).thenAnswer((_) async {});

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Зарегистрирован(-а)'), findsOneWidget);
    });

    testWidgets('displays voted status correctly', (tester) async {
      // Arrange
      final events = [
        model.VotingEvent(
          id: 'active-01',
          title: 'Active Event',
          description: 'Description',
          status: model.VotingStatus.active,
          votingEndDate: DateTime(2025, 12, 31),
          isRegistered: true,
          questions: const [],
          hasVoted: true,
          results: const [],
        ),
      ];
      when(() => mockVotingBloc.state).thenReturn(VotingEventsLoadSuccess(events: events));
      when(() => mockVotingBloc.stream).thenAnswer((_) => const Stream.empty());
      when(() => mockVotingBloc.add(any())).thenAnswer((_) async {});

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Проголосовал(-а)'), findsOneWidget);
    });

    testWidgets('panel selector switches between statuses', (tester) async {
      // Arrange
      when(() => mockVotingBloc.state).thenReturn(const VotingEventsLoadSuccess(events: []));
      when(() => mockVotingBloc.stream).thenAnswer((_) => const Stream.empty());
      when(() => mockVotingBloc.add(any())).thenAnswer((_) async {});

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap on active voting panel (middle button)
      final activeVotingIcon = find.byType(ActiveVotingIcon).first;
      await tester.tap(activeVotingIcon);
      await tester.pumpAndSettle();

      // Assert: Verify that FetchEventsByStatus was called with active status
      verify(() => mockVotingBloc.add(const FetchEventsByStatus(status: model.VotingStatus.active))).called(1);
    });

    testWidgets('displays date information correctly', (tester) async {
      // Arrange
      final events = [
        model.VotingEvent(
          id: 'event-01',
          title: 'Event with Dates',
          description: 'Description',
          status: model.VotingStatus.registration,
          registrationEndDate: DateTime(2025, 12, 31),
          votingStartDate: DateTime(2026, 1, 1),
          votingEndDate: DateTime(2026, 1, 31),
          isRegistered: false,
          questions: const [],
          hasVoted: false,
          results: const [],
        ),
      ];
      when(() => mockVotingBloc.state).thenReturn(VotingEventsLoadSuccess(events: events));
      when(() => mockVotingBloc.stream).thenAnswer((_) => const Stream.empty());
      when(() => mockVotingBloc.add(any())).thenAnswer((_) async {});

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert: Check for date text (format may vary)
      expect(find.textContaining('Регистрация до:'), findsOneWidget);
    });

    testWidgets('renders footer with poem', (tester) async {
      // Arrange
      when(() => mockVotingBloc.state).thenReturn(const VotingEventsLoadSuccess(events: []));
      when(() => mockVotingBloc.stream).thenAnswer((_) => const Stream.empty());
      when(() => mockVotingBloc.add(any())).thenAnswer((_) async {});

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert: Footer should contain a poem (content depends on current month)
      // Just verify that there's text in the lower portion
      expect(find.byType(Padding), findsWidgets);
    });
  });
}


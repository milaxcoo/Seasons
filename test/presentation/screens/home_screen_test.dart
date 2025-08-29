import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart'; // Import for date formatting
import 'package:mocktail/mocktail.dart';
import 'package:seasons/data/models/voting_event.dart' as model;
import 'package:seasons/presentation/bloc/auth/auth_bloc.dart';
import 'package:seasons/presentation/bloc/voting/voting_bloc.dart';
import 'package:seasons/presentation/bloc/voting/voting_event.dart';
import 'package:seasons/presentation/bloc/voting/voting_state.dart';
import 'package:seasons/presentation/screens/home_screen.dart';

import '../../mocks.dart'; // Import the mock classes

void main() {
  late MockAuthBloc mockAuthBloc;
  late MockVotingBloc mockVotingBloc;

  // This runs once before all tests in this file
  setUpAll(() async {
    // Initialize date formatting for the Russian locale
    await initializeDateFormatting('ru_RU', null);
  });

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    mockVotingBloc = MockVotingBloc();

    // Stub the initial state for the AuthBloc for all tests
    when(() => mockAuthBloc.state).thenReturn(const AuthAuthenticated(userLogin: 'testuser'));
  });

  // Helper function to build the widget tree with necessary providers.
  Widget createTestWidget() {
    return MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: mockAuthBloc),
          BlocProvider<VotingBloc>.value(value: mockVotingBloc),
        ],
        child: const HomeScreen(),
      ),
    );
  }

  group('HomeScreen', () {
    testWidgets('renders main layout components correctly', (tester) async {
      // Arrange: Set the BLoC to a successful but empty state.
      when(() => mockVotingBloc.state).thenReturn(const VotingEventsLoadSuccess(events: []));
      when(() => mockVotingBloc.stream).thenAnswer((_) => Stream.value(const VotingEventsLoadSuccess(events: [])));

      // Act: Build the widget.
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert: Verify that the new UI components are present.
      expect(find.text('testuser'), findsOneWidget); // From _TopBar
      expect(find.text('Seasons'), findsOneWidget); // From _Header
      expect(find.byIcon(Icons.how_to_reg_outlined), findsOneWidget); // From _PanelSelector
    });

    testWidgets('renders list of events when state is VotingEventsLoadSuccess', (tester) async {
      // Arrange
      final events = [
        model.VotingEvent(
          id: 'reg-01',
          title: 'Лучшее мобильное приложение',
          description: '',
          status: model.VotingStatus.registration,
          registrationEndDate: DateTime.now(),
          votingStartDate: DateTime.now(),
          votingEndDate: DateTime.now(),
        ),
      ];
      final state = VotingEventsLoadSuccess(events: events);
      when(() => mockVotingBloc.state).thenReturn(state);
      when(() => mockVotingBloc.stream).thenAnswer((_) => Stream.value(state));

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert
      expect(find.text('Лучшее мобильное приложение'), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
    });
  });
}


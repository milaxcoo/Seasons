import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:seasons/data/models/voting_event.dart' as model;
import 'package:seasons/presentation/bloc/auth/auth_bloc.dart';
import 'package:seasons/presentation/bloc/voting/voting_bloc.dart';
import 'package:seasons/presentation/bloc/voting/voting_state.dart';
import 'package:seasons/presentation/screens/home_screen.dart';

// Mock classes for the BLoCs used by the HomeScreen.
class MockAuthBloc extends Mock implements AuthBloc {
  @override
  AuthState get state => const AuthAuthenticated(userLogin: 'testuser');
}

class MockVotingBloc extends Mock implements VotingBloc {
  @override
  VotingState get state => VotingInitial();
}

void main() {
  late MockAuthBloc mockAuthBloc;
  late MockVotingBloc mockVotingBloc;

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    mockVotingBloc = MockVotingBloc();
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
    testWidgets('renders TabBar with correct tabs', (tester) async {
      // Arrange: Set the BLoC to an initial state.
      when(() => mockVotingBloc.state).thenReturn(VotingInitial());

      // Act: Build the widget.
      await tester.pumpWidget(createTestWidget());

      // Assert: Verify that the main UI elements are present.
      expect(find.byType(TabBar), findsOneWidget);
      expect(find.text('Registration'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Results'), findsOneWidget);
    });

    testWidgets('renders CircularProgressIndicator when state is VotingLoadInProgress', (tester) async {
      // Arrange: Set the BLoC to the loading state.
      when(() => mockVotingBloc.state).thenReturn(VotingLoadInProgress());

      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders list of events when state is VotingEventsLoadSuccess', (tester) async {
      // Arrange: Create mock data and set the BLoC to the success state.
      final events = [
        model.VotingEvent(
          id: 'reg-01',
          title: 'Best Mobile App',
          description: '',
          status: model.VotingStatus.registration,
          registrationEndDate: DateTime.now(),
          votingStartDate: DateTime.now(),
          votingEndDate: DateTime.now(),
        ),
      ];
      when(() => mockVotingBloc.state).thenReturn(VotingEventsLoadSuccess(events: events));

      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert: Verify that the event card is rendered.
      expect(find.text('Best Mobile App'), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('renders error message when state is VotingFailure', (tester) async {
      // Arrange: Set the BLoC to the failure state.
      when(() => mockVotingBloc.state).thenReturn(const VotingFailure(error: 'Failed to load'));

      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.text('Error: Failed to load'), findsOneWidget);
    });
  });
}

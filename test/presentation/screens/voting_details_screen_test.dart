import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:seasons/data/models/nominee.dart';
import 'package:seasons/data/models/voting_event.dart' as model;
import 'package:seasons/presentation/bloc/voting/voting_bloc.dart';
import 'package:seasons/presentation/bloc/voting/voting_event.dart';
import 'package:seasons/presentation/bloc/voting/voting_state.dart';
import 'package:seasons/presentation/screens/voting_details_screen.dart';

import '../../mocks.dart'; // Import the mock classes

void main() {
  late MockVotingBloc mockVotingBloc;
  late model.VotingEvent testEvent;

  setUp(() {
    mockVotingBloc = MockVotingBloc();
    testEvent = model.VotingEvent(
      id: 'active-01',
      title: 'Innovator of the Year',
      description: '',
      status: model.VotingStatus.active,
      registrationEndDate: DateTime.now(),
      votingStartDate: DateTime.now(),
      votingEndDate: DateTime.now(),
    );
    // Register a fallback value for the event for mocktail verification
    registerFallbackValue(const SubmitVote(eventId: '', nomineeId: ''));

    // FIXED: Stub the close method to prevent the dispose error.
    // This tells the mock BLoC how to handle being closed by the BlocProvider.
    when(() => mockVotingBloc.close()).thenAnswer((_) async {});
  });

  Widget createTestWidget() {
    return MaterialApp(
      home: BlocProvider<VotingBloc>.value(
        value: mockVotingBloc,
        child: VotingDetailsScreen(event: testEvent),
      ),
    );
  }

  group('VotingDetailsScreen', () {
    testWidgets('renders CircularProgressIndicator when state is VotingLoadInProgress', (tester) async {
      // Arrange
      when(() => mockVotingBloc.state).thenReturn(VotingLoadInProgress());
      when(() => mockVotingBloc.stream).thenAnswer((_) => Stream.value(VotingLoadInProgress()));

      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders list of nominees when state is VotingNomineesLoadSuccess', (tester) async {
      // Arrange
      final nominees = [
        const Nominee(id: 'nom-01', name: 'Project Alpha'),
        const Nominee(id: 'nom-02', name: 'Team Innovate'),
      ];
      final state = VotingNomineesLoadSuccess(nominees: nominees);
      when(() => mockVotingBloc.state).thenReturn(state);
      when(() => mockVotingBloc.stream).thenAnswer((_) => Stream.value(state));

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert
      expect(find.text('Project Alpha'), findsOneWidget);
      expect(find.text('Team Innovate'), findsOneWidget);
      expect(find.byType(RadioListTile<String>), findsNWidgets(2));
    });

    testWidgets('enables submit button only when a nominee is selected', (tester) async {
      // Arrange
      final nominees = [const Nominee(id: 'nom-01', name: 'Project Alpha')];
      final state = VotingNomineesLoadSuccess(nominees: nominees);
      when(() => mockVotingBloc.state).thenReturn(state);
      when(() => mockVotingBloc.stream).thenAnswer((_) => Stream.value(state));

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert: Initially, the button should be disabled.
      final submitButton = find.widgetWithText(ElevatedButton, 'Submit Vote');
      expect(tester.widget<ElevatedButton>(submitButton).onPressed, isNull);

      // Act: Tap on a nominee to select it.
      await tester.tap(find.text('Project Alpha'));
      await tester.pump(); // Rebuild the widget after state change.

      // Assert: After selection, the button should be enabled.
      expect(tester.widget<ElevatedButton>(submitButton).onPressed, isNotNull);
    });

    testWidgets('dispatches SubmitVote event when submit button is tapped', (tester) async {
      // Arrange
      final nominees = [const Nominee(id: 'nom-01', name: 'Project Alpha')];
      final state = VotingNomineesLoadSuccess(nominees: nominees);
      when(() => mockVotingBloc.state).thenReturn(state);
      when(() => mockVotingBloc.stream).thenAnswer((_) => Stream.value(state));
      when(() => mockVotingBloc.add(any())).thenReturn(null);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Select a nominee and tap the submit button.
      await tester.tap(find.text('Project Alpha'));
      await tester.pump();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Submit Vote'));
      await tester.pump();

      // Assert: Verify that the SubmitVote event was added to the BLoC.
      verify(() => mockVotingBloc.add(const SubmitVote(eventId: 'active-01', nomineeId: 'nom-01'))).called(1);
    });
  });
}

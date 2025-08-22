import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:seasons/data/models/nominee.dart';
import 'package:seasons/data/models/voting_event.dart' as model;
import 'package:seasons/data/repositories/voting_repository.dart';
import 'package:seasons/presentation/bloc/voting/voting_bloc.dart';
import 'package:seasons/presentation/bloc/voting/voting_event.dart';
import 'package:seasons/presentation/bloc/voting/voting_state.dart';
import 'package:seasons/presentation/screens/voting_details_screen.dart';

import '../../mocks.dart'; // Import the mock classes from a central file

void main() {
  late MockVotingRepository mockVotingRepository;
  late model.VotingEvent testEvent;

  setUp(() {
    mockVotingRepository = MockVotingRepository();
    testEvent = model.VotingEvent(
      id: 'active-01',
      title: 'Innovator of the Year',
      description: '',
      status: model.VotingStatus.active,
      registrationEndDate: DateTime.now(),
      votingStartDate: DateTime.now(),
      votingEndDate: DateTime.now(),
    );
  });

  // A helper function to create the widget under test.
  // It now provides the MockVotingRepository, which the screen needs to create its BLoC.
  Widget createTestWidget() {
    return RepositoryProvider<VotingRepository>.value(
      value: mockVotingRepository,
      child: MaterialApp(
        home: VotingDetailsScreen(event: testEvent),
      ),
    );
  }

  group('VotingDetailsScreen', () {
    testWidgets('renders CircularProgressIndicator initially', (tester) async {
      // Arrange: Set up the repository to simulate a delay.
      when(() => mockVotingRepository.getNomineesForEvent(any()))
          .thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 100));
        return [];
      });

      // Act: Build the widget.
      await tester.pumpWidget(createTestWidget());

      // Assert: Verify that the loading indicator is displayed while fetching.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Allow the future to complete.
      await tester.pumpAndSettle();
    });

    testWidgets('renders list of nominees on successful load', (tester) async {
      // Arrange: Set up the repository to return a list of nominees.
      final nominees = [
        const Nominee(id: 'nom-01', name: 'Project Alpha'),
        const Nominee(id: 'nom-02', name: 'Team Innovate'),
      ];
      when(() => mockVotingRepository.getNomineesForEvent(any()))
          .thenAnswer((_) async => nominees);

      // Act: Build the widget and let it settle.
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert: Verify that the nominees are rendered.
      expect(find.text('Project Alpha'), findsOneWidget);
      expect(find.text('Team Innovate'), findsOneWidget);
      expect(find.byType(RadioListTile<String>), findsNWidgets(2));
    });

    testWidgets('enables submit button only when a nominee is selected', (tester) async {
      // Arrange
      final nominees = [const Nominee(id: 'nom-01', name: 'Project Alpha')];
      when(() => mockVotingRepository.getNomineesForEvent(any()))
          .thenAnswer((_) async => nominees);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert: Initially, the button should be disabled.
      final submitButton = find.widgetWithText(ElevatedButton, 'Submit Vote');
      expect(tester.widget<ElevatedButton>(submitButton).onPressed, isNull);

      // Act: Tap on a nominee to select it.
      await tester.tap(find.text('Project Alpha'));
      await tester.pump(); // Rebuild the widget after the local state change.

      // Assert: After selection, the button should be enabled.
      expect(tester.widget<ElevatedButton>(submitButton).onPressed, isNotNull);
    });

    testWidgets('shows confirmation dialog on successful vote submission', (tester) async {
      // Arrange
      final nominees = [const Nominee(id: 'nom-01', name: 'Project Alpha')];
      when(() => mockVotingRepository.getNomineesForEvent(any()))
          .thenAnswer((_) async => nominees);
      when(() => mockVotingRepository.submitVote(any(), any()))
          .thenAnswer((_) async {}); // Simulate a successful vote.

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Select a nominee and tap the submit button.
      await tester.tap(find.text('Project Alpha'));
      await tester.pump();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Submit Vote'));
      
      // FIXED: We need one pump to process the state change from the BLoC,
      // and then pumpAndSettle to wait for the dialog animation.
      await tester.pump();
      await tester.pumpAndSettle();

      // Assert: Verify that the confirmation dialog is shown.
      expect(find.text('Vote Submitted'), findsOneWidget);
      expect(find.text('Thank you for your participation!'), findsOneWidget);
    });
  });
}

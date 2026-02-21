import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seasons/data/models/vote_result.dart';
import 'package:seasons/data/models/voting_event.dart';
import 'package:seasons/l10n/app_localizations.dart';
import 'package:seasons/presentation/screens/results_screen.dart';

void main() {
  Widget createTestWidget(VotingEvent event) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ru'), Locale('en')],
      locale: const Locale('en'),
      home: ResultsScreen(event: event, imagePath: ''),
    );
  }

  testWidgets('renders results table and event details', (tester) async {
    final event = VotingEvent(
      id: 'result-1',
      title: 'Annual Voting',
      description: 'Choose the winner',
      status: VotingStatus.completed,
      votingStartDate: DateTime(2026, 1, 1, 12, 0, 0),
      votingEndDate: DateTime(2026, 1, 31, 12, 0, 0),
      isRegistered: true,
      questions: const [],
      hasVoted: true,
      results: const [
        QuestionResult(
          name: 'Board decision',
          type: 'standard',
          subjectResults: [
            SubjectResult(name: 'Candidate A', voteCounts: {'Yes': 10, 'No': 2}),
          ],
        ),
      ],
    );

    await tester.pumpWidget(createTestWidget(event));
    await tester.pumpAndSettle();

    expect(find.text('Annual Voting'), findsOneWidget);
    expect(find.text('Choose the winner'), findsOneWidget);
    expect(find.textContaining('Board decision'), findsOneWidget);
    expect(find.text('Candidate A'), findsOneWidget);
    expect(find.byType(Table), findsOneWidget);
  });

  testWidgets('renders empty-result state without table', (tester) async {
    final event = VotingEvent(
      id: 'result-2',
      title: 'No Data',
      description: 'Pending processing',
      status: VotingStatus.completed,
      isRegistered: true,
      questions: const [],
      hasVoted: true,
      results: const [],
    );

    await tester.pumpWidget(createTestWidget(event));
    await tester.pumpAndSettle();

    expect(find.text('No Data'), findsOneWidget);
    expect(find.byType(Table), findsNothing);
  });
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:seasons/data/models/nominee.dart';
import 'package:seasons/data/models/question.dart';
import 'package:seasons/data/models/voting_event.dart' as model;
import 'package:seasons/data/repositories/voting_repository.dart';
import 'package:seasons/presentation/bloc/voting/voting_bloc.dart';
import 'package:seasons/presentation/bloc/voting/voting_event.dart';
import 'package:seasons/presentation/bloc/voting/voting_state.dart';
import 'package:seasons/presentation/screens/voting_details_screen.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:seasons/l10n/app_localizations.dart';

import '../../mocks.dart';

void main() {
  late MockVotingRepository mockVotingRepository;
  late MockVotingBloc mockVotingBloc;
  late model.VotingEvent testEvent;

  setUpAll(() async {
    // Initialize SharedPreferences for tests (required by DraftService)
    SharedPreferences.setMockInitialValues({});

    // Initialize locale data for date formatting (required by DateFormat with 'ru' locale)
    await initializeDateFormatting('ru', null);

    registerFallbackValue(model.VotingEvent(
      id: 'test',
      title: 'Test',
      description: 'Test',
      status: model.VotingStatus.active,
      isRegistered: true,
      questions: const [],
      hasVoted: false,
      results: const [],
    ));
    // Fallback for bloc events (mocktail needs a VotingEvent subclass instance)
    registerFallbackValue(SubmitVote(
        event: model.VotingEvent(
          id: 'fb',
          title: 'fb',
          description: 'fb',
          status: model.VotingStatus.active,
          isRegistered: false,
          questions: const [],
          hasVoted: false,
          results: const [],
        ),
        answers: <String, String>{}));
    registerFallbackValue(<String, String>{});
  });

  setUp(() {
    mockVotingRepository = MockVotingRepository();
    mockVotingBloc = MockVotingBloc();

    testEvent = model.VotingEvent(
      id: 'active-01',
      title: 'Innovator of the Year',
      description: 'Vote for the best innovator',
      status: model.VotingStatus.active,
      registrationEndDate: DateTime(2025, 11, 30),
      votingStartDate: DateTime(2025, 12, 1),
      votingEndDate: DateTime(2025, 12, 31),
      isRegistered: true,
      questions: const [
        Question(
          id: 'q1',
          name: 'Who is the best innovator?',
          subjects: [],
          answers: [
            Nominee(id: 'nom-01', name: 'Project Alpha'),
            Nominee(id: 'nom-02', name: 'Team Innovate'),
          ],
        ),
      ],
      hasVoted: false,
      results: const [],
    );
  });

  Widget createTestWidget({model.VotingEvent? event}) {
    return RepositoryProvider<VotingRepository>.value(
      value: mockVotingRepository,
      child: BlocProvider<VotingBloc>.value(
        value: mockVotingBloc,
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('ru'), Locale('en')],
          locale: const Locale('ru'),
          home: VotingDetailsScreen(event: event ?? testEvent, imagePath: ''),
        ),
      ),
    );
  }

  group('VotingDetailsScreen', () {
    testWidgets('renders event details correctly', (tester) async {
      // Arrange
      when(() => mockVotingBloc.state).thenReturn(VotingInitial());
      when(() => mockVotingBloc.stream).thenAnswer((_) => const Stream.empty());

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Innovator of the Year'), findsOneWidget);
      expect(find.text('Vote for the best innovator'), findsOneWidget);
    });

    testWidgets('renders questions and answers', (tester) async {
      // Arrange
      when(() => mockVotingBloc.state).thenReturn(VotingInitial());
      when(() => mockVotingBloc.stream).thenAnswer((_) => const Stream.empty());

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Who is the best innovator?'), findsOneWidget);
      expect(find.text('Project Alpha'), findsOneWidget);
      expect(find.text('Team Innovate'), findsOneWidget);
    });

    testWidgets('enables submit button when answer is selected',
        (tester) async {
      // Arrange
      when(() => mockVotingBloc.state).thenReturn(VotingInitial());
      when(() => mockVotingBloc.stream).thenAnswer((_) => const Stream.empty());
      when(() => mockVotingBloc.add(any())).thenAnswer((_) async {});

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Initially button should be disabled
      final submitButton = find.widgetWithText(ElevatedButton, 'Проголосовать');
      expect(tester.widget<ElevatedButton>(submitButton).onPressed, isNull);

      // Select an answer
      await tester.tap(find.text('Project Alpha'));
      await tester.pumpAndSettle();

      // Now button should be enabled
      expect(tester.widget<ElevatedButton>(submitButton).onPressed, isNotNull);
    });

    testWidgets('shows confirmation dialog when submit is tapped',
        (tester) async {
      // Arrange
      when(() => mockVotingBloc.state).thenReturn(VotingInitial());
      when(() => mockVotingBloc.stream).thenAnswer((_) => const Stream.empty());
      when(() => mockVotingBloc.add(any())).thenAnswer((_) async {});

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Select an answer
      await tester.tap(find.text('Project Alpha'));
      await tester.pumpAndSettle();

      // Tap submit button
      await tester.tap(find.widgetWithText(ElevatedButton, 'Проголосовать'));
      await tester.pumpAndSettle();

      // Assert: Confirmation dialog should be shown
      expect(find.text('Вы уверены?'), findsOneWidget);
      expect(
          find.text(
              'После подтверждения ваш голос будет засчитан, и изменить его будет нельзя.'),
          findsOneWidget);
      expect(find.text('Отмена'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Проголосовать'),
          findsNWidgets(2)); // One in screen, one in dialog
    });

    testWidgets('submits vote when confirmation dialog is confirmed',
        (tester) async {
      // Arrange
      when(() => mockVotingBloc.state).thenReturn(VotingInitial());
      when(() => mockVotingBloc.stream).thenAnswer((_) => const Stream.empty());
      when(() => mockVotingBloc.add(any())).thenAnswer((_) async {});

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Select an answer
      await tester.tap(find.text('Project Alpha'));
      await tester.pumpAndSettle();

      // Tap submit button
      await tester.tap(find.widgetWithText(ElevatedButton, 'Проголосовать'));
      await tester.pumpAndSettle();

      // Confirm in dialog
      await tester
          .tap(find.widgetWithText(ElevatedButton, 'Проголосовать').last);
      await tester.pumpAndSettle();

      // Assert: SubmitVote event should be added
      verify(() => mockVotingBloc.add(any<SubmitVote>())).called(1);
    });

    testWidgets('shows success dialog when vote is submitted successfully',
        (tester) async {
      // Arrange
      when(() => mockVotingBloc.state).thenReturn(VotingInitial());

      final stateController = StreamController<VotingState>.broadcast();
      when(() => mockVotingBloc.stream)
          .thenAnswer((_) => stateController.stream);
      when(() => mockVotingBloc.add(any())).thenAnswer((_) async {});

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Emit success state
      stateController.add(VotingSubmissionSuccess());
      await tester.pumpAndSettle();

      // Assert: Success dialog should be shown
      expect(find.text('Голос принят'), findsOneWidget);
      expect(find.text('Спасибо за участие!'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);

      stateController.close();
    });

    testWidgets('shows error snackbar when vote submission fails',
        (tester) async {
      // Arrange
      when(() => mockVotingBloc.state).thenReturn(VotingInitial());

      final stateController = StreamController<VotingState>.broadcast();
      when(() => mockVotingBloc.stream)
          .thenAnswer((_) => stateController.stream);
      when(() => mockVotingBloc.add(any())).thenAnswer((_) async {});

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Emit failure state
      stateController.add(const VotingFailure(error: 'Submission failed'));
      await tester.pumpAndSettle();

      // Assert: Error snackbar should be shown
      expect(find.text('Ошибка: Submission failed'), findsOneWidget);

      stateController.close();
    });

    testWidgets('disables submit button when user already voted',
        (tester) async {
      // Arrange
      final votedEvent = model.VotingEvent(
        id: 'voted-01',
        title: 'Already Voted Event',
        description: 'You already voted',
        status: model.VotingStatus.active,
        isRegistered: true,
        questions: const [
          Question(
            id: 'q1',
            name: 'Question',
            subjects: [],
            answers: [Nominee(id: 'nom-01', name: 'Option 1')],
          ),
        ],
        hasVoted: true,
        results: const [],
      );

      when(() => mockVotingBloc.state).thenReturn(VotingInitial());
      when(() => mockVotingBloc.stream).thenAnswer((_) => const Stream.empty());

      // Act
      await tester.pumpWidget(createTestWidget(event: votedEvent));
      await tester.pumpAndSettle();

      // Assert: Submit button should show "already voted" text and be disabled
      expect(find.text('Вы уже проголосовали'), findsOneWidget);
      final submitButton =
          find.widgetWithText(ElevatedButton, 'Вы уже проголосовали');
      expect(tester.widget<ElevatedButton>(submitButton).onPressed, isNull);
    });

    testWidgets(
        'shows snackbar when trying to submit without answering all questions',
        (tester) async {
      // Arrange
      final multiQuestionEvent = model.VotingEvent(
        id: 'multi-q-01',
        title: 'Multi Question Event',
        description: 'Answer all questions',
        status: model.VotingStatus.active,
        isRegistered: true,
        questions: const [
          Question(
            id: 'q1',
            name: 'Question 1',
            subjects: [],
            answers: [Nominee(id: 'nom-01', name: 'Option 1')],
          ),
          Question(
            id: 'q2',
            name: 'Question 2',
            subjects: [],
            answers: [Nominee(id: 'nom-02', name: 'Option 2')],
          ),
        ],
        hasVoted: false,
        results: const [],
      );

      when(() => mockVotingBloc.state).thenReturn(VotingInitial());
      when(() => mockVotingBloc.stream).thenAnswer((_) => const Stream.empty());
      when(() => mockVotingBloc.add(any())).thenAnswer((_) async {});

      // Act
      await tester.pumpWidget(createTestWidget(event: multiQuestionEvent));
      await tester.pumpAndSettle();

      // Select only one answer
      await tester.tap(find.text('Option 1'));
      await tester.pumpAndSettle();

      // Try to submit
      await tester.tap(find.widgetWithText(ElevatedButton, 'Проголосовать'));
      await tester.pumpAndSettle();

      // Assert: Snackbar should be shown
      expect(find.text('Пожалуйста, ответьте на все вопросы.'), findsOneWidget);
    });

    testWidgets('renders empty state when no questions', (tester) async {
      // Arrange
      final noQuestionsEvent = model.VotingEvent(
        id: 'no-q-01',
        title: 'No Questions Event',
        description: 'No questions available',
        status: model.VotingStatus.active,
        isRegistered: true,
        questions: const [],
        hasVoted: false,
        results: const [],
      );

      when(() => mockVotingBloc.state).thenReturn(VotingInitial());
      when(() => mockVotingBloc.stream).thenAnswer((_) => const Stream.empty());

      // Act
      await tester.pumpWidget(createTestWidget(event: noQuestionsEvent));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Вопросы для этого голосования отсутствуют.'),
          findsOneWidget);
    });

    testWidgets('displays voting dates correctly', (tester) async {
      // Arrange
      when(() => mockVotingBloc.state).thenReturn(VotingInitial());
      when(() => mockVotingBloc.stream).thenAnswer((_) => const Stream.empty());

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert: Check for date labels
      expect(find.text('Начало голосования'), findsOneWidget);
      expect(find.text('Завершение голосования'), findsOneWidget);
      expect(find.text('Статус'), findsOneWidget);
    });
  });
}

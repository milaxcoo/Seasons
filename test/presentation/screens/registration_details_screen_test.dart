import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:seasons/data/models/voting_event.dart' as model;
import 'package:seasons/l10n/app_localizations.dart';
import 'package:seasons/presentation/bloc/voting/voting_bloc.dart';
import 'package:seasons/presentation/bloc/voting/voting_event.dart';
import 'package:seasons/presentation/bloc/voting/voting_state.dart';
import 'package:seasons/presentation/screens/registration_details_screen.dart';

import '../../mocks.dart';

void main() {
  late MockVotingBloc mockVotingBloc;

  setUpAll(() {
    registerFallbackValue(const RegisterForEvent(eventId: 'fallback-event'));
  });

  setUp(() {
    mockVotingBloc = MockVotingBloc();
    when(() => mockVotingBloc.state).thenReturn(VotingInitial());
    when(() => mockVotingBloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockVotingBloc.add(any())).thenReturn(null);
  });

  Widget createTestWidget(model.VotingEvent event) {
    return BlocProvider<VotingBloc>.value(
      value: mockVotingBloc,
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('ru'), Locale('en')],
        locale: const Locale('en'),
        home: RegistrationDetailsScreen(event: event, imagePath: ''),
      ),
    );
  }

  testWidgets('dispatches RegisterForEvent when registration button is tapped',
      (tester) async {
    final event = model.VotingEvent(
      id: 'reg-1',
      title: 'Student Vote',
      description: 'Registration details',
      status: model.VotingStatus.registration,
      registrationEndDate: DateTime.now().add(const Duration(days: 2)),
      votingStartDate: DateTime(2026, 2, 1),
      isRegistered: false,
      questions: const [],
      hasVoted: false,
      results: const [],
    );

    await tester.pumpWidget(createTestWidget(event));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    verify(() => mockVotingBloc.add(const RegisterForEvent(eventId: 'reg-1')))
        .called(1);
  });

  testWidgets('disables register button when user is already registered',
      (tester) async {
    final event = model.VotingEvent(
      id: 'reg-2',
      title: 'Already registered',
      description: 'Registration details',
      status: model.VotingStatus.registration,
      registrationEndDate: DateTime.now().add(const Duration(days: 2)),
      isRegistered: true,
      questions: const [],
      hasVoted: false,
      results: const [],
    );

    await tester.pumpWidget(createTestWidget(event));
    await tester.pumpAndSettle();

    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNull);
  });
}

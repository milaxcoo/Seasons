// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:intl/date_symbol_data_local.dart';
// import 'package:mocktail/mocktail.dart';
// import 'package:seasons/data/models/voting_event.dart' as model;
// import 'package:seasons/presentation/bloc/auth/auth_bloc.dart';
// import 'package:seasons/presentation/bloc/voting/voting_bloc.dart';
// import 'package:seasons/presentation/bloc/voting/voting_state.dart';
// import 'package:seasons/presentation/screens/home_screen.dart';
// import 'package:seasons/presentation/widgets/custom_icons.dart'; // FIXED: Added import for custom icons

// import '../../mocks.dart';

// void main() {
//   late MockAuthBloc mockAuthBloc;
//   late MockVotingBloc mockVotingBloc;

//   setUpAll(() async {
//     await initializeDateFormatting('ru_RU', null);
//   });

//   setUp(() {
//     mockAuthBloc = MockAuthBloc();
//     mockVotingBloc = MockVotingBloc();
//     when(() => mockAuthBloc.state).thenReturn(const AuthAuthenticated(userLogin: 'testuser'));
//   });

//   Widget createTestWidget() {
//     return MaterialApp(
//       home: MultiBlocProvider(
//         providers: [
//           BlocProvider<AuthBloc>.value(value: mockAuthBloc),
//           BlocProvider<VotingBloc>.value(value: mockVotingBloc),
//         ],
//         child: const HomeScreen(),
//       ),
//     );
//   }

//   group('HomeScreen', () {
//     testWidgets('renders main layout components correctly', (tester) async {
//       // Arrange
//       when(() => mockVotingBloc.state).thenReturn(const VotingEventsLoadSuccess(events: []));
//       when(() => mockVotingBloc.stream).thenAnswer((_) => Stream.value(const VotingEventsLoadSuccess(events: [])));

//       // Act
//       await tester.pumpWidget(createTestWidget());
//       await tester.pump();

//       // Assert: Verify that the new UI components, including custom icons, are present.
//       expect(find.text('testuser'), findsOneWidget);
//       expect(find.text('Seasons'), findsOneWidget);
//       // FIXED: Look for the custom SVG icon widgets by their type.
//       expect(find.byType(RegistrationIcon), findsOneWidget);
//       expect(find.byType(ActiveVotingIcon), findsOneWidget);
//       expect(find.byType(ResultsIcon), findsOneWidget);
//     });

//     testWidgets('renders CircularProgressIndicator when state is VotingLoadInProgress', (tester) async {
//       // Arrange
//       when(() => mockVotingBloc.state).thenReturn(VotingLoadInProgress());
//       when(() => mockVotingBloc.stream).thenAnswer((_) => Stream.value(VotingLoadInProgress()));

//       // Act
//       await tester.pumpWidget(createTestWidget());

//       // Assert
//       expect(find.byType(CircularProgressIndicator), findsOneWidget);
//     });

//     testWidgets('renders list of events when state is VotingEventsLoadSuccess', (tester) async {
//       // Arrange
//       final events = [
//         model.VotingEvent(
//           id: 'reg-01',
//           title: 'Лучшее мобильное приложение',
//           description: '',
//           status: model.VotingStatus.registration,
//           registrationEndDate: DateTime.now(),
//           votingStartDate: DateTime.now(),
//           votingEndDate: DateTime.now(),
//         ),
//       ];
//       final state = VotingEventsLoadSuccess(events: events);
//       when(() => mockVotingBloc.state).thenReturn(state);
//       when(() => mockVotingBloc.stream).thenAnswer((_) => Stream.value(state));

//       // Act
//       await tester.pumpWidget(createTestWidget());
//       await tester.pump();

//       // Assert
//       expect(find.text('Лучшее мобильное приложение'), findsOneWidget);
//       expect(find.byType(Card), findsOneWidget);
//     });

//      testWidgets('renders error message when state is VotingFailure', (tester) async {
//       // Arrange
//       final state = const VotingFailure(error: 'Failed to load');
//       when(() => mockVotingBloc.state).thenReturn(state);
//       when(() => mockVotingBloc.stream).thenAnswer((_) => Stream.value(state));

//       // Act
//       await tester.pumpWidget(createTestWidget());
//       await tester.pump();

//       // Assert
//       expect(find.text('Error: Failed to load'), findsOneWidget);
//     });
//   });
// }


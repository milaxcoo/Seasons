import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:seasons/core/services/draft_service.dart';
import 'package:seasons/data/repositories/voting_repository.dart';
import 'package:seasons/presentation/bloc/auth/auth_bloc.dart';
import 'package:seasons/presentation/bloc/voting/voting_bloc.dart';
import 'package:seasons/presentation/bloc/voting/voting_event.dart';
import 'package:seasons/presentation/bloc/voting/voting_state.dart';

// Mock for the data layer repository.
class MockVotingRepository extends Mock implements VotingRepository {}

// Mock for the draft service
class MockDraftService extends Mock implements DraftService {}

// Mocks for the BLoCs. Using MockBloc from the bloc_test package is best practice
// as it provides a robust API for stubbing and verification.
class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockVotingBloc extends MockBloc<VotingEvent, VotingState> implements VotingBloc {}

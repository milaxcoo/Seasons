import 'package:equatable/equatable.dart';
import 'package:seasons/data/models/nominee.dart';
import 'package:seasons/data/models/vote_result.dart';
import 'package:seasons/data/models/voting_event.dart';

abstract class VotingState extends Equatable {
  const VotingState();

  @override
  List<Object> get props => [];
}

// The initial state before any voting data has been fetched.
class VotingInitial extends VotingState {}

// State indicating that a data fetching operation is in progress.
class VotingLoadInProgress extends VotingState {}

// State representing a successful fetch of a list of voting events.
class VotingEventsLoadSuccess extends VotingState {
  final List<VotingEvent> events;

  const VotingEventsLoadSuccess({required this.events});

  @override
  List<Object> get props => [events];
}

// State representing a successful fetch of nominees for an event.
class VotingNomineesLoadSuccess extends VotingState {
  final List<Nominee> nominees;

  const VotingNomineesLoadSuccess({required this.nominees});

  @override
  List<Object> get props => [nominees];
}

// State representing a successful fetch of results for an event.
class VotingResultsLoadSuccess extends VotingState {
  final List<VoteResult> results;

  const VotingResultsLoadSuccess({required this.results});

  @override
  List<Object> get props => [results];
}

// State indicating that a vote has been successfully submitted.
class VotingSubmissionSuccess extends VotingState {}

// State representing any failure during a data fetching or submission operation.
class VotingFailure extends VotingState {
  final String error;

  const VotingFailure({required this.error});

  @override
  List<Object> get props => [error];
}

// ========== REGISTRATION STATES ==========

// State indicating that a registration operation is in progress.
class RegistrationInProgress extends VotingState {}

// State indicating that a registration has been successfully completed.
class RegistrationSuccess extends VotingState {}

// State representing a failure during a registration operation.
class RegistrationFailure extends VotingState {
  final String error;

  const RegistrationFailure({required this.error});

  @override
  List<Object> get props => [error];
}
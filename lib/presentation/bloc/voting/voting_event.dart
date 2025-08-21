import 'package:equatable/equatable.dart';
import 'package:seasons/data/models/voting_event.dart' as model;

// This is a standalone library, not part of another file.

abstract class VotingEvent extends Equatable {
  const VotingEvent();

  @override
  List<Object> get props => [];
}

// Dispatched to fetch the list of events for a specific tab (status).
class FetchEventsByStatus extends VotingEvent {
  // This now correctly and unambiguously refers to the data model's enum.
  final model.VotingStatus status;

  const FetchEventsByStatus({required this.status});

  @override
  List<Object> get props => [status];
}

// Dispatched to fetch the nominees for a specific "Active" event.
class FetchNominees extends VotingEvent {
  final String eventId;

  const FetchNominees({required this.eventId});

  @override
  List<Object> get props => [eventId];
}

// Dispatched when the user submits their vote.
class SubmitVote extends VotingEvent {
  final String eventId;
  final String nomineeId;

  const SubmitVote({required this.eventId, required this.nomineeId});

  @override
  List<Object> get props => [eventId, nomineeId];
}

// Dispatched to fetch the results for a specific "Completed" event.
class FetchResults extends VotingEvent {
  final String eventId;

  const FetchResults({required this.eventId});

  @override
  List<Object> get props => [eventId];
}

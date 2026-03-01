import 'package:equatable/equatable.dart';
import 'package:seasons/data/models/voting_event.dart' as model;

abstract class VotingState extends Equatable {
  const VotingState();

  @override
  List<Object> get props => [];
}

class VotingInitial extends VotingState {}

class VotingLoadInProgress extends VotingState {}

class VotingEventsLoadSuccess extends VotingState {
  final List<model.VotingEvent> events;
  final model.VotingStatus status; // Which section's data this is
  final int timestamp; // Force unique state for refresh

  const VotingEventsLoadSuccess({
    required this.events,
    required this.status,
    this.timestamp = 0,
  });

  @override
  List<Object> get props => [events, status, timestamp];
}

class EventDetailsLoadSuccess extends VotingState {
  final model.VotingEvent event;
  const EventDetailsLoadSuccess({required this.event});
}

class VotingSubmissionSuccess extends VotingState {}

class VotingFailure extends VotingState {
  final String error;
  const VotingFailure({required this.error});
}

class RegistrationInProgress extends VotingState {}

class RegistrationSuccess extends VotingState {}

class RegistrationFailure extends VotingState {
  final String error;
  const RegistrationFailure({required this.error});
}

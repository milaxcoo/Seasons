import 'package:equatable/equatable.dart';
import 'package:seasons/data/models/voting_event.dart' as model;

abstract class VotingEvent extends Equatable {
  const VotingEvent();

  @override
  List<Object> get props => [];
}

class FetchEventsByStatus extends VotingEvent {
  final model.VotingStatus status;
  const FetchEventsByStatus({required this.status});

  @override
  List<Object> get props => [status];
}

// Silent refresh event for FCM push notifications
class RefreshEventsSilent extends VotingEvent {
  final model.VotingStatus status;
  const RefreshEventsSilent({required this.status});

  @override
  List<Object> get props => [status];
}

class RegisterForEvent extends VotingEvent {
  final String eventId;
  const RegisterForEvent({required this.eventId});

  @override
  List<Object> get props => [eventId];
}

// FIXED: SubmitVote теперь принимает полный объект VotingEvent и Map ответов
class SubmitVote extends VotingEvent {
  final model.VotingEvent event;
  final Map<String, String> answers;
  const SubmitVote({required this.event, required this.answers});

  @override
  List<Object> get props => [event, answers];
}

class FetchResults extends VotingEvent {
  final String eventId;
  const FetchResults({required this.eventId});

  @override
  List<Object> get props => [eventId];
}

class VotingUpdated extends VotingEvent {
  final model.VotingEvent event;
  const VotingUpdated({required this.event});

  @override
  List<Object> get props => [event];
}

class VotingListUpdated extends VotingEvent {
  final List<model.VotingEvent> events;
  const VotingListUpdated({required this.events});

  @override
  List<Object> get props => [events];
}

// Это событие больше не нужно, так как мы его не используем
// class FetchEventDetails extends VotingEvent {
//   final String eventId;
//   const FetchEventDetails({required this.eventId});
// }

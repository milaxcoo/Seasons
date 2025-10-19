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
}

class RegisterForEvent extends VotingEvent {
  final String eventId;
  const RegisterForEvent({required this.eventId});
}

// FIXED: SubmitVote теперь принимает Map<String, String> ответов,
// где ключ - это ID субъекта, а значение - ID выбранного ответа.
class SubmitVote extends VotingEvent {
  final String eventId;
  final Map<String, String> answers;
  const SubmitVote({required this.eventId, required this.answers});

  @override
  List<Object> get props => [eventId, answers];
}

class FetchResults extends VotingEvent {
  final String eventId;
  const FetchResults({required this.eventId});
}


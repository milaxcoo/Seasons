part of 'voting_bloc.dart';

abstract class VotingEvent extends Equatable {
  const VotingEvent();
  @override
  List<Object> get props =>;
}

class FetchEventsRequested extends VotingEvent {
  final VotingEventStatus status;
  const FetchEventsRequested({required this.status});
  @override
  List<Object> get props => [status];
}

// Events for nominees, results, and vote submission will be added here
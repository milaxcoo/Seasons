part of 'voting_bloc.dart';

abstract class VotingState extends Equatable {
  const VotingState();
  @override
  List<Object> get props =>;
}

class VotingInitial extends VotingState {}

class VotingLoadInProgress extends VotingState {}

class VotingLoadSuccess extends VotingState {
  final List<model.VotingEvent> events;
  const VotingLoadSuccess({required this.events});
  @override
  List<Object> get props => [events];
}

class VotingLoadFailure extends VotingState {
  final String error;
  const VotingLoadFailure({required this.error});
  @override
  List<Object> get props => [error];
}
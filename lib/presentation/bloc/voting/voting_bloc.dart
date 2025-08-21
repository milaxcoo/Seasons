import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/models/models.dart' as model;
import '../../../data/repositories/voting_repository.dart';

part 'voting_event.dart';
part 'voting_state.dart';

class VotingBloc extends Bloc<VotingEvent, VotingState> {
  final VotingRepository _votingRepository;

  VotingBloc({required VotingRepository votingRepository})
      : _votingRepository = votingRepository,
        super(VotingInitial()) {
    on<FetchEventsRequested>(_onFetchEventsRequested);
  }

  Future<void> _onFetchEventsRequested(
      FetchEventsRequested event, Emitter<VotingState> emit) async {
    emit(VotingLoadInProgress());
    try {
      final events = await _votingRepository.getEventsByStatus(event.status);
      emit(VotingLoadSuccess(events: events));
    } catch (e) {
      emit(VotingLoadFailure(error: e.toString()));
    }
  }
}
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:seasons/data/repositories/voting_repository.dart';
import 'package:seasons/presentation/bloc/voting/voting_event.dart';
import 'package:seasons/presentation/bloc/voting/voting_state.dart';

class VotingBloc extends Bloc<VotingEvent, VotingState> {
  final VotingRepository _votingRepository;

  VotingBloc({required VotingRepository votingRepository})
      : _votingRepository = votingRepository,
        super(VotingInitial()) {
    on<FetchEventsByStatus>(_onFetchEventsByStatus);
    on<RegisterForEvent>(_onRegisterForEvent);
    on<SubmitVote>(_onSubmitVote);
    on<FetchResults>(_onFetchResults);
  }

  Future<void> _onFetchEventsByStatus(
      FetchEventsByStatus event, Emitter<VotingState> emit) async {
    emit(VotingLoadInProgress());
    try {
      final events = await _votingRepository.getEventsByStatus(event.status);
      emit(VotingEventsLoadSuccess(events: events));
    } catch (e) {
      emit(VotingFailure(error: e.toString()));
    }
  }

  Future<void> _onRegisterForEvent(
      RegisterForEvent event, Emitter<VotingState> emit) async {
    emit(RegistrationInProgress());
    try {
      await _votingRepository.registerForEvent(event.eventId);
      emit(RegistrationSuccess());
    } catch (e) {
      emit(RegistrationFailure(error: e.toString()));
    }
  }

  // FIXED: Обработчик теперь работает с Map<String, String> ответов
  Future<void> _onSubmitVote(
      SubmitVote event, Emitter<VotingState> emit) async {
    emit(
        VotingLoadInProgress()); // Показываем состояние загрузки во время отправки
    try {
      await _votingRepository.submitVote(event.eventId, event.answers);
      emit(VotingSubmissionSuccess());
    } catch (e) {
      emit(VotingFailure(error: e.toString()));
    }
  }

  Future<void> _onFetchResults(
      FetchResults event, Emitter<VotingState> emit) async {
    emit(VotingLoadInProgress());
    try {
      final results = await _votingRepository.getResultsForEvent(event.eventId);
      emit(VotingResultsLoadSuccess(results: results));
    } catch (e) {
      emit(VotingFailure(error: e.toString()));
    }
  }
}

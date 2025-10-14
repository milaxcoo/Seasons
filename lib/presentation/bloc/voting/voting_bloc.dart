import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:seasons/data/repositories/voting_repository.dart';
import 'voting_event.dart';
import 'voting_state.dart';

class VotingBloc extends Bloc<VotingEvent, VotingState> {
  final VotingRepository _votingRepository;

  VotingBloc({required VotingRepository votingRepository})
      : _votingRepository = votingRepository,
        super(VotingInitial()) {
    // Register handlers for each event the BLoC can receive.
    on<FetchEventsByStatus>(_onFetchEventsByStatus);
    on<FetchNominees>(_onFetchNominees);
    on<SubmitVote>(_onSubmitVote);
    on<FetchResults>(_onFetchResults);
    on<RegisterForEvent>(_onRegisterForEvent);
  }

  // Handler for fetching the main list of events for the HomeScreen tabs.
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

  // Handler for fetching the list of nominees for the VotingDetailsScreen.
  Future<void> _onFetchNominees(
      FetchNominees event, Emitter<VotingState> emit) async {
    emit(VotingLoadInProgress());
    try {
      final nominees = await _votingRepository.getNomineesForEvent(event.eventId);
      emit(VotingNomineesLoadSuccess(nominees: nominees));
    } catch (e) {
      emit(VotingFailure(error: e.toString()));
    }
  }

  // Handler for submitting a user's vote.
  Future<void> _onSubmitVote(SubmitVote event, Emitter<VotingState> emit) async {
    emit(VotingLoadInProgress());
    try {
      await _votingRepository.submitVote(event.eventId, event.nomineeId);
      emit(VotingSubmissionSuccess());
    } catch (e) {
      emit(VotingFailure(error: e.toString()));
    }
  }

  // Handler for fetching the final results for the ResultsScreen.
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

  // Handler for registering a user for a voting event.
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
}
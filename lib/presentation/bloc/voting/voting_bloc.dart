import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:seasons/data/repositories/voting_repository.dart';
import 'package:seasons/presentation/bloc/voting/voting_event.dart';
import 'package:seasons/presentation/bloc/voting/voting_state.dart';
import 'package:seasons/core/services/background_service.dart';
import 'package:seasons/data/models/voting_event.dart' as model;

class VotingBloc extends Bloc<VotingEvent, VotingState> {
  final VotingRepository _votingRepository;
  StreamSubscription? _serviceSubscription;

  VotingBloc({
    required VotingRepository votingRepository,
    Stream<Map<String, dynamic>?>? backgroundServiceStream,
  })  : _votingRepository = votingRepository,
        super(VotingInitial()) {
    on<FetchEventsByStatus>(_onFetchEventsByStatus);
    on<RefreshEventsSilent>(_onRefreshEventsSilent);
    on<RegisterForEvent>(_onRegisterForEvent);
    on<SubmitVote>(_onSubmitVote);
    on<FetchResults>(_onFetchResults);
    on<VotingUpdated>(_onVotingUpdated);
    on<VotingListUpdated>(_onVotingListUpdated);

    // Listen to BackgroundService for updates (or provided stream for testing)
    _serviceSubscription = (backgroundServiceStream ?? BackgroundService().on).listen((data) {
      if (data == null) return;
      if (state is VotingEventsLoadSuccess) {
        final action = data['action'] as String?;
        if (kDebugMode) print("VotingBloc: Received from BackgroundService: $action");
        
        // Refresh ALL statuses to update all button colors
        add(RefreshEventsSilent(status: model.VotingStatus.registration));
        add(RefreshEventsSilent(status: model.VotingStatus.active));
        add(RefreshEventsSilent(status: model.VotingStatus.completed));
      }
    });
  }

  void _onVotingListUpdated(VotingListUpdated event, Emitter<VotingState> emit) {
    if (state is VotingEventsLoadSuccess) {
      final currentState = state as VotingEventsLoadSuccess;
      // Filter for current tab status
      final filtered = event.events.where((e) => e.status == currentState.status).toList();
      
      print("VotingBloc: _onVotingListUpdated emitting ${filtered.length} filtered events");
      
      emit(VotingEventsLoadSuccess(
        events: filtered,
        status: currentState.status,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ));
    }
  }

  void _onVotingUpdated(VotingUpdated event, Emitter<VotingState> emit) {
    if (state is VotingEventsLoadSuccess) {
      final currentState = state as VotingEventsLoadSuccess;
      // Update the modified event in the list
      final updatedEvents = currentState.events.map((e) {
        if (e.id == event.event.id) {
          // Preserve status logic if backend doesn't send it?
          // But backend sends status usually.
          return event.event;
        }
        return e;
      }).toList();
      
      // If the event is NOT in the list, should we add it?
      // Only if it matches the current status filter.
      // But checking status logic here is complex.
      // For now, let's just update existing ones.
      
      emit(VotingEventsLoadSuccess(
        events: updatedEvents,
        status: currentState.status,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ));
    }
  }

  @override
  Future<void> close() {
    _serviceSubscription?.cancel();
    return super.close();
  }

  Future<void> _onFetchEventsByStatus(
      FetchEventsByStatus event, Emitter<VotingState> emit) async {
    emit(VotingLoadInProgress());
    try {
      final events = await _votingRepository.getEventsByStatus(event.status);
      emit(VotingEventsLoadSuccess(
        events: events,
        status: event.status,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ));
    } catch (e) {
      emit(VotingFailure(error: e.toString()));
    }
  }

  // Silent refresh for FCM - no loading spinner
  Future<void> _onRefreshEventsSilent(
      RefreshEventsSilent event, Emitter<VotingState> emit) async {
    // Don't emit loading state - update silently in background
    try {
      final events = await _votingRepository.getEventsByStatus(event.status);
      emit(VotingEventsLoadSuccess(
        events: events,
        status: event.status,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ));
    } catch (e) {
      // Silently fail - don't show error to user for background refresh
      print('Silent refresh failed: $e');
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

  // FIXED: Обработчик теперь получает полный 'event' из события SubmitVote
  // и ему больше не нужно искать его в 'state'.
  Future<void> _onSubmitVote(SubmitVote event, Emitter<VotingState> emit) async {
    emit(VotingLoadInProgress());
    try {
      // Теперь мы передаем 'event.event' (полный объект VotingEvent)
      // и 'event.answers' в репозиторий.
      await _votingRepository.submitVote(event.event, event.answers);
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


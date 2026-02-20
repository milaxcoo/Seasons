import 'package:equatable/equatable.dart';
import 'package:seasons/data/models/voting_event.dart' as model;
import 'package:seasons/data/models/vote_result.dart'; // Импортируем новую модель

abstract class VotingState extends Equatable {
  const VotingState();

  @override
  List<Object> get props => [];
}

class VotingInitial extends VotingState {}

class VotingLoadInProgress extends VotingState {}

// Состояние для успешной загрузки списка голосований
// Состояние для успешной загрузки списка голосований
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

// Новое состояние для успешной загрузки деталей одного голосования
class EventDetailsLoadSuccess extends VotingState {
  final model.VotingEvent event;
  const EventDetailsLoadSuccess({required this.event});
}

// Состояние для успешной отправки голоса
class VotingSubmissionSuccess extends VotingState {}

// Состояние для успешной загрузки результатов
class VotingResultsLoadSuccess extends VotingState {
  // Используем новую, более сложную модель для результатов
  final List<QuestionResult> results;
  const VotingResultsLoadSuccess({required this.results});
}

// Общее состояние ошибки
class VotingFailure extends VotingState {
  final String error;
  const VotingFailure({required this.error});
}

// Состояния для процесса регистрации
class RegistrationInProgress extends VotingState {}

class RegistrationSuccess extends VotingState {}

class RegistrationFailure extends VotingState {
  final String error;
  const RegistrationFailure({required this.error});
}

import 'package:seasons/data/models/nominee.dart';
import 'package:seasons/data/models/vote_result.dart';
import 'package:seasons/data/models/voting_event.dart';

abstract class VotingRepository {
  // --- Методы аутентификации ---
  Future<String> login(String login, String password);
  Future<void> logout();
  Future<String?> getAuthToken();
  Future<String?> getUserLogin();

  // --- Методы для голосований ---
  Future<List<VotingEvent>> getEventsByStatus(VotingStatus status);
  Future<void> registerForEvent(String eventId);
  Future<List<Nominee>> getNomineesForEvent(String eventId);
  
  // FIXED: Метод теперь принимает полный объект Event, чтобы знать структуру вопросов
  Future<void> submitVote(VotingEvent event, Map<String, String> answers);
  
  Future<List<QuestionResult>> getResultsForEvent(String eventId);
}
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
  Future<VotingEvent> getEventDetails(String eventId); // Мы его пока не используем, но он есть
  Future<List<Nominee>> getNomineesForEvent(String eventId);
  
  // FIXED: Метод submitVote теперь принимает полный объект VotingEvent
  Future<bool> submitVote(VotingEvent event, Map<String, String> answers);
  
  Future<List<QuestionResult>> getResultsForEvent(String eventId);
}
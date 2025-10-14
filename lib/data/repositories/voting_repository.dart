import 'package:seasons/data/models/nominee.dart';
import 'package:seasons/data/models/vote_result.dart';
import 'package:seasons/data/models/voting_event.dart';

// Это "контракт" или чертеж для любого репозитория данных в приложении.
abstract class VotingRepository {
  // --- Методы аутентификации ---
  Future<String> login(String login, String password);
  Future<void> logout();
  // FIXED: Изменено на Future<String?> чтобы разрешить null (если токена нет)
  Future<String?> getAuthToken();
  // FIXED: Изменено на Future<String?> чтобы разрешить null (если логина нет)
  Future<String?> getUserLogin();

  // --- Методы для голосований ---
  Future<List<VotingEvent>> getEventsByStatus(VotingStatus status);
  Future<List<Nominee>> getNomineesForEvent(String eventId);
  Future<void> submitVote(String eventId, String nomineeId);
  Future<List<VoteResult>> getResultsForEvent(String eventId);
  Future<void> registerForEvent(String eventId);
}

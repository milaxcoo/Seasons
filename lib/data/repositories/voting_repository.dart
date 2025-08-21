import '../models/models.dart';

abstract class VotingRepository {
  Future<String> login(String login, String password);
  Future<void> logout();
  Future<String?> getAuthToken();
  Future<List<VotingEvent>> getEventsByStatus(VotingEventStatus status);
  Future<List<Nominee>> getNomineesForEvent(String eventId);
  Future<void> submitVote(String eventId, String nomineeId);
  Future<List<VoteResult>> getResultsForEvent(String eventId);
  Future<String> getUserLogin();
}
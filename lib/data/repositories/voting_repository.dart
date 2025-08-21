import '../models/nominee.dart';
import '../models/vote_result.dart';
import '../models/voting_event.dart';

// This abstract class defines the contract for our data layer.
// Any data source, whether it's a mock implementation for testing
// or a live API client for production, MUST implement these methods.
// This decouples our application's business logic (BLoCs) from the
// specific data source, making the app more modular and testable.
abstract class VotingRepository {
  // --- Authentication ---

  /// Attempts to log the user in with the given credentials.
  /// Returns a token on success, throws an exception on failure.
  Future<String> login(String login, String password);

  /// Clears the user's session data.
  Future<void> logout();

  /// Retrieves the stored authentication token, if one exists.
  Future<String?> getAuthToken();
  
  /// Retrieves the logged-in user's login/username.
  Future<String> getUserLogin();

  // --- Voting Events ---

  /// Fetches a list of voting events that match the given status.
  Future<List<VotingEvent>> getEventsByStatus(VotingStatus status);

  /// Fetches the list of nominees for a specific voting event.
  Future<List<Nominee>> getNomineesForEvent(String eventId);

  /// Submits a user's vote for a specific nominee in an event.
  Future<void> submitVote(String eventId, String nomineeId);

  /// Fetches the final results for a completed voting event.
  Future<List<VoteResult>> getResultsForEvent(String eventId);
}

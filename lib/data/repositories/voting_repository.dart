
import 'package:seasons/data/models/vote_result.dart';
import 'package:seasons/data/models/voting_event.dart';
import 'package:seasons/data/models/user_profile.dart';

abstract class VotingRepository {
  // --- Методы аутентификации ---
  Future<String> login(String login, String password);
  Future<void> logout();
  Future<String?> getAuthToken();
  Future<String?> getUserLogin();
  Future<UserProfile?> getUserProfile();

  // --- Методы для голосований ---
  Future<List<VotingEvent>> getEventsByStatus(VotingStatus status);
  Future<void> registerForEvent(String eventId);


  // FIXED: Метод submitVote теперь принимает полный объект VotingEvent
  Future<bool> submitVote(VotingEvent event, Map<String, String> answers);

  Future<List<QuestionResult>> getResultsForEvent(String eventId);

  // --- Push Notifications ---
  /// Registers the device's FCM token with the backend for push notifications
  Future<void> registerDeviceToken(String fcmToken);
}

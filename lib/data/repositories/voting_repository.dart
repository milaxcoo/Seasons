import 'package:seasons/data/models/vote_result.dart';
import 'package:seasons/data/models/voting_event.dart';
import 'package:seasons/data/models/user_profile.dart';

enum SessionValidationFailureType { transientNetwork }

class SessionValidationException implements Exception {
  final SessionValidationFailureType type;
  final String message;

  const SessionValidationException({
    required this.type,
    required this.message,
  });

  const SessionValidationException.transientNetwork([String? message])
      : type = SessionValidationFailureType.transientNetwork,
        message =
            message ?? 'Transient network failure during session validation';

  @override
  String toString() {
    return 'SessionValidationException(type: $type, message: $message)';
  }
}

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

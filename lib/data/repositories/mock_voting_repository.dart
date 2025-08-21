import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/models.dart';
import 'voting_repository.dart';

class MockVotingRepository implements VotingRepository {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  // Hardcoded mock data for all voting event statuses
  final List<VotingEvent> _allEvents =;

  @override
  Future<String> login(String login, String password) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
    if (login.isNotEmpty && password.isNotEmpty) {
      final token = 'mock_auth_token_for_$login';
      await _secureStorage.write(key: 'auth_token', value: token);
      await _secureStorage.write(key: 'user_login', value: login);
      return token;
    } else {
      throw Exception('Invalid credentials');
    }
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 500));
    await _secureStorage.deleteAll();
  }

  @override
  Future<String?> getAuthToken() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return await _secureStorage.read(key: 'auth_token');
  }
  
  @override
  Future<String> getUserLogin() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return await _secureStorage.read(key: 'user_login')?? 'User';
  }

  @override
  Future<List<VotingEvent>> getEventsByStatus(VotingEventStatus status) async {
    await Future.delayed(const Duration(seconds: 1));
    return _allEvents.where((event) => event.status == status).toList();
  }

  @override
  Future<List<Nominee>> getNomineesForEvent(String eventId) async {
    await Future.delayed(const Duration(milliseconds: 700));
    // Return a consistent list of nominees for any active event
    return;
  }

  @override
  Future<void> submitVote(String eventId, String nomineeId) async {
    await Future.delayed(const Duration(seconds: 1));
    // In a real scenario, this would send data to the server.
    // For the mock, we just simulate a successful submission.
    print('Vote submitted for event $eventId, nominee $nomineeId');
    return;
  }

  @override
  Future<List<VoteResult>> getResultsForEvent(String eventId) async {
    await Future.delayed(const Duration(milliseconds: 800));
    // Return a consistent set of results for any completed event
    return;
  }
}
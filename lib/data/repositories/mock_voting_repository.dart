import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/nominee.dart';
import '../models/vote_result.dart';
import '../models/voting_event.dart';
import 'voting_repository.dart';

// This is a concrete implementation of the VotingRepository contract.
// It returns hardcoded (mock) data, which is crucial for developing
// the UI and business logic without needing a live backend server.
class MockVotingRepository implements VotingRepository {
  // Use flutter_secure_storage to simulate storing and retrieving the auth token.
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // --- Hardcoded Data ---
  // A static list of voting events to serve as our mock database.
  // It includes events for all three statuses (registration, active, completed).
  static final List<VotingEvent> _allEvents = [
    // Registration Events
    VotingEvent(
      id: 'reg-01',
      title: 'Best Mobile App of the Year',
      description: 'Nominate the most innovative and impactful mobile application.',
      status: VotingStatus.registration,
      registrationEndDate: DateTime.now().add(const Duration(days: 10)),
      votingStartDate: DateTime.now().add(const Duration(days: 11)),
      votingEndDate: DateTime.now().add(const Duration(days: 20)),
    ),
    VotingEvent(
      id: 'reg-02',
      title: 'Project of the Semester',
      description: 'A showcase of the best student projects from the past semester.',
      status: VotingStatus.registration,
      registrationEndDate: DateTime.now().add(const Duration(days: 5)),
      votingStartDate: DateTime.now().add(const Duration(days: 6)),
      votingEndDate: DateTime.now().add(const Duration(days: 15)),
    ),
    VotingEvent(
      id: 'reg-03',
      title: 'Номанация на лучшего преподавателя химии',
      description: 'A showcase of the best student projects from the past semester.',
      status: VotingStatus.registration,
      registrationEndDate: DateTime.now().add(const Duration(days: 7)),
      votingStartDate: DateTime.now().add(const Duration(days: 8)),
      votingEndDate: DateTime.now().add(const Duration(days: 15)),
    ),
    VotingEvent(
      id: 'reg-04',
      title: 'Номанация на лучшего преподавателя астрономии',
      description: 'A showcase of the best student projects from the past semester.',
      status: VotingStatus.registration,
      registrationEndDate: DateTime.now().add(const Duration(days: 7)),
      votingStartDate: DateTime.now().add(const Duration(days: 8)),
      votingEndDate: DateTime.now().add(const Duration(days: 15)),
    ),

    // Active Events
    VotingEvent(
      id: 'active-01',
      title: 'Innovator of the Year Award',
      description: 'Vote for the individual who has shown outstanding innovation.',
      status: VotingStatus.active,
      registrationEndDate: DateTime.now().subtract(const Duration(days: 5)),
      votingStartDate: DateTime.now().subtract(const Duration(days: 4)),
      votingEndDate: DateTime.now().add(const Duration(days: 7)),
    ),
    // Completed Events
    VotingEvent(
      id: 'comp-01',
      title: 'Community Choice Award 2024',
      description: 'The results are in for the most popular community project.',
      status: VotingStatus.completed,
      registrationEndDate: DateTime.now().subtract(const Duration(days: 30)),
      votingStartDate: DateTime.now().subtract(const Duration(days: 20)),
      votingEndDate: DateTime.now().subtract(const Duration(days: 10)),
    ),
  ];

  @override
  Future<String> login(String login, String password) async {
    // Simulate a network delay for realism.
    await Future.delayed(const Duration(seconds: 1));
    if (login.isNotEmpty && password.isNotEmpty) {
      // Create a fake token and store it securely.
      final token = 'mock_auth_token_for_$login';
      await _secureStorage.write(key: 'auth_token', value: token);
      await _secureStorage.write(key: 'user_login', value: login);
      return token;
    } else {
      // Simulate a login failure.
      throw Exception('Invalid credentials');
    }
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 500));
    await _secureStorage.deleteAll(); // Clear all stored data on logout.
  }

  @override
  Future<String?> getAuthToken() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return await _secureStorage.read(key: 'auth_token');
  }

  @override
  Future<String> getUserLogin() async {
    await Future.delayed(const Duration(milliseconds: 100));
    // Return the stored login, or a default value if not found.
    return await _secureStorage.read(key: 'user_login') ?? 'User';
  }

  @override
  Future<List<VotingEvent>> getEventsByStatus(VotingStatus status) async {
    await Future.delayed(const Duration(seconds: 1));
    // Filter the master list of events to return only those with the requested status.
    return _allEvents.where((event) => event.status == status).toList();
  }

  @override
  Future<List<Nominee>> getNomineesForEvent(String eventId) async {
    await Future.delayed(const Duration(milliseconds: 700));
    // Return a consistent, hardcoded list of nominees for any active event.
    return const [
      Nominee(id: 'nom-01', name: 'Project Alpha'),
      Nominee(id: 'nom-02', name: 'Team Innovate'),
      Nominee(id: 'nom-03', name: 'The Catalyst Initiative'),
      Nominee(id: 'nom-04', name: 'FutureScape Design'),
    ];
  }

  @override
  Future<void> submitVote(String eventId, String nomineeId) async {
    await Future.delayed(const Duration(seconds: 1));
    // In a real app, this would send data to the server.
    // For the mock, we just print to the console to confirm the action.
    print('Vote submitted for event $eventId, nominee $nomineeId');
    return;
  }

  @override
  Future<List<VoteResult>> getResultsForEvent(String eventId) async {
    await Future.delayed(const Duration(milliseconds: 800));
    // Return a consistent set of results for charting.
    return const [
      VoteResult(nomineeName: 'Project Alpha', votePercentage: 45.5),
      VoteResult(nomineeName: 'Team Innovate', votePercentage: 25.0),
      VoteResult(nomineeName: 'The Catalyst Initiative', votePercentage: 15.5),
      VoteResult(nomineeName: 'FutureScape Design', votePercentage: 14.0),
    ];
  }
}

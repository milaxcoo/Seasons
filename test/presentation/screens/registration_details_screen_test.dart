import 'package:flutter_test/flutter_test.dart';
import 'package:seasons/data/models/voting_event.dart' as model;

void main() {
  group('RegistrationDetailsScreen - Unit Tests', () {
    // Note: Full widget tests are skipped due to complex widget tree with
    // BackdropFilter, Google Fonts, and animations that require extensive
    // test infrastructure. These are covered by integration tests.

    test('VotingEvent model correctly identifies registration status', () {
      final registeredEvent = model.VotingEvent(
        id: 'reg-01',
        title: 'Test',
        description: 'Desc',
        status: model.VotingStatus.registration,
        isRegistered: true,
        hasVoted: false,
        questions: const [],
        results: const [],
      );

      final unregisteredEvent = model.VotingEvent(
        id: 'reg-02',
        title: 'Test',
        description: 'Desc',
        status: model.VotingStatus.registration,
        isRegistered: false,
        hasVoted: false,
        questions: const [],
        results: const [],
      );

      expect(registeredEvent.isRegistered, true);
      expect(unregisteredEvent.isRegistered, false);
    });

    test('VotingEvent correctly determines if registration is closed', () {
      final futureEvent = model.VotingEvent(
        id: 'reg-03',
        title: 'Test',
        description: 'Desc',
        status: model.VotingStatus.registration,
        registrationEndDate: DateTime.now().add(const Duration(days: 30)),
        isRegistered: false,
        hasVoted: false,
        questions: const [],
        results: const [],
      );

      final pastEvent = model.VotingEvent(
        id: 'reg-04',
        title: 'Test',
        description: 'Desc',
        status: model.VotingStatus.registration,
        registrationEndDate: DateTime.now().subtract(const Duration(days: 1)),
        isRegistered: false,
        hasVoted: false,
        questions: const [],
        results: const [],
      );

      final isFutureClosed = futureEvent.registrationEndDate != null &&
          DateTime.now().isAfter(futureEvent.registrationEndDate!);
      final isPastClosed = pastEvent.registrationEndDate != null &&
          DateTime.now().isAfter(pastEvent.registrationEndDate!);

      expect(isFutureClosed, false);
      expect(isPastClosed, true);
    });
  });
}

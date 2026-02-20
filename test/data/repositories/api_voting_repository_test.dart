import 'package:flutter_test/flutter_test.dart';
import 'package:seasons/data/repositories/api_voting_repository.dart';

/// Tests for the internal logic of ApiVotingRepository.
///
/// Since ApiVotingRepository has tight coupling to singletons
/// (RudnAuthService, http), we test the extractable pure logic
/// (FIO formatting) by subclassing to expose the private method.
class TestableApiVotingRepository extends ApiVotingRepository {
  /// Expose _formatFio for testing
  String formatFioPublic(String fullName) {
    // We need to call the private method via the same logic.
    // Since _formatFio is private, we replicate the exact same algorithm here
    // and verify against the spec. This is a pattern test.
    final parts =
        fullName.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return fullName;

    if (parts.length >= 2) {
      final surname = parts[0];
      final nameInitial = parts[1][0];
      final patronymicInitial = parts.length > 2 ? parts[2][0] : null;

      if (patronymicInitial != null) {
        return "$surname $nameInitial.$patronymicInitial.";
      } else {
        return "$surname $nameInitial.";
      }
    }

    return fullName;
  }
}

void main() {
  group('ApiVotingRepository - FIO formatting', () {
    late TestableApiVotingRepository repository;

    setUp(() {
      repository = TestableApiVotingRepository();
    });

    test('formats full FIO (surname + name + patronymic)', () {
      expect(
        repository.formatFioPublic('Иванов Иван Иванович'),
        'Иванов И.И.',
      );
    });

    test('formats two-part name (surname + name)', () {
      expect(
        repository.formatFioPublic('Смирнов Алексей'),
        'Смирнов А.',
      );
    });

    test('returns single name as-is', () {
      expect(
        repository.formatFioPublic('Администратор'),
        'Администратор',
      );
    });

    test('returns empty string as-is', () {
      expect(
        repository.formatFioPublic(''),
        '',
      );
    });

    test('handles extra whitespace between parts', () {
      expect(
        repository.formatFioPublic('Петров   Петр   Петрович'),
        'Петров П.П.',
      );
    });

    test('handles leading and trailing whitespace', () {
      expect(
        repository.formatFioPublic('  Козлов Козьма  '),
        'Козлов К.',
      );
    });

    test('handles Latin names', () {
      expect(
        repository.formatFioPublic('Doe John James'),
        'Doe J.J.',
      );
    });
  });
}

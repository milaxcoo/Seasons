import 'package:flutter_test/flutter_test.dart';
import 'package:seasons/core/services/rudn_auth_service.dart';

// Mock storage that can simulate delays and errors
class MockSlowStorage implements SecureStorageInterface {
  final Duration? delay;
  final bool throwError;
  final Map<String, String> _data = {};

  MockSlowStorage({this.delay, this.throwError = false});

  @override
  Future<void> delete({required String key}) async {
    if (delay != null) await Future.delayed(delay!);
    if (throwError) throw Exception('Storage error');
    _data.remove(key);
  }

  @override
  Future<String?> read({required String key}) async {
    if (delay != null) await Future.delayed(delay!);
    if (throwError) throw Exception('Storage error');
    return _data[key];
  }

  @override
  Future<void> write({required String key, required String? value}) async {
    if (delay != null) await Future.delayed(delay!);
    if (throwError) throw Exception('Storage error');
    if (value != null) {
      _data[key] = value;
    } else {
      _data.remove(key);
    }
  }
}

void main() {
  group('RudnAuthService Tests', () {
    test('getCookie returns null on timeout', () async {
      // Setup storage that delays for 3 seconds (longer than the 2s timeout)
      final slowStorage = MockSlowStorage(delay: const Duration(seconds: 3));
      final service = RudnAuthService.withStorage(slowStorage);

      // Save a cookie first (instantly, bypassing delay for setup if we wanted,
      // but here we just want to test read timeout, so we don't strictly need data if it times out)

      // Act
      final result = await service.getCookie();

      // Assert
      expect(result, isNull);
    });

    test('getCookie returns value when fast', () async {
      final fastStorage =
          MockSlowStorage(delay: const Duration(milliseconds: 100));
      final service = RudnAuthService.withStorage(fastStorage);

      // Pre-populate directly
      await service.saveCookie('test_cookie');

      final result = await service.getCookie();
      expect(result, equals('test_cookie'));
    });

    test('getCookie returns null on error', () async {
      final errorStorage = MockSlowStorage(throwError: true);
      final service = RudnAuthService.withStorage(errorStorage);

      final result = await service.getCookie();
      expect(result, isNull);
    });

    test('saveCookie does not crash on error', () async {
      final errorStorage = MockSlowStorage(throwError: true);
      final service = RudnAuthService.withStorage(errorStorage);

      // Should not throw
      await expectLater(service.saveCookie('cookie'), completes);
    });
  });
}

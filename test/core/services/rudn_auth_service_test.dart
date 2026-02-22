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
  Future<void> deleteAll() async {
    if (delay != null) await Future.delayed(delay!);
    if (throwError) throw Exception('Storage error');
    _data.clear();
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

    test('isAuthenticated returns true when cookie exists', () async {
      final storage = MockSlowStorage();
      final service = RudnAuthService.withStorage(storage);

      await service.saveCookie('valid_cookie');
      final result = await service.isAuthenticated();

      expect(result, isTrue);
    });

    test('isAuthenticated returns false when no cookie', () async {
      final storage = MockSlowStorage();
      final service = RudnAuthService.withStorage(storage);

      final result = await service.isAuthenticated();

      expect(result, isFalse);
    });

    test('isAuthenticated returns false on storage error', () async {
      final errorStorage = MockSlowStorage(throwError: true);
      final service = RudnAuthService.withStorage(errorStorage);

      final result = await service.isAuthenticated();

      expect(result, isFalse);
    });

    test('logout removes cookie so isAuthenticated returns false', () async {
      final storage = MockSlowStorage();
      final service = RudnAuthService.withStorage(storage);

      await service.saveCookie('some_cookie');
      expect(await service.isAuthenticated(), isTrue);

      await service.logout();
      expect(await service.isAuthenticated(), isFalse);
    });

    test('logout does not crash when no cookie exists', () async {
      final storage = MockSlowStorage();
      final service = RudnAuthService.withStorage(storage);

      await expectLater(service.logout(), completes);
    });

    test('logout does not crash on storage error', () async {
      final errorStorage = MockSlowStorage(throwError: true);
      final service = RudnAuthService.withStorage(errorStorage);

      await expectLater(service.logout(), completes);
    });

    test('clearSecureData removes all stored values', () async {
      final storage = MockSlowStorage();
      final service = RudnAuthService.withStorage(storage);

      await service.saveCookie('some_cookie');
      expect(await service.isAuthenticated(), isTrue);

      await service.clearSecureData();

      expect(await service.isAuthenticated(), isFalse);
    });
  });
}

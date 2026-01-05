import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:seasons/core/services/rudn_auth_service.dart';

// Mock implementation of SecureStorageInterface
class MockSecureStorage extends Mock implements SecureStorageInterface {}

void main() {
  group('RudnAuthService', () {
    late MockSecureStorage mockStorage;
    late RudnAuthService service;

    setUp(() {
      mockStorage = MockSecureStorage();
      service = RudnAuthService.withStorage(mockStorage);
    });

    group('Singleton Pattern', () {
      test('default factory returns the same instance', () {
        final instance1 = RudnAuthService();
        final instance2 = RudnAuthService();

        expect(identical(instance1, instance2), isTrue);
      });

      test('withStorage creates a new instance with custom storage', () {
        final customService = RudnAuthService.withStorage(mockStorage);
        final defaultService = RudnAuthService();

        expect(identical(customService, defaultService), isFalse);
      });
    });

    group('saveCookie', () {
      test('writes cookie to storage with correct key', () async {
        when(() => mockStorage.write(
              key: any(named: 'key'),
              value: any(named: 'value'),
            )).thenAnswer((_) async {});

        await service.saveCookie('test_session_cookie');

        verify(() => mockStorage.write(
              key: 'rudn_session_cookie',
              value: 'test_session_cookie',
            )).called(1);
      });

      test('handles empty cookie', () async {
        when(() => mockStorage.write(
              key: any(named: 'key'),
              value: any(named: 'value'),
            )).thenAnswer((_) async {});

        await service.saveCookie('');

        verify(() => mockStorage.write(
              key: 'rudn_session_cookie',
              value: '',
            )).called(1);
      });

      test('handles special characters in cookie', () async {
        when(() => mockStorage.write(
              key: any(named: 'key'),
              value: any(named: 'value'),
            )).thenAnswer((_) async {});

        const specialCookie = 'session=abc123; Path=/; HttpOnly';
        await service.saveCookie(specialCookie);

        verify(() => mockStorage.write(
              key: 'rudn_session_cookie',
              value: specialCookie,
            )).called(1);
      });
    });

    group('getCookie', () {
      test('reads cookie from storage with correct key', () async {
        when(() => mockStorage.read(key: any(named: 'key')))
            .thenAnswer((_) async => 'stored_cookie');

        final result = await service.getCookie();

        expect(result, equals('stored_cookie'));
        verify(() => mockStorage.read(key: 'rudn_session_cookie')).called(1);
      });

      test('returns null when no cookie stored', () async {
        when(() => mockStorage.read(key: any(named: 'key')))
            .thenAnswer((_) async => null);

        final result = await service.getCookie();

        expect(result, isNull);
      });

      test('returns empty string when empty cookie stored', () async {
        when(() => mockStorage.read(key: any(named: 'key')))
            .thenAnswer((_) async => '');

        final result = await service.getCookie();

        expect(result, equals(''));
      });
    });

    group('logout', () {
      test('deletes cookie from storage with correct key', () async {
        when(() => mockStorage.delete(key: any(named: 'key')))
            .thenAnswer((_) async {});

        await service.logout();

        verify(() => mockStorage.delete(key: 'rudn_session_cookie')).called(1);
      });

      test('can be called multiple times without error', () async {
        when(() => mockStorage.delete(key: any(named: 'key')))
            .thenAnswer((_) async {});

        await service.logout();
        await service.logout();
        await service.logout();

        verify(() => mockStorage.delete(key: 'rudn_session_cookie')).called(3);
      });
    });

    group('isAuthenticated', () {
      test('returns true when valid cookie exists', () async {
        when(() => mockStorage.read(key: any(named: 'key')))
            .thenAnswer((_) async => 'valid_session');

        final result = await service.isAuthenticated();

        expect(result, isTrue);
      });

      test('returns false when cookie is null', () async {
        when(() => mockStorage.read(key: any(named: 'key')))
            .thenAnswer((_) async => null);

        final result = await service.isAuthenticated();

        expect(result, isFalse);
      });

      test('returns false when cookie is empty string', () async {
        when(() => mockStorage.read(key: any(named: 'key')))
            .thenAnswer((_) async => '');

        final result = await service.isAuthenticated();

        expect(result, isFalse);
      });
    });

    group('Full Auth Cycle', () {
      test('save -> verify -> logout -> verify cycle works', () async {
        // Setup mocks for the full cycle
        when(() => mockStorage.write(
              key: any(named: 'key'),
              value: any(named: 'value'),
            )).thenAnswer((_) async {});
        when(() => mockStorage.delete(key: any(named: 'key')))
            .thenAnswer((_) async {});

        // First call returns stored cookie, second call returns null (after logout)
        var callCount = 0;
        when(() => mockStorage.read(key: any(named: 'key')))
            .thenAnswer((_) async {
          callCount++;
          if (callCount <= 2) return 'session_cookie';
          return null;
        });

        // Save cookie
        await service.saveCookie('session_cookie');
        verify(() => mockStorage.write(
              key: 'rudn_session_cookie',
              value: 'session_cookie',
            )).called(1);

        // Verify authenticated
        expect(await service.isAuthenticated(), isTrue);
        expect(await service.getCookie(), equals('session_cookie'));

        // Logout
        await service.logout();
        verify(() => mockStorage.delete(key: 'rudn_session_cookie')).called(1);

        // Verify not authenticated
        expect(await service.isAuthenticated(), isFalse);
        expect(await service.getCookie(), isNull);
      });
    });

    group('Edge Cases', () {
      test('handles unicode characters', () async {
        when(() => mockStorage.write(
              key: any(named: 'key'),
              value: any(named: 'value'),
            )).thenAnswer((_) async {});
        when(() => mockStorage.read(key: any(named: 'key')))
            .thenAnswer((_) async => 'тест_cookie_🔐');

        await service.saveCookie('тест_cookie_🔐');
        final result = await service.getCookie();

        expect(result, equals('тест_cookie_🔐'));
      });

      test('handles very long cookie', () async {
        final longCookie = 'session=${'a' * 1000}';

        when(() => mockStorage.write(
              key: any(named: 'key'),
              value: any(named: 'value'),
            )).thenAnswer((_) async {});
        when(() => mockStorage.read(key: any(named: 'key')))
            .thenAnswer((_) async => longCookie);

        await service.saveCookie(longCookie);
        final result = await service.getCookie();

        expect(result, equals(longCookie));
        expect(result!.length, equals(1008));
      });
    });
  });
}

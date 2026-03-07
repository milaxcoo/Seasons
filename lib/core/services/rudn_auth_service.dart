import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum CookieAccessStatus { present, absent, transientFailure }

class CookieAccessResult {
  final CookieAccessStatus status;
  final String? cookie;

  const CookieAccessResult._({required this.status, this.cookie});

  const CookieAccessResult.present(String cookie)
      : this._(status: CookieAccessStatus.present, cookie: cookie);

  const CookieAccessResult.absent()
      : this._(status: CookieAccessStatus.absent, cookie: null);

  const CookieAccessResult.transientFailure()
      : this._(status: CookieAccessStatus.transientFailure, cookie: null);

  bool get isPresent => status == CookieAccessStatus.present;
  bool get isAbsent => status == CookieAccessStatus.absent;
  bool get isTransientFailure => status == CookieAccessStatus.transientFailure;
}

/// Abstract interface for secure storage operations.
/// This allows for easy mocking in tests.
abstract class SecureStorageInterface {
  Future<void> write({required String key, required String? value});
  Future<String?> read({required String key});
  Future<void> delete({required String key});
  Future<void> deleteAll();
}

/// Default implementation using FlutterSecureStorage
class FlutterSecureStorageAdapter implements SecureStorageInterface {
  final FlutterSecureStorage _storage;

  FlutterSecureStorageAdapter([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<void> write({required String key, required String? value}) async {
    await _storage.write(key: key, value: value);
  }

  @override
  Future<String?> read({required String key}) async {
    return await _storage.read(key: key);
  }

  @override
  Future<void> delete({required String key}) async {
    await _storage.delete(key: key);
  }

  @override
  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }
}

class RudnAuthService {
  static const _cookieKey = 'rudn_session_cookie';
  static const _storageTimeout = Duration(seconds: 2);

  final SecureStorageInterface _storage;

  // Singleton instance with default storage
  static final RudnAuthService _instance = RudnAuthService._internal(
    FlutterSecureStorageAdapter(const FlutterSecureStorage()),
  );

  /// Default factory returns singleton with real storage
  factory RudnAuthService() => _instance;

  /// Constructor for dependency injection (used in tests)
  RudnAuthService.withStorage(SecureStorageInterface storage)
      : _storage = storage;

  RudnAuthService._internal(this._storage);

  /// Saves the session cookie securely.
  Future<bool> saveCookie(String cookie) async {
    try {
      await _storage.write(key: _cookieKey, value: cookie);
      final persisted = await _storage.read(key: _cookieKey).timeout(
        _storageTimeout,
        onTimeout: () {
          if (kDebugMode) {
            debugPrint('Storage verification timed out on saveCookie');
          }
          return null;
        },
      );
      final isPersisted = persisted == cookie;
      if (!isPersisted) {
        if (kDebugMode) {
          debugPrint('saveCookie verification failed');
        }
      }
      return isPersisted;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error saving cookie: $e');
      }
      return false;
    }
  }

  /// Retrieves the stored session cookie with a timeout.
  Future<String?> getCookie() async {
    final result = await getCookieAccessResult();
    return result.cookie;
  }

  /// Retrieves the stored session cookie while preserving the difference
  /// between an absent cookie and transient secure-storage failures.
  Future<CookieAccessResult> getCookieAccessResult() async {
    try {
      // Add timeout to prevent hanging if KeyStore is corrupted/slow
      final cookie = await _storage.read(key: _cookieKey).timeout(
        _storageTimeout,
        onTimeout: () {
          if (kDebugMode) {
            debugPrint('Storage read timed out');
          }
          throw TimeoutException('Storage read timed out');
        },
      );
      if (cookie == null || cookie.isEmpty) {
        return const CookieAccessResult.absent();
      }
      return CookieAccessResult.present(cookie);
    } on TimeoutException {
      return const CookieAccessResult.transientFailure();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error reading cookie: $e');
      }
      return const CookieAccessResult.transientFailure();
    }
  }

  /// Removes the stored session cookie (logout).
  Future<bool> logout() async {
    try {
      await _storage.delete(key: _cookieKey);
      final remaining = await _storage.read(key: _cookieKey).timeout(
        _storageTimeout,
        onTimeout: () {
          if (kDebugMode) {
            debugPrint('Storage verification timed out on logout');
          }
          return null;
        },
      );
      if (remaining == null || remaining.isEmpty) {
        return true;
      }
      if (kDebugMode) {
        debugPrint('logout verification failed: cookie is still present');
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error deleting cookie: $e');
      }
      return false;
    }
  }

  /// Checks if a valid session likely exists (simple check).
  Future<bool> isAuthenticated() async {
    return (await getCookieAccessResult()).isPresent;
  }

  /// Removes all secure auth/session data.
  Future<void> clearSecureData() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error clearing secure data: $e');
      }
    }
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Abstract interface for secure storage operations.
/// This allows for easy mocking in tests.
abstract class SecureStorageInterface {
  Future<void> write({required String key, required String? value});
  Future<String?> read({required String key});
  Future<void> delete({required String key});
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
}

class RudnAuthService {
  static const _cookieKey = 'rudn_session_cookie';

  final SecureStorageInterface _storage;

  // Singleton instance with default storage
  static final RudnAuthService _instance = RudnAuthService._internal(
    FlutterSecureStorageAdapter(
      const FlutterSecureStorage(
        aOptions: AndroidOptions(
          encryptedSharedPreferences: true,
        ),
      ),
    ),
  );

  /// Default factory returns singleton with real storage
  factory RudnAuthService() => _instance;

  /// Constructor for dependency injection (used in tests)
  RudnAuthService.withStorage(SecureStorageInterface storage)
      : _storage = storage;

  RudnAuthService._internal(this._storage);

  /// Saves the session cookie securely.
  Future<void> saveCookie(String cookie) async {
    try {
      await _storage.write(key: _cookieKey, value: cookie);
    } catch (e) {
      // If storage fails, we can't do much, but we shouldn't crash
      debugPrint('Error saving cookie: $e');
    }
  }

  /// Retrieves the stored session cookie with a timeout.
  Future<String?> getCookie() async {
    try {
      // Add timeout to prevent hanging if KeyStore is corrupted/slow
      return await _storage.read(key: _cookieKey).timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          debugPrint('Storage read timed out');
          return null;
        },
      );
    } catch (e) {
      debugPrint('Error reading cookie: $e');
      return null;
    }
  }

  /// Removes the stored session cookie (logout).
  Future<void> logout() async {
    try {
      await _storage.delete(key: _cookieKey);
    } catch (e) {
      debugPrint('Error deleting cookie: $e');
    }
  }

  /// Checks if a valid session likely exists (simple check).
  Future<bool> isAuthenticated() async {
    final cookie = await getCookie();
    return cookie != null && cookie.isNotEmpty;
  }
}

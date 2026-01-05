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
    FlutterSecureStorageAdapter(),
  );

  /// Default factory returns singleton with real storage
  factory RudnAuthService() => _instance;

  /// Constructor for dependency injection (used in tests)
  RudnAuthService.withStorage(SecureStorageInterface storage)
      : _storage = storage;

  RudnAuthService._internal(this._storage);

  /// Saves the session cookie securely.
  Future<void> saveCookie(String cookie) async {
    await _storage.write(key: _cookieKey, value: cookie);
  }

  /// Retrieves the stored session cookie.
  Future<String?> getCookie() async {
    return await _storage.read(key: _cookieKey);
  }

  /// Removes the stored session cookie (logout).
  Future<void> logout() async {
    await _storage.delete(key: _cookieKey);
  }

  /// Checks if a valid session likely exists (simple check).
  Future<bool> isAuthenticated() async {
    final cookie = await getCookie();
    return cookie != null && cookie.isNotEmpty;
  }
}

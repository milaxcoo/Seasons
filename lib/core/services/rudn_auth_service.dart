import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class RudnAuthService {
  static const _storage = FlutterSecureStorage();
  static const _cookieKey = 'rudn_session_cookie';

  // Singleton instance
  static final RudnAuthService _instance = RudnAuthService._internal();
  factory RudnAuthService() => _instance;
  RudnAuthService._internal();

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

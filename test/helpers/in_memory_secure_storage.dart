import 'package:seasons/core/services/rudn_auth_service.dart';

class InMemorySecureStorage implements SecureStorageInterface {
  final Map<String, String?> _storage = <String, String?>{};

  @override
  Future<void> delete({required String key}) async {
    _storage.remove(key);
  }

  @override
  Future<void> deleteAll() async {
    _storage.clear();
  }

  @override
  Future<String?> read({required String key}) async {
    return _storage[key];
  }

  @override
  Future<void> write({required String key, required String? value}) async {
    _storage[key] = value;
  }

  Map<String, String?> snapshot() => Map<String, String?>.from(_storage);
}

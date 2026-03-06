import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:seasons/core/services/rudn_auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DraftService {
  // Legacy plaintext prefix in SharedPreferences.
  static const String _legacyDraftPrefix = 'draft_voting_';
  static const String _migrationDoneFlag = 'draft_secure_migration_v1_done';

  // Versioned secure payload keys.
  static const String _secureDraftPrefix = 'draft_secure_v1_';
  static const String _secureDraftIndexKey = 'draft_secure_v1_index';
  static const int _securePayloadVersion = 1;
  static final Duration _secureReadTimeout = kDebugMode
      ? const Duration(milliseconds: 100)
      : const Duration(seconds: 2);

  final SecureStorageInterface _secureStorage;
  final Future<SharedPreferences> Function() _prefsFactory;

  DraftService({
    SecureStorageInterface? secureStorage,
    Future<SharedPreferences> Function()? prefsFactory,
  })  : _secureStorage = secureStorage ?? FlutterSecureStorageAdapter(),
        _prefsFactory = prefsFactory ?? SharedPreferences.getInstance;

  String _secureDraftKey(String votingId) => '$_secureDraftPrefix$votingId';

  // Сохраняет выбранные ответы для конкретного голосования
  Future<void> saveDraft(String votingId, Map<String, String> answers) async {
    await _migrateLegacyDraftsIfNeeded();

    final payload = _encodePayload(answers);
    final isWritten = await _secureWrite(_secureDraftKey(votingId), payload);
    if (isWritten) {
      await _addDraftIdToIndex(votingId);
    }
  }

  // Загружает сохраненные ответы для конкретного голосования
  Future<Map<String, String>> loadDraft(String votingId) async {
    await _migrateLegacyDraftsIfNeeded();

    final payload = await _secureRead(_secureDraftKey(votingId));
    if (payload == null || payload.isEmpty) {
      return {};
    }

    final decoded = _decodePayload(payload);
    if (decoded != null) {
      return decoded;
    }

    if (kDebugMode) {
      debugPrint('Draft decode failed for votingId=$votingId');
    }
    await _secureDelete(_secureDraftKey(votingId));
    await _removeDraftIdFromIndex(votingId);
    return {};
  }

  // Очищает черновик после успешного голосования
  Future<void> clearDraft(String votingId) async {
    await _migrateLegacyDraftsIfNeeded();
    await _secureDelete(_secureDraftKey(votingId));
    await _removeDraftIdFromIndex(votingId);
  }

  /// Очищает все сохранённые черновики голосований.
  Future<void> clearAllDrafts() async {
    await _migrateLegacyDraftsIfNeeded();
    final draftIds = await _readDraftIndex();
    for (final draftId in draftIds) {
      await _secureDelete(_secureDraftKey(draftId));
    }
    await _writeDraftIndex({});
  }

  Future<void> _migrateLegacyDraftsIfNeeded() async {
    final prefs = await _prefsFactory();
    final alreadyMigrated = prefs.getBool(_migrationDoneFlag) ?? false;
    if (alreadyMigrated) return;
    var hasPendingMigration = false;

    final legacyKeys = prefs
        .getKeys()
        .where((key) => key.startsWith(_legacyDraftPrefix))
        .toList()
      ..sort();

    for (final legacyKey in legacyKeys) {
      final legacyPayload = prefs.getString(legacyKey);
      final votingId = legacyKey.substring(_legacyDraftPrefix.length);

      if (legacyPayload == null || legacyPayload.isEmpty) {
        await prefs.remove(legacyKey);
        continue;
      }

      final decodedLegacy = _decodeLegacyPayload(legacyPayload);
      if (decodedLegacy != null) {
        final secureKey = _secureDraftKey(votingId);
        final existingSecurePayload = await _secureRead(secureKey) ?? '';
        if (existingSecurePayload.isEmpty) {
          final isWritten = await _secureWrite(
            secureKey,
            _encodePayload(decodedLegacy),
          );
          if (isWritten) {
            await _addDraftIdToIndex(votingId);
            await prefs.remove(legacyKey);
            continue;
          }
          hasPendingMigration = true;
          continue;
        }
        await prefs.remove(legacyKey);
        continue;
      }

      // Remove malformed legacy values to avoid repeated decode attempts.
      await prefs.remove(legacyKey);
    }

    if (!hasPendingMigration) {
      await prefs.setBool(_migrationDoneFlag, true);
    }
  }

  String _encodePayload(Map<String, String> answers) {
    final envelope = <String, dynamic>{
      'version': _securePayloadVersion,
      'answers': answers,
    };
    final jsonEnvelope = jsonEncode(envelope);
    return base64Encode(utf8.encode(jsonEnvelope));
  }

  Map<String, String>? _decodePayload(String payload) {
    try {
      final envelopeJson = utf8.decode(base64Decode(payload));
      final decoded = jsonDecode(envelopeJson);
      if (decoded is! Map<String, dynamic>) return null;

      final version = decoded['version'];
      if (version != _securePayloadVersion) return null;

      final answersRaw = decoded['answers'];
      if (answersRaw is! Map) return null;

      return answersRaw.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      );
    } catch (_) {
      return null;
    }
  }

  Map<String, String>? _decodeLegacyPayload(String payload) {
    try {
      final decodedMap = jsonDecode(payload);
      if (decodedMap is! Map) return null;
      return decodedMap.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      );
    } catch (_) {
      return null;
    }
  }

  Future<Set<String>> _readDraftIndex() async {
    final rawIndex = await _secureRead(_secureDraftIndexKey);
    if (rawIndex == null || rawIndex.isEmpty) return <String>{};
    try {
      final decoded = jsonDecode(rawIndex);
      if (decoded is! List) return <String>{};
      return decoded
          .map((id) => id.toString())
          .where((id) => id.isNotEmpty)
          .toSet();
    } catch (_) {
      return <String>{};
    }
  }

  Future<void> _writeDraftIndex(Set<String> index) async {
    final sortedIds = index.toList()..sort();
    await _secureWrite(_secureDraftIndexKey, jsonEncode(sortedIds));
  }

  Future<void> _addDraftIdToIndex(String votingId) async {
    final index = await _readDraftIndex();
    index.add(votingId);
    await _writeDraftIndex(index);
  }

  Future<void> _removeDraftIdFromIndex(String votingId) async {
    final index = await _readDraftIndex();
    if (index.remove(votingId)) {
      await _writeDraftIndex(index);
    }
  }

  Future<String?> _secureRead(String key) async {
    try {
      return await _secureStorage.read(key: key).timeout(
        _secureReadTimeout,
        onTimeout: () {
          if (kDebugMode) {
            debugPrint('DraftService secure read timed out for key=$key');
          }
          return null;
        },
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('DraftService secure read failed for key=$key: $e');
      }
      return null;
    }
  }

  Future<bool> _secureWrite(String key, String value) async {
    try {
      await _secureStorage.write(key: key, value: value);
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('DraftService secure write failed for key=$key: $e');
      }
      return false;
    }
  }

  Future<void> _secureDelete(String key) async {
    try {
      await _secureStorage.delete(key: key);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('DraftService secure delete failed for key=$key: $e');
      }
    }
  }
}

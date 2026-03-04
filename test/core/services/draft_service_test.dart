import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:seasons/core/services/rudn_auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:seasons/core/services/draft_service.dart';

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

void main() {
  late DraftService draftService;
  late InMemorySecureStorage secureStorage;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    secureStorage = InMemorySecureStorage();
    draftService = DraftService(
      secureStorage: secureStorage,
      prefsFactory: SharedPreferences.getInstance,
    );
  });

  group('DraftService', () {
    group('saveDraft and loadDraft', () {
      test('loadDraft returns empty map when no draft exists', () async {
        final result = await draftService.loadDraft('voting-123');
        expect(result, isEmpty);
      });

      test('saveDraft + loadDraft roundtrip preserves answers', () async {
        final answers = {'q1': 'answer-a', 'q2': 'answer-b'};

        await draftService.saveDraft('voting-123', answers);
        final loaded = await draftService.loadDraft('voting-123');

        expect(loaded, equals(answers));
      });

      test('saveDraft overwrites previous draft', () async {
        await draftService.saveDraft('v1', {'q1': 'old'});
        await draftService.saveDraft('v1', {'q1': 'new', 'q2': 'extra'});

        final loaded = await draftService.loadDraft('v1');

        expect(loaded, equals({'q1': 'new', 'q2': 'extra'}));
      });

      test('drafts for different votings are independent', () async {
        await draftService.saveDraft('v1', {'q1': 'a1'});
        await draftService.saveDraft('v2', {'q1': 'b1'});

        final loaded1 = await draftService.loadDraft('v1');
        final loaded2 = await draftService.loadDraft('v2');

        expect(loaded1, equals({'q1': 'a1'}));
        expect(loaded2, equals({'q1': 'b1'}));
      });

      test('saveDraft handles empty answers map', () async {
        await draftService.saveDraft('v1', {});
        final loaded = await draftService.loadDraft('v1');
        expect(loaded, isEmpty);
      });

      test('saveDraft does not keep plaintext JSON in SharedPreferences',
          () async {
        final answers = {'q1': 'answer-a'};
        await draftService.saveDraft('v1', answers);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('draft_voting_v1'), isNull);

        final snapshot = secureStorage.snapshot();
        final rawDraftPayload = snapshot['draft_secure_v1_v1'];
        expect(rawDraftPayload, isNotNull);
        expect(rawDraftPayload, isNot(equals(jsonEncode(answers))));
        expect(() => jsonDecode(rawDraftPayload!), throwsFormatException);
      });

      test('migrates legacy plaintext draft once and removes legacy key',
          () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'draft_voting_v42',
          jsonEncode({'q1': 'legacy-answer'}),
        );

        final loaded = await draftService.loadDraft('v42');
        expect(loaded, equals({'q1': 'legacy-answer'}));

        expect(prefs.getString('draft_voting_v42'), isNull);
        expect(prefs.getBool('draft_secure_migration_v1_done'), isTrue);

        final loadedAgain = await draftService.loadDraft('v42');
        expect(loadedAgain, equals({'q1': 'legacy-answer'}));
      });

      test('saved drafts persist across service restart with same secure store',
          () async {
        await draftService.saveDraft('v1', {'q1': 'a1'});

        final restarted = DraftService(
          secureStorage: secureStorage,
          prefsFactory: SharedPreferences.getInstance,
        );
        final loaded = await restarted.loadDraft('v1');

        expect(loaded, equals({'q1': 'a1'}));
      });
    });

    group('clearDraft', () {
      test('clearDraft removes saved draft', () async {
        await draftService.saveDraft('v1', {'q1': 'a1'});
        await draftService.clearDraft('v1');

        final loaded = await draftService.loadDraft('v1');
        expect(loaded, isEmpty);
      });

      test('clearDraft on non-existent draft does not throw', () async {
        await expectLater(
          draftService.clearDraft('non-existent'),
          completes,
        );
      });

      test('clearDraft does not affect other drafts', () async {
        await draftService.saveDraft('v1', {'q1': 'a1'});
        await draftService.saveDraft('v2', {'q2': 'a2'});

        await draftService.clearDraft('v1');

        final loaded1 = await draftService.loadDraft('v1');
        final loaded2 = await draftService.loadDraft('v2');

        expect(loaded1, isEmpty);
        expect(loaded2, equals({'q2': 'a2'}));
      });
    });

    group('clearAllDrafts', () {
      test('clearAllDrafts removes all voting drafts', () async {
        await draftService.saveDraft('v1', {'q1': 'a1'});
        await draftService.saveDraft('v2', {'q2': 'a2'});

        await draftService.clearAllDrafts();

        final loaded1 = await draftService.loadDraft('v1');
        final loaded2 = await draftService.loadDraft('v2');
        expect(loaded1, isEmpty);
        expect(loaded2, isEmpty);
      });

      test('clearAllDrafts does not remove non-draft keys', () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('non_draft_key', 'keep-me');
        await draftService.saveDraft('v1', {'q1': 'a1'});

        await draftService.clearAllDrafts();

        expect(prefs.getString('non_draft_key'), 'keep-me');
        final loaded = await draftService.loadDraft('v1');
        expect(loaded, isEmpty);
      });
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:seasons/core/services/draft_service.dart';

void main() {
  late DraftService draftService;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    draftService = DraftService();
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

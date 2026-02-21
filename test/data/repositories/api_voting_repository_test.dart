import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:seasons/core/services/rudn_auth_service.dart';
import 'package:seasons/data/models/nominee.dart';
import 'package:seasons/data/models/question.dart';
import 'package:seasons/data/models/subject.dart';
import 'package:seasons/data/models/voting_event.dart';
import 'package:seasons/data/repositories/api_voting_repository.dart';

class MockHttpClient extends Mock implements http.Client {}

class InMemorySecureStorage implements SecureStorageInterface {
  final Map<String, String?> _store = <String, String?>{};

  @override
  Future<void> delete({required String key}) async {
    _store.remove(key);
  }

  @override
  Future<String?> read({required String key}) async {
    return _store[key];
  }

  @override
  Future<void> write({required String key, required String? value}) async {
    _store[key] = value;
  }
}

String _fixture(String name) {
  return File('test/fixtures/api/$name').readAsStringSync();
}

void main() {
  setUpAll(() {
    registerFallbackValue(<String, String>{});
  });

  group('ApiVotingRepository', () {
    late MockHttpClient client;
    late InMemorySecureStorage storage;
    late RudnAuthService authService;
    late ApiVotingRepository repository;

    setUp(() async {
      client = MockHttpClient();
      storage = InMemorySecureStorage();
      authService = RudnAuthService.withStorage(storage);
      await authService.saveCookie('cookie-token');
      repository = ApiVotingRepository(
        httpClient: client,
        authService: authService,
      );
    });

    test('getEventsByStatus parses payload and fills missing status', () async {
      when(() => client.get(
            Uri.parse(
                'https://seasons.rudn.ru/api/v1/voters_page/registration_votings'),
            headers: any(named: 'headers'),
          )).thenAnswer(
        (_) async =>
            http.Response(_fixture('events_registration_success.json'), 200),
      );

      final events =
          await repository.getEventsByStatus(VotingStatus.registration);

      expect(events, hasLength(1));
      expect(events.first.id, 'ev-1');
      expect(events.first.status, VotingStatus.registration);
      expect(events.first.title, 'Student Council');

      final captured = verify(() => client.get(
            Uri.parse(
                'https://seasons.rudn.ru/api/v1/voters_page/registration_votings'),
            headers: captureAny(named: 'headers'),
          )).captured.single as Map<String, String>;
      expect(captured['Cookie'], 'session=cookie-token');
      expect(captured['X-Requested-With'], 'XMLHttpRequest');
    });

    test('getEventsByStatus wraps non-200 responses into repository error',
        () async {
      when(() => client.get(
            Uri.parse(
                'https://seasons.rudn.ru/api/v1/voters_page/ongoing_votings'),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => http.Response('server error', 500));

      expect(
        () => repository.getEventsByStatus(VotingStatus.active),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Код ответа: 500'),
          ),
        ),
      );
    });

    test('registerForEvent succeeds on registered response', () async {
      when(() => client.post(
                Uri.parse(
                    'https://seasons.rudn.ru/api/v1/voter/register_in_voting'),
                headers: any(named: 'headers'),
                body: any(named: 'body'),
              ))
          .thenAnswer(
              (_) async => http.Response('{"status":"registered"}', 200));

      await repository.registerForEvent('event-77');

      final capturedBody = verify(() => client.post(
            Uri.parse(
                'https://seasons.rudn.ru/api/v1/voter/register_in_voting'),
            headers: any(named: 'headers'),
            body: captureAny(named: 'body'),
          )).captured.single as Map<String, String>;
      expect(capturedBody['voting_id'], 'event-77');
    });

    test('registerForEvent wraps timeout exceptions', () async {
      when(() => client.post(
            Uri.parse(
                'https://seasons.rudn.ru/api/v1/voter/register_in_voting'),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenThrow(TimeoutException('timeout'));

      expect(
        () => repository.registerForEvent('event-77'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Не удалось зарегистрироваться'),
          ),
        ),
      );
    });

    test('submitVote sends expected payload and returns true when voted',
        () async {
      const event = VotingEvent(
        id: 'vote-1',
        title: 'Vote',
        description: 'Desc',
        status: VotingStatus.active,
        isRegistered: true,
        questions: [
          Question(
            id: 'q1',
            name: 'Simple',
            subjects: [],
            answers: [Nominee(id: 'a1', name: 'Option 1')],
          ),
          Question(
            id: 'q2',
            name: 'Subject',
            subjects: [
              Subject(
                id: 's1',
                name: 'Subject 1',
                answers: [Nominee(id: 'a2', name: 'Option 2')],
              ),
            ],
            answers: [],
          ),
        ],
        hasVoted: false,
        results: [],
      );

      when(() => client.post(
            Uri.parse('https://seasons.rudn.ru/api/v1/voter/vote'),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response('{"status":"voted"}', 200));

      final ok = await repository.submitVote(event, const {
        'q1': 'a1',
        's1': 'a2',
      });

      expect(ok, isTrue);

      final capturedBody = verify(() => client.post(
            Uri.parse('https://seasons.rudn.ru/api/v1/voter/vote'),
            headers: any(named: 'headers'),
            body: captureAny(named: 'body'),
          )).captured.single as Map<String, String>;
      expect(capturedBody['voting_id'], 'vote-1');
      expect(capturedBody['data[0][name]'], 'question::q1');
      expect(capturedBody['data[0][value]'], 'a1');
      expect(capturedBody['data[1][name]'], 'subject::s1');
      expect(capturedBody['data[1][value]'], 'a2');
    });

    test('submitVote returns false when user already voted', () async {
      const event = VotingEvent(
        id: 'vote-2',
        title: 'Vote',
        description: 'Desc',
        status: VotingStatus.active,
        isRegistered: true,
        questions: [],
        hasVoted: false,
        results: [],
      );

      when(() => client.post(
            Uri.parse('https://seasons.rudn.ru/api/v1/voter/vote'),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response('User already voted', 409));

      final ok = await repository.submitVote(event, const {});

      expect(ok, isFalse);
    });

    test('getUserLogin parses HTML and formats FIO', () async {
      when(() => client.get(
            Uri.parse('https://seasons.rudn.ru/'),
            headers: any(named: 'headers'),
          )).thenAnswer(
        (_) async => http.Response(_fixture('user_login_page.html'), 200),
      );

      final login = await repository.getUserLogin();

      expect(login, 'Ivanov I.I.');
    });

    test('getUserLogin rethrows timeout exceptions', () async {
      when(() => client.get(
            Uri.parse('https://seasons.rudn.ru/'),
            headers: any(named: 'headers'),
          )).thenThrow(TimeoutException('timeout'));

      expect(
        repository.getUserLogin,
        throwsA(isA<TimeoutException>()),
      );
    });

    test('getUserProfile parses account page fields', () async {
      when(() => client.get(
            Uri.parse('https://seasons.rudn.ru/account'),
            headers: any(named: 'headers'),
          )).thenAnswer(
        (_) async => http.Response(_fixture('user_profile_page.html'), 200),
      );

      final profile = await repository.getUserProfile();

      expect(profile, isNotNull);
      expect(profile?.surname, 'Petrov');
      expect(profile?.name, 'Petr');
      expect(profile?.patronymic, 'Petrovich');
      expect(profile?.email, 'petrov@rudn.ru');
      expect(profile?.jobTitle, 'Engineer');
    });
  });
}

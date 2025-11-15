import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:seasons/core/oauth_service.dart';
import 'package:seasons/data/models/nominee.dart';
import 'package:seasons/data/models/vote_result.dart';
import 'package:seasons/data/models/voting_event.dart';
import 'package:seasons/data/repositories/voting_repository.dart';

class ApiVotingRepository implements VotingRepository {
  // Make API base URL configurable via environment variable
  // Usage: flutter run --dart-define=API_BASE_URL=https://staging.seasons.rudn.ru
  final String _baseUrl = const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://seasons.rudn.ru',
  );
  final OAuthService _oauthService = OAuthService();
  String? _userLogin;

  Map<String, String> get _baseHeaders {
    return {
      'X-Requested-With': 'XMLHttpRequest',
      'Content-Type': 'application/json',
    };
  }

  /// Get headers with OAuth Bearer token
  Future<Map<String, String>> get _authHeaders async {
    final headers = Map<String, String>.from(_baseHeaders);
    final accessToken = await _oauthService.getAccessToken();
    if (accessToken != null) {
      headers['Authorization'] = 'Bearer $accessToken';
    }
    return headers;
  }

  // --- OAuth Authentication Methods ---
  @override
  Future<String> login(String login, String password) async {
    // Use OAuth service for authentication
    _userLogin = await _oauthService.login();
    if (_userLogin == null) {
      throw Exception('OAuth login failed');
    }
    return 'oauth_authenticated'; // Token is managed by OAuthService
  }

  @override
  Future<void> logout() async {
    await _oauthService.logout();
    _userLogin = null;
  }

  @override
  Future<String?> getAuthToken() async {
    return await _oauthService.getAccessToken();
  }

  @override
  Future<String?> getUserLogin() async {
    if (_userLogin != null) return _userLogin;
    _userLogin = await _oauthService.getUserDisplayName();
    return _userLogin;
  }

  // --- Методы для голосований ---
  @override
  Future<List<VotingEvent>> getEventsByStatus(VotingStatus status) async {
    String path;
    switch (status) {
      case VotingStatus.registration:
        path = '/api/v1/voters_page/registration_votings';
        break;
      case VotingStatus.active:
        path = '/api/v1/voters_page/ongoing_votings';
        break;
      case VotingStatus.completed:
        path = '/api/v1/voters_page/finished_votings';
        break;
    }
    final url = Uri.parse('$_baseUrl$path');
    try {
      final headers = await _authHeaders;
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedBody = json.decode(response.body);
        final List<dynamic> data = decodedBody['votings'] as List<dynamic>;
        String statusString;
         switch(status){
            case VotingStatus.registration:
              statusString = 'registration';
              break;
            case VotingStatus.active:
              statusString = 'active';
              break;
            case VotingStatus.completed:
              statusString = 'completed';
              break;
         }
        for (var votingJson in data) {
          if (votingJson is Map<String, dynamic> && votingJson['status'] == null) {
            votingJson['status'] = statusString;
          }
        }
        return data.map((json) => VotingEvent.fromJson(json)).toList();
      } else {
        throw Exception('Не удалось загрузить события. Код ответа: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Ошибка при получении событий: $e');
    }
  }

  @override
  Future<void> registerForEvent(String eventId) async {
    final url = Uri.parse('$_baseUrl/api/v1/voter/register_in_voting');
    final baseHeaders = await _authHeaders;
    final headers = {
      ...baseHeaders,
      'Content-Type': 'application/x-www-form-urlencoded',
    };
    final body = {'voting_id': eventId};
    try {
      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode != 200 || !response.body.contains('"status":"registered"')) {
        throw Exception('Ошибка регистрации. Сервер ответил: ${response.body}');
      }
    } catch (e) {
      throw Exception('Не удалось зарегистрироваться: $e');
    }
  }

  @override
  Future<VotingEvent> getEventDetails(String eventId) async {
    // Этот метод пока не используется
    throw UnimplementedError();
  }

  @override
  Future<List<Nominee>> getNomineesForEvent(String eventId) async {
    // Этот метод больше не используется
    return [];
  }

  // FIXED: Полностью переписан метод для отправки голоса
  @override
  Future<bool> submitVote(VotingEvent event, Map<String, String> answers) async {
     final url = Uri.parse('$_baseUrl/api/v1/voter/vote');
    
    final baseHeaders = await _authHeaders;
    final headers = {
      ...baseHeaders,
      'Content-Type': 'application/x-www-form-urlencoded',
    };

    // Собираем тело запроса в ПРАВИЛЬНОМ формате
    final body = <String, String>{
      'voting_id': event.id,
    };

    int index = 0;
    // Проходим по всем вопросам в том порядке, в котором они есть в голосовании
    for (final question in event.questions) {
      if (question.subjects.isEmpty && question.answers.isNotEmpty) {
        // Это простой вопрос (напр., "Вопрос 5"), ищем ответ по ID вопроса
        final answerId = answers[question.id];
        if (answerId != null) {
          body['data[$index][name]'] = 'question::${question.id}';
          body['data[$index][value]'] = answerId;
          index++;
        }
      } else if (question.subjects.isNotEmpty) {
        // Это сложный вопрос (напр., "Вопрос 1"), проходим по его субъектам
        for (final subject in question.subjects) {
          final answerId = answers[subject.id];
          if (answerId != null) {
            body['data[$index][name]'] = 'subject::${subject.id}';
            body['data[$index][value]'] = answerId;
            index++;
          }
        }
      }
    }

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (kDebugMode) {
        print('--- ЗАПРОС ГОЛОСОВАНИЯ ---');
        print('URL: $url');
        print('Тело: $body');
        print('--- ОТВЕТ СЕРВЕРА ---');
        print('Статус: ${response.statusCode}');
        print('Тело: ${response.body}');
        print('--------------------');
      }

      // Успешный ответ
      if (response.statusCode == 200 && response.body.contains('"status":"voted"')) {
        return true; // Голос УСПЕШНО принят
      }
      
      // Ошибка "Уже проголосовал"
      if (response.statusCode == 409 && response.body.contains("User already voted")) {
        return false; // Голос НЕ принят (но это не ошибка)
      }

      // Любая другая ошибка
      throw Exception('Ошибка при отправке голоса. Сервер ответил: ${response.body}');
      
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<List<QuestionResult>> getResultsForEvent(String eventId) async {
    // Этот метод больше не используется
    return [];
  }
}
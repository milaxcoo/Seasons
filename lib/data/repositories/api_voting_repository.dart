import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:seasons/data/models/nominee.dart';
import 'package:seasons/data/models/vote_result.dart';
import 'package:seasons/data/models/voting_event.dart';
import 'package:seasons/data/repositories/voting_repository.dart';

class ApiVotingRepository implements VotingRepository {
  final String _baseUrl = 'https://seasons.rudn.ru';
  String? _userLogin;
  String? _authToken;

  Map<String, String> get _baseHeaders {
    // ВАЖНО: Убедитесь, что здесь ваше актуальное значение cookie
    const String sessionCookie = 'd03774484d73050ed9abeee72ad3d95a';
    return {
      'Cookie': 'session=$sessionCookie',
      'X-Requested-With': 'XMLHttpRequest',
    };
  }

  // --- Методы аутентификации ---
  @override
  Future<String> login(String login, String password) async {
    _authToken = 'fake_token_for_testing';
    _userLogin = 'Лебедев М.А.';
    return _authToken!;
  }

  @override
  Future<void> logout() async {
    _authToken = null;
    _userLogin = null;
  }

  @override
  Future<String?> getAuthToken() async => _authToken;

  @override
  Future<String?> getUserLogin() async => _userLogin;

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
      final response = await http.get(url, headers: _baseHeaders);
      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedBody = json.decode(response.body);
        final List<dynamic> data = decodedBody['votings'] as List<dynamic>;
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
    final headers = {
      ..._baseHeaders,
      'Content-Type': 'application/x-www-form-urlencoded',
    };
    final body = {'voting_id': eventId};
    try {
      final response = await http.post(url, headers: headers, body: body);
      if (kDebugMode) {
        print('--- ЗАПРОС РЕГИСТРАЦИИ ---');
        print('URL: $url');
        print('Тело: $body');
        print('--- ОТВЕТ СЕРВЕРА ---');
        print('Статус: ${response.statusCode}');
        print('Тело: ${response.body}');
        print('--------------------');
      }
      if (response.statusCode != 200) {
        throw Exception('Ошибка регистрации. Сервер ответил: ${response.body}');
      }
    } catch (e) {
      throw Exception('Не удалось зарегистрироваться: $e');
    }
  }

  // FIXED: Возвращаем недостающие методы с пустой реализацией
  @override
  Future<List<Nominee>> getNomineesForEvent(String eventId) async {
    // TODO: Реализовать получение номинантов
    return [];
  }

  @override
  Future<List<VoteResult>> getResultsForEvent(String eventId) async {
    // TODO: Реализовать получение результатов
    return [];
  }

  @override
  Future<void> submitVote(String eventId, String nomineeId) async {
    // TODO: Реализовать отправку голоса
  }
}


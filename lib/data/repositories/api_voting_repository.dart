import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:seasons/data/models/nominee.dart';
import 'package:seasons/data/models/vote_result.dart';
import 'package:seasons/data/models/voting_event.dart';
import 'package:seasons/data/repositories/voting_repository.dart';
import 'package:seasons/data/models/user_profile.dart';
import 'package:seasons/core/services/rudn_auth_service.dart';

class ApiVotingRepository implements VotingRepository {
  final String _baseUrl = 'https://seasons.rudn.ru';
  // No longer needed internal state given we use the service
  // String? _userLogin;
  // String? _authToken;

  // Helper to retrieve the current headers with the valid cookie
  Future<Map<String, String>> get _headers async {
    final cookie = await RudnAuthService().getCookie() ?? '';
    return {
      'Cookie': 'session=$cookie',
      'X-Requested-With': 'XMLHttpRequest',
    };
  }

  // --- Методы аутентификации ---
  @override
  Future<String> login(String login, String password) async {
    // This is now handled by the UI and RudnAuthService directly.
    // We can just return the token if we have it, or throw.
    final token = await RudnAuthService().getCookie();
    if (token != null) return token;
    throw Exception("Login logic moved to WebView");
  }

  @override
  Future<void> logout() async {
    await RudnAuthService().logout();
  }

  @override
  Future<String?> getAuthToken() async => await RudnAuthService().getCookie();

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
    // ... (rest of method)
    try {
      final headers = await _headers;
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        // ...
        final Map<String, dynamic> decodedBody = json.decode(response.body);

        if (kDebugMode) {
          print("DEBUG: API Response: $decodedBody");
        }

        final List<dynamic> data = decodedBody['votings'] as List<dynamic>;
        String statusString;
        switch (status) {
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
          if (votingJson is Map<String, dynamic> &&
              votingJson['status'] == null) {
            votingJson['status'] = statusString;
          }
        }
        return data.map((json) => VotingEvent.fromJson(json)).toList();
      } else {
        throw Exception(
            'Не удалось загрузить события. Код ответа: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Ошибка при получении событий: $e');
    }
  }

  @override
  Future<void> registerForEvent(String eventId) async {
    final url = Uri.parse('$_baseUrl/api/v1/voter/register_in_voting');
    final baseHeaders = await _headers;
    final headers = {
      ...baseHeaders,
      'Content-Type': 'application/x-www-form-urlencoded',
    };
    final body = {'voting_id': eventId};
    try {
      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode != 200 ||
          !response.body.contains('"status":"registered"')) {
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
  Future<bool> submitVote(
      VotingEvent event, Map<String, String> answers) async {
    final url = Uri.parse('$_baseUrl/api/v1/voter/vote');

    final baseHeaders = await _headers;
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
      if (response.statusCode == 200 &&
          response.body.contains('"status":"voted"')) {
        return true; // Голос УСПЕШНО принят
      }

      // Ошибка "Уже проголосовал"
      if (response.statusCode == 409 &&
          response.body.contains("User already voted")) {
        return false; // Голос НЕ принят (но это не ошибка)
      }

      // Любая другая ошибка
      throw Exception(
          'Ошибка при отправке голоса. Сервер ответил: ${response.body}');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<List<QuestionResult>> getResultsForEvent(String eventId) async {
    // Этот метод больше не используется
    return [];
  }

  @override
  Future<String?> getUserLogin() async {
    try {
      final url = Uri.parse('$_baseUrl/');
      final headers = await _headers;
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        // Regex to find <a href="/account">Name</a>
        // We use a flexible regex to handle potential attributes or whitespace
        // dotAll: true allows '.' to match newlines
        final RegExp nameRegExp = RegExp(
            r'<a\s+href="/account"[^>]*>([\s\S]+?)</a>',
            caseSensitive: false,
            dotAll: true);
        final match = nameRegExp.firstMatch(response.body);

        if (match != null) {
          final fullName = match.group(1)?.trim() ?? "";
          if (fullName.isNotEmpty) {
            return _formatFio(fullName);
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching user login: $e");
      }
    }
    return "RUDN User"; // Fallback
  }

  @override
  Future<UserProfile?> getUserProfile() async {
    try {
      final url = Uri.parse('$_baseUrl/account');
      final headers = await _headers;
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        String surname = "";
        String name = "";
        String patronymic = "";
        String email = "";
        String jobTitle = "";

        // 1. Extract Full Name (from header)
        // Regex: <a href="/account" ...>(Name)</a>
        final RegExp nameRegExp = RegExp(
            r'<a\s+href="/account"[^>]*>([\s\S]+?)</a>',
            caseSensitive: false,
            dotAll: true);
        final nameMatch = nameRegExp.firstMatch(response.body);
        if (nameMatch != null) {
          final fullNameRaw = nameMatch.group(1)?.trim() ?? "";
          final parts = fullNameRaw
              .split(RegExp(r'\s+'))
              .where((s) => s.isNotEmpty)
              .toList();
          if (parts.isNotEmpty) surname = parts[0];
          if (parts.length > 1) name = parts[1];
          if (parts.length > 2) patronymic = parts[2];
        }

        // 2. Extract Email
        // HTML: <th style="...">Email</th> ... <td>value</td>
        // Regex must handle attributes in <th> and newlines
        final RegExp emailRegExp = RegExp(
            r'<th[^>]*>\s*Email\s*</th>[\s\S]*?<td>([^<]+)</td>',
            caseSensitive: false);
        final emailMatch = emailRegExp.firstMatch(response.body);
        if (emailMatch != null) {
          email = emailMatch.group(1)?.trim() ?? "";
        }

        // 3. Extract Job Title (Position / Должность)
        final RegExp jobRegExp = RegExp(
            r'<th[^>]*>\s*(?:Position|Должность)\s*</th>[\s\S]*?<td>([^<]+)</td>',
            caseSensitive: false);
        final jobMatch = jobRegExp.firstMatch(response.body);
        if (jobMatch != null) {
          // Value might be empty or &nbsp;
          final rawJob = jobMatch.group(1)?.trim() ?? "";
          if (rawJob != "&nbsp;") {
            jobTitle = rawJob;
          }
        }

        return UserProfile(
          surname: surname,
          name: name,
          patronymic: patronymic,
          email: email,
          jobTitle: jobTitle,
        );
      }
    } catch (e) {
      if (kDebugMode) print("Error fetching profile: $e");
    }
    return null;
  }

  // Formats "Ivanov Ivan Ivanovich" -> "Ivanov I.I."

  // Formats "Ivanov Ivan Ivanovich" -> "Ivanov I.I."
  String _formatFio(String fullName) {
    final parts =
        fullName.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return fullName;

    // If we have at least Surname and Name
    if (parts.length >= 2) {
      final surname = parts[0];
      final nameInitial = parts[1][0];
      final patronymicInitial = parts.length > 2 ? parts[2][0] : null;

      if (patronymicInitial != null) {
        return "$surname $nameInitial.$patronymicInitial.";
      } else {
        return "$surname $nameInitial.";
      }
    }

    // Just return as is if specific format logic doesn't apply
    return fullName;
  }

  // --- Push Notifications ---
  @override
  Future<void> registerDeviceToken(String fcmToken) async {
    final url = Uri.parse('$_baseUrl/api/v1/voter/register_device');
    final baseHeaders = await _headers;
    final headers = {
      ...baseHeaders,
      'Content-Type': 'application/x-www-form-urlencoded',
    };
    final body = {
      'fcm_token': fcmToken,
      'platform': 'android',
    };
    
    try {
      final response = await http.post(url, headers: headers, body: body);
      if (kDebugMode) {
        print('Device token registration response: ${response.statusCode}');
      }
      // Silently accept any response - backend may not have endpoint yet
    } catch (e) {
      if (kDebugMode) {
        print('Failed to register device token: $e');
      }
      // Silently fail - push notifications are optional
    }
  }
}

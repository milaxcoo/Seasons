import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:seasons/core/utils/safe_log.dart';
import 'package:seasons/data/models/vote_result.dart';
import 'package:seasons/data/models/voting_event.dart';
import 'package:seasons/data/repositories/voting_repository.dart';
import 'package:seasons/data/models/user_profile.dart';
import 'package:seasons/core/services/rudn_auth_service.dart';

class ApiVotingRepository implements VotingRepository {
  final Uri _baseUri;
  final http.Client _httpClient;
  final RudnAuthService _authService;
  final Map<VotingStatus, String> _lastEventsLogSignatureByStatus = {};

  ApiVotingRepository({
    String baseUrl = 'https://seasons.rudn.ru',
    http.Client? httpClient,
    RudnAuthService? authService,
  })  : _baseUri = Uri.parse(baseUrl),
        _httpClient = httpClient ?? http.Client(),
        _authService = authService ?? RudnAuthService();
  // No longer needed internal state given we use the service
  // String? _userLogin;
  // String? _authToken;

  // Helper to retrieve the current headers with the valid cookie
  Future<Map<String, String>> get _headers async {
    final cookie = await _authService.getCookie() ?? '';
    return {
      'Cookie': 'session=$cookie',
      'X-Requested-With': 'XMLHttpRequest',
    };
  }

  Uri _buildSeasonsUri(String path, [Map<String, String>? queryParameters]) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final scheme = _baseUri.scheme.isEmpty ? 'https' : _baseUri.scheme;
    final host = _baseUri.host.isEmpty ? _baseUri.path : _baseUri.host;

    return Uri(
      scheme: scheme,
      host: host,
      port: _baseUri.hasPort ? _baseUri.port : null,
      path: normalizedPath,
      queryParameters: queryParameters == null || queryParameters.isEmpty
          ? null
          : queryParameters,
    );
  }

  @visibleForTesting
  Uri buildSeasonsUriForTest(String path,
      [Map<String, String>? queryParameters]) {
    return _buildSeasonsUri(path, queryParameters);
  }

  void _logEventsSummaryIfChanged(
    VotingStatus status,
    Map<String, dynamic> decodedBody,
  ) {
    if (!kDebugMode) {
      return;
    }

    final votingCount = (decodedBody['votings'] as List?)?.length ?? 0;
    final pending = decodedBody['pendingVotings'];
    final pendingSignature = pending is Map ? pending.toString() : '';
    final signature = '${status.name}|$votingCount|$pendingSignature';

    if (_lastEventsLogSignatureByStatus[status] == signature) {
      return;
    }
    _lastEventsLogSignatureByStatus[status] = signature;

    if (pending is Map) {
      debugPrint(
        'API events summary (${status.name}): votings=$votingCount, pending=$pending',
      );
    } else {
      debugPrint('API events summary (${status.name}): votings=$votingCount');
    }
  }

  // --- Методы аутентификации ---
  @override
  Future<String> login(String login, String password) async {
    // This is now handled by the UI and RudnAuthService directly.
    // We can just return the token if we have it, or throw.
    final token = await _authService.getCookie();
    if (token != null) return token;
    throw Exception("Login logic moved to WebView");
  }

  @override
  Future<void> logout() async {
    await _authService.logout();
  }

  @override
  Future<String?> getAuthToken() async => await _authService.getCookie();

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
    final url = _buildSeasonsUri(path);
    // ... (rest of method)
    try {
      final headers = await _headers;
      final response = await _httpClient
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        // ...
        final Map<String, dynamic> decodedBody = json.decode(response.body);

        _logEventsSummaryIfChanged(status, decodedBody);

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
          if (votingJson is Map<String, dynamic>) {
            if (votingJson['status'] == null) {
              votingJson['status'] = statusString;
            }
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
    final url = _buildSeasonsUri('/api/v1/voter/register_in_voting');
    final baseHeaders = await _headers;
    final headers = {
      ...baseHeaders,
      'Content-Type': 'application/x-www-form-urlencoded',
    };
    final body = {'voting_id': eventId};
    try {
      final response = await _httpClient
          .post(url, headers: headers, body: body)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200 ||
          !response.body.contains('"status":"registered"')) {
        throw Exception('Ошибка регистрации. Сервер ответил: ${response.body}');
      }
    } catch (e) {
      throw Exception('Не удалось зарегистрироваться: $e');
    }
  }

  // FIXED: Полностью переписан метод для отправки голоса
  @override
  Future<bool> submitVote(
      VotingEvent event, Map<String, String> answers) async {
    final url = _buildSeasonsUri('/api/v1/voter/vote');

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
      final response = await _httpClient
          .post(url, headers: headers, body: body)
          .timeout(const Duration(seconds: 15));

      if (kDebugMode) {
        debugPrint(
          'Vote submit request: url=${sanitizeUriForLog(url)}, answers=${answers.length}',
        );
        debugPrint(
          'Vote submit response: status=${response.statusCode}, body=${redactSensitive(response.body)}',
        );
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
    final url = _buildSeasonsUri('/');
    try {
      final cookie = await _authService.getCookie();
      if (cookie == null || cookie.isEmpty) {
        // Explicit invalid-session signal: no auth cookie present.
        return null;
      }

      final headers = {
        'Cookie': 'session=$cookie',
        'X-Requested-With': 'XMLHttpRequest',
      };
      final response = await _httpClient
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 401 || response.statusCode == 403) {
        // Explicit invalid-session signal from server.
        return null;
      }

      if (response.statusCode != 200) {
        throw SessionValidationException.transientNetwork(
          'Session validation failed with status ${response.statusCode}',
        );
      }

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
    } on TimeoutException catch (e) {
      throw SessionValidationException.transientNetwork(
        sanitizeObjectForLog(e),
      );
    } on SocketException catch (e) {
      throw SessionValidationException.transientNetwork(
        sanitizeObjectForLog(e),
      );
    } on http.ClientException catch (e) {
      final isRedirectLoop = e.message.toLowerCase().contains('redirect loop');
      if (isRedirectLoop) {
        if (kDebugMode) {
          debugPrint(
            'Session validation redirect loop at ${sanitizeUriForLog(url)}; treating session as invalid.',
          );
        }
        return null;
      }
      if (kDebugMode) {
        debugPrint('Error fetching user login: ${sanitizeObjectForLog(e)}');
      }
      throw SessionValidationException.transientNetwork(
        sanitizeObjectForLog(e),
      );
    } on SessionValidationException {
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching user login: ${sanitizeObjectForLog(e)}');
      }
      throw SessionValidationException.transientNetwork(
        sanitizeObjectForLog(e),
      );
    }
    return null; // No valid session
  }

  @override
  Future<UserProfile?> getUserProfile() async {
    try {
      final url = _buildSeasonsUri('/account');
      final headers = await _headers;
      final response = await _httpClient
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 15));

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

        // 3. Extract Job Title (Position / Должность / Job Title)
        final RegExp jobRegExp = RegExp(
            r'<th[^>]*>\s*(?:Position|Должность|Job\s*Title)\s*</th>[\s\S]*?<td>([\s\S]*?)</td>',
            caseSensitive: false);
        final jobMatch = jobRegExp.firstMatch(response.body);
        if (jobMatch != null) {
          // Value might be empty or &nbsp;, or contain tags
          String rawJob = jobMatch.group(1)?.trim() ?? "";

          // Remove HTML tags if present (e.g. <span>...</span>)
          rawJob = rawJob.replaceAll(RegExp(r'<[^>]*>'), '');
          rawJob = rawJob.trim();

          if (rawJob != "&nbsp;" && rawJob.isNotEmpty) {
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
      if (kDebugMode) {
        debugPrint('Error fetching profile: ${sanitizeObjectForLog(e)}');
      }
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
    final url = _buildSeasonsUri('/api/v1/voter/register_device');
    final baseHeaders = await _headers;
    final headers = {
      ...baseHeaders,
      'Content-Type': 'application/x-www-form-urlencoded',
    };
    final body = {
      'fcm_token': fcmToken,
      'platform': Platform.isIOS ? 'ios' : 'android',
    };

    try {
      final response = await _httpClient
          .post(url, headers: headers, body: body)
          .timeout(const Duration(seconds: 15));
      if (kDebugMode) {
        debugPrint(
            'Device token registration response: ${response.statusCode}');
      }
      // Silently accept any response - backend may not have endpoint yet
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          'Failed to register device token: ${sanitizeObjectForLog(e)}',
        );
      }
      // Silently fail - push notifications are optional
    }
  }
}

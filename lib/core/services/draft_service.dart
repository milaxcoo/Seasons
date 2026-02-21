import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DraftService {
  // Ключ-префикс, чтобы наши черновики не перемешались с другими данными
  static const String _draftPrefix = 'draft_voting_';

  // Сохраняет выбранные ответы для конкретного голосования
  Future<void> saveDraft(String votingId, Map<String, String> answers) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_draftPrefix$votingId';
    // Конвертируем Map в JSON-строку для сохранения
    final jsonString = json.encode(answers);
    await prefs.setString(key, jsonString);
  }

  // Загружает сохраненные ответы для конкретного голосования
  Future<Map<String, String>> loadDraft(String votingId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_draftPrefix$votingId';

    final jsonString = prefs.getString(key);

    if (jsonString != null) {
      try {
        // Конвертируем JSON-строку обратно в Map
        final decodedMap = json.decode(jsonString) as Map<String, dynamic>;
        // Убедимся, что все ключи и значения - это строки
        return decodedMap.map((key, value) => MapEntry(key, value.toString()));
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Draft decode failed: $e');
        }
      }
    }

    // Если черновика нет, возвращаем пустую карту
    return {};
  }

  // Очищает черновик после успешного голосования
  Future<void> clearDraft(String votingId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_draftPrefix$votingId';
    await prefs.remove(key);
  }
}

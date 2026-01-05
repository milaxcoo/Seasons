import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:seasons/data/models/question.dart';
import 'package:seasons/data/models/vote_result.dart'; // Импортируем нашу модель результатов

enum VotingStatus { registration, active, completed }

class VotingEvent extends Equatable {
  final String id;
  final String title;
  final String description;
  final VotingStatus status;
  final DateTime? registrationEndDate;
  final DateTime? votingStartDate;
  final DateTime? votingEndDate;
  final bool isRegistered;
  final List<Question> questions;
  final bool hasVoted;
  final List<QuestionResult> results;

  const VotingEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    this.registrationEndDate,
    this.votingStartDate,
    this.votingEndDate,
    required this.isRegistered,
    required this.questions,
    required this.hasVoted,
    required this.results,
  });

  factory VotingEvent.fromJson(Map<String, dynamic> json) {
    // Вложенный JSON для основного события может быть в ключе 'voting' или в корне
    final votingData = json['voting'] as Map<String, dynamic>? ?? json;

    VotingStatus status;
    final statusString =
        json['status'] as String? ?? votingData['status'] as String?;

    switch (statusString) {
      case 'active':
      case 'ongoing':
        status = VotingStatus.active;
        break;
      case 'completed':
      case 'finished':
        status = VotingStatus.completed;
        break;
      default:
        status = VotingStatus.registration;
    }

    DateTime? parseDate(String? dateString) {
      if (dateString == null || dateString.isEmpty) return null;
      try {
        // Добавляем 'Z' в конец строки, чтобы Dart понял, что это время в UTC
        final utcDateTime = DateTime.parse('${dateString}Z');
        // Затем конвертируем его в локальное время устройства
        return utcDateTime.toLocal();
      } catch (e) {
        return null;
      }
    }

    // FIXED: Логика парсинга теперь создает список объектов Question
    List<Question> parsedQuestions = [];
    try {
      if (votingData['questions'] != null && votingData['questions'] is List) {
        parsedQuestions = (votingData['questions'] as List)
            .map((qJson) => Question.fromJson(qJson as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка парсинга вопросов: $e');
      }
    }

    // FIXED: Полностью переписана логика для парсинга сложной структуры результатов
    List<QuestionResult> parsedResults = [];
    try {
      if (json['resultsData']?['results'] is Map) {
        final resultsMap =
            json['resultsData']['results'] as Map<String, dynamic>;

        resultsMap.forEach((questionName, questionData) {
          // Проверяем, что questionData - это Map
          if (questionData is! Map<String, dynamic>) {
            parsedResults.add(QuestionResult(
              name: questionName,
              type: 'unknown',
              subjectResults: [],
            ));
            return;
          }

          final questionValue = questionData;
          final questionType = questionValue['type'] as String? ?? 'unknown';
          final List<SubjectResult> subjectResults = [];

          final resultsField = questionValue['results'];

          // Проверяем, что results - это Map (не пустой array и не null)
          if (resultsField is Map<String, dynamic> && resultsField.isNotEmpty) {
            // Проверяем, есть ли вложенный ключ 'details' на верхнем уровне (для multiple_variants)
            final topLevelDetails = resultsField['details'];
            if (topLevelDetails is Map<String, dynamic> && topLevelDetails.isNotEmpty) {
              // multiple_variants с заполненными данными
              topLevelDetails.forEach((variantName, voteCount) {
                final count = voteCount is int ? voteCount : 0;
                subjectResults.add(SubjectResult(
                  name: variantName,
                  voteCounts: {variantName: count},
                ));
              });
            } else {
              // Стандартный парсинг для yes_no, yes_no_abstained, subject_oriented
              resultsField.forEach((subjectName, subjectData) {
                // Пропускаем нечисловые ключи типа 'details' или 'total'
                if (subjectName == 'details' || subjectName == 'total') return;
                
                // subjectData должен быть Map с 'details'
                if (subjectData is Map<String, dynamic>) {
                  final details = subjectData['details'];
                  if (details is Map<String, dynamic>) {
                    final voteCounts = <String, int>{};
                    details.forEach((key, value) {
                      voteCounts[key] = value is int ? value : 0;
                    });
                    subjectResults.add(SubjectResult(
                      name: subjectName,
                      voteCounts: voteCounts,
                    ));
                  }
                }
              });
            }
          }
          // Если results - пустой array [] или не Map, subjectResults останется пустым
          
          parsedResults.add(QuestionResult(
              name: questionName,
              type: questionType,
              subjectResults: subjectResults));
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка парсинга результатов: $e');
      }
    }

    return VotingEvent(
      id: votingData['id'] as String? ?? 'unknown_id',
      title: votingData['name'] as String? ?? 'Без названия',
      description:
          votingData['description'] as String? ?? 'Описание отсутствует.',
      status: status,
      registrationEndDate:
          parseDate(votingData['end_registration_at'] as String?) ??
              parseDate(votingData['registration_ended_at'] as String?),
      votingStartDate:
          parseDate(votingData['registration_started_at'] as String?) ??
              parseDate(votingData['voting_started_at'] as String?),
      votingEndDate: parseDate(votingData['end_voting_at'] as String?) ??
          parseDate(votingData['voting_ended_at'] as String?),
      isRegistered: votingData['registered'] == 1,
      questions: parsedQuestions, // Передаем распарсенный список вопросов
      hasVoted: votingData['voted'] == 1,
      results: parsedResults, // Передаем распарсенные результаты
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        status,
        registrationEndDate,
        votingStartDate,
        votingEndDate,
        isRegistered,
        questions,
        hasVoted,
        results, // Добавлено в props
      ];
}

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:seasons/core/utils/safe_log.dart';
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
        // If the server already provides timezone info, parse directly;
        // otherwise assume UTC by appending 'Z'.
        final normalized = dateString.contains('Z') ||
                dateString.contains('+') ||
                RegExp(r'-\d{2}:\d{2}$').hasMatch(dateString)
            ? dateString
            : '${dateString}Z';
        final utcDateTime = DateTime.parse(normalized);
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
        debugPrint('Ошибка парсинга вопросов: ${sanitizeObjectForLog(e)}');
      }
    }

    // FIXED: Полностью переписана логика для парсинга сложной структуры результатов
    List<QuestionResult> parsedResults = [];
    try {
      if (json['resultsData']?['results'] is Map) {
        final resultsMap =
            json['resultsData']['results'] as Map<String, dynamic>;

        resultsMap.forEach((questionName, questionData) {
          final questionValue = questionData as Map<String, dynamic>;
          final questionType = questionValue['type'] as String? ?? 'unknown';
          final List<SubjectResult> subjectResults = [];

          if (questionValue['results'] is Map) {
            final subjectsMap =
                questionValue['results'] as Map<String, dynamic>;

            // Проверяем, есть ли вложенный ключ 'details' (для multiple_variants)
            if (subjectsMap['details'] is Map) {
              final details = subjectsMap['details'] as Map<String, dynamic>;
              details.forEach((variantName, voteCount) {
                subjectResults.add(SubjectResult(
                  name: variantName,
                  voteCounts: {variantName: voteCount as int? ?? 0},
                ));
              });
            } else {
              // Стандартный парсинг для yes_no, yes_no_abstained, subject_oriented
              subjectsMap.forEach((subjectName, subjectData) {
                final details =
                    subjectData['details'] as Map<String, dynamic>? ?? {};
                final voteCounts = details
                    .map((key, value) => MapEntry(key, value as int? ?? 0));

                subjectResults.add(SubjectResult(
                  name: subjectName,
                  voteCounts: voteCounts,
                ));
              });
            }
          }
          parsedResults.add(QuestionResult(
              name: questionName,
              type: questionType,
              subjectResults: subjectResults));
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ошибка парсинга результатов: ${sanitizeObjectForLog(e)}');
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

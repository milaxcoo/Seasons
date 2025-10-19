import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:seasons/data/models/question.dart';
import 'package:seasons/data/models/vote_result.dart';

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
    final votingData = json['voting'] as Map<String, dynamic>? ?? json;

    VotingStatus status;
    final statusString = json['status'] as String? ?? votingData['status'] as String?;
    
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
        final utcDateTime = DateTime.parse('${dateString}Z');
        return utcDateTime.toLocal();
      } catch (e) {
        return null;
      }
    }

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

    List<QuestionResult> parsedResults = [];
    try {
      if (json['resultsData']?['results'] is Map) {
        final resultsMap = json['resultsData']['results'] as Map<String, dynamic>;
        resultsMap.forEach((questionName, questionData) {
          final questionValue = questionData as Map<String, dynamic>;
          if (questionValue['results'] is Map) {
            final subjectsMap = questionValue['results'] as Map<String, dynamic>;
            final List<SubjectResult> subjectResults = [];
            subjectsMap.forEach((subjectName, subjectData) {
              final details = subjectData['details'] as Map<String, dynamic>?;
              subjectResults.add(SubjectResult(
                name: subjectName,
                forVotes: details?['За'] as int? ?? 0,
                againstVotes: details?['Против'] as int? ?? 0,
              ));
            });
            parsedResults.add(QuestionResult(name: questionName, subjectResults: subjectResults));
          }
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
      description: votingData['description'] as String? ?? 'Описание отсутствует.',
      status: status,
      registrationEndDate: parseDate(votingData['end_registration_at'] as String?) ?? parseDate(votingData['registration_ended_at'] as String?),
      votingStartDate: parseDate(votingData['registration_started_at'] as String?) ?? parseDate(votingData['voting_started_at'] as String?),
      votingEndDate: parseDate(votingData['end_voting_at'] as String?) ?? parseDate(votingData['voting_ended_at'] as String?),
      isRegistered: votingData['registered'] == 1,
      questions: parsedQuestions,
      hasVoted: votingData['voted'] == 1,
      results: parsedResults,
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
        results,
      ];
}
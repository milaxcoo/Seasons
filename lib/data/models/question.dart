import 'package:equatable/equatable.dart';
import 'package:seasons/data/models/nominee.dart';
import 'package:seasons/data/models/subject.dart';

class Question extends Equatable {
  final String id;
  final String name;
  // Вопрос может иметь ИЛИ список субъектов (сложный)
  final List<Subject> subjects;
  // ИЛИ прямой список ответов (простой)
  final List<Nominee> answers;

  const Question({
    required this.id,
    required this.name,
    required this.subjects,
    required this.answers,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    List<Subject> parsedSubjects = [];
    List<Nominee> parsedAnswers = [];

    final data = json['data'] as Map<String, dynamic>?;

    if (data != null) {
      // Пытаемся найти "subjects" (сложная структура)
      if (data['subjects'] is Map) {
        final subjectsMap = data['subjects'] as Map<String, dynamic>;
        subjectsMap.forEach((key, value) {
          parsedSubjects
              .add(Subject.fromJson(value as Map<String, dynamic>, key));
        });
      }
      // Если "subjects" нет, ищем "answers" (простая структура)
      else if (data['answers'] is List) {
        parsedAnswers = (data['answers'] as List)
            .map((answerJson) =>
                Nominee.fromJson(answerJson as Map<String, dynamic>))
            .toList();
      }
    }

    return Question(
      id: data?['question']?['id'] as String? ?? 'unknown_question_id',
      name: data?['question']?['name'] as String? ?? 'Без названия',
      subjects: parsedSubjects,
      answers: parsedAnswers,
    );
  }

  @override
  List<Object?> get props => [id, name, subjects, answers];
}

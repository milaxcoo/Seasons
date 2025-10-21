import 'package:equatable/equatable.dart';
import 'package:seasons/data/models/subject.dart';

class Question extends Equatable {
  final String id;
  final String name;
  final List<Subject> subjects;

  const Question({
    required this.id,
    required this.name,
    required this.subjects,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    List<Subject> parsedSubjects = [];
    // Проверяем, что 'subjects' существует и является картой (Map)
    if (json['data']?['subjects'] is Map) {
      final subjectsMap = json['data']['subjects'] as Map<String, dynamic>;
      // Проходим по карте, где ключ - это ID субъекта, а значение - его данные
      subjectsMap.forEach((key, value) {
        parsedSubjects.add(Subject.fromJson(value as Map<String, dynamic>, key));
      });
    }

    return Question(
      id: json['data']?['question']?['id'] as String? ?? 'unknown_question_id',
      name: json['data']?['question']?['name'] as String? ?? 'Без названия',
      subjects: parsedSubjects,
    );
  }

  @override
  List<Object?> get props => [id, name, subjects];
}


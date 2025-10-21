import 'package:equatable/equatable.dart';

// Представляет одну строку в таблице результатов (например, "David Guetta")
class SubjectResult extends Equatable {
  final String name;
  // FIXED: Храним результаты в виде карты, чтобы поддерживать любые варианты
  final Map<String, int> voteCounts;

  const SubjectResult({
    required this.name,
    required this.voteCounts,
  });

  // Вспомогательный геттер для получения всех колонок (За, Против, и т.д.)
  List<String> get columns => voteCounts.keys.toList();

  @override
  List<Object?> get props => [name, voteCounts];
}

// Представляет один вопрос/группу с его результатами (например, "Group 1")
class QuestionResult extends Equatable {
  final String name;
  final String type; // 'yes_no', 'multiple_variants' и т.д.
  final List<SubjectResult> subjectResults;

  const QuestionResult({
    required this.name,
    required this.type,
    required this.subjectResults,
  });

  // Вспомогательный геттер для получения всех уникальных колонок в этой таблице
  List<String> get allColumns {
    final columns = <String>{};
    for (var result in subjectResults) {
      columns.addAll(result.columns);
    }
    return columns.toList();
  }

  @override
  List<Object?> get props => [name, type, subjectResults];
}

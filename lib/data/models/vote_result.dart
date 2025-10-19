import 'package:equatable/equatable.dart';

// Представляет одну строку в таблице результатов (например, "vvv")
class SubjectResult extends Equatable {
  final String name;
  final int forVotes;
  final int againstVotes;

  const SubjectResult({
    required this.name,
    required this.forVotes,
    required this.againstVotes,
  });

  @override
  List<Object?> get props => [name, forVotes, againstVotes];
}

// Представляет один вопрос с его результатами (например, "1. zzz")
class QuestionResult extends Equatable {
  final String name;
  final List<SubjectResult> subjectResults;

  const QuestionResult({
    required this.name,
    required this.subjectResults,
  });

  @override
  List<Object?> get props => [name, subjectResults];
}


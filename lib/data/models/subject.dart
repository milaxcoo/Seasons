    import 'package:equatable/equatable.dart';
    import 'package:seasons/data/models/nominee.dart'; 

    class Subject extends Equatable {
      final String id; // FIXED: Добавлено поле ID
      final String name;
      final List<Nominee> answers;

      const Subject({
        required this.id, // Добавлено в конструктор
        required this.name,
        required this.answers,
      });

      // Конструктор теперь принимает ID
      factory Subject.fromJson(Map<String, dynamic> json, String id) {
        List<Nominee> parsedAnswers = [];
        if (json['answers'] is List) {
          parsedAnswers = (json['answers'] as List)
              .map((answerJson) => Nominee.fromJson(answerJson as Map<String, dynamic>))
              .toList();
        }

        return Subject(
          id: id,
          name: json['name'] as String? ?? 'Без названия',
          answers: parsedAnswers,
        );
      }

      @override
      List<Object?> get props => [id, name, answers];
    }
    


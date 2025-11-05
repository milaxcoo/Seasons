import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:seasons/data/models/question.dart' as model;
import 'package:seasons/data/models/subject.dart' as model;
import 'package:seasons/data/models/voting_event.dart' as model;
import 'package:seasons/presentation/bloc/voting/voting_bloc.dart';
import 'package:seasons/presentation/bloc/voting/voting_event.dart';
import 'package:seasons/presentation/bloc/voting/voting_state.dart';
import 'package:seasons/presentation/widgets/app_background.dart';

class VotingDetailsScreen extends StatelessWidget {
  final model.VotingEvent event;
  final String imagePath;

  const VotingDetailsScreen({
    super.key,
    required this.event,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      imagePath: imagePath,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
        child: Scaffold(
          backgroundColor: Colors.black.withOpacity(0.2),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              "Вопросы голосования",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white),
            ),
          ),
          body: _VotingDetailsView(event: event),
        ),
      ),
    );
  }
}

class _VotingDetailsView extends StatefulWidget {
  final model.VotingEvent event;
  const _VotingDetailsView({required this.event});

  @override
  State<_VotingDetailsView> createState() => _VotingDetailsViewState();
}

class _VotingDetailsViewState extends State<_VotingDetailsView> {
  // Храним выбранные ответы.
  // Ключ - ID вопроса (для простых) или ID субъекта (для сложных).
  // Значение - ID ответа.
  final Map<String, String> _selectedAnswers = {};

  void _submitVote() {
    // Считаем общее количество "линий выбора"
    int totalItemsToVoteOn = 0;
    for (var q in widget.event.questions) {
      if (q.subjects.isNotEmpty) {
        totalItemsToVoteOn += q.subjects.length;
      } else if (q.answers.isNotEmpty) {
        totalItemsToVoteOn += 1; // 1 выбор на простой вопрос
      }
    }
    
    if (_selectedAnswers.length < totalItemsToVoteOn) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          content: Text('Пожалуйста, ответьте на все вопросы.'),
          backgroundColor: Colors.orange,
        ));
      return;
    }
    
    // FIXED: Передаем полный объект event и карту ответов
    context.read<VotingBloc>().add(
          SubmitVote(
            event: widget.event,
            answers: _selectedAnswers,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<VotingBloc, VotingState>(
      listener: (context, state) {
        if (state is VotingSubmissionSuccess) {
          showDialog(
            context: context, 
            barrierDismissible: false,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Голос принят'),
              content: const Text('Спасибо за участие!'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    Navigator.of(context).pop(true); // Возвращаем true для обновления
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        } else if (state is VotingFailure) {
          // FIXED: "Умная" обработка ошибки, которую мы видели в логах
          final errorMessage = state.error.toLowerCase();
          if (errorMessage.contains("user already voted")) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(
                content: const Text('Ваш голос уже был учтен ранее.'),
                backgroundColor: Colors.blue,
              ));
            Navigator.of(context).pop(true); // Все равно обновляем
          } else {
            // Любая другая, настоящая ошибка
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(
                content: Text('Ошибка: ${state.error}'),
                backgroundColor: Colors.redAccent,
              ));
          }
        }
      },
      builder: (context, state) {
        if (widget.event.questions.isEmpty) {
          return Center(
            child: Text(
              'Вопросы для этого голосования отсутствуют.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white),
            ),
          );
        }

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: widget.event.questions.length,
                itemBuilder: (context, index) {
                  final question = widget.event.questions[index];
                  return _QuestionCard(
                    question: question,
                    selectedAnswers: _selectedAnswers,
                    onAnswerSelected: (key, answerId) {
                      setState(() {
                        _selectedAnswers[key] = answerId;
                      });
                    },
                    hasVoted: widget.event.hasVoted,
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: widget.event.hasVoted ? Colors.grey : Theme.of(context).colorScheme.primary,
                  ),
                  onPressed: (state is VotingLoadInProgress || _selectedAnswers.isEmpty || widget.event.hasVoted)
                      ? null
                      : _submitVote,
                  child: state is VotingLoadInProgress
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          widget.event.hasVoted ? 'Вы уже проголосовали' : 'Проголосовать',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
                        ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final model.Question question;
  final Map<String, String> selectedAnswers;
  // Ключ - это ID субъекта (для сложных) или ID вопроса (для простых)
  final Function(String, String) onAnswerSelected;
  final bool hasVoted;

  const _QuestionCard({
    required this.question,
    required this.selectedAnswers,
    required this.onAnswerSelected,
    required this.hasVoted,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSimpleQuestion = question.subjects.isEmpty && question.answers.isNotEmpty;

    return Card(
      color: const Color(0xFFe4dcc5),
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question.name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Divider(height: 24),
            
            if (isSimpleQuestion)
              ...question.answers.map((answer) {
                return RadioListTile<String>(
                  title: Text(answer.name),
                  value: answer.id,
                  groupValue: selectedAnswers[question.id], // Ключ - ID вопроса
                  onChanged: hasVoted ? null : (answerId) {
                    if (answerId != null) {
                      onAnswerSelected(question.id, answerId);
                    }
                  },
                );
              }),
            
            if (!isSimpleQuestion)
              ...question.subjects.map((subject) {
                return _SubjectWidget(
                  subject: subject,
                  groupValue: selectedAnswers[subject.id], // Ключ - ID субъекта
                  onChanged: hasVoted ? null : (answerId) {
                    if (answerId != null) {
                      onAnswerSelected(subject.id, answerId);
                    }
                  },
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _SubjectWidget extends StatelessWidget {
  final model.Subject subject;
  final String? groupValue;
  final ValueChanged<String?>? onChanged;

  const _SubjectWidget({
    required this.subject,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subject.name,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          ...subject.answers.map((answer) {
            return RadioListTile<String>(
              title: Text(answer.name),
              value: answer.id,
              groupValue: groupValue,
              onChanged: onChanged,
            );
          }),
        ],
      ),
    );
  }
}
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
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
          backgroundColor: Colors.black.withOpacity(0.25),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              event.title, // Заголовок теперь - название голосования
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
  final Map<String, String> _selectedAnswers = {};

  void _submitVote() {
    final totalSubjects = widget.event.questions.fold<int>(0, (sum, q) => sum + q.subjects.length);
    if (_selectedAnswers.length < totalSubjects) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          content: Text('Пожалуйста, ответьте на все вопросы.'),
          backgroundColor: Colors.orange,
        ));
      return;
    }
    
    context.read<VotingBloc>().add(
          SubmitVote(
            eventId: widget.event.id,
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
                    Navigator.of(context).pop(true);
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        } else if (state is VotingFailure) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(
              content: Text('Ошибка: ${state.error}'),
              backgroundColor: Colors.redAccent,
            ));
        }
      },
      builder: (context, state) {
        return Column(
          children: [
            // FIXED: Добавлен новый информационный блок
            _EventInfoCard(event: widget.event),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: widget.event.questions.length,
                itemBuilder: (context, index) {
                  final question = widget.event.questions[index];
                  return _QuestionCard(
                    question: question,
                    selectedAnswers: _selectedAnswers,
                    onAnswerSelected: (subjectId, answerId) {
                      setState(() {
                        _selectedAnswers[subjectId] = answerId;
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

// --- НОВЫЕ И ОБНОВЛЕННЫЕ ВИДЖЕТЫ ---

// Виджет для отображения основной информации о голосовании
class _EventInfoCard extends StatelessWidget {
  final model.VotingEvent event;
  const _EventInfoCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm:ss', 'ru');
    
    final startDate = event.votingStartDate != null
        ? dateFormat.format(event.votingStartDate!)
        : 'Не установлено';
        
    final endDate = event.votingEndDate != null
        ? dateFormat.format(event.votingEndDate!)
        : 'Не установлено';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE4DCC5).withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            event.description,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          _InfoRow(label: 'Начало\nголосования', value: startDate),
          const Divider(height: 1),
          _InfoRow(label: 'Завершение\nголосования', value: endDate),
          const Divider(height: 1),
          _InfoRow(
            label: 'Статус',
            value: event.hasVoted ? 'Проголосовано' : 'Не проголосовано',
            valueColor: event.hasVoted ? const Color(0xFF00A94F) : Colors.red,
          ),
        ],
      ),
    );
  }
}

// Виджет для отображения строки информации
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.black54)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: valueColor ?? Colors.black,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}


// Виджет для отображения одной карточки вопроса
class _QuestionCard extends StatelessWidget {
  final model.Question question;
  final Map<String, String> selectedAnswers;
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
    return Card(
      color: const Color(0xFFE4DCC5),
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
            ...question.subjects.map((subject) {
              return _SubjectWidget(
                subject: subject,
                groupValue: selectedAnswers[subject.id],
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

// Виджет для одного "под-вопроса"
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


import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:seasons/core/services/draft_service.dart';
import 'package:seasons/data/models/question.dart' as model;
import 'package:seasons/data/models/subject.dart' as model;
import 'package:seasons/data/models/voting_event.dart' as model;
import 'package:seasons/presentation/bloc/voting/voting_bloc.dart';
import 'package:seasons/presentation/bloc/voting/voting_event.dart';
import 'package:seasons/presentation/bloc/voting/voting_state.dart';
import 'package:seasons/presentation/widgets/app_background.dart';

const Color rudnGreenColor = Color(0xFF52a355);

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
  Map<String, String> _selectedAnswers = {};
  final DraftService _draftService = DraftService();
  bool _isLoadingDraft = true;

  @override
  void initState() {
    super.initState();
    _loadDraft();
  }

  Future<void> _loadDraft() async {
    final draft = await _draftService.loadDraft(widget.event.id);
    setState(() {
      _selectedAnswers = draft;
      _isLoadingDraft = false;
    });
  }

  Future<void> _saveDraft() async {
    await _draftService.saveDraft(widget.event.id, _selectedAnswers);
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Вы уверены?"),
        content: const Text("После подтверждения ваш голос будет засчитан, и изменить его будет нельзя."),
        actions: <Widget>[
          TextButton(
            child: const Text("Отмена"),
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: rudnGreenColor),
            child: const Text("Проголосовать", style: TextStyle(color: Colors.white)),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<VotingBloc>().add(
                    SubmitVote(
                      event: widget.event,
                      answers: _selectedAnswers,
                    ),
                  );
            },
          ),
        ],
      ),
    );
  }

  void _submitVote() {
    int totalItemsToVoteOn = 0;
    for (var q in widget.event.questions) {
      if (q.subjects.isNotEmpty) {
        totalItemsToVoteOn += q.subjects.length;
      } else if (q.answers.isNotEmpty) {
        totalItemsToVoteOn += 1;
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
    
    _showConfirmationDialog();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingDraft) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    return BlocConsumer<VotingBloc, VotingState>(
      listener: (context, state) {
        if (state is VotingSubmissionSuccess) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Голос принят'),
              content: const Text('Спасибо за участие!'),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: rudnGreenColor,
                    minimumSize: const Size(120, 44),
                  ),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    Navigator.of(context).pop(true);
                  },
                  child: const Text('OK', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
        } else if (state is VotingFailure) {
          final errorMessage = state.error.toLowerCase();
          if (errorMessage.contains("user already voted")) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(
                content: const Text('Ваш голос уже был учтен ранее.'),
                backgroundColor: Colors.blue,
              ));
            Navigator.of(context).pop(true);
          } else {
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
                      _saveDraft();
                    },
                    hasVoted: widget.event.hasVoted,
                    isLoadingDraft: _isLoadingDraft,
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
                    backgroundColor: widget.event.hasVoted ? Colors.grey : rudnGreenColor,
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
  final Function(String, String) onAnswerSelected;
  final bool hasVoted;
  final bool isLoadingDraft;

  const _QuestionCard({
    required this.question,
    required this.selectedAnswers,
    required this.onAnswerSelected,
    required this.hasVoted,
    required this.isLoadingDraft,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSimpleQuestion = question.subjects.isEmpty && question.answers.isNotEmpty;
    final bool isDisabled = hasVoted || isLoadingDraft;

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
                return _CustomCheckboxTile(
                  title: answer.name,
                  value: selectedAnswers[question.id] == answer.id,
                  // FIXED: Передаем 'isDisabled' прямо в 'onChanged'
                  onChanged: isDisabled ? null : (bool? newValue) {
                    if (newValue == true) {
                      onAnswerSelected(question.id, answer.id);
                    }
                  },
                );
              }).toList(),
            
            if (!isSimpleQuestion)
              ...question.subjects.map((subject) {
                return _SubjectWidget(
                  subject: subject,
                  groupValue: selectedAnswers[subject.id],
                  // FIXED: Передаем 'isDisabled' прямо в 'onChanged'
                  onChanged: isDisabled ? null : (answerId) {
                    if (answerId != null) {
                      onAnswerSelected(subject.id, answerId);
                    }
                  },
                );
              }).toList(),
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
    this.groupValue,
    this.onChanged,
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
            return _CustomCheckboxTile(
              title: answer.name,
              value: groupValue == answer.id,
              // FIXED: Проверяем, является ли 'onChanged' (этого виджета) null,
              // и в зависимости от этого передаем либо null, либо новую функцию.
              onChanged: onChanged == null ? null : (bool? newValue) {
                if (newValue == true) {
                  onChanged!(answer.id);
                }
              },
            );
          }).toList(),
        ],
      ),
    );
  }
}

// Наш кастомный CheckboxListTile
class _CustomCheckboxTile extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool?>? onChanged;

  const _CustomCheckboxTile({
    required this.title,
    required this.value,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Определяем, активен ли виджет
    final bool isEnabled = onChanged != null;

    return InkWell(
      onTap: isEnabled ? () => onChanged!(!value) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Transform.scale(
              scale: 1.2,
              child: Checkbox(
                value: value,
                // FIXED: Если виджет неактивен, цвет "галочки" - серый
                activeColor: isEnabled ? rudnGreenColor : Colors.grey.shade600,
                onChanged: onChanged,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                side: BorderSide(
                  color: isEnabled ? Colors.black54 : Colors.grey.shade400,
                  width: 2,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: isEnabled ? Colors.black : Colors.grey.shade600,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
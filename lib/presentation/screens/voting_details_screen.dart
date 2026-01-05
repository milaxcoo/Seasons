import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:seasons/core/services/draft_service.dart';
import 'package:seasons/data/models/question.dart' as model;
import 'package:seasons/data/models/subject.dart' as model;
import 'package:seasons/data/models/voting_event.dart' as model;
import 'package:seasons/presentation/bloc/voting/voting_bloc.dart';
import 'package:seasons/presentation/bloc/voting/voting_event.dart';
import 'package:seasons/presentation/bloc/voting/voting_state.dart';
import 'package:seasons/presentation/widgets/app_background.dart';

const Color rudnGreenColor = Color(0xFF23a74c);

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
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              event.title,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
            ),
            centerTitle: true,
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
        title: Text(
          "Вы уверены?",
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        content: const Text(
            "После подтверждения ваш голос будет засчитан, и изменить его будет нельзя."),
        actions: <Widget>[
          TextButton(
            child: const Text("Отмена"),
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: rudnGreenColor),
            child: const Text("Проголосовать",
                style: TextStyle(color: Colors.white)),
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
  Widget build(BuildContext ctxt) {
    if (_isLoadingDraft) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.white));
    }

    final dateFormat = DateFormat('dd.MM.yyyy HH:mm:ss', 'ru');
    final startDate = widget.event.votingStartDate != null
        ? dateFormat.format(widget.event.votingStartDate!)
        : 'Не установлено';
    final endDate = widget.event.votingEndDate != null
        ? dateFormat.format(widget.event.votingEndDate!)
        : 'Не установлено';

    final statusText =
        widget.event.hasVoted ? "Проголосовал" : "Не проголосовал";
    final statusColor = widget.event.hasVoted ? rudnGreenColor : Colors.black;

    final now = DateTime.now();
    final bool isOngoing = widget.event.votingStartDate != null &&
        widget.event.votingStartDate!.isBefore(now) &&
        (widget.event.votingEndDate == null ||
            widget.event.votingEndDate!.isAfter(now));

    return BlocConsumer<VotingBloc, VotingState>(
      listener: (context, state) {
        if (state is VotingSubmissionSuccess) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) => AlertDialog(
              title: Text(
                'Голос принят',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
              ),
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
                  child:
                      const Text('OK', style: TextStyle(color: Colors.white)),
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
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: Colors.white),
            ),
          );
        }

        // --- ИСПРАВЛЕНИЕ: Обертка в Stack для кнопки ---
        return Stack(
          children: [
            // --- ИСПРАВЛЕНИЕ: Используем Column + NestedScrollView ---
            NestedScrollView(
              // --- ИСПРАВЛЕНИЕ: headerSliverBuilder для "нелипких" плашек ---
              headerSliverBuilder:
                  (BuildContext context, bool innerBoxIsScrolled) {
                return <Widget>[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFFe4dcc5),
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // --- ОПИСАНИЕ (внутри плашки) ---
                            if (widget.event.description.isNotEmpty)
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 8, 16, 8),
                                child: Text(
                                  widget.event.description,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                        color: Colors.black,
                                      ),
                                ),
                              ),
                            // --- ДАТЫ/СТАТУС (внутри плашки) ---
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (widget.event.description.isNotEmpty)
                                    const Divider(
                                        color: Colors.black12, height: 1),
                                  _InfoRow(
                                      label: 'Начало голосования',
                                      value: startDate),
                                  const Divider(color: Colors.black12),
                                  _InfoRow(
                                      label: 'Завершение голосования',
                                      value: endDate),
                                  const Divider(color: Colors.black12),
                                  _InfoRow(
                                    label: 'Статус',
                                    value: statusText,
                                    valueColor: statusColor,
                                  ),
                                ],
                              ),
                            ),
                            if (isOngoing && !widget.event.hasVoted)
                              Align(
                                alignment: Alignment.bottomLeft,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF4a4a4a),
                                    borderRadius: BorderRadius.only(
                                      topRight: Radius.circular(12),
                                      bottomLeft: Radius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    'Идет голосование',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                        ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ];
              },
              // --- ИСПРАВЛЕНИЕ: body - это сам список вопросов ---
              body: ListView.builder(
                padding: const EdgeInsets.fromLTRB(
                    16, 8, 16, 120), // Отступ для кнопки
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

            // --- КНОПКА (остается прибитой к низу) ---
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor:
                          widget.event.hasVoted ? Colors.grey : rudnGreenColor,
                    ),
                    onPressed: (state is VotingLoadInProgress ||
                            _selectedAnswers.isEmpty ||
                            widget.event.hasVoted)
                        ? null
                        : _submitVote,
                    child: state is VotingLoadInProgress
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            widget.event.hasVoted
                                ? 'Вы уже проголосовали'
                                : 'Проголосовать',
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900),
                          ),
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
    final bool isSimpleQuestion =
        question.subjects.isEmpty && question.answers.isNotEmpty;
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
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
            ),
            const Divider(height: 24),
            if (isSimpleQuestion)
              ...question.answers.map((answer) {
                return _CustomCheckboxTile(
                  title: answer.name,
                  value: selectedAnswers[question.id] == answer.id,
                  onChanged: isDisabled
                      ? null
                      : (bool? newValue) {
                          if (newValue == true) {
                            onAnswerSelected(question.id, answer.id);
                          }
                        },
                );
              }),
            if (!isSimpleQuestion)
              ...question.subjects.map((subject) {
                return _SubjectWidget(
                  subject: subject,
                  groupValue: selectedAnswers[subject.id],
                  onChanged: isDisabled
                      ? null
                      : (answerId) {
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
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          ...subject.answers.map((answer) {
            return _CustomCheckboxTile(
              title: answer.name,
              value: groupValue == answer.id,
              onChanged: onChanged == null
                  ? null
                  : (bool? newValue) {
                      if (newValue == true) {
                        onChanged!(answer.id);
                      }
                    },
            );
          }),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.black.withOpacity(0.6),
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: valueColor ?? Colors.black,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomCheckboxTile extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool?>? onChanged;

  const _CustomCheckboxTile({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onChanged != null ? () => onChanged!(!value) : null,
      splashColor: rudnGreenColor.withOpacity(0.2),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Icon(
              value ? Icons.check_box : Icons.check_box_outline_blank,
              color: onChanged == null
                  ? Colors.grey
                  : (value
                      ? rudnGreenColor
                      : Theme.of(context).textTheme.bodyLarge?.color ??
                          Colors.black),
              size: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: onChanged == null
                          ? Colors.grey
                          : (Theme.of(context).textTheme.bodyLarge?.color ??
                              Colors.black),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

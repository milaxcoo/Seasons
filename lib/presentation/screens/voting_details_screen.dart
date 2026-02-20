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
import 'package:seasons/l10n/app_localizations.dart';

import 'package:seasons/core/theme.dart';
import 'package:seasons/presentation/widgets/seasons_loader.dart';

// Removed local rudnGreenColor constant in favor of AppTheme.rudnGreenColor

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
          backgroundColor: Colors.black.withValues(alpha: 0.2),
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
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          l10n.areYouSure,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w900,
                fontSize: 22, // Increased size
              ),
        ),
        content: Text(
          l10n.voteConfirmationMessage,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontSize: 18, // Increased size
              ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        actions: <Widget>[
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
            child: Text(
              l10n.cancel,
              style: const TextStyle(fontSize: 18), // Increased size
            ),
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.rudnGreenColor,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              l10n.vote,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18, // Increased size
                fontWeight: FontWeight.bold,
              ),
            ),
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
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(l10n.answerAllQuestions),
          backgroundColor: Colors.orange,
        ));
      return;
    }

    _showConfirmationDialog();
  }

  @override
  Widget build(BuildContext ctxt) {
    if (_isLoadingDraft) {
      return const Center(child: SeasonsLoader());
    }

    final locale = Localizations.localeOf(context);
    final dateFormat = DateFormat(
        'dd.MM.yyyy HH:mm:ss', locale.languageCode == 'ru' ? 'ru' : 'en');
    final l10n = AppLocalizations.of(context)!;
    final startDate = widget.event.votingStartDate != null
        ? dateFormat.format(widget.event.votingStartDate!)
        : l10n.notSet;
    final endDate = widget.event.votingEndDate != null
        ? dateFormat.format(widget.event.votingEndDate!)
        : l10n.notSet;

    final statusText = widget.event.hasVoted ? l10n.voted : l10n.notVoted;
    final statusColor =
        widget.event.hasVoted ? AppTheme.rudnGreenColor : AppTheme.rudnRedColor;

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
              contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Text(
                l10n.voteAccepted,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                    ),
              ),
              content: Text(
                l10n.thankYou,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontSize: 18,
                    ),
              ),
              actionsAlignment: MainAxisAlignment.center,
              actionsPadding: const EdgeInsets.only(bottom: 24),
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.rudnGreenColor,
                    minimumSize: const Size(140, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    Navigator.of(context).pop(true);
                  },
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        } else if (state is VotingFailure) {
          final errorMessage = state.error.toLowerCase();
          if (errorMessage.contains("user already voted")) {
            final l10n = AppLocalizations.of(context)!;
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(
                content: Text(l10n.alreadyVotedError),
                backgroundColor: Colors.blue,
              ));
            Navigator.of(context).pop(true);
          } else {
            final l10n = AppLocalizations.of(context)!;
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(
                content: Text(l10n.error(state.error)),
                backgroundColor: AppTheme.rudnRedColor,
              ));
          }
        }
      },
      builder: (context, state) {
        if (widget.event.questions.isEmpty) {
          final l10n = AppLocalizations.of(context)!;
          return Center(
            child: Text(
              l10n.noQuestionsAvailable,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: Colors.white),
            ),
          );
        }

        return LayoutBuilder(builder: (context, constraints) {
          final bool isPinnedButton = constraints.maxHeight > 500;
          final double bottomPadding = isPinnedButton ? 120.0 : 24.0;

          // FIXED: Standardized scrollable area style (Window with internal scroll)
          final isLandscape =
              MediaQuery.of(context).orientation == Orientation.landscape;
          return SafeArea(
            child: Center(
              child: Padding(
                // Responsive padding: Smaller margins in landscape to maximize card size
                padding: isLandscape
                    ? const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 4.0)
                    : const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Container(
                  decoration: BoxDecoration(
                    // Voting screen usually handles its own background colors, but we need a container frame
                    color: Colors.transparent,
                    // However, the header is #e4dcc5. The body is transparent?
                    // The body list items have their own cards.
                    // The container frame should probably be transparent if the list items are cards.
                    // BUT, the user wants the "scrollable area" to have round corners.
                    // If we clip the whole NestedScrollView, corners will be rounded.
                    borderRadius: BorderRadius.circular(26),
                    // No shadow/border on the outer frame if we want transparency?
                    // Let's keep it consistent. If the content is "floating", it needs a background or shadow?
                    // Actually, VotingDetailsScreen has a transparent Scaffold background.
                    // The list items are floating cards.
                    // If we clip the viewport, the list items will be clipped at the edges.
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(26),
                    child: Stack(
                      children: [
                        NestedScrollView(
                          headerSliverBuilder:
                              (BuildContext context, bool innerBoxIsScrolled) {
                            return <Widget>[
                              SliverToBoxAdapter(
                                child: Padding(
                                  // Remove outer padding since we are already inside a padded window?
                                  // Or keep it for inner spacing.
                                  padding:
                                      const EdgeInsets.fromLTRB(0, 0, 0, 0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFe4dcc5)
                                          .withValues(alpha: 0.9),
                                      // Use only bottom radius? Or all?
                                      // The header looks like a card.
                                      borderRadius: const BorderRadius.vertical(
                                          bottom: Radius.circular(26)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(20),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              if (widget.event.description
                                                  .isNotEmpty) ...[
                                                Text(
                                                  widget.event.description,
                                                  textAlign: TextAlign.left,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyLarge
                                                      ?.copyWith(
                                                        color: Colors.black,
                                                      ),
                                                ),
                                                const SizedBox(height: 16),
                                                const Divider(
                                                    color: Colors.grey,
                                                    height: 1),
                                                const SizedBox(height: 16),
                                              ],
                                              _InfoRow(
                                                  label: l10n.votingStart,
                                                  value: startDate),
                                              const SizedBox(height: 16),
                                              const Divider(
                                                  color: Colors.grey,
                                                  height: 1),
                                              const SizedBox(height: 16),
                                              _InfoRow(
                                                  label: l10n.votingEnd,
                                                  value: endDate),
                                              const SizedBox(height: 16),
                                              const Divider(
                                                  color: Colors.grey,
                                                  height: 1),
                                              const SizedBox(height: 16),
                                              _InfoRow(
                                                label: l10n.status,
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
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 8),
                                              decoration: const BoxDecoration(
                                                color: Color(0xFF4a4a4a),
                                                borderRadius: BorderRadius.only(
                                                  topRight: Radius.circular(26),
                                                  bottomLeft: Radius.circular(
                                                      26), // Match bottom corner
                                                ),
                                              ),
                                              child: Text(
                                                l10n.votingInProgress,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyLarge
                                                    ?.copyWith(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w900,
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
                          body: ListView.builder(
                            padding: EdgeInsets.fromLTRB(0, 8, 0,
                                bottomPadding), // Remove side padding as window is padded
                            itemCount: widget.event.questions.length +
                                (isPinnedButton ? 0 : 1),
                            itemBuilder: (context, index) {
                              if (index == widget.event.questions.length) {
                                // Button inside the list (for Landscape/Small screens)
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 24.0),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16),
                                        backgroundColor: widget.event.hasVoted
                                            ? Colors.grey
                                            : AppTheme.rudnGreenColor,
                                      ),
                                      onPressed:
                                          (state is VotingLoadInProgress ||
                                                  _selectedAnswers.isEmpty ||
                                                  widget.event.hasVoted)
                                              ? null
                                              : _submitVote,
                                      child: state is VotingLoadInProgress
                                          ? const SeasonsLoader(
                                              size: 24, color: Colors.white)
                                          : Text(
                                              widget.event.hasVoted
                                                  ? l10n.alreadyVoted
                                                  : l10n.vote,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyLarge
                                                  ?.copyWith(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w900),
                                            ),
                                    ),
                                  ),
                                );
                              }
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

                        // Pinned Button (for Portrait/Large screens)
                        if (isPinnedButton)
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                              child: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    backgroundColor: widget.event.hasVoted
                                        ? Colors.grey
                                        : AppTheme.rudnGreenColor,
                                  ),
                                  onPressed: (state is VotingLoadInProgress ||
                                          _selectedAnswers.isEmpty ||
                                          widget.event.hasVoted)
                                      ? null
                                      : _submitVote,
                                  child: state is VotingLoadInProgress
                                      ? const SeasonsLoader(
                                          size: 24, color: Colors.white)
                                      : Text(
                                          widget.event.hasVoted
                                              ? l10n.alreadyVoted
                                              : l10n.vote,
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
                    ),
                  ),
                ),
              ),
            ),
          );
        });
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
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
            const Divider(height: 24, color: Colors.grey),
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
    return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.black.withValues(alpha: 0.6),
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
      splashColor: AppTheme.rudnGreenColor.withValues(alpha: 0.2),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Icon(
              value ? Icons.check_box : Icons.check_box_outline_blank,
              color: onChanged == null
                  ? Colors.grey
                  : (value
                      ? AppTheme.rudnGreenColor
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

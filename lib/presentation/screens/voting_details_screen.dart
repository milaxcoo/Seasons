import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:seasons/core/layout/adaptive_layout.dart';
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
import 'package:seasons/core/utils/user_friendly_error_mapper.dart';
import 'package:seasons/presentation/widgets/seasons_loader.dart';

// Removed local rudnGreenColor constant in favor of AppTheme.rudnGreenColor

class VotingDetailsScreen extends StatelessWidget {
  final model.VotingEvent event;
  final String imagePath;
  final DraftService? draftService;

  const VotingDetailsScreen({
    super.key,
    required this.event,
    required this.imagePath,
    this.draftService,
  });

  @override
  Widget build(BuildContext context) {
    final detailStyle = context.adaptiveLayout.detailLayoutStyle;
    return AppBackground(
      imagePath: imagePath,
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
                  fontSize: detailStyle.appBarTitleFontSize,
                ),
          ),
          centerTitle: true,
        ),
        body: _VotingDetailsView(event: event, draftService: draftService),
      ),
    );
  }
}

class _VotingDetailsView extends StatefulWidget {
  final model.VotingEvent event;
  final DraftService? draftService;

  const _VotingDetailsView({required this.event, this.draftService});

  @override
  State<_VotingDetailsView> createState() => _VotingDetailsViewState();
}

class _VotingDetailsViewState extends State<_VotingDetailsView> {
  Map<String, String> _selectedAnswers = {};
  late final DraftService _draftService;
  bool _isLoadingDraft = true;

  @override
  void initState() {
    super.initState();
    _draftService = widget.draftService ?? DraftService();
    _loadDraft();
  }

  Future<void> _loadDraft() async {
    final draft = await _draftService.loadDraft(widget.event.id);
    if (!mounted) return;
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
    final detailStyle = context.adaptiveLayout.detailLayoutStyle;
    showDialog(
      context: context,
      builder: (dialogContext) => Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: detailStyle.dialogMaxWidth),
          child: AlertDialog(
            contentPadding: detailStyle.dialogContentPadding,
            titlePadding: detailStyle.dialogTitlePadding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              l10n.areYouSure,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: detailStyle.titleFontSize + 1.0,
                  ),
            ),
            content: Text(
              l10n.voteConfirmationMessage,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontSize: detailStyle.titleFontSize - 2.0,
                  ),
            ),
            actionsPadding: detailStyle.dialogActionsPadding,
            actions: <Widget>[
              TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: detailStyle.cardPadding,
                    vertical: detailStyle.actionVerticalPadding,
                  ),
                ),
                child: Text(
                  l10n.cancel,
                  style: TextStyle(fontSize: detailStyle.titleFontSize - 2.0),
                ),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.rudnGreenColor,
                  padding: EdgeInsets.symmetric(
                    horizontal:
                        detailStyle.cardPadding + detailStyle.sectionGap,
                    vertical: detailStyle.actionVerticalPadding,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  l10n.vote,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: detailStyle.titleFontSize - 2.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  context.read<VotingBloc>().add(
                        SubmitVote(
                            event: widget.event, answers: _selectedAnswers),
                      );
                },
              ),
            ],
          ),
        ),
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
        ..showSnackBar(
          SnackBar(
            content: Text(l10n.answerAllQuestions),
            backgroundColor: Colors.orange,
          ),
        );
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
      'dd.MM.yyyy HH:mm:ss',
      locale.languageCode == 'ru' ? 'ru' : 'en',
    );
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
    final detailStyle = context.adaptiveLayout.detailLayoutStyle;

    return BlocConsumer<VotingBloc, VotingState>(
      listener: (context, state) async {
        if (state is VotingSubmissionSuccess) {
          if (!context.mounted) return;
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) => Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: detailStyle.dialogMaxWidth,
                ),
                child: AlertDialog(
                  contentPadding: detailStyle.dialogContentPadding,
                  titlePadding: detailStyle.dialogTitlePadding,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  title: Text(
                    l10n.voteAccepted,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          fontSize: detailStyle.titleFontSize + 1.0,
                        ),
                  ),
                  content: Text(
                    l10n.thankYou,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: detailStyle.titleFontSize - 2.0,
                        ),
                  ),
                  actionsAlignment: MainAxisAlignment.center,
                  actionsPadding: detailStyle.dialogActionsPadding,
                  actions: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.rudnGreenColor,
                        minimumSize: Size(140, detailStyle.actionMinHeight),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        Navigator.of(context).pop(true);
                      },
                      child: Text(
                        'OK',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: detailStyle.titleFontSize - 2.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        } else if (state is VotingFailure) {
          if (UserFriendlyErrorMapper.isAlreadyVotedError(state.error)) {
            final l10n = AppLocalizations.of(context)!;
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(l10n.alreadyVotedError),
                  backgroundColor: Colors.blue,
                ),
              );
            Navigator.of(context).pop(true);
          } else {
            final l10n = AppLocalizations.of(context)!;
            final userMessage = UserFriendlyErrorMapper.toMessage(
              l10n,
              state.error,
              context: UserErrorContext.voteSubmit,
            );
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(userMessage),
                  backgroundColor: AppTheme.rudnRedColor,
                ),
              );
          }
        }
      },
      builder: (context, state) {
        if (widget.event.questions.isEmpty) {
          final l10n = AppLocalizations.of(context)!;
          return Center(
            child: Text(
              l10n.noQuestionsAvailable,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.white),
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final bool isPinnedButton = constraints.maxHeight >
                (detailStyle.isExtremeCompact ? 420 : 500);
            final double bottomPadding = isPinnedButton
                ? (detailStyle.actionMinHeight +
                    detailStyle.sectionGapLarge +
                    20.0)
                : detailStyle.sectionGapLarge;
            return SafeArea(
              child: Center(
                child: Padding(
                  padding: detailStyle.outerPadding,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: detailStyle.maxContentWidth,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(26),
                        child: Stack(
                          children: [
                            NestedScrollView(
                              headerSliverBuilder: (BuildContext context,
                                  bool innerBoxIsScrolled) {
                                return <Widget>[
                                  SliverToBoxAdapter(
                                    child: Padding(
                                      padding: EdgeInsets.zero,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFFe4dcc5,
                                          ).withValues(alpha: 0.9),
                                          borderRadius:
                                              const BorderRadius.vertical(
                                            bottom: Radius.circular(26),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Padding(
                                              padding: EdgeInsets.all(
                                                detailStyle.cardPadding,
                                              ),
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
                                                    SizedBox(
                                                      height: detailStyle
                                                          .sectionGap,
                                                    ),
                                                    const Divider(
                                                      color: Colors.grey,
                                                      height: 1,
                                                    ),
                                                    SizedBox(
                                                      height: detailStyle
                                                          .sectionGap,
                                                    ),
                                                  ],
                                                  _InfoRow(
                                                    label: l10n.votingStart,
                                                    value: startDate,
                                                    style: detailStyle,
                                                  ),
                                                  SizedBox(
                                                    height:
                                                        detailStyle.sectionGap,
                                                  ),
                                                  const Divider(
                                                    color: Colors.grey,
                                                    height: 1,
                                                  ),
                                                  SizedBox(
                                                    height:
                                                        detailStyle.sectionGap,
                                                  ),
                                                  _InfoRow(
                                                    label: l10n.votingEnd,
                                                    value: endDate,
                                                    style: detailStyle,
                                                  ),
                                                  SizedBox(
                                                    height:
                                                        detailStyle.sectionGap,
                                                  ),
                                                  const Divider(
                                                    color: Colors.grey,
                                                    height: 1,
                                                  ),
                                                  SizedBox(
                                                    height:
                                                        detailStyle.sectionGap,
                                                  ),
                                                  _InfoRow(
                                                    label: l10n.status,
                                                    value: statusText,
                                                    valueColor: statusColor,
                                                    style: detailStyle,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (isOngoing &&
                                                !widget.event.hasVoted)
                                              Align(
                                                alignment: Alignment.bottomLeft,
                                                child: Container(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: detailStyle
                                                            .cardPadding -
                                                        detailStyle
                                                            .sectionGapSmall,
                                                    vertical: detailStyle
                                                            .sectionGapSmall +
                                                        2.0,
                                                  ),
                                                  decoration:
                                                      const BoxDecoration(
                                                    color: Color(0xFF4a4a4a),
                                                    borderRadius:
                                                        BorderRadius.only(
                                                      topRight: Radius.circular(
                                                        26,
                                                      ),
                                                      bottomLeft:
                                                          Radius.circular(
                                                        26,
                                                      ), // Match bottom corner
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
                                padding: EdgeInsets.fromLTRB(
                                  0,
                                  detailStyle.sectionGapSmall,
                                  0,
                                  bottomPadding,
                                ),
                                itemCount: widget.event.questions.length +
                                    (isPinnedButton ? 0 : 1),
                                itemBuilder: (context, index) {
                                  if (index == widget.event.questions.length) {
                                    // Button inside the list (for Landscape/Small screens)
                                    return Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: detailStyle.sectionGapLarge,
                                      ),
                                      child: SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            minimumSize: Size(
                                              double.infinity,
                                              detailStyle.actionMinHeight,
                                            ),
                                            padding: EdgeInsets.symmetric(
                                              vertical: detailStyle
                                                  .actionVerticalPadding,
                                            ),
                                            backgroundColor:
                                                widget.event.hasVoted
                                                    ? Colors.grey
                                                    : AppTheme.rudnGreenColor,
                                          ),
                                          onPressed: (state
                                                      is VotingLoadInProgress ||
                                                  _selectedAnswers.isEmpty ||
                                                  widget.event.hasVoted)
                                              ? null
                                              : _submitVote,
                                          child: state is VotingLoadInProgress
                                              ? const SeasonsLoader(
                                                  size: 24,
                                                  color: Colors.white,
                                                )
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
                                                            FontWeight.w900,
                                                      ),
                                                ),
                                        ),
                                      ),
                                    );
                                  }
                                  final question =
                                      widget.event.questions[index];
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
                                  padding: EdgeInsets.fromLTRB(
                                    detailStyle.cardPadding,
                                    detailStyle.sectionGap,
                                    detailStyle.cardPadding,
                                    detailStyle.sectionGapSmall + 2.0,
                                  ),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        minimumSize: Size(
                                          double.infinity,
                                          detailStyle.actionMinHeight,
                                        ),
                                        padding: EdgeInsets.symmetric(
                                          vertical:
                                              detailStyle.actionVerticalPadding,
                                        ),
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
                                              size: 24,
                                              color: Colors.white,
                                            )
                                          : Text(
                                              widget.event.hasVoted
                                                  ? l10n.alreadyVoted
                                                  : l10n.vote,
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
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
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
    final detailStyle = context.adaptiveLayout.detailLayoutStyle;
    final bool isSimpleQuestion =
        question.subjects.isEmpty && question.answers.isNotEmpty;
    final bool isDisabled = hasVoted || isLoadingDraft;

    return Card(
      color: const Color(0xFFe4dcc5),
      margin: EdgeInsets.symmetric(vertical: detailStyle.sectionGapSmall),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      child: Padding(
        padding: EdgeInsets.all(detailStyle.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question.name,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: detailStyle.titleFontSize,
                  ),
            ),
            Divider(height: detailStyle.sectionGapLarge, color: Colors.grey),
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
    final detailStyle = context.adaptiveLayout.detailLayoutStyle;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: detailStyle.sectionGapSmall),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subject.name, style: Theme.of(context).textTheme.bodyLarge),
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
  final AdaptiveDetailLayoutStyle style;
  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final shouldStack =
            style.isExtremeCompact || constraints.maxWidth < 350;
        if (shouldStack) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.black.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w900,
                    ),
              ),
              SizedBox(height: style.sectionGapSmall),
              Text(
                value,
                textAlign: TextAlign.left,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: valueColor ?? Colors.black,
                    ),
              ),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: style.rowLabelWidth,
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.black.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
            SizedBox(width: style.rowGap),
            Expanded(
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
      },
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
    final detailStyle = context.adaptiveLayout.detailLayoutStyle;
    final iconSize = detailStyle.isExtremeCompact ? 24.0 : 28.0;
    return InkWell(
      onTap: onChanged != null ? () => onChanged!(!value) : null,
      splashColor: AppTheme.rudnGreenColor.withValues(alpha: 0.2),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: detailStyle.sectionGapSmall),
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
              size: iconSize,
            ),
            SizedBox(width: detailStyle.rowGap),
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

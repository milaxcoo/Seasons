import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:seasons/core/layout/adaptive_layout.dart';
import 'package:seasons/data/models/voting_event.dart' as model;
import 'package:seasons/presentation/bloc/voting/voting_bloc.dart';
import 'package:seasons/presentation/bloc/voting/voting_event.dart';
import 'package:seasons/presentation/bloc/voting/voting_state.dart';
import 'package:seasons/presentation/widgets/app_background.dart';
import 'package:seasons/l10n/app_localizations.dart';
import 'package:seasons/core/theme.dart';
import 'package:seasons/core/utils/user_friendly_error_mapper.dart';

class RegistrationDetailsScreen extends StatelessWidget {
  final model.VotingEvent event;
  final String imagePath;

  const RegistrationDetailsScreen({
    super.key,
    required this.event,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    // Use the parent-provided VotingBloc so registration state
    // propagates back to HomeScreen (no orphaned local bloc).
    return AppBackground(
      imagePath: imagePath,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.35),
                    Colors.black.withValues(alpha: 0.25),
                    Colors.black.withValues(alpha: 0.35),
                  ],
                ),
              ),
            ),
          ),
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
            body: _RegistrationDetailsView(event: event),
          ),
        ],
      ),
    );
  }
}

class _RegistrationDetailsView extends StatelessWidget {
  final model.VotingEvent event;
  const _RegistrationDetailsView({required this.event});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final dateFormat = DateFormat(
      'dd.MM.yyyy HH:mm:ss',
      locale.languageCode == 'ru' ? 'ru' : 'en',
    );
    final l10n = AppLocalizations.of(context)!;

    final startDate = event.votingStartDate != null
        ? dateFormat.format(event.votingStartDate!)
        : l10n.notSet;

    final endDate = event.registrationEndDate != null
        ? dateFormat.format(event.registrationEndDate!)
        : l10n.notSet;
    final detailStyle = context.adaptiveLayout.detailLayoutStyle;

    return BlocListener<VotingBloc, VotingState>(
      listener: (context, state) {
        if (state is RegistrationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.registrationSuccess),
              backgroundColor: AppTheme.rudnGreenColor,
            ),
          );
          Navigator.of(context).pop(true);
        }
        if (state is RegistrationFailure) {
          final userMessage = UserFriendlyErrorMapper.toMessage(
            l10n,
            state.error,
            context: UserErrorContext.registration,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(userMessage),
              backgroundColor: AppTheme.rudnRedColor,
            ),
          );
        }
      },
      // FIXED: Standardized scrollable area style (Window with internal scroll)
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: detailStyle.outerPadding,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: detailStyle.maxContentWidth,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFE4DCC5).withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(26),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: EdgeInsets.all(detailStyle.cardPadding),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                event.title,
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      fontSize: detailStyle.titleFontSize,
                                    ),
                              ),
                              SizedBox(height: detailStyle.sectionGap),
                              const Divider(color: Colors.grey, height: 1),
                              SizedBox(height: detailStyle.sectionGap),
                              if (event.description.isNotEmpty) ...[
                                Text(
                                  event.description,
                                  textAlign: TextAlign.left,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                SizedBox(height: detailStyle.sectionGap),
                                const Divider(color: Colors.grey, height: 1),
                                SizedBox(height: detailStyle.sectionGap),
                              ],
                              _InfoRow(
                                label: l10n.registrationStart,
                                value: startDate,
                                style: detailStyle,
                              ),
                              SizedBox(height: detailStyle.sectionGap),
                              const Divider(color: Colors.grey, height: 1),
                              SizedBox(height: detailStyle.sectionGap),
                              _InfoRow(
                                label: l10n.registrationEnd,
                                value: endDate,
                                style: detailStyle,
                              ),
                              SizedBox(height: detailStyle.sectionGap),
                              const Divider(color: Colors.grey, height: 1),
                              SizedBox(height: detailStyle.sectionGap),
                              _InfoRow(
                                label: l10n.status,
                                value: event.isRegistered
                                    ? l10n.registered
                                    : l10n.notRegistered,
                                valueColor: event.isRegistered
                                    ? AppTheme.rudnGreenColor
                                    : AppTheme.rudnRedColor,
                                style: detailStyle,
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            detailStyle.cardPadding,
                            0,
                            detailStyle.cardPadding,
                            detailStyle.cardPadding,
                          ),
                          child: BlocBuilder<VotingBloc, VotingState>(
                            builder: (context, state) {
                              if (state is RegistrationInProgress) {
                                return Container(
                                  padding: EdgeInsets.symmetric(
                                    vertical: detailStyle.actionVerticalPadding,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(26),
                                  ),
                                  child: Center(
                                    child: Text(
                                      l10n.registering,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(color: Colors.white),
                                    ),
                                  ),
                                );
                              }

                              final isRegistrationClosed =
                                  event.registrationEndDate != null &&
                                      DateTime.now().isAfter(
                                        event.registrationEndDate!,
                                      );

                              return ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  side: BorderSide(
                                    color: (event.isRegistered ||
                                            isRegistrationClosed)
                                        ? Colors.grey
                                        : const Color(0xFF6A9457),
                                    width: 2,
                                  ),
                                  backgroundColor: (event.isRegistered ||
                                          isRegistrationClosed)
                                      ? Colors.grey.shade300
                                      : Colors.transparent,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(26),
                                  ),
                                  minimumSize: Size(
                                    double.infinity,
                                    detailStyle.actionMinHeight,
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    vertical: detailStyle.actionVerticalPadding,
                                  ),
                                ),
                                onPressed:
                                    (event.isRegistered || isRegistrationClosed)
                                        ? null
                                        : () {
                                            context.read<VotingBloc>().add(
                                                  RegisterForEvent(
                                                      eventId: event.id),
                                                );
                                          },
                                child: Text(
                                  event.isRegistered
                                      ? l10n.alreadyRegistered
                                      : (isRegistrationClosed
                                          ? l10n.registrationClosed
                                          : l10n.registerButton),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                        color: (event.isRegistered ||
                                                isRegistrationClosed)
                                            ? Colors.black54
                                            : const Color(0xFF6A9457),
                                      ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
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
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.black54),
              ),
              SizedBox(height: style.sectionGapSmall),
              Text(
                value,
                textAlign: TextAlign.left,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: valueColor ?? Colors.black,
                    ),
              ),
            ],
          );
        }
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: style.rowLabelWidth,
              child: Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.black54),
              ),
            ),
            SizedBox(width: style.rowGap),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
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

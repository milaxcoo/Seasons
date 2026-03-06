import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:seasons/core/layout/adaptive_layout.dart';
import 'package:seasons/core/services/monthly_theme_service.dart';
import 'package:seasons/presentation/widgets/app_background.dart';
import 'package:seasons/data/repositories/voting_repository.dart';
import 'package:seasons/data/models/user_profile.dart';
import 'package:seasons/l10n/app_localizations.dart';
import 'package:seasons/presentation/widgets/seasons_loader.dart';

class ProfileScreen extends StatefulWidget {
  final String? imagePathOverride;

  const ProfileScreen({super.key, this.imagePathOverride});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<UserProfile?> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = context.read<VotingRepository>().getUserProfile();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.read<MonthlyThemeService>().theme;
    final imagePath = widget.imagePathOverride ?? theme.imagePath;
    final adaptive = context.adaptiveLayout;
    final detailStyle = adaptive.detailLayoutStyle;

    return AppBackground(
      imagePath: imagePath,
      child: Scaffold(
        backgroundColor: Colors.black.withValues(alpha: 0.25),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            AppLocalizations.of(context)!.userData,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white,
              fontSize: detailStyle.appBarTitleFontSize,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        body: FutureBuilder<UserProfile?>(
          future: _profileFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: SeasonsLoader());
            }

            final profile = snapshot.data;
            if (profile == null) {
              return Center(
                child: Text(
                  AppLocalizations.of(context)!.failedToLoadProfile,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                ),
              );
            }

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
                          child: Padding(
                            padding: EdgeInsets.all(detailStyle.cardPadding),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _UserInfoRow(
                                  label: AppLocalizations.of(context)!.surname,
                                  value: profile.surname,
                                  style: detailStyle,
                                ),
                                SizedBox(height: detailStyle.sectionGap),
                                const Divider(color: Colors.grey, height: 1),
                                SizedBox(height: detailStyle.sectionGap),
                                _UserInfoRow(
                                  label: AppLocalizations.of(context)!.name,
                                  value: profile.name,
                                  style: detailStyle,
                                ),
                                SizedBox(height: detailStyle.sectionGap),
                                const Divider(color: Colors.grey, height: 1),
                                SizedBox(height: detailStyle.sectionGap),
                                _UserInfoRow(
                                  label: AppLocalizations.of(
                                    context,
                                  )!.patronymic,
                                  value: profile.patronymic,
                                  style: detailStyle,
                                ),
                                SizedBox(height: detailStyle.sectionGap),
                                const Divider(color: Colors.grey, height: 1),
                                SizedBox(height: detailStyle.sectionGap),
                                _UserInfoRow(
                                  label: AppLocalizations.of(context)!.email,
                                  value: profile.email,
                                  style: detailStyle,
                                ),
                                SizedBox(height: detailStyle.sectionGap),
                                const Divider(color: Colors.grey, height: 1),
                                SizedBox(height: detailStyle.sectionGap),
                                _UserInfoRow(
                                  label: AppLocalizations.of(context)!.jobTitle,
                                  value: profile.jobTitle,
                                  style: detailStyle,
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
          },
        ),
      ),
    );
  }
}

class _UserInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final AdaptiveDetailLayoutStyle style;

  const _UserInfoRow({
    required this.label,
    required this.value,
    required this.style,
  });

  void _showFullText(BuildContext context) {
    if (value.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: style.dialogMaxWidth),
          child: AlertDialog(
            title: Text(label),
            content: SelectableText(value),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final shouldStack =
            style.isExtremeCompact || constraints.maxWidth < 360;
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
              GestureDetector(
                onTap: () => _showFullText(context),
                child: Text(
                  value,
                  softWrap: true,
                  overflow: TextOverflow.fade,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
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
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.black54),
              ),
            ),
            SizedBox(width: style.rowGap),
            Expanded(
              child: GestureDetector(
                onTap: () => _showFullText(context),
                child: Text(
                  value,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
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

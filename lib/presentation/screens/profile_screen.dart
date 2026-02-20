import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:seasons/core/monthly_theme_data.dart';
import 'package:seasons/presentation/widgets/app_background.dart';
import 'package:seasons/data/repositories/voting_repository.dart';
import 'package:seasons/data/models/user_profile.dart';
import 'package:seasons/l10n/app_localizations.dart';
import 'package:seasons/presentation/widgets/seasons_loader.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

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
    final currentMonth = DateTime.now().month;
    final theme = monthlyThemes[currentMonth] ?? monthlyThemes[10]!;

    return AppBackground(
        imagePath: theme.imagePath,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
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
                      fontSize: 20,
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
                    style:
                        TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                  ));
                }

                // FIXED: Standardized scrollable area style (Window with internal scroll)
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
                          : const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 24.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFE4DCC5).withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(26),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withValues(alpha: 0.2), // Subtle shadow
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(26),
                          child: SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _UserInfoRow(
                                    label:
                                        AppLocalizations.of(context)!.surname,
                                    value: profile.surname,
                                  ),
                                  const SizedBox(height: 16),
                                  const Divider(color: Colors.grey, height: 1),
                                  const SizedBox(height: 16),
                                  _UserInfoRow(
                                    label: AppLocalizations.of(context)!.name,
                                    value: profile.name,
                                  ),
                                  const SizedBox(height: 16),
                                  const Divider(color: Colors.grey, height: 1),
                                  const SizedBox(height: 16),
                                  _UserInfoRow(
                                    label: AppLocalizations.of(context)!
                                        .patronymic,
                                    value: profile.patronymic,
                                  ),
                                  const SizedBox(height: 16),
                                  const Divider(color: Colors.grey, height: 1),
                                  const SizedBox(height: 16),
                                  _UserInfoRow(
                                    label: AppLocalizations.of(context)!.email,
                                    value: profile.email,
                                  ),
                                  const SizedBox(height: 16),
                                  const Divider(color: Colors.grey, height: 1),
                                  const SizedBox(height: 16),
                                  _UserInfoRow(
                                    label:
                                        AppLocalizations.of(context)!.jobTitle,
                                    value: profile.jobTitle,
                                  ),
                                ],
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
        ));
  }
}

class _UserInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _UserInfoRow({required this.label, required this.value});

  void _showFullText(BuildContext context) {
    if (value.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(label),
        content: SelectableText(value),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 150,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.black54,
                ),
          ),
        ),
        const SizedBox(width: 16),
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
  }
}

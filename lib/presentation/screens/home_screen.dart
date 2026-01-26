import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:seasons/core/monthly_theme_data.dart';
import 'package:seasons/core/services/notification_navigation_service.dart';
import 'package:seasons/data/models/voting_event.dart' as model;
import 'package:seasons/presentation/bloc/auth/auth_bloc.dart';
import 'package:seasons/presentation/bloc/voting/voting_bloc.dart';
import 'package:seasons/presentation/bloc/voting/voting_event.dart';
import 'package:seasons/presentation/bloc/voting/voting_state.dart';
import 'package:seasons/presentation/bloc/locale/locale_bloc.dart';
import 'package:seasons/presentation/bloc/locale/locale_event.dart';
import 'package:seasons/presentation/screens/login_screen.dart';
import 'package:seasons/presentation/screens/profile_screen.dart';
import 'package:seasons/presentation/screens/registration_details_screen.dart';
import 'package:seasons/presentation/screens/results_screen.dart';
import 'package:seasons/presentation/screens/voting_details_screen.dart';
import 'package:seasons/presentation/widgets/app_background.dart';
import 'package:seasons/presentation/widgets/animated_panel_selector.dart';
import 'package:seasons/l10n/app_localizations.dart';
import 'package:seasons/core/theme.dart';

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    
    String userLogin = 'User';
    if (authState is AuthAuthenticated) {
      userLogin = authState.userLogin;
    }

    return Padding(
      // Reduced padding in landscape to save vertical space
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: isLandscape ? 0.0 : 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Language switcher button (moved to left)
          PopupMenuButton<Locale>(
            icon: const Icon(Icons.language, color: Colors.white),
            onSelected: (Locale locale) {
              context.read<LocaleBloc>().add(ChangeLocale(locale));
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<Locale>(
                value: const Locale('ru'),
                child: Row(
                  children: [
                    const Text('🇷🇺'),
                    const SizedBox(width: 8),
                    Text(AppLocalizations.of(context)!.languageRussian),
                  ],
                ),
              ),
              PopupMenuItem<Locale>(
                value: const Locale('en'),
                child: Row(
                  children: [
                    const Text('🇬🇧'),
                    const SizedBox(width: 8),
                    Text(AppLocalizations.of(context)!.languageEnglish),
                  ],
                ),
              ),
            ],
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                },
                child: Text(userLogin,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(color: Colors.white)),
              ),
              IconButton(
                icon: const Icon(Icons.exit_to_app, color: Colors.white),
                onPressed: () {
                  context.read<AuthBloc>().add(LoggedOut());
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isLandscape ? 2.0 : 10.0),
      child: Column(
        children: [
          Text(
            'Seasons',
            style: (isLandscape 
                ? Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 20) // Very compact in landscape
                : Theme.of(context).textTheme.displayMedium)?.copyWith(
                  color: Colors.white,
                  shadows: [
                    const Shadow(blurRadius: 10, color: Colors.black54),
                    const Shadow(blurRadius: 2, color: Colors.black87)
                  ],
                  fontWeight: FontWeight.w900,
                ),
          ),
          if (!isLandscape) 
            Transform.translate(
              offset: const Offset(0, -5), // Move slightly closer to Seasons title
              child: Text(
                'времена года',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.95),
                      shadows: [
                        const Shadow(blurRadius: 8, color: Colors.black54),
                        const Shadow(blurRadius: 2, color: Colors.black54)
                      ],
                      fontStyle: FontStyle.normal,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      letterSpacing: 5,
                    ),
              ),
            )
          else 
            Text(
              'времена года',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    shadows: [
                      const Shadow(blurRadius: 4, color: Colors.black87),
                    ],
                    fontStyle: FontStyle.normal,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                    letterSpacing: 2,
                  ),
            ),
        ],
      ),
    );
  }
}



class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedPanelIndex = 0;
  int _previousPanelIndex = 0;
  // Use ValueNotifier for efficient updates without rebuilding the entire tree
  final ValueNotifier<int> _timeNotifier = ValueNotifier<int>(0);
  
  // Track number of actionable items (unregistered for registration, unvoted for active, total for completed)
  // Button is green only when there are actionable items
  final Map<model.VotingStatus, int> _actionableCount = {
    model.VotingStatus.registration: 0,
    model.VotingStatus.active: 0,
    model.VotingStatus.completed: 0,
  };


  // Hybrid Auto-Update Logic






  void _updateActionableCount(model.VotingStatus status, int count) {
    setState(() {
      _actionableCount[status] = count;
    });
  }

  void _fetchEventsForPanel(int index) {
    setState(() {
      _previousPanelIndex = _selectedPanelIndex;
      _selectedPanelIndex = index;
    });
    // Fetch data for the new panel
    final status = [
      model.VotingStatus.registration,
      model.VotingStatus.active,
      model.VotingStatus.completed,
    ][index];
    context.read<VotingBloc>().add(FetchEventsByStatus(status: status));
  }

  void _onPageChanged(int index) {
    // This method is now used for refresh callbacks
    final status = [
      model.VotingStatus.registration,
      model.VotingStatus.active,
      model.VotingStatus.completed,
    ][index];
    context.read<VotingBloc>().add(FetchEventsByStatus(status: status));
  }


  Timer? _uiTicker;
  Timer? _dataTicker;
  StreamSubscription? _navigationSubscription;
  
  @override
  void initState() {
    super.initState();
    
    // Listen for notification navigation events
    _navigationSubscription = NotificationNavigationService().onNavigate.listen((event) {
      if (mounted) {
        // Switch to the requested tab
        setState(() {
          _selectedPanelIndex = event.tabIndex;
        });
        
        // Trigger data refresh if requested
        if (event.shouldRefresh) {
          final status = [
            model.VotingStatus.registration,
            model.VotingStatus.active,
            model.VotingStatus.completed,
          ][event.tabIndex];
          context.read<VotingBloc>().add(FetchEventsByStatus(status: status));
        }
      }
    });
    
    // UI Ticker: Updates every 1 second to handle time-based UI changes instantly
    // e.g. "Registration closes in..." or switching from Open to Closed based on local time
    _uiTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      // Notify listeners (VotingCards) without rebuilding the whole HomeScreen
      _timeNotifier.value++;
    });

    // Data Ticker: Background sync every 3 seconds (as requested, WS insufficient)
    // This keeps button colors up-to-date and handles backend updates not pushed via WebSocket
    _dataTicker = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) {
        // Fetch fresh data for ALL statuses to keep button colors updated
        context.read<VotingBloc>().add(RefreshEventsSilent(status: model.VotingStatus.registration));
        context.read<VotingBloc>().add(RefreshEventsSilent(status: model.VotingStatus.active));
        context.read<VotingBloc>().add(RefreshEventsSilent(status: model.VotingStatus.completed));
      }
    });
    
    // Fetch initial data for all sections to populate button colors
    context.read<VotingBloc>().add(FetchEventsByStatus(status: model.VotingStatus.registration));
    context.read<VotingBloc>().add(RefreshEventsSilent(status: model.VotingStatus.active));
    context.read<VotingBloc>().add(RefreshEventsSilent(status: model.VotingStatus.completed));
  }
  
  @override
  void dispose() {
    _uiTicker?.cancel();
    _dataTicker?.cancel();
    _navigationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentMonth = DateTime.now().month;
    final theme = monthlyThemes[currentMonth] ?? monthlyThemes[10]!;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    return AppBackground(
      imagePath: theme.imagePath,
      child: Stack(
        clipBehavior: Clip.none,
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
          Positioned.fill(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: SafeArea(
                bottom: false,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Column(
                      children: [
                        // Top section - pinned at top
                        if (isLandscape) ...[
                          // Landscape: Header inline with TopBar
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              _TopBar(),
                              IgnorePointer(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Seasons',
                                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                              fontSize: 20,
                                              height: 1.0, // Reduce line height to pull elements closer
                                              color: Colors.white,
                                              shadows: [
                                                const Shadow(blurRadius: 10, color: Colors.black54),
                                                const Shadow(blurRadius: 2, color: Colors.black87)
                                              ],
                                              fontWeight: FontWeight.w900,
                                            ),
                                      ),
                                      Transform.translate(
                                        offset: const Offset(0, 0), // Move closer to title
                                        child: Text(
                                          'времена года',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                fontFamily: 'HemiHead',
                                                color: Colors.white.withValues(alpha: 0.9),
                                                shadows: [
                                                  const Shadow(blurRadius: 4, color: Colors.black87),
                                                ],
                                                fontStyle: FontStyle.normal,
                                                fontWeight: FontWeight.w900,
                                                fontSize: 8, // Reduced from 10
                                                letterSpacing: 2,
                                                height: 1.0,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          // Portrait: Stacked
                          _TopBar(),
                          _Header(),
                        ],
                        
                        BlocListener<VotingBloc, VotingState>(
                          listener: (context, state) {
                            if (state is VotingEventsLoadSuccess) {
                              // Use status from state (now correctly tracks which section was fetched)
                              final status = state.status;
                              
                              // Calculate actionable items count:
                              // - Registration: count events where user is NOT registered
                              // - Active: count events where user has NOT voted
                              // - Completed: count ALL completed votings (results available)
                              int actionableCount;
                              if (status == model.VotingStatus.registration) {
                                // Only count events where user is NOT registered AND registration is still open
                                actionableCount = state.events.where((e) => 
                                  !e.isRegistered && 
                                  (e.registrationEndDate == null || !DateTime.now().isAfter(e.registrationEndDate!))
                                ).length;
                              } else if (status == model.VotingStatus.active) {
                                // Only count events where user has NOT voted AND voting is still open
                                actionableCount = state.events.where((e) => 
                                  !e.hasVoted && 
                                  (e.votingEndDate == null || !DateTime.now().isAfter(e.votingEndDate!))
                                ).length;
                              } else {
                                actionableCount = state.events.length; // Count all completed votings
                              }
                              
                              _updateActionableCount(status, actionableCount);
                            }
                          },
                          child: AnimatedPanelSelector(
                            selectedIndex: _selectedPanelIndex,
                            onPanelSelected: _fetchEventsForPanel,
                            hasEvents: _actionableCount,
                            // Compact dimensions for landscape
                            totalHeight: isLandscape ? 80.0 : 110.0,
                            barHeight: isLandscape ? 60.0 : 90.0,
                            buttonRadius: 26.0, // Standardized to 26.0
                            verticalMargin: isLandscape ? 4.0 : 16.0,
                          ),
                        ),
                        // Scrollable voting cards area
                        Expanded(
                          child: Padding(
                            // Add side padding so the clip doesn't touch screen edges if desired, 
                            // or keep 0 if full width is needed. Using small horizontal padding for better look.
                            // Added bottom padding (20.0) to create space above the poem/footer
                            padding: const EdgeInsets.fromLTRB(32.0, 0, 32.0, 0),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(26.0), // Standardized to 26.0
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2), // Thin visible border
                                  width: 1.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.2), // Subtle white outer glow
                                    blurRadius: 8.0, 
                                    spreadRadius: 1.0, 
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(26.0), // Standardized to 26.0
                                child: GestureDetector(
                                onHorizontalDragEnd: (details) {
                                  // Detect swipe direction based on velocity
                                  final velocity = details.primaryVelocity ?? 0;
                                  
                                  if (velocity < -500) {
                                    // Swipe Left -> Move to Next tab
                                    if (_selectedPanelIndex < 2) {
                                      _fetchEventsForPanel(_selectedPanelIndex + 1);
                                    }
                                  } else if (velocity > 500) {
                                    // Swipe Right -> Move to Previous tab
                                    if (_selectedPanelIndex > 0) {
                                      _fetchEventsForPanel(_selectedPanelIndex - 1);
                                    }
                                  }
                                },
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 600),
                                  switchInCurve: Curves.easeOutCubic,
                                  switchOutCurve: Curves.easeInCubic,
                                  layoutBuilder: (currentChild, previousChildren) {
                                    // Stack layout prevents width shifts during transition
                                    return Stack(
                                      alignment: Alignment.topCenter,
                                      children: <Widget>[
                                        ...previousChildren,
                                        if (currentChild != null) currentChild,
                                      ],
                                    );
                                  },
                                  transitionBuilder: (Widget child, Animation<double> animation) {
                                    // Determine slide direction based on index change
                                    final isMovingForward = _selectedPanelIndex > _previousPanelIndex;
                                    final offsetBegin = isMovingForward 
                                        ? const Offset(1.0, 0.0)  // Slide in from right
                                        : const Offset(-1.0, 0.0); // Slide in from left
                                    
                                    return SlideTransition(
                                      position: Tween<Offset>(
                                        begin: offsetBegin,
                                        end: Offset.zero,
                                      ).animate(animation),
                                      child: child,
                                    );
                                  },
                                  child: _EventListPage(
                                    key: ValueKey(_selectedPanelIndex),
                                    status: [
                                      model.VotingStatus.registration,
                                      model.VotingStatus.active,
                                      model.VotingStatus.completed,
                                    ][_selectedPanelIndex],
                                    imagePath: theme.imagePath,
                                    onRefresh: () => _onPageChanged(_selectedPanelIndex),
                                    timeNotifier: _timeNotifier, // Pass notifier
                                  ),
                                ),
                              ),
                            ),
                          ),
                          ),
                        ),
                        // Footer at bottom - pinned
                        _Footer(poem: theme.poem, author: theme.author),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  final String poem;
  final String author;

  const _Footer({required this.poem, required this.author});

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16.0,
        isLandscape ? 4.0 : 4.0,  // Reduced top padding (was 24.0) to give more space to scrollable area
        16.0,
        isLandscape ? 20.0 : 16.0,  // Lifted footer higher in landscape (20.0)
      ),
      child: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              poem,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                height: 1.5,
                fontSize: isLandscape ? 12 : 14,
                shadows: [const Shadow(blurRadius: 6, color: Colors.black87)],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              author,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontStyle: FontStyle.italic,
                fontSize: isLandscape ? 12 : 14,
                shadows: [const Shadow(blurRadius: 6, color: Colors.black87)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}



// Widget for each page in the PageView
class _EventListPage extends StatelessWidget {
  final model.VotingStatus status;
  final String imagePath;
  final VoidCallback onRefresh;
  final ValueNotifier<int> timeNotifier; // Use ValueNotifier

  const _EventListPage({
    super.key,
    required this.status,
    required this.imagePath,
    required this.onRefresh,
    required this.timeNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VotingBloc, VotingState>(
      // Only rebuild if the state is for this section's status
      // This prevents the list from showing wrong data during background refresh of other sections
      buildWhen: (previous, current) {
        if (current is VotingEventsLoadSuccess) {
          return current.status == status;
        }
        // Allow rebuild for loading and error states
        return current is VotingLoadInProgress || current is VotingFailure;
      },
      builder: (context, state) {
        if (state is VotingLoadInProgress) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }
        if (state is VotingEventsLoadSuccess) {
          if (state.events.isEmpty) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 72.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.black.withOpacity(0.5),
                  ],
                ),
                borderRadius: BorderRadius.circular(26.0),
              ),
              child: Center(
                child: Text(
                  AppLocalizations.of(context)!.noActiveVotings,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white,
                    fontSize: 20.0,
                    shadows: [const Shadow(blurRadius: 6, color: Colors.black87)],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.builder(
            // Removed horizontal padding so cards touch the edges (0 left/right)
            padding: const EdgeInsets.fromLTRB(0, 16, 0, 16),
            itemCount: state.events.length,
            itemBuilder: (context, index) {
              return _VotingEventCard(
                event: state.events[index],
                imagePath: imagePath,
                onActionComplete: onRefresh,
                timeNotifier: timeNotifier, // Pass notifier
              );
            },
          );
        }
        if (state is VotingFailure) {
          return Center(
            child: Text(
              'Error: ${state.error}',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _VotingEventCard extends StatelessWidget {
  final model.VotingEvent event;
  final String imagePath;
  final VoidCallback onActionComplete;
  final ValueNotifier<int> timeNotifier;

  const _VotingEventCard({
    required this.event,
    required this.imagePath,
    required this.onActionComplete,
    required this.timeNotifier,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final dateFormat = DateFormat.yMMMd(locale.languageCode == 'ru' ? 'ru' : 'en');
    final l10n = AppLocalizations.of(context)!;
    String dateInfo;

    switch (event.status) {
      case model.VotingStatus.registration:
        if (event.registrationEndDate != null) {
          if (DateTime.now().isAfter(event.registrationEndDate!)) {
            dateInfo = l10n.registrationClosed;
          } else {
            dateInfo = l10n.registrationUntil(
                dateFormat.format(event.registrationEndDate!));
          }
        } else {
          dateInfo = l10n.registrationOpen;
        }
        break;
      case model.VotingStatus.active:
        dateInfo = event.votingEndDate != null
            ? l10n.votingUntil(dateFormat.format(event.votingEndDate!))
            : l10n.votingActive;
        break;
      case model.VotingStatus.completed:
        dateInfo = event.votingEndDate != null
            ? l10n.completedOn(dateFormat.format(event.votingEndDate!))
            : l10n.completed;
        break;
    }

    return Card(
      // Removed horizontal margin (0) to fit full width. Kept vertical for spacing.
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26.0)),
      elevation: 4,
      color: const Color(0xFFE4DCC5),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        title: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            event.title,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.black87,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dateInfo,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.black54,
                  ),
            ),
            if (event.status == model.VotingStatus.registration ||
                event.status == model.VotingStatus.active) ...[
              const SizedBox(height: 2),
            ValueListenableBuilder<int>(
              valueListenable: timeNotifier,
              builder: (context, _, __) {
                // Determine registration status based on CURRENT time (updates every second)
                final isRegistrationClosed = event.registrationEndDate != null && 
                                           DateTime.now().isAfter(event.registrationEndDate!);
                
                return Text(
                  event.status == model.VotingStatus.registration
                      ? (event.isRegistered
                          ? AppLocalizations.of(context)!.registered
                          : (isRegistrationClosed
                              ? AppLocalizations.of(context)!.registrationClosed
                              : AppLocalizations.of(context)!.notRegistered))
                      : (event.hasVoted
                          ? AppLocalizations.of(context)!.voted
                          : AppLocalizations.of(context)!.notVoted),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: (event.status == model.VotingStatus.registration
                                ? event.isRegistered
                                : event.hasVoted)
                            ? AppTheme.rudnGreenColor
                            : AppTheme.rudnRedColor,
                        fontWeight: FontWeight.w500,
                      ),
                );
              }
            ),
            ],
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.black54),
        onTap: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) {
                if (event.status == model.VotingStatus.registration) {
                  return RegistrationDetailsScreen(
                      event: event, imagePath: imagePath);
                } else if (event.status == model.VotingStatus.active) {
                  return VotingDetailsScreen(
                      event: event, imagePath: imagePath);
                } else {
                  return ResultsScreen(event: event, imagePath: imagePath);
                }
              },
            ),
          );

          if (result == true) {
            onActionComplete();
          }
        },
      ),
    );
  }
}



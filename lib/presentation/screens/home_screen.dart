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

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    String userLogin = 'User';
    if (authState is AuthAuthenticated) {
      userLogin = authState.userLogin;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
      padding: EdgeInsets.symmetric(vertical: isLandscape ? 4.0 : 10.0),
      child: Column(
        children: [
          Text(
            'Seasons',
            style: (isLandscape 
                ? Theme.of(context).textTheme.displaySmall 
                : Theme.of(context).textTheme.displayMedium)?.copyWith(
                  color: Colors.white,
                  shadows: [
                    const Shadow(blurRadius: 10, color: Colors.black54),
                    const Shadow(blurRadius: 2, color: Colors.black87)
                  ],
                  fontWeight: FontWeight.w900,
                ),
          ),
          Text(
            'времена года',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                  shadows: [
                    const Shadow(blurRadius: 8, color: Colors.black54),
                    const Shadow(blurRadius: 2, color: Colors.black54)
                  ],
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w900,
                  fontSize: isLandscape ? 12 : 16,
                  letterSpacing: isLandscape ? 5 : 7,
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


  Timer? _ticker;
  StreamSubscription? _navigationSubscription;
  
  @override
  void initState() {
    super.initState();
    
    // Listen for notification navigation events
    _navigationSubscription = NotificationNavigationService().onNavigate.listen((event) {
      if (mounted) {
        if (kDebugMode) print("HomeScreen: Navigating to tab ${event.tabIndex}");
        
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
    
    // Ticker to update UI every 10 seconds AND fetch fresh data for ALL sections
    // This keeps button colors up-to-date and handles backend updates not pushed via WebSocket
    _ticker = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) {
        // Rebuild UI for time-based checks
        setState(() {});
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
    _ticker?.cancel();
    _navigationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentMonth = DateTime.now().month;
    final theme = monthlyThemes[currentMonth] ?? monthlyThemes[10]!;
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
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _TopBar(),
                          _Header(),
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
                                  actionableCount = state.events.where((e) => !e.isRegistered).length;
                                } else if (status == model.VotingStatus.active) {
                                  actionableCount = state.events.where((e) => !e.hasVoted).length;
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
                            ),
                          ),
                          GestureDetector(
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
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: MediaQuery.of(context).size.height * 0.2,
                              ),
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
                                ),
                              ),
                            ),
                          ),
                          _Footer(poem: theme.poem, author: theme.author),
                        ],
                      ),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(24.0, 120.0, 24.0, 16.0),
      child: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              poem,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                height: 1.5,
                shadows: [const Shadow(blurRadius: 6, color: Colors.black87)],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              author,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontStyle: FontStyle.italic,
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

  const _EventListPage({
    super.key,
    required this.status,
    required this.imagePath,
    required this.onRefresh,
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
                    Colors.black.withValues(alpha: 0.7),
                    Colors.black.withValues(alpha: 0.5),
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(30),
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
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(8, 16, 8, 0),
            itemCount: state.events.length,
            itemBuilder: (context, index) {
              return _VotingEventCard(
                event: state.events[index],
                imagePath: imagePath,
                onActionComplete: onRefresh,
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

  const _VotingEventCard({
    required this.event,
    required this.imagePath,
    required this.onActionComplete,
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
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
              Text(
                event.status == model.VotingStatus.registration
                    ? (event.isRegistered
                        ? AppLocalizations.of(context)!.registered
                        : AppLocalizations.of(context)!.notRegistered)
                    : (event.hasVoted
                        ? AppLocalizations.of(context)!.voted
                        : AppLocalizations.of(context)!.notVoted),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: (event.status == model.VotingStatus.registration
                              ? event.isRegistered
                              : event.hasVoted)
                          ? const Color(0xFF00A94F)
                          : Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.black54),
        onTap: () async {
          if (kDebugMode) {
            print(
                '\n--- DEBUG [HomeScreen]: Нажата карточка "${event.title}" ---');
            print(
                '--- DEBUG [HomeScreen]: Статус объекта event: ${event.status} ---');
          }

          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) {
                if (event.status == model.VotingStatus.registration) {
                  if (kDebugMode) {
                    print(
                        '--- DEBUG [HomeScreen]: Навигация -> RegistrationDetailsScreen ---');
                  }
                  return RegistrationDetailsScreen(
                      event: event, imagePath: imagePath);
                } else if (event.status == model.VotingStatus.active) {
                  if (kDebugMode) {
                    print(
                        '--- DEBUG [HomeScreen]: Навигация -> VotingDetailsScreen ---');
                  }
                  return VotingDetailsScreen(
                      event: event, imagePath: imagePath);
                } else {
                  if (kDebugMode) {
                    print(
                        '--- DEBUG [HomeScreen]: Навигация -> ResultsScreen ---');
                  }
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



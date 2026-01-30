import 'dart:async';
import 'dart:ui';

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
import 'package:seasons/presentation/widgets/seasons_loader.dart';

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
      padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: isLandscape ? 0.0 : 8.0),
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
      padding: EdgeInsets.symmetric(vertical: isLandscape ? 2.0 : 4.0), // Reduced from 10.0
      child: Column(
        children: [
          Text(
            'Seasons',
            style: (isLandscape 
                ? Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 20) // Very compact in landscape
                : Theme.of(context).textTheme.displayMedium)?.copyWith(
                  color: Colors.white,
                  shadows: [
                    const Shadow(blurRadius: 15, color: Colors.black87), // Stronger outer glow
                    const Shadow(blurRadius: 4, color: Colors.black),    // Sharper inner shadow
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
                        const Shadow(blurRadius: 10, color: Colors.black87),
                        const Shadow(blurRadius: 2, color: Colors.black),
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
                      const Shadow(blurRadius: 6, color: Colors.black87),
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
  // Use ValueNotifier for efficient updates without rebuilding the entire tree
  final ValueNotifier<int> _timeNotifier = ValueNotifier<int>(0);
  
  // Track number of actionable items (unregistered for registration, unvoted for active, total for completed)
  // Button is green only when there are actionable items
  final Map<model.VotingStatus, int> _actionableCount = {
    model.VotingStatus.registration: 0,
    model.VotingStatus.active: 0,
    model.VotingStatus.completed: 0,
  };

  late PageController _pageController;

  void _updateActionableCount(model.VotingStatus status, int count) {
    setState(() {
      _actionableCount[status] = count;
    });
  }

  void _fetchEventsForPanel(int index) {
    // Animate to the page. This will trigger onPageChanged which handles fetching.
    _pageController.animateToPage(
      index, 
      duration: const Duration(milliseconds: 500), 
      curve: Curves.easeOutQuart, // Smoother curve
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _selectedPanelIndex = index;
    });
    _refreshCurrentPage(index);
  }

  void _refreshCurrentPage(int index) {
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
    _pageController = PageController(initialPage: _selectedPanelIndex);
    
    // Listen for notification navigation events
    _navigationSubscription = NotificationNavigationService().onNavigate.listen((event) {
      if (mounted) {
        // Smoothly animate to the requested tab
        _fetchEventsForPanel(event.tabIndex);
        
        // Trigger data refresh if requested (onPageChanged will do it, but force if needed)
        if (event.shouldRefresh) {
           // Wait a bit for animation or just trigger
           // Actually _onPageChanged will trigger fetch. 
           // If we are ALREADY on that page, onPageChanged won't fire for animateToPage(sameIndex).
           if (_selectedPanelIndex == event.tabIndex) {
              _refreshCurrentPage(event.tabIndex);
           }
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
    _pageController.dispose();
    _uiTicker?.cancel();
    _dataTicker?.cancel();
    _navigationSubscription?.cancel();
    super.dispose();
  }

  int _debugThemeOffset = 0;

  @override
  Widget build(BuildContext context) {
    // Calculate current month with debug offset
    // (month - 1 + offset) % 12 + 1 ensures 1-12 range
    final realMonth = DateTime.now().month;
    final debugMonth = ((realMonth - 1 + _debugThemeOffset) % 12) + 1;
    final theme = monthlyThemes[debugMonth] ?? monthlyThemes[1]!;
    
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    // --- UI COMPONENTS ---

    // 1. Top Bar (Profile / Lang)
    final topBar = _TopBar();

    // 2. Header (Seasons Title) with optional tap-to-test
    Widget header = isLandscape 
      ? Stack(
          alignment: Alignment.center,
          children: [
            IgnorePointer(
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                      Text(
                        'Seasons',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontSize: 32, // Restored to much larger size for visibility (Original was ~34 in portrait)
                              height: 1.0,
                              color: Colors.white,
                              shadows: [
                                const Shadow(blurRadius: 10, color: Colors.black54),
                                const Shadow(blurRadius: 2, color: Colors.black87)
                              ],
                              fontWeight: FontWeight.w900,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      Transform.translate(
                        offset: const Offset(0, 0),
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
                                fontSize: 12, // Larger subtext
                                letterSpacing: 2,
                                height: 1.0,
                              ),
                        textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        )
      : GestureDetector(
          onTap: () {
            setState(() {
              _debugThemeOffset++;
            });
            final nextMonth = ((realMonth - 1 + _debugThemeOffset) % 12) + 1;
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Testing Month: $nextMonth'),
                duration: const Duration(milliseconds: 500),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Colors.black87,
              ),
            );
          },
          child: _Header(),
        );

    // 3. Navbar (Panel Selector)
    final navbar = BlocListener<VotingBloc, VotingState>(
      listener: (context, state) {
        if (state is VotingEventsLoadSuccess) {
          final status = state.status;
          int actionableCount;
          if (status == model.VotingStatus.registration) {
            actionableCount = state.events.where((e) => 
              !e.isRegistered && 
              (e.registrationEndDate == null || !DateTime.now().isAfter(e.registrationEndDate!))
            ).length;
          } else if (status == model.VotingStatus.active) {
            actionableCount = state.events.where((e) => 
              !e.hasVoted && 
              (e.votingEndDate == null || !DateTime.now().isAfter(e.votingEndDate!))
            ).length;
          } else {
            actionableCount = state.events.length;
          }
          _updateActionableCount(status, actionableCount);
        }
      },
      child: AnimatedPanelSelector(
        selectedIndex: _selectedPanelIndex,
        onPanelSelected: _fetchEventsForPanel,
        hasEvents: _actionableCount,
        // Compact landscape navbar as requested to save space for poem
        totalHeight: isLandscape ? 80.0 : 110.0,
        barHeight: isLandscape ? 60.0 : 90.0,
        buttonRadius: isLandscape ? 20.0 : 26.0,
        verticalMargin: isLandscape ? 4.0 : 16.0, 
      ),
    );

    // 4. Voting List (The Main Content) - WITHOUT Expanded wrapper here
    final votingListContent = Padding(
      padding: const EdgeInsets.fromLTRB(24.0, 0.0, 24.0, 0.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26.0),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.2),
              blurRadius: 8.0, 
              spreadRadius: 1.0, 
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: PageView.builder(
          controller: _pageController,
          physics: const BouncingScrollPhysics(),
          onPageChanged: _onPageChanged,
          itemCount: 3,
          itemBuilder: (context, index) {
            return _SmokeTransition(
              index: index,
              pageController: _pageController,
              child: _EventListPage(
                status: [
                  model.VotingStatus.registration,
                  model.VotingStatus.active,
                  model.VotingStatus.completed,
                ][index],
                imagePath: theme.imagePath,
                onRefresh: () => _refreshCurrentPage(index),
                timeNotifier: _timeNotifier,
              ),
            );
          },
        ),
      ),
    );

    // 5. Footer (Poem)
    // Pass isLandscape=false to footer when in split-view so it doesn't limit height
    // Actually, we will just use the footer widget and rely on layout constraints
    final footer = _Footer(poem: theme.poem, author: theme.author);

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
                left: false,
                right: false,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: isLandscape 
                      // LANDSCAPE: Split Layout (50/50 Split)
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Left: Voting List (The "Detailed" content)
                            Expanded( 
                              flex: 1, // 50% width
                              child: Padding(
                                padding: const EdgeInsets.only(top: 0.0), // Maximized height (removed top padding)
                                child: votingListContent,
                              ),
                            ),
                            
                            // Right: Sidebar (Header, Controls, Poem)
                            Expanded(
                              flex: 1, // 50% width
                              child: Column(
                                children: [
                                  topBar,
                                  Expanded( // Distribute space
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        header,
                                        const SizedBox(height: 4), // Ultra compact spacing
                                        navbar,
                                        const SizedBox(height: 4), // Ultra compact spacing
                                        Expanded(child: footer), // Force footer to fit in remaining space
                                        const SizedBox(height: 12), // Restored bottom breathing room
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      // PORTRAIT: Stacked Layout (Original)
                      : Column(
                          children: [
                            topBar,
                            header,
                            navbar,
                            Expanded(child: votingListContent), // Correctly applied Expanded inside Column
                            footer,
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
        isLandscape ? 16.0 : 24.0, // Restored safe margins (was 8.0)
        isLandscape ? 4.0 : 4.0,
        isLandscape ? 16.0 : 24.0, // Restored safe margins (was 8.0)
        isLandscape ? 8.0 : 16.0,  // Restored bottom internal padding
      ),
      child: Container(
        width: double.infinity, // Ensure full width frame
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26.0),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.2),
              blurRadius: 8.0, 
              spreadRadius: 1.0, 
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(20.0), // Internal padding for the frame
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                // In landscape, limit footer to 80% of screen height (plenty of room in sidebar)
                // In portrait, keep 25% limit
                maxHeight: isLandscape 
                    ? MediaQuery.of(context).size.height * 0.80 
                    : MediaQuery.of(context).size.height * 0.25,
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                mainAxisSize: MainAxisSize.min, // Tightly wrap content
                crossAxisAlignment: CrossAxisAlignment.start, // Align all text to left edge
                children: [
                  Text(
                    poem,
                    softWrap: false,
                    textAlign: TextAlign.left, // Explictly left align
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      height: 1.5,
                      fontSize: isLandscape ? 14 : 14, // Back to 14 base size, FittedBox will scale it
                      shadows: [const Shadow(blurRadius: 6, color: Colors.black87)],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    author,
                    softWrap: false,
                    textAlign: TextAlign.left, // Explicitly left align
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontStyle: FontStyle.italic,
                      fontSize: isLandscape ? 14 : 14, // Back to 14 base size
                      shadows: [const Shadow(blurRadius: 6, color: Colors.black87)],
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
}
}



// Widget for each page in the PageView
class _EventListPage extends StatelessWidget {
  final model.VotingStatus status;
  final String imagePath;
  final VoidCallback onRefresh;
  final ValueNotifier<int> timeNotifier; // Use ValueNotifier

  const _EventListPage({
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
        Widget content;

        if (state is VotingLoadInProgress) {
          content = const Center(
            key: ValueKey('loader'),
            child: SeasonsLoader(),
          );
        } else if (state is VotingEventsLoadSuccess) {
          if (state.events.isEmpty) {
            content = Container(
              key: const ValueKey('empty'),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.black.withValues(alpha: 0.1),
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
          } else {
            content = ListView.builder(
              key: const ValueKey('list'),
              padding: const EdgeInsets.fromLTRB(0, 16, 0, 16),
              itemCount: state.events.length,
              itemBuilder: (context, index) {
                return _VotingEventCard(
                  event: state.events[index],
                  imagePath: imagePath,
                  onActionComplete: onRefresh,
                  timeNotifier: timeNotifier,
                );
              },
            );
          }
        } else if (state is VotingFailure) {
          content = Center(
            key: const ValueKey('error'),
            child: Text(
              'Error: ${state.error}',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white),
            ),
          );
        } else {
          content = const SizedBox.shrink(key: ValueKey('shrink'));
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 600),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.95, end: 1.0).animate(animation),
                child: child,
              ),
            );
          },
          child: content,
        );
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


// Smoke effect transition wrapper
class _SmokeTransition extends StatelessWidget {
  final Widget child;
  final int index;
  final PageController pageController;

  const _SmokeTransition({
    required this.child,
    required this.index,
    required this.pageController,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        
        return AnimatedBuilder(
          animation: pageController,
          child: child,
          builder: (context, child) {
            double value = 0.0;
            try {
              if (pageController.hasClients && pageController.position.haveDimensions) {
                value = pageController.page ?? 0.0;
              } else {
                 value = (index).toDouble();
              }
            } catch (_) {
              // Fallback if multiple clients are attached during layout transition
              value = (index).toDouble();
            }

            final double dist = (value - index);
            final double absDist = dist.abs();

            if (absDist > 1.0) {
              return const SizedBox.shrink();
            }

            // Effects
            final double opacity = (1.0 - absDist).clamp(0.0, 1.0);
            final double scale = 1.0 + (absDist * 0.15);
            final double blur = absDist * 10.0;

            // Counteract the sliding movement
            final double translation = dist * width;

            return Transform.translate(
              offset: Offset(translation, 0),
              child: Opacity(
                opacity: opacity,
                child: Transform.scale(
                  scale: scale,
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                    child: child,
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

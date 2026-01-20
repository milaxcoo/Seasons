import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:intl/intl.dart';
import 'package:seasons/core/monthly_theme_data.dart';
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
import 'package:seasons/presentation/widgets/custom_icons.dart';
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

class _PanelSelector extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onPanelSelected;
  final Map<model.VotingStatus, int> hasEvents;

  const _PanelSelector({
    required this.selectedIndex,
    required this.onPanelSelected,
    required this.hasEvents,
  });

  @override
  Widget build(BuildContext context) {
    // --- НАСТРОЙКИ ---
    const double barHeight = 60.0;
    const double buttonRadius = 25.0; // <-- ⭐ ГЛАВНЫЙ РАДИУС
    const double moundHeight = 20.0;
    const double moundWidth = (buttonRadius * 2) + 30.0; // (25*2)+30 = 80.0
    const double horizontalMargin = 10.0;

    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.black.withValues(alpha: 0.5),
        Colors.black.withValues(alpha: 0.3),
        Colors.black.withValues(alpha: 0.5),
      ],
    );

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      height: barHeight + moundHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double barWidth = constraints.maxWidth - (horizontalMargin * 2);
          final double buttonSlotWidth = barWidth / 3;

          return Stack(
            clipBehavior: Clip.none, // Оставляем
            alignment: Alignment.topCenter,
            children: [
              // --- Слой 1: ЕДИНЫЙ РАЗМЫТЫЙ БАР-БУГОРОК ---
              Positioned(
                top: 0,
                bottom: 0,
                left: 0,
                right: 0,
                child: ClipPath(
                  clipper: _UnifiedBarClipper(
                    moundIndex: selectedIndex,
                    buttonSlotWidth: buttonSlotWidth,
                    barHeight: barHeight,
                    moundHeight: moundHeight,
                    moundWidth: moundWidth,
                    horizontalMargin: horizontalMargin,
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      decoration: BoxDecoration(gradient: gradient),
                    ),
                  ),
                ),
              ),

              // --- Слой 2: Ряд с Кнопками ---
              Positioned(
                top: moundHeight,
                left: horizontalMargin,
                right: horizontalMargin,
                height: barHeight,
                child: Row(
                  children: [
                    // Слот 1
                    SizedBox(
                      width: buttonSlotWidth,
                      child: _PanelButton(
                        icon: RegistrationIcon(isSelected: false),
                        isSelected: selectedIndex == 0,
                        onTap: () => onPanelSelected(0),
                        hasActiveEvents:
                            hasEvents[model.VotingStatus.registration]! > 0,
                        buttonRadius: buttonRadius,
                      ),
                    ),
                    // Слот 2
                    SizedBox(
                      width: buttonSlotWidth,
                      child: _PanelButton(
                        icon: ActiveVotingIcon(isSelected: false),
                        isSelected: selectedIndex == 1,
                        onTap: () => onPanelSelected(1),
                        hasActiveEvents:
                            hasEvents[model.VotingStatus.active]! > 0,
                        buttonRadius: buttonRadius,
                      ),
                    ),
                    // Слот 3
                    SizedBox(
                      width: buttonSlotWidth,
                      child: _PanelButton(
                        icon: ResultsIcon(isSelected: false),
                        isSelected: selectedIndex == 2,
                        onTap: () => onPanelSelected(2),
                        hasActiveEvents:
                            hasEvents[model.VotingStatus.completed]! > 0,
                        buttonRadius: buttonRadius,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _selectedPanelIndex = 0;
  int _previousPanelIndex = 0;
  // Track number of actionable items (unregistered for registration, unvoted for active, total for completed)
  // Button is green only when there are actionable items
  final Map<model.VotingStatus, int> _actionableCount = {
    model.VotingStatus.registration: 0,
    model.VotingStatus.active: 0,
    model.VotingStatus.completed: 0,
  };
  Timer? _pollingTimer;

  // Hybrid Auto-Update Logic
  void _setupAutoUpdate() {
    if (Platform.isAndroid) {
      // Android: Use Real-Time FCM (Silent Push)
      try {
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          print('FCM message received: ${message.data}');
          if (message.data['action'] == 'REFRESH_VOTES') {
            print('FCM Refresh Triggered (Android)');
            _fetchSilent();
          }
        });
      } catch (e) {
        print('FCM Listener Error: $e');
      }
    } else if (Platform.isIOS) {
      // iOS: Fallback to Polling (every 10 seconds) due to no paid APNS
      _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
        print('iOS Polling tick: Refreshing votes...');
        _fetchSilent();
      });
    }
  }

  // Helper for background refresh without loading spinner
  // Fetches both registration and active sections to update all navigation button colors
  void _fetchSilent() {
    // Fetch registration section
    context.read<VotingBloc>().add(RefreshEventsSilent(status: model.VotingStatus.registration));
    
    // Fetch active section after a short delay
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        context.read<VotingBloc>().add(RefreshEventsSilent(status: model.VotingStatus.active));
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // Save battery when app is backgrounded
      _pollingTimer?.cancel();
    } else if (state == AppLifecycleState.resumed) {
      // Resume polling on iOS
      if (Platform.isIOS) {
        _pollingTimer?.cancel(); // Ensure no duplicates
        _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
          print('iOS Polling tick (Resumed): Refreshing votes...');
          _fetchSilent();
        });
        // Immediate fetch on resume for fresh data
        _fetchSilent();
      }
    }
  }

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

  // Handle notification taps from background/terminated state
  Future<void> _setupInteractedMessage() async {
    // Get message that terminated the app (if any)
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
    
    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }
  
  void _handleNotificationTap(RemoteMessage message) {
    print('Notification tapped: ${message.data}');
    
    // Extract tab index from message data
    final tabIndexStr = message.data['tab_index'];
    final status = message.data['status'];
    
    int? targetIndex;
    
    // Determine target index from data
    if (tabIndexStr != null) {
      targetIndex = int.tryParse(tabIndexStr);
    } else if (status != null) {
      // Map status string to index
      switch (status) {
        case 'registration':
          targetIndex = 0;
          break;
        case 'active':
          targetIndex = 1;
          break;
        case 'completed':
          targetIndex = 2;
          break;
      }
    }
    
    // Navigate to target tab if valid
    if (targetIndex != null && targetIndex >= 0 && targetIndex <= 2) {
      // Use the existing method to switch tabs
      _fetchEventsForPanel(targetIndex);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Register lifecycle observer
    
    // Print the token to the console so you can copy it
    FirebaseMessaging.instance.getToken().then((token) {
      print("==================================");
      print("MY DEVICE TOKEN:");
      print(token);
      print("==================================");
    });

    // Setup notification tap handling (background/terminated)
    _setupInteractedMessage();
    
    // Setup Hybrid Auto-Update (FCM for Android, Polling for iOS)
    _setupAutoUpdate();
    
    // Fetch initial data
    final initialStatus = [
      model.VotingStatus.registration,
      model.VotingStatus.active,
      model.VotingStatus.completed,
    ][_selectedPanelIndex];
    context.read<VotingBloc>().add(FetchEventsByStatus(status: initialStatus));
  }
  
  @override
  void dispose() {
    _pollingTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
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
                child: Center(
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
                                // - Completed: always 0 (no action needed)
                                int actionableCount;
                                if (status == model.VotingStatus.registration) {
                                  actionableCount = state.events.where((e) => !e.isRegistered).length;
                                } else if (status == model.VotingStatus.active) {
                                  actionableCount = state.events.where((e) => !e.hasVoted).length;
                                } else {
                                  actionableCount = 0; // Completed section has no actionable items
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
                                minHeight: MediaQuery.of(context).size.height * 0.5,
                                maxHeight: MediaQuery.of(context).size.height * 0.7,
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

class _PanelButton extends StatelessWidget {
  final Widget icon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool hasActiveEvents;
  final double buttonRadius;

  const _PanelButton({
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.hasActiveEvents,
    required this.buttonRadius,
  });

  @override
  Widget build(BuildContext context) {
    const Duration animDuration = Duration(milliseconds: 600);
    const double buttonPopUpHeight = 15.0;

    Color backgroundColor;
    if (hasActiveEvents) {
      backgroundColor = const Color(0xFF00A94F);
    } else {
      backgroundColor = const Color(0xFF6d9fc5);
    }

    final double buttonYTranslation = isSelected ? -buttonPopUpHeight : 0.0;
    final double scale = isSelected ? 1.0 : 0.8;

    // Иконка (1.2 * 25.0 = 30.0)
    final double iconSize = buttonRadius * 1.2;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.translucent,
      child: AnimatedContainer(
        duration: animDuration,
        curve: Curves.fastOutSlowIn,
        transform: Matrix4.translationValues(0, buttonYTranslation, 0),
        transformAlignment: Alignment.center,
        child: AnimatedScale(
          duration: animDuration,
          curve: Curves.fastOutSlowIn,
          scale: scale,
          child: CircleAvatar(
            radius: buttonRadius,
            backgroundColor: backgroundColor,
            child: IconTheme(
              data: IconTheme.of(context).copyWith(
                size: iconSize,
              ),
              child: icon,
            ),
          ),
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
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

class _EventList extends StatelessWidget {
  final model.VotingStatus status;
  final String imagePath;
  final VoidCallback onRefresh;

  const _EventList(
      {super.key,
      required this.status,
      required this.imagePath,
      required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VotingBloc, VotingState>(
      builder: (context, state) {
        if (state is VotingLoadInProgress) {
          return const SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }
        if (state is VotingEventsLoadSuccess) {
          if (state.events.isEmpty) {
            return SliverFillRemaining(
              hasScrollBody: false,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 24.0),
                margin: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 72.0),
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
                      shadows: [
                        const Shadow(blurRadius: 6, color: Colors.black87)
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          }
          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return _VotingEventCard(
                  event: state.events[index],
                  imagePath: imagePath,
                  onActionComplete: onRefresh,
                );
              },
              childCount: state.events.length,
            ),
          );
        }
        if (state is VotingFailure) {
          return SliverToBoxAdapter(
            child: Center(
              child: Text('Error: ${state.error}',
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: Colors.white)),
            ),
          );
        }
        return const SliverToBoxAdapter(child: SizedBox.shrink());
      },
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
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
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
        dateInfo = event.registrationEndDate != null
            ? l10n.registrationUntil(dateFormat.format(event.registrationEndDate!))
            : l10n.registrationOpen;
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

class _UnifiedBarClipper extends CustomClipper<Path> {
  final int moundIndex;
  final double buttonSlotWidth;
  final double barHeight;
  final double moundHeight;
  final double moundWidth;
  final double horizontalMargin;

  _UnifiedBarClipper({
    required this.moundIndex,
    required this.buttonSlotWidth,
    required this.barHeight,
    required this.moundHeight,
    required this.moundWidth,
    required this.horizontalMargin,
  });

  @override
  Path getClip(Size size) {
    // size.width - это ПОЛНАЯ ширина экрана
    final path = Path();
    final double cornerRadius = 30.0;

    // Y-координаты
    final double barTopY = moundHeight;
    final double barBottomY = moundHeight + barHeight;

    // X-координаты "виртуального" бара
    final double barLeftX = horizontalMargin;
    final double barRightX = size.width - horizontalMargin;

    // X-координаты "бугорка"
    final double moundCenterX =
        barLeftX + (moundIndex * buttonSlotWidth) + (buttonSlotWidth / 2);
    final double moundStart = moundCenterX - (moundWidth / 2);
    final double moundEnd = moundCenterX + (moundWidth / 2);

    // X-координаты углов (для проверки)
    final double topLeftCornerX = barLeftX + cornerRadius;
    final double topRightCornerX = barRightX - cornerRadius;

    // --- Рисуем путь (Новая, правильная логика v16) ---

    // 1. Начинаем с верхнего-левого угла
    path.moveTo(barLeftX, barTopY + cornerRadius);
    path.arcToPoint(
      Offset(topLeftCornerX, barTopY),
      radius: Radius.circular(cornerRadius),
      clockwise: true,
    );

    // 2. Рисуем верхнюю грань + "бугорок"
    if (moundIndex == 0) {
      path.quadraticBezierTo(moundCenterX, 0.0, moundEnd, barTopY);
      path.lineTo(topRightCornerX, barTopY);
    } else if (moundIndex == 1) {
      path.lineTo(moundStart, barTopY);
      path.quadraticBezierTo(moundCenterX, 0.0, moundEnd, barTopY);
      path.lineTo(topRightCornerX, barTopY);
    } else {
      path.lineTo(moundStart, barTopY);
      path.quadraticBezierTo(moundCenterX, 0.0, moundEnd, barTopY);
    }

    // 3. Рисуем верхний-правый угол
    path.arcToPoint(
      Offset(barRightX, barTopY + cornerRadius),
      radius: Radius.circular(cornerRadius),
      clockwise: true,
    );

    // 4. Рисуем правую грань
    path.lineTo(barRightX, barBottomY - cornerRadius);

    // 5. Рисуем нижний-правый угол
    path.arcToPoint(
      Offset(barRightX - cornerRadius, barBottomY),
      radius: Radius.circular(cornerRadius),
      clockwise: true,
    );

    // 6. Рисуем нижнюю грань
    path.lineTo(topLeftCornerX, barBottomY); // (barLeftX + cornerRadius)

    // 7. Рисуем нижний-левый угол
    path.arcToPoint(
      Offset(barLeftX, barBottomY - cornerRadius),
      radius: Radius.circular(cornerRadius),
      clockwise: true,
    );

    // 8. Замыкаем путь (рисуем левую грань)
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _UnifiedBarClipper oldClipper) {
    return oldClipper.moundIndex != moundIndex ||
        oldClipper.buttonSlotWidth != buttonSlotWidth ||
        oldClipper.moundHeight != moundHeight ||
        oldClipper.horizontalMargin != horizontalMargin;
  }
}

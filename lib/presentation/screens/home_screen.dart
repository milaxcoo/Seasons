import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:seasons/core/monthly_theme_data.dart';
import 'package:seasons/core/layout/adaptive_layout.dart';
import 'package:seasons/core/navigation/corporate_page_transition.dart';
import 'package:seasons/core/services/monthly_theme_service.dart';
import 'package:seasons/core/services/notification_navigation_service.dart';
import 'package:seasons/data/models/voting_event.dart' as model;
import 'package:seasons/presentation/bloc/auth/auth_bloc.dart';
import 'package:seasons/presentation/bloc/home_tab/home_tab_cubit.dart';
import 'package:seasons/presentation/bloc/voting/voting_bloc.dart';
import 'package:seasons/presentation/bloc/voting/voting_connection_status.dart';
import 'package:seasons/presentation/bloc/voting/voting_event.dart';
import 'package:seasons/presentation/bloc/voting/voting_state.dart';
import 'package:seasons/presentation/bloc/locale/locale_bloc.dart';
import 'package:seasons/presentation/bloc/locale/locale_event.dart';

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
  final String imagePath;

  const _TopBar({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final currentLanguageCode = Localizations.localeOf(context).languageCode;
    final adaptive = context.adaptiveLayout;
    final isLandscape = adaptive.isLandscape;

    String userLogin = 'User';
    if (authState is AuthAuthenticated) {
      userLogin = authState.userLogin;
    }

    return Padding(
      // Reduced padding in landscape to save vertical space
      padding: EdgeInsets.symmetric(
        horizontal: adaptive.homeSectionHorizontalPadding,
        vertical: isLandscape ? 0.0 : (adaptive.isExpanded ? 10.0 : 8.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Language switcher button (moved to left)
          PopupMenuButton<Locale>(
            initialValue: Locale(
              currentLanguageCode == 'en' ? 'en' : 'ru',
            ),
            icon: const Icon(Icons.language, color: Colors.white),
            onSelected: (Locale locale) {
              context.read<LocaleBloc>().add(ChangeLocale(locale));
            },
            itemBuilder: (BuildContext context) => [
              CheckedPopupMenuItem<Locale>(
                checked: currentLanguageCode == 'ru',
                value: const Locale('ru'),
                child: Row(
                  children: [
                    const Text('🇷🇺'),
                    const SizedBox(width: 8),
                    Text(AppLocalizations.of(context)!.languageRussian),
                  ],
                ),
              ),
              CheckedPopupMenuItem<Locale>(
                checked: currentLanguageCode == 'en',
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
                    buildCorporatePageRoute(
                        ProfileScreen(imagePathOverride: imagePath)),
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
                  // BlocBuilder in main.dart handles switching to LoginScreen
                  // when AuthUnauthenticated is emitted. No manual navigation needed.
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
  final VoidCallback? onDebugTap;

  const _Header({this.onDebugTap});

  @override
  Widget build(BuildContext context) {
    final adaptive = context.adaptiveLayout;
    final isLandscape = adaptive.isLandscape;

    final headerContent = Padding(
      padding: EdgeInsets.symmetric(
        vertical: adaptive.headerVerticalPadding,
      ),
      child: Column(
        children: [
          Text(
            'Seasons',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontSize: adaptive.headerTitleFontSize,
                  height: 1.0,
                  color: Colors.white,
                  shadows: [
                    const Shadow(
                        blurRadius: 15,
                        color: Colors.black87), // Stronger outer glow
                    const Shadow(
                        blurRadius: 4,
                        color: Colors.black), // Sharper inner shadow
                  ],
                  fontWeight: FontWeight.w900,
                ),
          ),
          if (!isLandscape)
            Transform.translate(
              offset: Offset(0, adaptive.headerSubtitleOffsetY),
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
                      fontSize: adaptive.headerSubtitleFontSize,
                      letterSpacing: adaptive.headerSubtitleLetterSpacing,
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
                    fontSize: adaptive.headerSubtitleFontSize,
                    letterSpacing: adaptive.headerSubtitleLetterSpacing,
                  ),
            ),
        ],
      ),
    );

    if (!kDebugMode || onDebugTap == null) {
      return headerContent;
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onDebugTap,
      child: headerContent,
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  static const Duration _sectionFadeDuration = Duration(milliseconds: 180);
  static const Duration _loaderFadeDuration = Duration(milliseconds: 120);
  static const Duration _minLoaderVisibleDuration = Duration(milliseconds: 180);
  static const Duration _sectionTransitionTimeout = Duration(seconds: 4);
  static const double _sectionSqueezedScale = 0.92;

  // Use ValueNotifier for efficient updates without rebuilding the entire tree
  final ValueNotifier<int> _timeNotifier = ValueNotifier<int>(0);

  // Track number of actionable items (unregistered for registration, unvoted for active, total for completed)
  // Button is green only when there are actionable items
  final Map<model.VotingStatus, int> _actionableCount = {
    model.VotingStatus.registration: 0,
    model.VotingStatus.active: 0,
    model.VotingStatus.completed: 0,
  };
  final Set<String> _seenCompletedEventIds = <String>{};
  final Set<String> _latestCompletedEventIds = <String>{};

  late final PageController _pageController;
  int? _pendingNavigationIndex;
  Orientation? _lastLoggedOrientation;
  Size? _lastLoggedSize;
  bool _showSectionLoader = false;
  double _sectionContentOpacity = 1.0;
  double _sectionContentScale = 1.0;
  int? _transitionTargetIndex;
  DateTime? _loaderShownAt;
  int _sectionTransitionToken = 0;
  Timer? _sectionTransitionTimeoutTimer;
  double _horizontalDragDx = 0;
  int? _debugThemeMonth;
  int? _resolvedThemeMonth;
  bool _isAppResumed = true;

  void _updateActionableCount(model.VotingStatus status, int count) {
    setState(() {
      _actionableCount[status] = count;
    });
  }

  void _debugLog(String message, [Map<String, Object?> details = const {}]) {
    if (!kDebugMode) return;
    final detailsString = details.entries
        .map((entry) => '${entry.key}=${entry.value}')
        .join(', ');
    debugPrint(
      detailsString.isEmpty
          ? 'HomeScreen.debug $message'
          : 'HomeScreen.debug $message {$detailsString}',
    );
  }

  int _normalizePanelIndex(int index) {
    if (index < 0) return 0;
    if (index > 2) return 2;
    return index;
  }

  model.VotingStatus _statusForIndex(int index) {
    return [
      model.VotingStatus.registration,
      model.VotingStatus.active,
      model.VotingStatus.completed,
    ][_normalizePanelIndex(index)];
  }

  Future<void> _switchSectionWithTransition(
    int index, {
    required String source,
  }) async {
    final normalizedIndex = _normalizePanelIndex(index);
    final currentIndex = context.read<HomeTabCubit>().state.index;
    if (normalizedIndex == currentIndex) {
      if (normalizedIndex == 2) {
        _markCompletedSectionAsViewed();
      }
      _refreshCurrentPage(normalizedIndex);
      return;
    }

    final alreadyRunningForTarget = _transitionTargetIndex == normalizedIndex;
    if (alreadyRunningForTarget) return;

    _sectionTransitionToken++;
    final token = _sectionTransitionToken;
    _sectionTransitionTimeoutTimer?.cancel();
    _sectionTransitionTimeoutTimer = Timer(_sectionTransitionTimeout, () {
      if (!mounted || _transitionTargetIndex == null) return;
      setState(() {
        _showSectionLoader = false;
        _sectionContentOpacity = 1.0;
        _sectionContentScale = 1.0;
        _transitionTargetIndex = null;
        _loaderShownAt = null;
      });
    });

    context.read<HomeTabCubit>().setIndex(
          normalizedIndex,
          source: source,
        );
    if (normalizedIndex == 2) {
      _markCompletedSectionAsViewed();
    }
    _transitionTargetIndex = normalizedIndex;
    _loaderShownAt = null;
    if (!mounted) return;
    setState(() {
      _showSectionLoader = false;
      _sectionContentOpacity = 0.0;
      _sectionContentScale = _sectionSqueezedScale;
    });

    await Future.delayed(_sectionFadeDuration);
    if (!mounted || token != _sectionTransitionToken) return;
    _movePageToIndex(
      normalizedIndex,
      source: '$source.hidden_switch',
      animate: false,
    );

    setState(() {
      _showSectionLoader = true;
      _loaderShownAt = DateTime.now();
    });
    _refreshCurrentPage(normalizedIndex);
  }

  Future<void> _completeSectionContentTransition({required int index}) async {
    if (_transitionTargetIndex != index) return;

    final token = _sectionTransitionToken;
    if (!_showSectionLoader) {
      if (!mounted || token != _sectionTransitionToken) return;
      setState(() {
        _showSectionLoader = true;
        _loaderShownAt = DateTime.now();
      });
      await Future.delayed(_loaderFadeDuration);
      if (!mounted || token != _sectionTransitionToken) return;
    }

    final shownAt = _loaderShownAt ?? DateTime.now();
    final elapsed = DateTime.now().difference(shownAt);
    final remaining = _minLoaderVisibleDuration - elapsed;
    if (remaining > Duration.zero) {
      await Future.delayed(remaining);
      if (!mounted || token != _sectionTransitionToken) return;
    }

    setState(() {
      _showSectionLoader = false;
    });
    await Future.delayed(_loaderFadeDuration);
    if (!mounted || token != _sectionTransitionToken) return;

    _sectionTransitionTimeoutTimer?.cancel();
    setState(() {
      _sectionContentOpacity = 1.0;
      _sectionContentScale = 1.0;
      _transitionTargetIndex = null;
      _loaderShownAt = null;
    });
  }

  void _handleSectionTransitionState(VotingState state) {
    final targetIndex = _transitionTargetIndex;
    if (targetIndex == null) return;

    final targetStatus = _statusForIndex(targetIndex);
    if (state is VotingEventsLoadSuccess && state.status == targetStatus) {
      _completeSectionContentTransition(index: targetIndex);
      return;
    }
    if (state is VotingFailure) {
      _completeSectionContentTransition(index: targetIndex);
    }
  }

  void _movePageToIndex(
    int index, {
    required String source,
    bool animate = true,
  }) {
    if (!_pageController.hasClients) {
      _pendingNavigationIndex = index;
      _debugLog(
        'panel_navigation_queued',
        {
          'source': source,
          'index': index,
          'reason': 'no_page_controller_clients',
        },
      );
      return;
    }

    final currentPage =
        (_pageController.page ?? _pageController.initialPage).round();
    if (currentPage == index) {
      if (source == 'user_tap') {
        _refreshCurrentPage(index);
      }
      _debugLog(
        'panel_navigation_skipped_same_page',
        {
          'source': source,
          'index': index,
        },
      );
      return;
    }

    _pendingNavigationIndex = null;
    _debugLog(
      'panel_navigation_execute',
      {
        'source': source,
        'index': index,
        'animate': animate,
      },
    );

    if (animate) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutQuart,
      );
      return;
    }
    _pageController.jumpToPage(index);
  }

  void _flushPendingNavigationIfNeeded({
    required String source,
  }) {
    final pendingIndex = _pendingNavigationIndex;
    if (pendingIndex == null) return;
    _debugLog(
      'panel_navigation_flush_pending',
      {
        'source': source,
        'index': pendingIndex,
      },
    );
    _movePageToIndex(
      pendingIndex,
      source: '$source.pending_flush',
      animate: false,
    );
  }

  void _onPanelSelected(int index) {
    _debugLog(
      'panel_tap',
      {
        'index': index,
      },
    );
    _switchSectionWithTransition(
      index,
      source: 'user_tap',
    );
  }

  void _cycleDebugThemeMonth() {
    if (!kDebugMode) return;
    final themeService = context.read<MonthlyThemeService>();
    final currentMonth = _debugThemeMonth ?? themeService.currentMonth;
    final nextMonth = currentMonth == 12 ? 1 : currentMonth + 1;
    if (!mounted) return;
    setState(() {
      _debugThemeMonth = nextMonth;
    });
    _debugLog(
      'debug_theme_cycle',
      {'month': nextMonth},
    );
  }

  void _onPageChanged(int index) {
    _debugLog(
      'page_changed',
      {
        'index': index,
      },
    );
    context.read<HomeTabCubit>().setIndex(
          index,
          source: 'page_sync',
        );
    if (index == 2) {
      _markCompletedSectionAsViewed();
    }
  }

  void _markCompletedSectionAsViewed() {
    if (_latestCompletedEventIds.isNotEmpty) {
      _seenCompletedEventIds.addAll(_latestCompletedEventIds);
    }
    if ((_actionableCount[model.VotingStatus.completed] ?? 0) == 0) {
      return;
    }
    setState(() {
      _actionableCount[model.VotingStatus.completed] = 0;
    });
  }

  void _onVotingAreaHorizontalDragStart(DragStartDetails details) {
    _horizontalDragDx = 0;
  }

  void _onVotingAreaHorizontalDragUpdate(DragUpdateDetails details) {
    _horizontalDragDx += details.delta.dx;
  }

  void _onVotingAreaHorizontalDragCancel() {
    _horizontalDragDx = 0;
  }

  void _onVotingAreaHorizontalDragEnd(DragEndDetails details) {
    if (_showSectionLoader) {
      _horizontalDragDx = 0;
      return;
    }

    final velocity = details.primaryVelocity ?? 0;
    int direction = 0;
    if (velocity.abs() > 350) {
      direction = velocity < 0 ? 1 : -1;
    } else if (_horizontalDragDx.abs() > 56) {
      direction = _horizontalDragDx < 0 ? 1 : -1;
    }
    _horizontalDragDx = 0;

    if (direction == 0) return;

    final currentIndex = context.read<HomeTabCubit>().state.index;
    final targetIndex = _normalizePanelIndex(currentIndex + direction);
    if (targetIndex == currentIndex) return;

    _switchSectionWithTransition(
      targetIndex,
      source: 'user_swipe',
    );
  }

  void _refreshCurrentPage(int index) {
    final status = _statusForIndex(index);
    context.read<VotingBloc>().add(FetchEventsByStatus(status: status));
  }

  void _handleNotificationNavigation(
    NotificationNavigationEvent event, {
    required String source,
  }) {
    if (!mounted) return;

    _debugLog(
      'notification_navigation_received',
      {
        'tab_index': event.tabIndex,
        'should_refresh': event.shouldRefresh,
        'source': source,
      },
    );
    final currentIndex = context.read<HomeTabCubit>().state.index;
    if (event.tabIndex == currentIndex) {
      if (event.shouldRefresh) {
        _refreshCurrentPage(event.tabIndex);
      }
      return;
    }
    _switchSectionWithTransition(
      event.tabIndex,
      source: source,
    );
  }

  bool _isHomeRouteActive() {
    final route = ModalRoute.of(context);
    if (route == null) return true;
    return route.isCurrent;
  }

  Timer? _uiTicker;
  StreamSubscription? _navigationSubscription;
  StreamSubscription<void>? _authInvalidSubscription;
  StreamSubscription<VotingConnectionStatus>? _connectionStatusSubscription;
  bool _authInvalidHandled = false;
  VotingConnectionStatus? _connectionOverlayStatus;
  Timer? _postReconnectSectionRefreshTimer;
  bool _needsSectionRefreshAfterReconnect = false;

  bool _isConnectionOverlayBlocking(VotingConnectionStatus? status) {
    if (status == null) return false;
    return status == VotingConnectionStatus.waitingForNetwork ||
        status == VotingConnectionStatus.reconnecting ||
        status == VotingConnectionStatus.syncing ||
        status == VotingConnectionStatus.disconnected;
  }

  String? _connectionStatusTitleFor(
    VotingConnectionStatus? status,
    AppLocalizations l10n,
  ) {
    switch (status) {
      case VotingConnectionStatus.waitingForNetwork:
        return l10n.waitingForNetwork;
      case VotingConnectionStatus.reconnecting:
        return l10n.reconnecting;
      case VotingConnectionStatus.syncing:
        return l10n.syncingUpdates;
      case VotingConnectionStatus.restored:
        return l10n.connectionRestored;
      case VotingConnectionStatus.disconnected:
        return l10n.connectivityIssue;
      case VotingConnectionStatus.connected:
      case null:
        return null;
    }
  }

  void _schedulePostReconnectSectionRefresh() {
    _postReconnectSectionRefreshTimer?.cancel();
    _postReconnectSectionRefreshTimer = Timer(
      const Duration(milliseconds: 700),
      () {
        if (!mounted) return;
        final currentIndex = context.read<HomeTabCubit>().state.index;
        _refreshCurrentPage(currentIndex);
      },
    );
  }

  void _handleConnectionStatus(VotingConnectionStatus status) {
    if (!mounted) return;

    final isDegraded = status == VotingConnectionStatus.waitingForNetwork ||
        status == VotingConnectionStatus.reconnecting ||
        status == VotingConnectionStatus.syncing ||
        status == VotingConnectionStatus.disconnected;
    if (isDegraded) {
      _needsSectionRefreshAfterReconnect = true;
    }

    if (status == VotingConnectionStatus.restored &&
        _needsSectionRefreshAfterReconnect) {
      _needsSectionRefreshAfterReconnect = false;
      _schedulePostReconnectSectionRefresh();
    }

    if (status == VotingConnectionStatus.connected) {
      if (_needsSectionRefreshAfterReconnect) {
        _needsSectionRefreshAfterReconnect = false;
        _schedulePostReconnectSectionRefresh();
      }
      if (_connectionOverlayStatus != null) {
        setState(() {
          _connectionOverlayStatus = null;
        });
      }
      return;
    }

    if (_connectionOverlayStatus == status) {
      return;
    }

    setState(() {
      _connectionOverlayStatus = status;
    });
  }

  void _handleAuthInvalid() {
    if (!mounted || _authInvalidHandled) return;
    _authInvalidHandled = true;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l10n.sessionExpiredReLogin),
          backgroundColor: AppTheme.rudnRedColor,
        ),
      );
    context.read<AuthBloc>().add(LoggedOut());
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final initialIndex = context.read<HomeTabCubit>().state.index;
    _pageController = PageController(initialPage: initialIndex);
    _resolvedThemeMonth = context.read<MonthlyThemeService>().currentMonth;
    _debugLog(
      'init_state',
      {
        'initial_index': initialIndex,
      },
    );

    // Listen for notification navigation events
    final navigationService = NotificationNavigationService();
    _navigationSubscription = navigationService.onNavigate.listen((event) {
      _handleNotificationNavigation(
        event,
        source: 'notification_live',
      );
    });

    final pendingNavigation = navigationService.consumePendingNavigation();
    if (pendingNavigation != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleNotificationNavigation(
          pendingNavigation,
          source: 'notification_replay',
        );
      });
    }

    _authInvalidSubscription = context.read<VotingBloc>().onAuthInvalid.listen(
          (_) => _handleAuthInvalid(),
        );
    final votingBloc = context.read<VotingBloc>();
    _handleConnectionStatus(votingBloc.currentConnectionStatus);
    _connectionStatusSubscription =
        votingBloc.connectionStatusStream.listen(_handleConnectionStatus);

    // UI Ticker: Updates every 1 second to handle time-based UI changes instantly
    // e.g. "Registration closes in..." or switching from Open to Closed based on local time
    _uiTicker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted || !_isAppResumed || !_isHomeRouteActive()) return;
      // Notify listeners (VotingCards) without rebuilding the whole HomeScreen
      _timeNotifier.value++;

      final latestMonth = context.read<MonthlyThemeService>().currentMonth;
      if (_resolvedThemeMonth != latestMonth) {
        _resolvedThemeMonth = latestMonth;
        setState(() {});
      }
    });

    // Fetch initial data for all sections to populate button colors
    context
        .read<VotingBloc>()
        .add(FetchEventsByStatus(status: model.VotingStatus.registration));
    context
        .read<VotingBloc>()
        .add(RefreshEventsSilent(status: model.VotingStatus.active));
    context
        .read<VotingBloc>()
        .add(RefreshEventsSilent(status: model.VotingStatus.completed));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _flushPendingNavigationIfNeeded(source: 'post_frame_init');
    });
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    if (!mounted) return;

    final view = View.of(context);
    final logicalSize = view.physicalSize / view.devicePixelRatio;
    final orientation = logicalSize.width >= logicalSize.height
        ? Orientation.landscape
        : Orientation.portrait;
    _debugLog(
      'metrics_changed',
      {
        'orientation': orientation.name,
        'size': '${logicalSize.width.toStringAsFixed(1)}x'
            '${logicalSize.height.toStringAsFixed(1)}',
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final targetIndex = context.read<HomeTabCubit>().state.index;
      _movePageToIndex(
        targetIndex,
        source: 'metrics_sync',
        animate: false,
      );
      _flushPendingNavigationIfNeeded(source: 'metrics_sync');
      _refreshCurrentPage(targetIndex);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final resumed = state == AppLifecycleState.resumed;
    if (_isAppResumed == resumed) return;
    _isAppResumed = resumed;
    if (!mounted || !resumed) return;
    _timeNotifier.value++;
    _resolvedThemeMonth = context.read<MonthlyThemeService>().currentMonth;
    _refreshCurrentPage(context.read<HomeTabCubit>().state.index);
    setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    _uiTicker?.cancel();
    _sectionTransitionTimeoutTimer?.cancel();
    _navigationSubscription?.cancel();
    _authInvalidSubscription?.cancel();
    _connectionStatusSubscription?.cancel();
    _postReconnectSectionRefreshTimer?.cancel();
    _timeNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeService = context.read<MonthlyThemeService>();
    final theme = (kDebugMode && _debugThemeMonth != null)
        ? (monthlyThemes[_debugThemeMonth!] ?? themeService.theme)
        : themeService.theme;
    final VoidCallback? debugThemeTapHandler =
        kDebugMode ? _cycleDebugThemeMonth : null;
    final selectedPanelIndex =
        context.select((HomeTabCubit cubit) => cubit.state.index);

    final adaptive = context.adaptiveLayout;
    final navDimensions = adaptive.navDimensions;
    final overlayDimensions = adaptive.overlayDimensions;
    final mediaQuery = MediaQuery.of(context);
    final isLandscape = mediaQuery.orientation == Orientation.landscape;
    final l10n = AppLocalizations.of(context)!;
    final overlayStatus = _connectionOverlayStatus;
    final overlayTitle = _connectionStatusTitleFor(overlayStatus, l10n);
    final shouldShowOverlay = overlayStatus != null && overlayTitle != null;
    final shouldBlockContentForConnection =
        shouldShowOverlay || _isConnectionOverlayBlocking(overlayStatus);

    if (kDebugMode &&
        (_lastLoggedOrientation != mediaQuery.orientation ||
            _lastLoggedSize != mediaQuery.size)) {
      _lastLoggedOrientation = mediaQuery.orientation;
      _lastLoggedSize = mediaQuery.size;
      _debugLog(
        'build_orientation_snapshot',
        {
          'orientation': mediaQuery.orientation.name,
          'size': '${mediaQuery.size.width.toStringAsFixed(1)}x'
              '${mediaQuery.size.height.toStringAsFixed(1)}',
          'selected_index': selectedPanelIndex,
          'tap_blocking_overlay': shouldBlockContentForConnection,
        },
      );
    }

    // --- UI COMPONENTS ---

    // 1. Top Bar (Profile / Lang)
    final topBar = _TopBar(imagePath: theme.imagePath);

    // 2. Header (Seasons Title)
    final Widget landscapeHeader = Stack(
      alignment: Alignment.center,
      children: [
        IgnorePointer(
          child: Padding(
            padding: EdgeInsets.only(top: adaptive.headerVerticalPadding + 1),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Seasons',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontSize: adaptive.headerTitleFontSize,
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
                          fontSize: adaptive.headerSubtitleFontSize,
                          letterSpacing: adaptive.headerSubtitleLetterSpacing,
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
    );
    final Widget header = isLandscape
        ? (debugThemeTapHandler == null
            ? landscapeHeader
            : GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: debugThemeTapHandler,
                child: landscapeHeader,
              ))
        : _Header(onDebugTap: debugThemeTapHandler);

    // 3. Navbar (Panel Selector)
    final navbar = BlocListener<VotingBloc, VotingState>(
      listener: (context, state) {
        if (state is VotingEventsLoadSuccess) {
          final status = state.status;
          final currentIndex = context.read<HomeTabCubit>().state.index;
          int actionableCount;
          if (status == model.VotingStatus.registration) {
            actionableCount = state.events
                .where((e) =>
                    !e.isRegistered &&
                    (e.registrationEndDate == null ||
                        !DateTime.now().isAfter(e.registrationEndDate!)))
                .length;
          } else if (status == model.VotingStatus.active) {
            actionableCount = state.events
                .where((e) =>
                    !e.hasVoted &&
                    (e.votingEndDate == null ||
                        !DateTime.now().isAfter(e.votingEndDate!)))
                .length;
          } else {
            _latestCompletedEventIds
              ..clear()
              ..addAll(state.events.map((event) => event.id));
            if (currentIndex == 2) {
              _seenCompletedEventIds.addAll(_latestCompletedEventIds);
              actionableCount = 0;
            } else {
              actionableCount = state.events
                  .where((event) => !_seenCompletedEventIds.contains(event.id))
                  .length;
            }
          }
          _updateActionableCount(status, actionableCount);
        }
      },
      child: AnimatedPanelSelector(
        selectedIndex: selectedPanelIndex,
        onPanelSelected: _onPanelSelected,
        hasEvents: _actionableCount,
        totalHeight: navDimensions.totalHeight,
        barHeight: navDimensions.barHeight,
        bumpHeight: navDimensions.bumpHeight,
        buttonRadius: navDimensions.buttonRadius,
        verticalMargin: navDimensions.verticalMargin,
        maxWidth: navDimensions.maxWidth,
        internalHorizontalPadding: navDimensions.internalHorizontalPadding,
        selectedScale: navDimensions.selectedScale,
        unselectedScale: navDimensions.unselectedScale,
        iconScaleFactor: navDimensions.iconScaleFactor,
      ),
    );

    // 4. Voting List (The Main Content) - WITHOUT Expanded wrapper here
    final votingListContent = Padding(
      padding: EdgeInsets.symmetric(
          horizontal: adaptive.homeSectionHorizontalPadding),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: adaptive.homeListMaxWidth),
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
            child: Stack(
              fit: StackFit.expand,
              children: [
                AbsorbPointer(
                  key: ValueKey(
                    'connection_content_absorb_${shouldBlockContentForConnection ? 'on' : 'off'}',
                  ),
                  absorbing: _transitionTargetIndex != null ||
                      shouldBlockContentForConnection,
                  child: AnimatedScale(
                    scale: _sectionContentScale,
                    duration: _sectionFadeDuration,
                    curve: Curves.easeOutCubic,
                    child: AnimatedOpacity(
                      opacity: shouldBlockContentForConnection
                          ? 0.0
                          : _sectionContentOpacity,
                      duration: _sectionFadeDuration,
                      curve: Curves.easeOut,
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onHorizontalDragStart: _onVotingAreaHorizontalDragStart,
                        onHorizontalDragUpdate:
                            _onVotingAreaHorizontalDragUpdate,
                        onHorizontalDragCancel:
                            _onVotingAreaHorizontalDragCancel,
                        onHorizontalDragEnd: _onVotingAreaHorizontalDragEnd,
                        child: PageView.builder(
                          controller: _pageController,
                          physics: const NeverScrollableScrollPhysics(),
                          onPageChanged: _onPageChanged,
                          itemCount: 3,
                          itemBuilder: (context, index) {
                            return _EventListPage(
                              status: _statusForIndex(index),
                              imagePath: theme.imagePath,
                              onRefresh: () => _refreshCurrentPage(index),
                              timeNotifier: _timeNotifier,
                              suppressTransitions:
                                  _transitionTargetIndex != null ||
                                      _showSectionLoader,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                AnimatedSwitcher(
                  duration: _loaderFadeDuration,
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: !_showSectionLoader || shouldShowOverlay
                      ? const SizedBox.shrink(
                          key: ValueKey('section_loader_off'))
                      : IgnorePointer(
                          key: const ValueKey('section_loader_on'),
                          child: Container(
                            color: Colors.transparent,
                            child: const Center(
                              child: SeasonsLoader(size: 64),
                            ),
                          ),
                        ),
                ),
                IgnorePointer(
                  ignoring: true,
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 240),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) {
                        final squeezeAnimation = TweenSequence<double>([
                          TweenSequenceItem(
                            tween: Tween<double>(
                              begin: _sectionSqueezedScale,
                              end: 1.02,
                            ).chain(
                              CurveTween(curve: Curves.easeOutCubic),
                            ),
                            weight: 70,
                          ),
                          TweenSequenceItem(
                            tween: Tween<double>(
                              begin: 1.02,
                              end: 1.0,
                            ).chain(
                              CurveTween(curve: Curves.easeInOutCubic),
                            ),
                            weight: 30,
                          ),
                        ]).animate(animation);
                        return FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: squeezeAnimation,
                            child: child,
                          ),
                        );
                      },
                      child: !shouldShowOverlay
                          ? const SizedBox.shrink(
                              key: ValueKey('connection_status_overlay_hidden'),
                            )
                          : Padding(
                              key: ValueKey(
                                'connection_status_overlay_${overlayStatus.name}',
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: overlayDimensions.horizontalPadding,
                              ),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: overlayDimensions.maxWidth,
                                ),
                                child: SizedBox(
                                  key: const ValueKey(
                                      'connection_status_overlay_content'),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        key: const ValueKey(
                                            'connection_status_overlay_loader'),
                                        width: overlayDimensions.loaderSize,
                                        height: overlayDimensions.loaderSize,
                                        child: SeasonsLoader(
                                          size: overlayDimensions.loaderSize,
                                        ),
                                      ),
                                      SizedBox(height: overlayDimensions.gap),
                                      Text(
                                        overlayTitle,
                                        key: const ValueKey(
                                            'connection_status_overlay_text'),
                                        maxLines: overlayDimensions.maxLines,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.copyWith(
                                          color: Colors.white,
                                          fontSize: overlayDimensions.textSize,
                                          shadows: [
                                            const Shadow(
                                              blurRadius: 6,
                                              color: Colors.black87,
                                            ),
                                          ],
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
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
          ),
        ),
      ),
    );

    // 5. Footer (Poem)
    // Pass isLandscape=false to footer when in split-view so it doesn't limit height
    // Actually, we will just use the footer widget and rely on layout constraints
    final footer = _Footer(poem: theme.poem, author: theme.author);

    Widget content = BlocListener<VotingBloc, VotingState>(
      listenWhen: (previous, current) =>
          current is VotingEventsLoadSuccess || current is VotingFailure,
      listener: (context, state) {
        _handleSectionTransitionState(state);
      },
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
                bottom:
                    true, // Enable bottom safe area for Galaxy Fold / Android Gestures
                left: true,
                right: true,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: adaptive.outerHorizontalPadding,
                  ),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: adaptive.homeContentMaxWidth,
                      ),
                      child: isLandscape
                          // LANDSCAPE: Adaptive split layout
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  flex: adaptive.homeLandscapeListFlex,
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: adaptive
                                          .homeListSectionVerticalPadding,
                                    ),
                                    child: votingListContent,
                                  ),
                                ),
                                Expanded(
                                  flex: adaptive.homeLandscapeSidebarFlex,
                                  child: Column(
                                    children: [
                                      topBar,
                                      Expanded(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            header,
                                            SizedBox(
                                              height: adaptive.headerToNavGap,
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 6.0,
                                              ),
                                              child: navbar,
                                            ),
                                            SizedBox(
                                              height: adaptive.headerToNavGap,
                                            ),
                                            Expanded(child: footer),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          // PORTRAIT: Stacked Layout
                          : Column(
                              children: [
                                topBar,
                                header,
                                navbar,
                                Expanded(child: votingListContent),
                                footer,
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

    if (kDebugMode) {
      content = Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (event) {
          _debugLog(
            'pointer_down',
            {
              'x': event.position.dx.toStringAsFixed(1),
              'y': event.position.dy.toStringAsFixed(1),
              'selected_index': selectedPanelIndex,
            },
          );
        },
        child: content,
      );
    }

    return AppBackground(
      imagePath: theme.imagePath,
      child: content,
    );
  }
}

class _Footer extends StatefulWidget {
  final String poem;
  final String author;

  const _Footer({required this.poem, required this.author});

  @override
  State<_Footer> createState() => _FooterState();
}

class _FooterState extends State<_Footer> with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  bool _isUserScrolling = false;
  bool _isAutoScrollAnimating = false;
  bool _showTopFade = false;
  bool _showBottomFade = false;
  bool _isAppResumed = true;
  Timer? _resumeTimer;
  int _scrollGeneration = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_handleScrollMetricsChanged);
    // Start rolling after a short delay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleScrollMetricsChanged();
      _resumeAutoScroll(delay: const Duration(seconds: 3));
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _resumeTimer?.cancel();
    _scrollController.removeListener(_handleScrollMetricsChanged);
    _scrollController.dispose();
    super.dispose();
  }

  bool _isRouteActive() {
    final route = ModalRoute.of(context);
    if (route == null) return true;
    return route.isCurrent;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    _isAppResumed = state == AppLifecycleState.resumed;
    if (!_isAppResumed) {
      _resumeTimer?.cancel();
      _isAutoScrollAnimating = false;
      return;
    }
    _resumeAutoScroll(delay: const Duration(seconds: 2));
  }

  @override
  void didUpdateWidget(covariant _Footer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the poem changes (e.g. month changes), reset scroll and invalidate
    // any in-flight animateTo callbacks by bumping the generation.
    if (oldWidget.poem != widget.poem) {
      _scrollGeneration++;
      _isAutoScrollAnimating = false;
      _resumeTimer?.cancel();
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
      _handleScrollMetricsChanged();
      _resumeAutoScroll(delay: const Duration(seconds: 3));
    }
  }

  void _handleScrollMetricsChanged() {
    if (!mounted || !_scrollController.hasClients) return;
    final position = _scrollController.position;
    final showTop = position.pixels > 1;
    final showBottom = position.pixels < (position.maxScrollExtent - 1);
    if (showTop == _showTopFade && showBottom == _showBottomFade) return;
    setState(() {
      _showTopFade = showTop;
      _showBottomFade = showBottom;
    });
  }

  void _ensureAutoScrollRunning() {
    if (!mounted ||
        !_isAppResumed ||
        !_isRouteActive() ||
        _isUserScrolling ||
        _isAutoScrollAnimating) {
      return;
    }
    if (_resumeTimer?.isActive ?? false) return;
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.maxScrollExtent <= 0) return;
    _resumeAutoScroll(delay: const Duration(milliseconds: 250));
  }

  void _resumeAutoScroll({Duration delay = const Duration(seconds: 2)}) {
    _resumeTimer?.cancel();
    final generation = _scrollGeneration;
    _resumeTimer = Timer(delay, () {
      if (mounted &&
          _isAppResumed &&
          _isRouteActive() &&
          !_isUserScrolling &&
          _scrollController.hasClients &&
          _scrollGeneration == generation) {
        _scrollLoop(generation);
      }
    });
  }

  void _scrollLoop(int generation) {
    if (!mounted ||
        !_isAppResumed ||
        !_isRouteActive() ||
        _isUserScrolling ||
        !_scrollController.hasClients ||
        _scrollGeneration != generation) {
      return;
    }

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    final remainingScroll = maxScroll - currentScroll;

    if (remainingScroll > 0) {
      // Very slow speed: 10 pixels per second
      final duration =
          Duration(milliseconds: (remainingScroll / 10 * 1000).toInt());

      _isAutoScrollAnimating = true;
      _scrollController
          .animateTo(
            maxScroll,
            duration: duration,
            curve: Curves.linear,
          )
          .catchError((_) {})
          .then((_) {
        if (!mounted ||
            _isUserScrolling ||
            !_scrollController.hasClients ||
            _scrollGeneration != generation) {
          return;
        }
        if (_scrollController.offset >=
            _scrollController.position.maxScrollExtent) {
          _resumeTimer?.cancel();
          _resumeTimer = Timer(const Duration(seconds: 5), () {
            if (mounted &&
                !_isUserScrolling &&
                _scrollController.hasClients &&
                _scrollGeneration == generation) {
              _scrollController.jumpTo(0);
              _resumeAutoScroll(delay: const Duration(seconds: 1));
            }
          });
        }
      }).whenComplete(() {
        _isAutoScrollAnimating = false;
        _ensureAutoScrollRunning();
      });
    } else {
      _resumeTimer?.cancel();
      _resumeTimer = Timer(const Duration(seconds: 5), () {
        if (mounted &&
            !_isUserScrolling &&
            _scrollController.hasClients &&
            _scrollGeneration == generation) {
          _scrollController.jumpTo(0);
          _resumeAutoScroll(delay: const Duration(seconds: 1));
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final adaptive = context.adaptiveLayout;
    final isLandscape = adaptive.isLandscape;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        adaptive.homeSectionHorizontalPadding,
        isLandscape ? 4.0 : 4.0,
        adaptive.homeSectionHorizontalPadding,
        isLandscape
            ? (adaptive.isExpanded ? 12.0 : 8.0)
            : (adaptive.isExpanded ? 30.0 : 24.0),
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
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: isLandscape
                    ? MediaQuery.of(context).size.height * 0.80
                    : (adaptive.isExpanded
                        ? 170.0
                        : adaptive.isMedium
                            ? 155.0
                            : 140.0),
              ),
              child: NotificationListener<ScrollNotification>(
                onNotification: (ScrollNotification notification) {
                  if (notification is ScrollStartNotification &&
                      notification.dragDetails != null) {
                    _isUserScrolling = true;
                    _isAutoScrollAnimating = false;
                    _resumeTimer?.cancel();
                  } else if (notification is UserScrollNotification &&
                      notification.direction != ScrollDirection.idle) {
                    _isUserScrolling = true;
                    _resumeTimer?.cancel();
                  } else if (notification is UserScrollNotification &&
                      notification.direction == ScrollDirection.idle) {
                    _isUserScrolling = false;
                    _resumeAutoScroll(delay: const Duration(seconds: 3));
                  } else if (notification is ScrollEndNotification) {
                    _isUserScrolling = false;
                    _resumeAutoScroll(delay: const Duration(seconds: 3));
                  }
                  return false;
                },
                child: ShaderMask(
                  blendMode: BlendMode.dstIn,
                  shaderCallback: (Rect bounds) {
                    return LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        _showTopFade ? Colors.transparent : Colors.white,
                        Colors.white,
                        Colors.white,
                        _showBottomFade ? Colors.transparent : Colors.white,
                      ],
                      stops: const [0.0, 0.10, 0.90, 1.0],
                    ).createShader(bounds);
                  },
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.poem,
                          textAlign: TextAlign.left,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                            height: adaptive.footerPoemLineHeight,
                            fontSize: adaptive.footerPoemFontSize,
                            shadows: [
                              const Shadow(blurRadius: 6, color: Colors.black87)
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.author,
                          textAlign: TextAlign.left,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                            fontStyle: FontStyle.italic,
                            fontSize: adaptive.footerAuthorFontSize,
                            shadows: [
                              const Shadow(blurRadius: 6, color: Colors.black87)
                            ],
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

// Widget for each page in the PageView
class _EventListPage extends StatelessWidget {
  final model.VotingStatus status;
  final String imagePath;
  final VoidCallback onRefresh;
  final ValueNotifier<int> timeNotifier; // Use ValueNotifier
  final bool suppressTransitions;

  const _EventListPage({
    required this.status,
    required this.imagePath,
    required this.onRefresh,
    required this.timeNotifier,
    this.suppressTransitions = false,
  });

  @override
  Widget build(BuildContext context) {
    final adaptive = context.adaptiveLayout;
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
          if (suppressTransitions) {
            content = const SizedBox.shrink(
              key: ValueKey('loader_suppressed'),
            );
          } else {
            content = const Center(
              key: ValueKey('loader'),
              child: SeasonsLoader(),
            );
          }
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
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: adaptive.emptyStateMaxWidth,
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.noActiveVotings,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white,
                      fontSize: adaptive.emptyStateFontSize,
                      height: adaptive.emptyStateLineHeight,
                      fontWeight: FontWeight.w800,
                      shadows: [
                        const Shadow(blurRadius: 6, color: Colors.black87)
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
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
                  key: ValueKey(
                    'event_card_${state.events[index].id}_${state.timestamp}_$index',
                  ),
                  event: state.events[index],
                  sectionStatus: status,
                  imagePath: imagePath,
                  onActionComplete: onRefresh,
                  timeNotifier: timeNotifier,
                );
              },
            );
          }
        } else if (state is VotingFailure) {
          content = GestureDetector(
            key: const ValueKey('error'),
            onTap: onRefresh,
            child: Container(
              padding: const EdgeInsets.all(24.0),
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off_rounded,
                        color: Colors.white70, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      AppLocalizations.of(context)!.connectionError,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white,
                        fontSize: 18.0,
                        shadows: [
                          const Shadow(blurRadius: 6, color: Colors.black87)
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!.tapToRetry,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white60,
                            fontSize: 14.0,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        } else {
          content = const SizedBox.shrink(key: ValueKey('shrink'));
        }

        if (suppressTransitions) {
          return content;
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
  final model.VotingStatus sectionStatus;
  final String imagePath;
  final VoidCallback onActionComplete;
  final ValueNotifier<int> timeNotifier;

  const _VotingEventCard({
    super.key,
    required this.event,
    required this.sectionStatus,
    required this.imagePath,
    required this.onActionComplete,
    required this.timeNotifier,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final dateFormat =
        DateFormat.yMMMd(locale.languageCode == 'ru' ? 'ru' : 'en');
    final l10n = AppLocalizations.of(context)!;
    String dateInfo;

    switch (sectionStatus) {
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
            if (sectionStatus == model.VotingStatus.registration ||
                sectionStatus == model.VotingStatus.active) ...[
              const SizedBox(height: 2),
              ValueListenableBuilder<int>(
                  valueListenable: timeNotifier,
                  builder: (context, _, __) {
                    return Text(
                      sectionStatus == model.VotingStatus.registration
                          ? (event.isRegistered
                              ? AppLocalizations.of(context)!.registered
                              : AppLocalizations.of(context)!.notRegistered)
                          : (event.hasVoted
                              ? AppLocalizations.of(context)!.voted
                              : AppLocalizations.of(context)!.notVoted),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: (sectionStatus ==
                                        model.VotingStatus.registration
                                    ? event.isRegistered
                                    : event.hasVoted)
                                ? AppTheme.rudnGreenColor
                                : AppTheme.rudnRedColor,
                            fontWeight: FontWeight.w500,
                          ),
                    );
                  }),
            ],
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.black54),
        onTap: () async {
          final Widget detailsScreen;
          if (sectionStatus == model.VotingStatus.registration) {
            detailsScreen =
                RegistrationDetailsScreen(event: event, imagePath: imagePath);
          } else if (sectionStatus == model.VotingStatus.active) {
            detailsScreen =
                VotingDetailsScreen(event: event, imagePath: imagePath);
          } else {
            detailsScreen = ResultsScreen(event: event, imagePath: imagePath);
          }

          final result = await Navigator.of(context).push(
            buildCorporatePageRoute(detailsScreen),
          );

          if (result == true) {
            onActionComplete();
          }
        },
      ),
    );
  }
}

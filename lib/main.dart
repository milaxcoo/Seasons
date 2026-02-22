import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:seasons/core/services/app_install_service.dart';
import 'package:seasons/core/services/background_service.dart';
import 'package:seasons/core/services/error_reporting_service.dart';
import 'package:seasons/core/services/notification_navigation_service.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:async';

import 'package:seasons/core/theme.dart';
import 'package:seasons/data/repositories/api_voting_repository.dart';
import 'package:seasons/data/repositories/voting_repository.dart';
import 'package:seasons/presentation/bloc/auth/auth_bloc.dart';
import 'package:seasons/presentation/bloc/auth/auth_background_service_gate.dart';
import 'package:seasons/presentation/bloc/voting/voting_bloc.dart';
import 'package:seasons/presentation/screens/home_screen.dart';
import 'package:seasons/presentation/screens/login_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:seasons/presentation/bloc/locale/locale_bloc.dart';
import 'package:seasons/presentation/bloc/locale/locale_event.dart';
import 'package:seasons/presentation/bloc/locale/locale_state.dart';
import 'package:seasons/l10n/app_localizations.dart';
import 'package:seasons/presentation/widgets/seasons_loader.dart';
import 'package:seasons/core/utils/safe_log.dart';

/// Global notification plugin for handling taps
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// App version for error reporting
const String appVersion = '1.1.0+9';

void main() async {
  // Run app inside error-catching zone
  await runZonedGuarded(() async {
    try {
      WidgetsFlutterBinding.ensureInitialized();

      // Initialize error reporting service
      await ErrorReportingService().initialize(appVersion: appVersion);

      // Set up Flutter framework error handler
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        ErrorReportingService().reportFlutterError(details);
      };

      await initializeDateFormatting('ru_RU', null);
      await initializeDateFormatting('en_US', null);
      await AppInstallService().ensureInstallConsistency();

      runApp(const SeasonsApp());

      // Post-launch initialization
      await _initializeNotifications();
    } catch (e, stackTrace) {
      debugPrint('Не удалось инициализировать приложение: $e');
      ErrorReportingService().reportCrash(e, stackTrace);
    }
  }, (error, stackTrace) {
    // Catch any unhandled async errors
    debugPrint('Unhandled error: $error');
    ErrorReportingService().reportCrash(error, stackTrace);
  });
}

/// Initialize local notifications with tap response handler
Future<void> _initializeNotifications() async {
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosSettings = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  const initSettings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: _onNotificationTapped,
  );

  // Check if app was launched from notification
  final launchDetails =
      await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
  if (launchDetails?.didNotificationLaunchApp ?? false) {
    final payload = launchDetails?.notificationResponse?.payload;
    if (payload != null) {
      _handleNotificationPayload(payload);
    }
  }
}

/// Called when user taps a notification
void _onNotificationTapped(NotificationResponse response) {
  final payload = response.payload;
  if (payload != null) {
    _handleNotificationPayload(payload);
  }
}

/// Parse notification payload and navigate accordingly
void _handleNotificationPayload(String payload) {
  if (kDebugMode) {
    debugPrint('Notification tapped with payload: ${redactSensitive(payload)}');
  }

  // Payload format: "Navigate:VotingList:tabIndex"
  if (payload.startsWith('Navigate:VotingList:')) {
    final parts = payload.split(':');
    if (parts.length >= 3) {
      final parsedIndex = int.tryParse(parts[2]);
      final tabIndex =
          (parsedIndex != null && parsedIndex >= 0 && parsedIndex <= 2)
              ? parsedIndex
              : 0;
      // Signal HomeScreen to navigate to this tab and refresh
      NotificationNavigationService()
          .navigateToTab(tabIndex, shouldRefresh: true);
    }
  }
}

class SeasonsApp extends StatelessWidget {
  const SeasonsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<VotingRepository>(
      create: (context) => ApiVotingRepository(),
      child: MultiBlocProvider(
        providers: [
          BlocProvider<LocaleBloc>(
            create: (context) => LocaleBloc()..add(const LoadLocale()),
          ),
          BlocProvider<AuthBloc>(
            create: (context) => AuthBloc(
              votingRepository:
                  RepositoryProvider.of<VotingRepository>(context),
            )..add(AppStarted()),
          ),
          BlocProvider<VotingBloc>(
            create: (context) => VotingBloc(
              votingRepository:
                  RepositoryProvider.of<VotingRepository>(context),
            ),
          ),
        ],
        child: BlocBuilder<LocaleBloc, LocaleState>(
          builder: (context, localeState) {
            return MaterialApp(
              title: 'Seasons',
              theme: AppTheme.lightTheme,
              debugShowCheckedModeBanner: false,
              locale: localeState.locale,
              supportedLocales: const [
                Locale('ru'),
                Locale('en'),
              ],
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: BlocListener<AuthBloc, AuthState>(
                listenWhen: (previous, current) {
                  final action = backgroundServiceActionForAuthTransition(
                    previous: previous,
                    current: current,
                  );
                  return action != AuthBackgroundServiceAction.none;
                },
                listener: (context, state) {
                  if (state is AuthAuthenticated) {
                    unawaited(
                      BackgroundService().startService(
                        reason:
                            'auth_transition:not_authenticated->authenticated',
                      ),
                    );
                  } else if (state is AuthUnauthenticated) {
                    unawaited(
                      BackgroundService().stopService(
                        reason:
                            'auth_transition:authenticated->unauthenticated',
                      ),
                    );
                  }
                },
                child: BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    if (state is AuthInitial || state is AuthChecking) {
                      return const Scaffold(
                          body: Center(child: SeasonsLoader()));
                    }
                    if (state is AuthAuthenticated) {
                      return const HomeScreen();
                    }
                    return const LoginScreen();
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

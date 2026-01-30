import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:seasons/core/services/background_service.dart';
import 'package:seasons/core/services/error_reporting_service.dart';
import 'package:seasons/core/services/notification_navigation_service.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:async';

import 'package:seasons/core/theme.dart';
import 'package:seasons/data/repositories/api_voting_repository.dart';
import 'package:seasons/data/repositories/voting_repository.dart';
import 'package:seasons/presentation/bloc/auth/auth_bloc.dart';
import 'package:seasons/presentation/bloc/voting/voting_bloc.dart';
import 'package:seasons/presentation/screens/home_screen.dart';
import 'package:seasons/presentation/screens/login_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:seasons/presentation/bloc/locale/locale_bloc.dart';
import 'package:seasons/presentation/bloc/locale/locale_event.dart';
import 'package:seasons/presentation/bloc/locale/locale_state.dart';
import 'package:seasons/l10n/app_localizations.dart';
import 'package:seasons/presentation/widgets/seasons_loader.dart';

/// Global notification plugin for handling taps
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// App version for error reporting
const String appVersion = '1.1.0+2';

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
      
      // Initialize background service for WebSocket
      // Moved AFTER runApp to prevent black screen on Android (waiting for permissions/init)
      
      runApp(const SeasonsApp());
      
      // Post-launch initialization
      await _initializeNotifications();
      await BackgroundService().initialize();
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
  final launchDetails = await flutterLocalNotificationsPlugin
      .getNotificationAppLaunchDetails();
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
  debugPrint('Notification tapped with payload: $payload');
  
  // Payload format: "Navigate:VotingList:tabIndex"
  if (payload.startsWith('Navigate:VotingList:')) {
    final parts = payload.split(':');
    if (parts.length >= 3) {
      final tabIndex = int.tryParse(parts[2]) ?? 0;
      // Signal HomeScreen to navigate to this tab and refresh
      NotificationNavigationService().navigateToTab(tabIndex, shouldRefresh: true);
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
              votingRepository: RepositoryProvider.of<VotingRepository>(context),
            )..add(AppStarted()),
          ),
          BlocProvider<VotingBloc>(
            create: (context) => VotingBloc(
              votingRepository: RepositoryProvider.of<VotingRepository>(context),
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
              home: BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  if (state is AuthInitial) {
                    return const Scaffold(
                        body: Center(child: SeasonsLoader()));
                  }
                  if (state is AuthAuthenticated) {
                    // Start background service for WebSocket connection
                    BackgroundService().startService();
                    return const HomeScreen();
                  }
                  if (state is AuthUnauthenticated) {
                    // Stop background service on logout
                    BackgroundService().stopService();
                    return const LoginScreen();
                  }
                  return const LoginScreen();
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

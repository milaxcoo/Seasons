import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart'; // 1. Add this import
import 'package:seasons/core/push_notification_service.dart'; // Corrected path
import 'package:seasons/core/theme.dart';
import 'package:seasons/data/repositories/mock_voting_repository.dart';
import 'package:seasons/data/repositories/voting_repository.dart';
import 'package:seasons/presentation/bloc/auth/auth_bloc.dart';
import 'package:seasons/presentation/bloc/voting/voting_bloc.dart';
import 'package:seasons/presentation/screens/home_screen.dart';
import 'package:seasons/presentation/screens/login_screen.dart';
import 'firebase_options.dart';

void main() async {
  try {
    // Ensure that Flutter bindings are initialized before any Flutter code is executed.
    WidgetsFlutterBinding.ensureInitialized();

    // 2. Initialize date formatting for the Russian locale.
    await initializeDateFormatting('ru_RU', null);

    // Initialize Firebase for services like push notifications.
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Run the root widget of the application.
    runApp(const SeasonsApp());
  } catch (e) {
    // If any error occurs during initialization, print it to the console.
    print('Failed to initialize app: $e');
  }
}

class SeasonsApp extends StatelessWidget {
  const SeasonsApp({super.key});

  @override
  Widget build(BuildContext context) {
    // RepositoryProvider makes the MockVotingRepository available to all
    // widgets and BLoCs down the widget tree.
    return RepositoryProvider<VotingRepository>(
      create: (context) => MockVotingRepository(),
      child: MultiBlocProvider(
        providers: [
          // The AuthBloc is created and provided here.
          // It immediately dispatches an AppStarted event to check for a stored token.
          BlocProvider<AuthBloc>(
            create: (context) => AuthBloc(
              votingRepository: RepositoryProvider.of<VotingRepository>(context),
            )..add(AppStarted()),
          ),
          // Added the BlocProvider for VotingBloc so HomeScreen can access it.
          BlocProvider<VotingBloc>(
            create: (context) => VotingBloc(
              votingRepository: RepositoryProvider.of<VotingRepository>(context),
            ),
          ),
        ],
        child: MaterialApp(
          title: 'Seasons',
          theme: AppTheme.lightTheme, // Apply the custom app theme.
          debugShowCheckedModeBanner: false,
          // BlocBuilder listens to AuthState changes to decide which screen to show.
          home: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              // While checking for the token, show a loading indicator.
              if (state is AuthInitial) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              // If a token is found, the user is authenticated. Show HomeScreen.
              if (state is AuthAuthenticated) {
                // Initialize the notification service after a successful login.
                PushNotificationService().initialize();
                return const HomeScreen();
              }
              // If no token is found or logout occurs, show LoginScreen.
              if (state is AuthUnauthenticated) {
                return const LoginScreen();
              }
              // Fallback case, should not be reached in normal flow.
              return const LoginScreen();
            },
          ),
        ),
      ),
    );
  }
}

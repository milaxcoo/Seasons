import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:seasons/core/push_notification_service.dart';
import 'package:seasons/core/theme.dart';
import 'package:seasons/data/repositories/api_voting_repository.dart';
import 'package:seasons/data/repositories/voting_repository.dart';
import 'package:seasons/presentation/bloc/auth/auth_bloc.dart';
import 'package:seasons/presentation/bloc/voting/voting_bloc.dart';
import 'package:seasons/presentation/screens/home_screen.dart';
import 'package:seasons/presentation/screens/login_screen.dart';
import 'firebase_options.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await initializeDateFormatting('ru_RU', null);
    runApp(const SeasonsApp());
  } catch (e) {
    // Error ignored in production
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
        child: MaterialApp(
          title: 'Seasons',
          theme: AppTheme.lightTheme,
          debugShowCheckedModeBanner: false,
          home: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is AuthInitial) {
                return const Scaffold(
                    body: Center(child: CircularProgressIndicator()));
              }
              if (state is AuthAuthenticated) {
                PushNotificationService().initialize();
                return const HomeScreen();
              }
              if (state is AuthUnauthenticated) {
                return const LoginScreen();
              }
              return const LoginScreen();
            },
          ),
        ),
      ),
    );
  }
}

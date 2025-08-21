import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:seasons/presentation/bloc/auth/auth_bloc.dart';
import 'package:seasons/presentation/screens/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Access the current authentication state to get user information.
    // Using context.watch will cause this widget to rebuild if the AuthState changes.
    final authState = context.watch<AuthBloc>().state;
    String userLogin = 'User'; // Default value

    if (authState is AuthAuthenticated) {
      userLogin = authState.userLogin;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      // BlocListener is used for side-effects like navigation.
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          // When the state becomes unauthenticated (after logout), navigate back to the login screen.
          if (state is AuthUnauthenticated) {
            // pushAndRemoveUntil clears the entire navigation stack, so the user
            // cannot press the back button to return to the authenticated part of the app.
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Display user's login name.
              Text(
                'Logged in as:',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                userLogin,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 48),
              // Logout Button
              ElevatedButton(
                onPressed: () {
                  // Dispatch the LoggedOut event to the AuthBloc.
                  context.read<AuthBloc>().add(LoggedOut());
                },
                // Use a different style for destructive actions.
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[700],
                ),
                child: const Text('Logout'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

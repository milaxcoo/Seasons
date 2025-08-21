import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:seasons/presentation/bloc/auth/auth_bloc.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controllers to manage the text input fields.
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    // It's important to dispose of controllers to free up resources.
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLoginButtonPressed() {
    if (_formKey.currentState!.validate()) {
      // If the form is valid, dispatch the LoggedIn event to the AuthBloc.
      context.read<AuthBloc>().add(LoggedIn(
            login: _loginController.text,
            password: _passwordController.text,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
        // The 'listener' handles one-time actions in response to state changes,
        // such as navigation or showing a SnackBar. It does not rebuild the UI.
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            // On successful login, navigate to the HomeScreen and remove the
            // login screen from the navigation stack.
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          } else if (state is AuthFailure) {
            // On login failure, show an error message.
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text('Login Failed: ${state.error}'),
                  backgroundColor: Colors.redAccent,
                ),
              );
          }
        },
        // The 'builder' is responsible for rebuilding the UI in response to state changes.
        builder: (context, state) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // App Title
                    Text(
                      'Seasons',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .headlineLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const SizedBox(height: 48),

                    // Login Text Field
                    TextFormField(
                      controller: _loginController,
                      decoration: const InputDecoration(labelText: 'Login'),
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter your login' : null,
                    ),
                    const SizedBox(height: 16),

                    // Password Text Field
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(labelText: 'Password'),
                      obscureText: true,
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter your password' : null,
                    ),
                    const SizedBox(height: 32),

                    // Sign In Button
                    // It shows a loading indicator when the state is AuthLoading.
                    state is AuthLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            onPressed: _onLoginButtonPressed,
                            child: const Text('Sign In'),
                          ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

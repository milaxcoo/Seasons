import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seasons/presentation/bloc/auth/auth_bloc.dart';
import 'package:seasons/presentation/widgets/app_background.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // This function shows the informational dialog.
  void _showRudnIdDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            "Авторизация через РУДН ID",
            style: GoogleFonts.russoOne(
              fontWeight: FontWeight.bold,
              shadows: [], // Removes any potential shadows from the theme
            ),
          ),
          content: SingleChildScrollView(
            child: Text(
              "Вы будете перенаправлены на сайт авторизации с помощью РУДН ID.\n\n"
              "Пользователям, не являющимся сотрудниками РУДН и не имеющим "
              "корпоративный аккаунт, необходимо пройти единовременную регистрацию, "
              "нажав на кнопку «Создать аккаунт в РУДН ID» на следующей странице, а "
              "затем выполнить повторный вход в систему.",
              style: GoogleFonts.russoOne(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                "Отмена",
                style: GoogleFonts.russoOne(),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close the dialog
              },
            ),
            ElevatedButton(
              child: Text(
                "Продолжить",
                style: GoogleFonts.russoOne(),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.read<AuthBloc>().add(const LoggedIn(login: "rudn_user", password: "password"));
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      imagePath: "assets/august.jpg",
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthAuthenticated) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              );
            }
          },
          // Use a Stack to layer the content and the footer
          child: Stack(
            children: [
              // Main content (Title and Button)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    // FIXED: Changed from .stretch to .center to allow containers to size themselves.
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // "Seasons" Title
                      _SkewedContainer(
                        reverse: true, // FIXED: Reversed the skew direction
                        color: const Color(0xFFD9D9D9), // Light grey
                        child: Text(
                          'Seasons',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                color: const Color(0xFF42445A),
                                fontWeight: FontWeight.w900,
                                fontSize: 40
                              ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // "Войти" Button
                      _SkewedContainer(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 30), // FIXED: Made padding smaller
                        color: const Color(0xFF4A5C7A), // Dark blue/grey
                        onTap: () => _showRudnIdDialog(context),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          // FIXED: Added this line to make the row only as wide as its children.
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Войти',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontSize: 26, // FIXED: Made font smaller
                                    color: Colors.white,
                                    fontWeight: FontWeight.w100,
                                  ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white,
                              size: 24, // FIXED: Made icon smaller
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Footer Text
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 40.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // This will use HemiHead
                      Text(
                        '© RUDN University 2025',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      // This will use HemiHead
                      Text(
                        'seasons-helpdesk@rudn.ru',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// A reusable widget for the skewed containers
class _SkewedContainer extends StatelessWidget {
  final Widget child;
  final Color color;
  final VoidCallback? onTap;
  final bool reverse;
  final EdgeInsetsGeometry padding;

  const _SkewedContainer({
    required this.child,
    required this.color,
    this.onTap,
    this.reverse = false,
    this.padding = const EdgeInsets.symmetric(vertical: 15, horizontal: 40),
  });

  @override
  Widget build(BuildContext context) {
    final skewValue = reverse ? 0.26 : -0.26;
    return GestureDetector(
      onTap: onTap,
      child: Transform(
        transform: Matrix4.skewX(skewValue), // Use the dynamic skew value
        child: Container(
          padding: padding, // Use the dynamic padding
          color: color,
          child: Transform(
            transform: Matrix4.skewX(-skewValue), // Un-skew the content
            child: child,
          ),
        ),
      ),
    );
  }
}

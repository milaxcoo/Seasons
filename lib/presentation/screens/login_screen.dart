import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:seasons/core/monthly_theme_data.dart';
import 'package:seasons/presentation/bloc/auth/auth_bloc.dart';
import 'package:seasons/presentation/widgets/app_background.dart';
import 'home_screen.dart';
import 'package:google_fonts/google_fonts.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Эта функция показывает информационный диалог
  void _showRudnIdDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            "Авторизация через РУДН ID",
            style: TextStyle(
              fontFamily: GoogleFonts.exo2().fontFamily,
              fontStyle: FontStyle.normal,
              fontWeight: FontWeight.w900,
              fontSize: 26.0,
              shadows: [],
            ),
          ),
          content: const SingleChildScrollView(
            child: Text(
              "Вы будете перенаправлены на сайт авторизации с помощью РУДН ID.\n\n"
              "Пользователям, не являющимся сотрудниками РУДН и не имеющим "
              "корпоративный аккаунт, необходимо пройти единовременную регистрацию, "
              "нажав на кнопку «Создать аккаунт в РУДН ID» на следующей странице, а "
              "затем выполнить повторный вход в систему.",
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("Отмена"),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              child: const Text("Продолжить"),
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
    // FIXED: Получаем тему из централизованного файла
    final currentMonth = DateTime.now().month;
    final theme = monthlyThemes[currentMonth] ?? monthlyThemes[10]!; // Октябрь по умолчанию

    return AppBackground(
      imagePath: theme.imagePath, // FIXED: Используем динамический фон
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
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _SkewedContainer(
                      reverse: true,
                      color: const Color(0xFFD9D9D9),
                      child: Text(
                        'Seasons',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              color: const Color(0xFF42445A),
                              fontWeight: FontWeight.w900,
                              fontSize: 40,
                            ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _SkewedContainer(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 30),
                      color: const Color(0xFF4A5C7A),
                      onTap: () => _showRudnIdDialog(context),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Войти',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: GoogleFonts.exo2().fontFamily,
                              fontStyle: FontStyle.normal,
                              fontWeight: FontWeight.w900,
                              fontSize: 26,
                              color: Colors.white,
                              shadows: [],
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white,
                            size: 24,
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 40.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '© RUDN University 2025',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 8),
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

// Вспомогательный виджет для "скошенных" контейнеров
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
        transform: Matrix4.skewX(skewValue),
        child: Container(
          padding: padding,
          color: color,
          child: Transform(
            transform: Matrix4.skewX(-skewValue),
            child: child,
          ),
        ),
      ),
    );
  }
}
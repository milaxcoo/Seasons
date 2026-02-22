import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:seasons/core/services/monthly_theme_service.dart';
import 'package:seasons/presentation/bloc/auth/auth_bloc.dart';
import 'package:seasons/presentation/bloc/locale/locale_bloc.dart';
import 'package:seasons/presentation/bloc/locale/locale_event.dart';
import 'package:seasons/presentation/widgets/app_background.dart';

import 'package:google_fonts/google_fonts.dart';
import 'rudn_webview_screen.dart';
import 'package:seasons/l10n/app_localizations.dart';
import 'package:seasons/presentation/widgets/seasons_loader.dart';
import 'package:seasons/core/services/error_reporting_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  static const Duration _entryAnimationDuration = Duration(milliseconds: 700);
  static const double _initialBlurSigma = 22;

  late final AnimationController _entryAnimationController;
  late final Animation<double> _blurSigmaAnimation;
  late final Animation<double> _contentOpacityAnimation;
  late final Animation<Offset> _contentSlideAnimation;
  bool _didPrecacheBackground = false;

  @override
  void initState() {
    super.initState();
    _entryAnimationController = AnimationController(
      vsync: this,
      duration: _entryAnimationDuration,
    );
    _blurSigmaAnimation = Tween<double>(
      begin: _initialBlurSigma,
      end: 0,
    ).animate(
      CurvedAnimation(
        parent: _entryAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );
    _contentOpacityAnimation = CurvedAnimation(
      parent: _entryAnimationController,
      curve: const Interval(0.18, 1, curve: Curves.easeOutCubic),
    );
    _contentSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.02),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entryAnimationController,
        curve: const Interval(0.12, 1, curve: Curves.easeOutCubic),
      ),
    );
    _entryAnimationController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didPrecacheBackground) return;
    final monthlyThemeService = context.read<MonthlyThemeService>();
    precacheImage(
      AssetImage(monthlyThemeService.backgroundAssetPath),
      context,
    );
    _didPrecacheBackground = true;
  }

  @override
  void dispose() {
    _entryAnimationController.dispose();
    super.dispose();
  }

  // Эта функция запускает процесс авторизации через WebView
  void _startRudnAuth(BuildContext context) async {
    ErrorReportingService().reportEvent('login_started');
    final String languageCode = Localizations.localeOf(context).languageCode;
    final bool? success = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RudnWebviewScreen(languageCode: languageCode),
      ),
    );

    ErrorReportingService().reportEvent('webview_returned', details: {
      'success': '$success',
      'context_mounted': '${context.mounted}',
    });

    if (success == true && context.mounted) {
      ErrorReportingService().reportEvent('dispatching_logged_in');
      context.read<AuthBloc>().add(const LoggedIn());
    } else if (success == true && !context.mounted) {
      ErrorReportingService()
          .reportEvent('LOGIN_FAILED_CONTEXT_UNMOUNTED', details: {
        'success': '$success',
      });
    } else {
      ErrorReportingService().reportEvent('webview_cancelled', details: {
        'success': '$success',
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.read<MonthlyThemeService>().theme;
    final currentLanguageCode = Localizations.localeOf(context).languageCode;

    return AppBackground(
      imagePath: theme.imagePath,
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _blurSigmaAnimation,
              builder: (context, child) {
                final sigma = _blurSigmaAnimation.value;
                if (sigma <= 0.01) {
                  return const SizedBox.shrink();
                }
                return BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: sigma,
                    sigmaY: sigma,
                  ),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.12),
                  ),
                );
              },
            ),
          ),
          FadeTransition(
            opacity: _contentOpacityAnimation,
            child: SlideTransition(
              position: _contentSlideAnimation,
              child: Scaffold(
                backgroundColor: Colors.transparent,
                body: Stack(
                  children: [
                    // Main Scrollable Content with Sticky Footer
                    CustomScrollView(
                      slivers: [
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: SafeArea(
                            child: Column(
                              children: [
                                const Spacer(),
                                // Main Content (Logo + Button)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _SkewedContainer(
                                        reverse: true,
                                        color: const Color(0xFFD9D9D9),
                                        child: Text(
                                          'Seasons',
                                          textAlign: TextAlign.center,
                                          style: Theme.of(context)
                                              .textTheme
                                              .displaySmall
                                              ?.copyWith(
                                                color: const Color(0xFF42445A),
                                                fontWeight: FontWeight.w900,
                                                fontSize: 40,
                                              ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      _SkewedContainer(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 10, horizontal: 30),
                                        color: const Color(0xFF4A5C7A),
                                        onTap: () => _startRudnAuth(context),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              AppLocalizations.of(context)!
                                                  .login,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontFamily: GoogleFonts
                                                        .gentiumBookPlus()
                                                    .fontFamily,
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
                                const Spacer(),
                                // Footer (Copyright + Email)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 24.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        AppLocalizations.of(context)!.copyright,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.copyWith(color: Colors.white),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        AppLocalizations.of(context)!.helpEmail,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.copyWith(color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Language switcher at top-right (must be last to render on top)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: PopupMenuButton<Locale>(
                            initialValue: Locale(
                              currentLanguageCode == 'en' ? 'en' : 'ru',
                            ),
                            icon: const Icon(Icons.language,
                                color: Colors.white, size: 28),
                            onSelected: (Locale locale) {
                              context
                                  .read<LocaleBloc>()
                                  .add(ChangeLocale(locale));
                            },
                            itemBuilder: (BuildContext context) => [
                              CheckedPopupMenuItem<Locale>(
                                checked: currentLanguageCode == 'ru',
                                value: const Locale('ru'),
                                child: Row(
                                  children: [
                                    const Text('🇷🇺'),
                                    const SizedBox(width: 8),
                                    Text(AppLocalizations.of(context)!
                                        .languageRussian),
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
                                    Text(AppLocalizations.of(context)!
                                        .languageEnglish),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Loading Overlay
                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        if (state is AuthLoading) {
                          return Container(
                            color: Colors.black.withValues(alpha: 0.3),
                            child: const Center(
                              child: SeasonsLoader(),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
          decoration: BoxDecoration(
            color: color,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 15,
                offset: const Offset(5, 5),
                spreadRadius: 2,
              ),
            ],
          ),
          child: Transform(
            transform: Matrix4.skewX(-skewValue),
            child: child,
          ),
        ),
      ),
    );
  }
}

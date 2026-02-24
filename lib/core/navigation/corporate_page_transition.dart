import 'package:flutter/material.dart';

class CorporatePageTransitionsBuilder extends PageTransitionsBuilder {
  const CorporatePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final primary = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    final secondary = CurvedAnimation(
      parent: secondaryAnimation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    return _buildCorporateTransition(
      child: child,
      primary: primary,
      secondary: secondary,
    );
  }
}

Route<T> buildCorporatePageRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionDuration: const Duration(milliseconds: 240),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final primary = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      final secondary = CurvedAnimation(
        parent: secondaryAnimation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return _buildCorporateTransition(
        child: child,
        primary: primary,
        secondary: secondary,
      );
    },
  );
}

Widget _buildCorporateTransition({
  required Widget child,
  required Animation<double> primary,
  required Animation<double> secondary,
}) {
  final incomingOpacity = Tween<double>(begin: 0.0, end: 1.0).evaluate(primary);
  final outgoingOpacity =
      Tween<double>(begin: 1.0, end: 0.92).evaluate(secondary);

  final incomingScale = Tween<double>(begin: 1.03, end: 1.0).evaluate(primary);
  final outgoingScale =
      Tween<double>(begin: 1.0, end: 0.985).evaluate(secondary);

  return Opacity(
    opacity: (incomingOpacity * outgoingOpacity).clamp(0.0, 1.0),
    child: Transform.scale(
      scale: incomingScale * outgoingScale,
      child: child,
    ),
  );
}

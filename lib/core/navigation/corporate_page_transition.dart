import 'package:flutter/gestures.dart';
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
    pageBuilder: (context, animation, secondaryAnimation) =>
        _EdgeSwipeBackWrapper(child: page),
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

const double _backSwipeEdgeWidth = 28.0;
const double _backSwipeTriggerDistance = 72.0;

@visibleForTesting
bool shouldTriggerBackSwipePop(
  double dragDistance, {
  double triggerDistance = _backSwipeTriggerDistance,
}) {
  return dragDistance >= triggerDistance;
}

class _EdgeSwipeBackWrapper extends StatefulWidget {
  final Widget child;

  const _EdgeSwipeBackWrapper({required this.child});

  @override
  State<_EdgeSwipeBackWrapper> createState() => _EdgeSwipeBackWrapperState();
}

class _EdgeSwipeBackWrapperState extends State<_EdgeSwipeBackWrapper> {
  double _dragDistance = 0;

  void _resetDrag() {
    _dragDistance = 0;
  }

  void _handleDragEnd(DragEndDetails _) {
    final navigator = Navigator.maybeOf(context);
    final route = ModalRoute.of(context);
    final canPop = navigator?.canPop() ?? false;
    final isCurrentRoute = route?.isCurrent ?? false;
    if (canPop && isCurrentRoute && shouldTriggerBackSwipePop(_dragDistance)) {
      navigator?.maybePop();
    }
    _resetDrag();
  }

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      behavior: HitTestBehavior.translucent,
      gestures: {
        _EdgeHorizontalDragGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<
                _EdgeHorizontalDragGestureRecognizer>(
          () => _EdgeHorizontalDragGestureRecognizer(
            edgeWidth: _backSwipeEdgeWidth,
          ),
          (recognizer) {
            recognizer.onStart = (_) {
              _dragDistance = 0;
            };
            recognizer.onUpdate = (details) {
              _dragDistance = (_dragDistance + details.delta.dx).clamp(
                0.0,
                10000.0,
              );
            };
            recognizer.onCancel = _resetDrag;
            recognizer.onEnd = _handleDragEnd;
          },
        ),
      },
      child: widget.child,
    );
  }
}

class _EdgeHorizontalDragGestureRecognizer
    extends HorizontalDragGestureRecognizer {
  _EdgeHorizontalDragGestureRecognizer({required this.edgeWidth});

  final double edgeWidth;

  @override
  bool isPointerAllowed(PointerEvent event) {
    if (event.position.dx > edgeWidth) return false;
    return super.isPointerAllowed(event);
  }
}

Widget _buildCorporateTransition({
  required Widget child,
  required Animation<double> primary,
  required Animation<double> secondary,
}) {
  final incomingOpacity = Tween<double>(begin: 0.0, end: 1.0).evaluate(primary);
  final outgoingOpacity = Tween<double>(
    begin: 1.0,
    end: 0.92,
  ).evaluate(secondary);

  final incomingScale = Tween<double>(begin: 1.03, end: 1.0).evaluate(primary);
  final outgoingScale = Tween<double>(
    begin: 1.0,
    end: 0.985,
  ).evaluate(secondary);

  return Opacity(
    opacity: (incomingOpacity * outgoingOpacity).clamp(0.0, 1.0),
    child: Transform.scale(scale: incomingScale * outgoingScale, child: child),
  );
}

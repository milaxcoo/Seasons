import 'package:flutter/material.dart';

class AppBackground extends StatelessWidget {
  final String imagePath;
  final Widget child;

  const AppBackground({
    super.key,
    required this.imagePath,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF101827),
                  Color(0xFF0B1220),
                  Color(0xFF04060A),
                ],
              ),
            ),
          ),
        ),
        // Background layer - always full screen
        Positioned.fill(
          child: IgnorePointer(
            child: imagePath.isNotEmpty
                ? Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    width: double.infinity,
                    height: double.infinity,
                    gaplessPlayback: true,
                    filterQuality: FilterQuality.medium,
                    excludeFromSemantics: true,
                  )
                : const SizedBox.expand(),
          ),
        ),
        // Content layer on top
        child,
      ],
    );
  }
}

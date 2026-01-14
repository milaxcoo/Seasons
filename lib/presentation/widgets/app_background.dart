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
      children: [
        // Background layer - always full screen
        Positioned.fill(
          child: imagePath.isNotEmpty
              ? Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                )
              : const SizedBox.expand(),
        ),
        // Content layer on top
        child,
      ],
    );
  }
}

import 'package:flutter/material.dart';

class AppBackground extends StatelessWidget {
  // 1. Add the imagePath property
  final String imagePath;
  final Widget child;

  const AppBackground({
    super.key,
    required this.imagePath, // Make it a required parameter
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          // 2. Use the imagePath variable here
          image: AssetImage(imagePath),
          fit: BoxFit.cover,
        ),
      ),
      child: child,
    );
  }
}

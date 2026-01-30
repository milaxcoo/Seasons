import 'package:flutter/material.dart';
import 'dart:math' as math;

class SeasonsLoader extends StatefulWidget {
  final double size;
  final Color? color; // Optional override

  const SeasonsLoader({
    super.key,
    this.size = 50.0,
    this.color,
  });

  @override
  State<SeasonsLoader> createState() => _SeasonsLoaderState();
}

class _SeasonsLoaderState extends State<SeasonsLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Muted/Pastel season colors (less "fancy", more elegant)
    final colors = [
      const Color(0xFFE1F5FE), // Winter - Very pale Blue
      const Color(0xFFE8F5E9), // Spring - Very pale Green
      const Color(0xFFFFFDE7), // Summer - Very pale Yellow
      const Color(0xFFFBE9E7), // Autumn - Very pale Orange
    ];

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            children: List.generate(4, (index) {
              // Calculate angle for each dot (0, 90, 180, 270 degrees) + rotation
              final angle = (index * 90.0 * (math.pi / 180.0)) +
                  (_controller.value * 2 * math.pi);
              
              // Variable radius for breathing effect
              // Goes from 0.0 to 1.0 twice per rotation
              final breathing = math.sin(_controller.value * 2 * math.pi);
              final radius = (widget.size / 3) + (breathing * 2.0); 

              return Positioned(
                left: (widget.size / 2) + (radius * math.cos(angle)) - (widget.size / 8),
                top: (widget.size / 2) + (radius * math.sin(angle)) - (widget.size / 8),
                child: Container(
                  width: widget.size / 4,
                  height: widget.size / 4,
                  decoration: BoxDecoration(
                    // Make colors less noticeable (more transparent)
                    color: (widget.color ?? colors[index]).withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (widget.color ?? colors[index]).withValues(alpha: 0.3),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

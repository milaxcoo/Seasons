import 'package:flutter/material.dart';
import 'package:seasons/core/theme/background_readability.dart';

class AppBackground extends StatefulWidget {
  final String imagePath;
  final Widget child;

  const AppBackground({
    super.key,
    required this.imagePath,
    required this.child,
  });

  @override
  State<AppBackground> createState() => _AppBackgroundState();
}

class _AppBackgroundState extends State<AppBackground> {
  BackgroundReadabilityProfile _readability =
      const BackgroundReadabilityProfile.neutral();
  String _resolvedImagePath = '';

  @override
  void initState() {
    super.initState();
    _loadReadability(widget.imagePath);
  }

  @override
  void didUpdateWidget(covariant AppBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imagePath == widget.imagePath) return;
    _loadReadability(widget.imagePath);
  }

  void _loadReadability(String imagePath) {
    _resolvedImagePath = imagePath;
    if (imagePath.isEmpty) {
      if (!mounted) return;
      setState(() {
        _readability = const BackgroundReadabilityProfile.neutral();
      });
      return;
    }
    BackgroundReadabilityAnalyzer.forAsset(imagePath).then((profile) {
      if (!mounted || _resolvedImagePath != imagePath) return;
      setState(() {
        _readability = profile;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = _readability;

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
            child: widget.imagePath.isNotEmpty
                ? Image.asset(
                    widget.imagePath,
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
        if (profile.globalLiftAlpha > 0)
          Positioned.fill(
            child: IgnorePointer(
              child: ColoredBox(
                color: Colors.white.withValues(alpha: profile.globalLiftAlpha),
              ),
            ),
          ),
        if (profile.topLiftAlpha > 0)
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.center,
                    colors: [
                      Colors.white.withValues(alpha: profile.topLiftAlpha),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
        if (profile.centerLiftAlpha > 0)
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.05),
                    radius: 0.95,
                    colors: [
                      Colors.white.withValues(alpha: profile.centerLiftAlpha),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 1.0],
                  ),
                ),
              ),
            ),
          ),
        if (profile.bottomLiftAlpha > 0)
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.center,
                    colors: [
                      Colors.white.withValues(alpha: profile.bottomLiftAlpha),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
        // Content layer on top
        widget.child,
      ],
    );
  }
}

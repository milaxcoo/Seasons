import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:seasons/data/models/voting_event.dart' as model;
import 'package:seasons/presentation/widgets/custom_icons.dart';

class AnimatedPanelSelector extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onPanelSelected;
  final Map<model.VotingStatus, int> hasEvents;

  // Customizable dimensions
  final double totalHeight;
  final double barHeight;
  final double buttonRadius;
  final double verticalMargin;

  const AnimatedPanelSelector({
    super.key,
    required this.selectedIndex,
    required this.onPanelSelected,
    required this.hasEvents,
    this.totalHeight = 110.0,
    this.barHeight = 90.0,
    this.buttonRadius = 25.0,
    this.verticalMargin = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    const double horizontalMargin = 10.0;
    const Duration animDuration = Duration(milliseconds: 600);
    const Curve animCurve = Curves.easeOutCubic;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Container(
          margin: EdgeInsets.symmetric(vertical: verticalMargin),
          height: totalHeight,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double internalPadding = 40.0;
              final double barWidth =
                  constraints.maxWidth - (horizontalMargin * 2);
              // Effective width for buttons is barWidth minus internal padding
              final double effectiveButtonAreaWidth =
                  barWidth - (internalPadding * 2);
              final double buttonSlotWidth = effectiveButtonAreaWidth / 3;

              return TweenAnimationBuilder<double>(
                tween: Tween<double>(
                  begin: selectedIndex.toDouble(),
                  end: selectedIndex.toDouble(),
                ),
                duration: animDuration,
                curve: animCurve,
                builder: (context, animationValue, child) {
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Unified background with blur
                      ClipPath(
                        clipper: _UnifiedShapeClipper(
                          animationValue: animationValue,
                          buttonSlotWidth: buttonSlotWidth,
                          barHeight: barHeight,
                          totalHeight: totalHeight,
                          horizontalMargin: horizontalMargin,
                          internalPadding: internalPadding,
                          totalWidth: constraints.maxWidth,
                        ),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                          child: Container(
                            width: constraints.maxWidth,
                            height: totalHeight,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.black.withValues(alpha: 0.5),
                                  Colors.black.withValues(alpha: 0.3),
                                  Colors.black.withValues(alpha: 0.5),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Buttons (positioned on top)
                      Positioned(
                        top: totalHeight - barHeight,
                        left: horizontalMargin,
                        right: horizontalMargin,
                        height: barHeight,
                        child: Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: internalPadding),
                          child: Row(
                            children: [
                              // Button 1 - Registration
                              SizedBox(
                                width: buttonSlotWidth,
                                child: _AnimatedButton(
                                  icon: RegistrationIcon(isSelected: false),
                                  isSelected: selectedIndex == 0,
                                  onTap: () => onPanelSelected(0),
                                  hasActiveEvents: (hasEvents[model
                                              .VotingStatus.registration] ??
                                          0) >
                                      0,
                                  buttonRadius: buttonRadius,
                                  animDuration: animDuration,
                                  animCurve: animCurve,
                                ),
                              ),
                              // Button 2 - Active Voting
                              SizedBox(
                                width: buttonSlotWidth,
                                child: _AnimatedButton(
                                  icon: ActiveVotingIcon(isSelected: false),
                                  isSelected: selectedIndex == 1,
                                  onTap: () => onPanelSelected(1),
                                  hasActiveEvents:
                                      (hasEvents[model.VotingStatus.active] ??
                                              0) >
                                          0,
                                  buttonRadius: buttonRadius,
                                  animDuration: animDuration,
                                  animCurve: animCurve,
                                ),
                              ),
                              // Button 3 - Results
                              SizedBox(
                                width: buttonSlotWidth,
                                child: _AnimatedButton(
                                  icon: ResultsIcon(isSelected: false),
                                  isSelected: selectedIndex == 2,
                                  onTap: () => onPanelSelected(2),
                                  hasActiveEvents: (hasEvents[
                                              model.VotingStatus.completed] ??
                                          0) >
                                      0,
                                  buttonRadius: buttonRadius,
                                  animDuration: animDuration,
                                  animCurve: animCurve,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

// Animated Button Widget
class _AnimatedButton extends StatelessWidget {
  final Widget icon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool hasActiveEvents;
  final double buttonRadius;
  final Duration animDuration;
  final Curve animCurve;

  const _AnimatedButton({
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.hasActiveEvents,
    required this.buttonRadius,
    required this.animDuration,
    required this.animCurve,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    if (hasActiveEvents) {
      backgroundColor = const Color(0xFF00A94F);
    } else {
      backgroundColor = const Color(0xFF6d9fc5);
    }

    final double scale = isSelected ? 1.25 : 0.9;
    final double iconSize = buttonRadius * 1.2;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.translucent,
      child: AnimatedScale(
        duration: animDuration,
        curve: animCurve,
        scale: scale,
        child: CircleAvatar(
          radius: buttonRadius,
          backgroundColor: backgroundColor,
          child: IconTheme(
            data: IconTheme.of(context).copyWith(size: iconSize),
            child: icon,
          ),
        ),
      ),
    );
  }
}

// Unified Shape Clipper - Creates single merged path
class _UnifiedShapeClipper extends CustomClipper<Path> {
  final double animationValue;
  final double buttonSlotWidth;
  final double barHeight;
  final double totalHeight;
  final double horizontalMargin;
  final double internalPadding;
  final double totalWidth;

  _UnifiedShapeClipper({
    required this.animationValue,
    required this.buttonSlotWidth,
    required this.barHeight,
    required this.totalHeight,
    required this.horizontalMargin,
    required this.internalPadding,
    required this.totalWidth,
  });

  @override
  Path getClip(Size size) {
    // Use barHeight/2 for perfect pill shape
    final double cornerRadius = barHeight / 2; // 35px for 70px bar
    const double blobWidth = 95.0;

    // Calculate bar dimensions
    final double barTop = totalHeight - barHeight;
    final double barBottom = totalHeight;
    final double barLeft = horizontalMargin;
    final double barRight = totalWidth - horizontalMargin;

    // ===== STEP 1: Create Base Rectangle (Pill Shape) =====
    final basePath = Path();
    basePath.moveTo(barLeft, barTop + cornerRadius);

    // Top-left corner (fully rounded)
    basePath.arcToPoint(
      Offset(barLeft + cornerRadius, barTop),
      radius: Radius.circular(cornerRadius),
      clockwise: true,
    );

    // Top edge
    basePath.lineTo(barRight - cornerRadius, barTop);

    // Top-right corner (fully rounded)
    basePath.arcToPoint(
      Offset(barRight, barTop + cornerRadius),
      radius: Radius.circular(cornerRadius),
      clockwise: true,
    );

    // Right edge
    basePath.lineTo(barRight, barBottom - cornerRadius);

    // Bottom-right corner (fully rounded)
    basePath.arcToPoint(
      Offset(barRight - cornerRadius, barBottom),
      radius: Radius.circular(cornerRadius),
      clockwise: true,
    );

    // Bottom edge
    basePath.lineTo(barLeft + cornerRadius, barBottom);

    // Bottom-left corner (fully rounded)
    basePath.arcToPoint(
      Offset(barLeft, barBottom - cornerRadius),
      radius: Radius.circular(cornerRadius),
      clockwise: true,
    );

    basePath.close();

    // ===== STEP 2: Create Blob/Curve Shape (Exact SVG) =====
    const double svgWidth = 203.0;
    const double svgHeight = 45.5;
    // Extend blob height to exact visible height (overlap handled by path skirt)
    final double blobHeight = totalHeight - barHeight;
    final double scaleX = blobWidth / svgWidth;
    final double scaleY = blobHeight / svgHeight;

    // Calculate blob center position based on animation with internal padding
    final double blobCenterX = barLeft +
        internalPadding +
        (animationValue * buttonSlotWidth) +
        (buttonSlotWidth / 2);
    final double blobStartX = blobCenterX - (blobWidth / 2);

    final blobPath = Path();
    // Start deep at the CENTER (V-shape skirt) to absolutely prevent corner poking
    blobPath.moveTo(101.5, 45.5 + 100.0);
    // Come up to the surface start point
    blobPath.lineTo(6.7, 45.5);

    // Curves (unchanged)
    blobPath.relativeCubicTo(15.0, 0.0, 20.0, -1.0, 23.3, -4.0);
    blobPath.relativeCubicTo(5.7, -2.3, 9.9, -5.0, 18.1, -10.5);
    blobPath.relativeCubicTo(10.7, -7.1, 11.8, -9.2, 20.6, -14.3);
    blobPath.relativeCubicTo(5.0, -2.9, 9.2, -5.2, 15.2, -7.0);
    blobPath.relativeCubicTo(7.1, -2.1, 13.3, -2.3, 17.6, -2.1);
    blobPath.relativeCubicTo(4.2, -0.2, 10.5, 0.1, 17.6, 2.1);
    blobPath.relativeCubicTo(6.1, 1.8, 10.2, 4.1, 15.2, 7.0);
    blobPath.relativeCubicTo(8.8, 5.0, 9.9, 7.1, 20.6, 14.3);
    blobPath.relativeCubicTo(8.3, 5.5, 12.4, 8.2, 18.1, 10.5);
    blobPath.relativeCubicTo(3.0, 3.0, 8.3, 4.0, 23.3, 4.0);

    // Go back to absolute deep center to close the V
    blobPath.lineTo(101.5, 45.5 + 100.0);
    blobPath.close();

    // Scale and position the blob (no negative Y shift needed now)
    final Matrix4 matrix = Matrix4.identity();
    matrix.setTranslationRaw(blobStartX, 0.0, 0.0);
    // Scale X and Y using setEntry (diagonal indices 0 and 5)
    matrix.setEntry(0, 0, scaleX);
    matrix.setEntry(1, 1, scaleY);
    final scaledBlobPath = blobPath.transform(matrix.storage);

    // ===== STEP 3: MERGE into Single Path =====
    final unifiedPath = Path.combine(
      PathOperation.union,
      basePath,
      scaledBlobPath,
    );

    return unifiedPath;
  }

  @override
  bool shouldReclip(covariant _UnifiedShapeClipper oldClipper) {
    return oldClipper.animationValue != animationValue ||
        oldClipper.internalPadding != internalPadding;
  }
}

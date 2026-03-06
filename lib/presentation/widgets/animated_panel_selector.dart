import 'dart:math' as math;

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
  final double bumpHeight;
  final double buttonRadius;
  final double verticalMargin;
  final double maxWidth;
  final double internalHorizontalPadding;
  final double selectedScale;
  final double unselectedScale;
  final double iconScaleFactor;

  const AnimatedPanelSelector({
    super.key,
    required this.selectedIndex,
    required this.onPanelSelected,
    required this.hasEvents,
    this.totalHeight = 110.0,
    this.barHeight = 90.0,
    this.bumpHeight = 18.0,
    this.buttonRadius = 25.0,
    this.verticalMargin = 16.0,
    this.maxWidth = 600.0,
    this.internalHorizontalPadding = 40.0,
    this.selectedScale = 1.25,
    this.unselectedScale = 0.9,
    this.iconScaleFactor = 1.2,
  });

  @override
  Widget build(BuildContext context) {
    const double horizontalMargin = 10.0;
    const Duration animDuration = Duration(milliseconds: 600);
    const Curve animCurve = Curves.easeOutCubic;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          margin: EdgeInsets.symmetric(vertical: verticalMargin),
          height: totalHeight,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double barWidth =
                  constraints.maxWidth - (horizontalMargin * 2);
              // Protect minimum slot width in extreme narrow layouts by
              // reducing side padding before geometry has to collapse.
              const double minPreferredButtonSlotWidth = 56.0;
              final double maxUsableInternalPadding = math.max(
                0.0,
                (barWidth - (minPreferredButtonSlotWidth * 3)) / 2,
              );
              final double resolvedInternalPadding = math.min(
                internalHorizontalPadding,
                maxUsableInternalPadding,
              );
              // Effective width for buttons is barWidth minus internal padding.
              final double effectiveButtonAreaWidth = math.max(
                0.0,
                barWidth - (resolvedInternalPadding * 2),
              );
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
                      // Unified background without expensive backdrop blur.
                      ClipPath(
                        clipper: _UnifiedShapeClipper(
                          animationValue: animationValue,
                          buttonSlotWidth: buttonSlotWidth,
                          barHeight: barHeight,
                          bumpHeight: bumpHeight,
                          totalHeight: totalHeight,
                          horizontalMargin: horizontalMargin,
                          internalPadding: resolvedInternalPadding,
                          totalWidth: constraints.maxWidth,
                        ),
                        child: Container(
                          width: constraints.maxWidth,
                          height: totalHeight,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.black.withValues(alpha: 0.52),
                                Colors.black.withValues(alpha: 0.36),
                                Colors.black.withValues(alpha: 0.52),
                              ],
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
                          padding: EdgeInsets.symmetric(
                            horizontal: resolvedInternalPadding,
                          ),
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
                                  selectedScale: selectedScale,
                                  unselectedScale: unselectedScale,
                                  iconScaleFactor: iconScaleFactor,
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
                                  selectedScale: selectedScale,
                                  unselectedScale: unselectedScale,
                                  iconScaleFactor: iconScaleFactor,
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
                                  selectedScale: selectedScale,
                                  unselectedScale: unselectedScale,
                                  iconScaleFactor: iconScaleFactor,
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
  final double selectedScale;
  final double unselectedScale;
  final double iconScaleFactor;

  const _AnimatedButton({
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.hasActiveEvents,
    required this.buttonRadius,
    required this.animDuration,
    required this.animCurve,
    required this.selectedScale,
    required this.unselectedScale,
    required this.iconScaleFactor,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    if (hasActiveEvents) {
      backgroundColor = const Color(0xFF00A94F);
    } else {
      backgroundColor = const Color(0xFF6d9fc5);
    }

    final double scale = isSelected ? selectedScale : unselectedScale;
    final double iconSize = buttonRadius * iconScaleFactor;

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
  final double bumpHeight;
  final double totalHeight;
  final double horizontalMargin;
  final double internalPadding;
  final double totalWidth;

  _UnifiedShapeClipper({
    required this.animationValue,
    required this.buttonSlotWidth,
    required this.barHeight,
    required this.bumpHeight,
    required this.totalHeight,
    required this.horizontalMargin,
    required this.internalPadding,
    required this.totalWidth,
  });

  @override
  Path getClip(Size size) {
    // Use barHeight/2 for perfect pill shape
    final double cornerRadius = barHeight / 2; // 35px for 70px bar
    const double maxBlobWidth = 95.0;
    const double minBlobWidth = 86.0;
    const double extremeEdgeTrimMax = 2.2;
    const double extremeEdgeTrimRange = 28.0;
    const double cornerVisualInset = 0.75;

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

    const double shoulderJoinOffset = 0.0;
    const double expressiveSlotWidth = 72.0;
    const double compactSlotWidth = 44.0;
    const double compactHeightFactorMin = 0.42;
    const double compactWidthFactorMin = 1.20;
    const double expressiveWidthFactor = 1.85;

    // ===== STEP 2: Create Blob/Curve Shape =====
    final double slotSupportT = ((buttonSlotWidth - compactSlotWidth) /
            (expressiveSlotWidth - compactSlotWidth))
        .clamp(0.0, 1.0)
        .toDouble();
    if (slotSupportT < 0.01) {
      return basePath;
    }
    final double baseBlobHeight = bumpHeight.clamp(12.0, 28.0).toDouble();
    final double compactHeightFactor = compactHeightFactorMin +
        ((1.0 - compactHeightFactorMin) * slotSupportT);
    final double blobHeight = baseBlobHeight * compactHeightFactor;
    final double desiredBlobCenterX = barLeft +
        internalPadding +
        (animationValue * buttonSlotWidth) +
        (buttonSlotWidth / 2);
    final double distanceToNearestBarEdge = math.min(
      (desiredBlobCenterX - barLeft).abs(),
      (barRight - desiredBlobCenterX).abs(),
    );
    final double edgeInfluence =
        ((distanceToNearestBarEdge - (cornerRadius + 36.0)) / 34.0)
            .clamp(0.0, 1.0)
            .toDouble();
    final double maxWidthBySlot = buttonSlotWidth *
        (compactWidthFactorMin +
            ((expressiveWidthFactor - compactWidthFactorMin) * slotSupportT));
    final double resolvedMaxBlobWidth = math.min(maxBlobWidth, maxWidthBySlot);
    final double resolvedMinBlobWidth = math.min(
      minBlobWidth,
      math.max(28.0, resolvedMaxBlobWidth - 6.0),
    );
    final double blobWidthBase = resolvedMinBlobWidth +
        ((resolvedMaxBlobWidth - resolvedMinBlobWidth) * edgeInfluence);
    // Tiny edge-only taper to remove residual protrusion on far-left/right tabs.
    final double extremeEdgeTrimT =
        ((cornerRadius + 44.0) - distanceToNearestBarEdge)
                .clamp(0.0, extremeEdgeTrimRange)
                .toDouble() /
            extremeEdgeTrimRange;
    final double edgeTrim =
        extremeEdgeTrimMax * extremeEdgeTrimT * extremeEdgeTrimT;
    final double blobWidthAfterEdgeTrim = (blobWidthBase - edgeTrim)
        .clamp(
          math.max(18.0, resolvedMinBlobWidth - extremeEdgeTrimMax),
          resolvedMaxBlobWidth,
        )
        .toDouble();
    // Keep shoulder joins inside rounded-corner safe bounds on extreme tabs.
    final double safeLeftShoulderX = barLeft + cornerRadius + cornerVisualInset;
    final double safeRightShoulderX =
        barRight - cornerRadius - cornerVisualInset;
    final double maxHalfWidthBySafeEdges = math.max(
      0.0,
      math.min(
        desiredBlobCenterX - safeLeftShoulderX,
        safeRightShoulderX - desiredBlobCenterX,
      ),
    );
    final double safeEdgeLimitedWidth = maxHalfWidthBySafeEdges * 2.0;
    final double blobWidth = math.min(
      blobWidthAfterEdgeTrim,
      safeEdgeLimitedWidth,
    );
    if (blobWidth < 3.0 || blobHeight < 2.0) {
      return basePath;
    }
    final double shoulderBaselineY = barTop + shoulderJoinOffset;
    final double blobPeakY = shoulderBaselineY - blobHeight;
    final double leftShoulderX = desiredBlobCenterX - (blobWidth / 2);
    final double rightShoulderX = desiredBlobCenterX + (blobWidth / 2);
    final double shoulderControlDx = blobWidth * 0.18;
    final double peakControlDx = blobWidth * 0.25;
    final double skirtDepth = barHeight + blobHeight + 22.0;

    final blobPath = Path();
    blobPath.moveTo(leftShoulderX, shoulderBaselineY);
    blobPath.cubicTo(
      leftShoulderX + shoulderControlDx,
      shoulderBaselineY,
      desiredBlobCenterX - peakControlDx,
      blobPeakY,
      desiredBlobCenterX,
      blobPeakY,
    );
    blobPath.cubicTo(
      desiredBlobCenterX + peakControlDx,
      blobPeakY,
      rightShoulderX - shoulderControlDx,
      shoulderBaselineY,
      rightShoulderX,
      shoulderBaselineY,
    );
    blobPath.lineTo(rightShoulderX, shoulderBaselineY + skirtDepth);
    blobPath.lineTo(leftShoulderX, shoulderBaselineY + skirtDepth);
    blobPath.close();

    // ===== STEP 3: MERGE into Single Path =====
    final unifiedPath = Path.combine(PathOperation.union, basePath, blobPath);

    return unifiedPath;
  }

  @override
  bool shouldReclip(covariant _UnifiedShapeClipper oldClipper) {
    return oldClipper.animationValue != animationValue ||
        oldClipper.buttonSlotWidth != buttonSlotWidth ||
        oldClipper.barHeight != barHeight ||
        oldClipper.bumpHeight != bumpHeight ||
        oldClipper.totalHeight != totalHeight ||
        oldClipper.horizontalMargin != horizontalMargin ||
        oldClipper.internalPadding != internalPadding ||
        oldClipper.totalWidth != totalWidth;
  }
}

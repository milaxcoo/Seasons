import 'package:flutter/material.dart';

enum AdaptiveSizeClass {
  compact,
  medium,
  expanded,
}

enum AdaptiveFooterMode {
  full,
  compact,
  minimal,
  hidden,
}

@immutable
class AdaptiveNavDimensions {
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

  const AdaptiveNavDimensions({
    required this.totalHeight,
    required this.barHeight,
    required this.bumpHeight,
    required this.buttonRadius,
    required this.verticalMargin,
    required this.maxWidth,
    required this.internalHorizontalPadding,
    required this.selectedScale,
    required this.unselectedScale,
    required this.iconScaleFactor,
  });
}

@immutable
class AdaptiveOverlayDimensions {
  final double maxWidth;
  final double horizontalPadding;
  final double loaderSize;
  final double gap;
  final double textSize;
  final int maxLines;

  const AdaptiveOverlayDimensions({
    required this.maxWidth,
    required this.horizontalPadding,
    required this.loaderSize,
    required this.gap,
    required this.textSize,
    required this.maxLines,
  });
}

@immutable
class AdaptiveHeaderStyle {
  final double titleFontSize;
  final double subtitleFontSize;
  final double subtitleLetterSpacing;
  final double verticalPadding;
  final double subtitleOffsetY;
  final List<Shadow> titleShadows;
  final List<Shadow> subtitleShadows;

  const AdaptiveHeaderStyle({
    required this.titleFontSize,
    required this.subtitleFontSize,
    required this.subtitleLetterSpacing,
    required this.verticalPadding,
    required this.subtitleOffsetY,
    required this.titleShadows,
    required this.subtitleShadows,
  });
}

@immutable
class AdaptiveFooterStyle {
  final AdaptiveFooterMode mode;
  final double poemFontSize;
  final double poemLineHeight;
  final double authorFontSize;
  final double contentPadding;
  final double poemAuthorSpacing;
  final double outerTopPadding;
  final double outerBottomPadding;
  final double maxContentHeight;
  final double maxTextWidth;

  const AdaptiveFooterStyle({
    required this.mode,
    required this.poemFontSize,
    required this.poemLineHeight,
    required this.authorFontSize,
    required this.contentPadding,
    required this.poemAuthorSpacing,
    required this.outerTopPadding,
    required this.outerBottomPadding,
    required this.maxContentHeight,
    required this.maxTextWidth,
  });

  bool get isVisible => mode != AdaptiveFooterMode.hidden;
}

@immutable
class AdaptiveLayoutData {
  static const double compactWidthBreakpoint = 600;
  static const double mediumWidthBreakpoint = 840;

  final Size screenSize;
  final EdgeInsets safeArea;
  final Orientation orientation;
  final double availableWidth;
  final double availableHeight;
  final AdaptiveSizeClass sizeClass;

  const AdaptiveLayoutData._({
    required this.screenSize,
    required this.safeArea,
    required this.orientation,
    required this.availableWidth,
    required this.availableHeight,
    required this.sizeClass,
  });

  factory AdaptiveLayoutData.of(BuildContext context) {
    return AdaptiveLayoutData.fromMediaQuery(MediaQuery.of(context));
  }

  factory AdaptiveLayoutData.fromMediaQuery(MediaQueryData mediaQuery) {
    final availableWidth =
        (mediaQuery.size.width - mediaQuery.padding.horizontal)
            .clamp(0.0, 6000.0)
            .toDouble();
    final availableHeight =
        (mediaQuery.size.height - mediaQuery.padding.vertical)
            .clamp(0.0, 6000.0)
            .toDouble();
    final sizeClass = switch (availableWidth) {
      < compactWidthBreakpoint => AdaptiveSizeClass.compact,
      < mediumWidthBreakpoint => AdaptiveSizeClass.medium,
      _ => AdaptiveSizeClass.expanded,
    };

    return AdaptiveLayoutData._(
      screenSize: mediaQuery.size,
      safeArea: mediaQuery.padding,
      orientation: mediaQuery.orientation,
      availableWidth: availableWidth,
      availableHeight: availableHeight,
      sizeClass: sizeClass,
    );
  }

  bool get isCompact => sizeClass == AdaptiveSizeClass.compact;

  bool get isMedium => sizeClass == AdaptiveSizeClass.medium;

  bool get isExpanded => sizeClass == AdaptiveSizeClass.expanded;

  bool get isLandscape => orientation == Orientation.landscape;

  bool get isPhoneLikeLandscape {
    return isLandscape && availableHeight < 500 && availableWidth < 980;
  }

  double get _phoneLandscapeWidthT {
    return ((availableWidth - 560.0) / 320.0).clamp(0.0, 1.0).toDouble();
  }

  double _lerp(double min, double max, double t) {
    return min + ((max - min) * t);
  }

  static const double _navBumpPeakHeadroom = 1.0;

  double _resolvedNavTotalHeight({
    required double preferredTotalHeight,
    required double barHeight,
    required double bumpHeight,
  }) {
    final requiredTotalHeight = barHeight + bumpHeight + _navBumpPeakHeadroom;
    return preferredTotalHeight < requiredTotalHeight
        ? requiredTotalHeight
        : preferredTotalHeight;
  }

  double get minVotingListUsableHeight {
    if (isLandscape) {
      return switch (sizeClass) {
        AdaptiveSizeClass.compact => 190.0,
        AdaptiveSizeClass.medium => 220.0,
        AdaptiveSizeClass.expanded => 250.0,
      };
    }
    return switch (sizeClass) {
      AdaptiveSizeClass.compact => 240.0,
      AdaptiveSizeClass.medium => 280.0,
      AdaptiveSizeClass.expanded => 320.0,
    };
  }

  double get estimatedTopBarHeight {
    if (isLandscape) return 52.0;
    return isExpanded ? 68.0 : 64.0;
  }

  double get estimatedHeaderHeight {
    final style = headerStyle;
    return (style.verticalPadding * 2) +
        style.titleFontSize +
        style.subtitleFontSize +
        style.subtitleOffsetY.abs() +
        10.0;
  }

  double get navReservedHeight {
    final nav = navDimensions;
    return nav.totalHeight + (nav.verticalMargin * 2);
  }

  double get minFooterVisibleHeight {
    if (isLandscape) {
      return isExpanded ? 120.0 : 104.0;
    }
    if (isExpanded) return 184.0;
    if (isMedium) return 168.0;
    return 152.0;
  }

  double get _coreVerticalChromeHeight {
    final base =
        estimatedTopBarHeight + estimatedHeaderHeight + navReservedHeight;
    if (isLandscape) {
      return base + (headerToNavGap * 2);
    }
    return base;
  }

  double get votingHeightBudgetWithFooter {
    return availableHeight - _coreVerticalChromeHeight - minFooterVisibleHeight;
  }

  double get footerBudgetAfterContentProtection {
    return availableHeight -
        _coreVerticalChromeHeight -
        minVotingListUsableHeight;
  }

  double get _footerFullMinBudget {
    if (isLandscape) {
      return switch (sizeClass) {
        AdaptiveSizeClass.compact => 112.0,
        AdaptiveSizeClass.medium => 126.0,
        AdaptiveSizeClass.expanded => 140.0,
      };
    }
    return switch (sizeClass) {
      AdaptiveSizeClass.compact => 156.0,
      AdaptiveSizeClass.medium => 176.0,
      AdaptiveSizeClass.expanded => 194.0,
    };
  }

  double get _footerCompactMinBudget => _footerFullMinBudget * 0.74;

  double get _footerMinimalMinBudget => _footerFullMinBudget * 0.52;

  AdaptiveFooterMode get footerMode {
    final budget = footerBudgetAfterContentProtection;
    if (budget >= _footerFullMinBudget) return AdaptiveFooterMode.full;
    if (budget >= _footerCompactMinBudget) return AdaptiveFooterMode.compact;
    if (budget >= _footerMinimalMinBudget) return AdaptiveFooterMode.minimal;
    return AdaptiveFooterMode.hidden;
  }

  bool get shouldCollapseFooterForContent {
    return footerMode == AdaptiveFooterMode.hidden;
  }

  AdaptiveFooterStyle get footerStyle {
    final mode = footerMode;
    if (mode == AdaptiveFooterMode.hidden) {
      return const AdaptiveFooterStyle(
        mode: AdaptiveFooterMode.hidden,
        poemFontSize: 0.0,
        poemLineHeight: 1.0,
        authorFontSize: 0.0,
        contentPadding: 0.0,
        poemAuthorSpacing: 0.0,
        outerTopPadding: 0.0,
        outerBottomPadding: 0.0,
        maxContentHeight: 0.0,
        maxTextWidth: 0.0,
      );
    }

    final basePoem = footerPoemFontSize;
    final baseAuthor = footerAuthorFontSize;
    final baseLineHeight = footerPoemLineHeight;
    final baseBottomPadding =
        isLandscape ? (isExpanded ? 12.0 : 8.0) : (isExpanded ? 30.0 : 24.0);
    final baseMaxHeight = isLandscape
        ? availableHeight * 0.80
        : (isExpanded
            ? 170.0
            : isMedium
                ? 155.0
                : 140.0);
    final baseMaxTextWidth = (availableWidth * 0.94).clamp(
      250.0,
      isLandscape ? 720.0 : 640.0,
    );

    final modeScale = switch (mode) {
      AdaptiveFooterMode.full => 1.0,
      AdaptiveFooterMode.compact => 0.90,
      AdaptiveFooterMode.minimal => 0.82,
      AdaptiveFooterMode.hidden => 0.0,
    };
    final spacingScale = switch (mode) {
      AdaptiveFooterMode.full => 1.0,
      AdaptiveFooterMode.compact => 0.78,
      AdaptiveFooterMode.minimal => 0.60,
      AdaptiveFooterMode.hidden => 0.0,
    };

    return AdaptiveFooterStyle(
      mode: mode,
      poemFontSize: (basePoem * modeScale).clamp(11.8, basePoem).toDouble(),
      poemLineHeight: (baseLineHeight - ((1.0 - modeScale) * 0.5))
          .clamp(1.24, baseLineHeight)
          .toDouble(),
      authorFontSize:
          (baseAuthor * modeScale).clamp(10.8, baseAuthor).toDouble(),
      contentPadding: (20.0 * spacingScale).clamp(10.0, 20.0).toDouble(),
      poemAuthorSpacing: (8.0 * spacingScale).clamp(4.0, 8.0).toDouble(),
      outerTopPadding: isLandscape ? 4.0 : 4.0,
      outerBottomPadding: (baseBottomPadding * spacingScale)
          .clamp(isLandscape ? 4.0 : 10.0, baseBottomPadding)
          .toDouble(),
      maxContentHeight: (baseMaxHeight * (0.72 + (modeScale * 0.28)))
          .clamp(isLandscape ? 74.0 : 98.0, baseMaxHeight)
          .toDouble(),
      maxTextWidth: (baseMaxTextWidth * (0.90 + (modeScale * 0.10)))
          .clamp(220.0, baseMaxTextWidth)
          .toDouble(),
    );
  }

  double get outerHorizontalPadding {
    if (isPhoneLikeLandscape) {
      final t = _phoneLandscapeWidthT;
      return switch (sizeClass) {
        AdaptiveSizeClass.compact => _lerp(8.0, 10.0, t),
        AdaptiveSizeClass.medium => _lerp(9.0, 12.0, t),
        AdaptiveSizeClass.expanded => _lerp(10.0, 13.0, t),
      };
    }
    if (isCompact) {
      return isLandscape ? 8 : 12;
    }
    if (isMedium) {
      return isLandscape ? 16 : 24;
    }
    return isLandscape ? 26 : 32;
  }

  double get homeContentMaxWidth {
    if (isCompact) {
      return double.infinity;
    }
    if (isMedium) {
      return 1040;
    }
    return isLandscape ? 1400 : 1120;
  }

  int get homeLandscapeListFlex {
    if (isExpanded) return 7;
    if (isMedium) return 6;
    return 1;
  }

  int get homeLandscapeSidebarFlex {
    if (isExpanded) return 5;
    if (isMedium) return 5;
    return 1;
  }

  double get homeSectionHorizontalPadding {
    if (isPhoneLikeLandscape) {
      final t = _phoneLandscapeWidthT;
      return switch (sizeClass) {
        AdaptiveSizeClass.compact => _lerp(7.0, 9.0, t),
        AdaptiveSizeClass.medium => _lerp(8.0, 10.5, t),
        AdaptiveSizeClass.expanded => _lerp(9.0, 12.0, t),
      };
    }
    if (isCompact) {
      return isLandscape ? 8 : 14;
    }
    if (isMedium) {
      return isLandscape ? 14 : 20;
    }
    return isLandscape ? 20 : 24;
  }

  double get homeListSectionVerticalPadding {
    if (isLandscape) {
      return isExpanded ? 12 : 8;
    }
    return 0;
  }

  double get homeListMaxWidth {
    if (isCompact) return double.infinity;
    if (isMedium) return 780;
    return isLandscape ? 900 : 820;
  }

  AdaptiveNavDimensions get navDimensions {
    if (isCompact) {
      final barHeight = isLandscape ? 62.0 : 90.0;
      const bumpHeight = 17.0;
      return AdaptiveNavDimensions(
        totalHeight: _resolvedNavTotalHeight(
          preferredTotalHeight: isLandscape ? 82.0 : 104.0,
          barHeight: barHeight,
          bumpHeight: bumpHeight,
        ),
        barHeight: barHeight,
        bumpHeight: bumpHeight,
        buttonRadius: isLandscape ? 20 : 26,
        verticalMargin: isLandscape ? 4 : 14,
        maxWidth: isLandscape ? 620 : 600,
        internalHorizontalPadding: isLandscape ? 28 : 34,
        selectedScale: isLandscape ? 1.22 : 1.24,
        unselectedScale: 0.92,
        iconScaleFactor: isLandscape ? 1.12 : 1.16,
      );
    }
    if (isMedium) {
      final barHeight = isLandscape ? 72.0 : 102.0;
      const bumpHeight = 20.0;
      return AdaptiveNavDimensions(
        totalHeight: _resolvedNavTotalHeight(
          preferredTotalHeight: isLandscape ? 96.0 : 118.0,
          barHeight: barHeight,
          bumpHeight: bumpHeight,
        ),
        barHeight: barHeight,
        bumpHeight: bumpHeight,
        buttonRadius: isLandscape ? 24 : 30,
        verticalMargin: isLandscape ? 8 : 16,
        maxWidth: isLandscape ? 720 : 680,
        internalHorizontalPadding: isLandscape ? 34 : 42,
        selectedScale: isLandscape ? 1.24 : 1.26,
        unselectedScale: 0.92,
        iconScaleFactor: isLandscape ? 1.18 : 1.2,
      );
    }
    final barHeight = isLandscape ? 86.0 : 114.0;
    const bumpHeight = 22.0;
    return AdaptiveNavDimensions(
      totalHeight: _resolvedNavTotalHeight(
        preferredTotalHeight: isLandscape ? 112.0 : 132.0,
        barHeight: barHeight,
        bumpHeight: bumpHeight,
      ),
      barHeight: barHeight,
      bumpHeight: bumpHeight,
      buttonRadius: isLandscape ? 28 : 34,
      verticalMargin: isLandscape ? 10 : 18,
      maxWidth: isLandscape ? 820 : 760,
      internalHorizontalPadding: isLandscape ? 44 : 50,
      selectedScale: isLandscape ? 1.25 : 1.27,
      unselectedScale: 0.92,
      iconScaleFactor: isLandscape ? 1.2 : 1.22,
    );
  }

  double get _headerTitleFontSize {
    final base = switch (sizeClass) {
      AdaptiveSizeClass.compact => isLandscape ? 35.0 : 42.0,
      AdaptiveSizeClass.medium => isLandscape ? 39.0 : 44.0,
      AdaptiveSizeClass.expanded => isLandscape ? 44.0 : 46.0,
    };
    final growth = isLandscape
        ? ((availableWidth - 700.0) / 500.0).clamp(0.0, 3.0)
        : ((availableWidth - 380.0) / 480.0).clamp(0.0, 1.5);
    return (base + growth).clamp(
      isLandscape ? 34.0 : 41.0,
      isLandscape ? 48.0 : 49.0,
    );
  }

  AdaptiveHeaderStyle get headerStyle {
    final titleFontSize = _headerTitleFontSize;
    // Keep subtitle proportional to title across all adaptive states.
    final subtitleFontSize =
        (titleFontSize * 0.305).clamp(11.8, 15.4).toDouble();
    final subtitleLetterSpacing =
        (subtitleFontSize * 0.34).clamp(2.8, 5.2).toDouble();
    final subtitleOffsetY =
        -(subtitleFontSize * (isLandscape ? 0.14 : 0.30)).toDouble();

    return AdaptiveHeaderStyle(
      titleFontSize: titleFontSize,
      subtitleFontSize: subtitleFontSize,
      subtitleLetterSpacing: subtitleLetterSpacing,
      verticalPadding: isLandscape ? 3.0 : 5.0,
      subtitleOffsetY: subtitleOffsetY,
      titleShadows: const [
        Shadow(blurRadius: 14, color: Color(0xDE000000)),
        Shadow(blurRadius: 4, color: Color(0xFF000000)),
      ],
      subtitleShadows: const [
        Shadow(blurRadius: 9, color: Color(0xDE000000)),
        Shadow(blurRadius: 2, color: Color(0xFF000000)),
      ],
    );
  }

  double get headerTitleFontSize => headerStyle.titleFontSize;

  double get headerSubtitleFontSize => headerStyle.subtitleFontSize;

  double get headerSubtitleLetterSpacing => headerStyle.subtitleLetterSpacing;

  double get headerVerticalPadding => headerStyle.verticalPadding;

  double get headerSubtitleOffsetY => headerStyle.subtitleOffsetY;

  double get headerToNavGap => isLandscape ? 6.0 : 0.0;

  double get footerPoemFontSize {
    if (isPhoneLikeLandscape) {
      final base = switch (sizeClass) {
        AdaptiveSizeClass.compact => 14.8,
        AdaptiveSizeClass.medium => 15.4,
        AdaptiveSizeClass.expanded => 16.0,
      };
      final growth =
          ((availableWidth - 620.0) / 720.0).clamp(0.0, 1.0).toDouble();
      return (base + growth).clamp(14.6, 17.4);
    }
    final base = switch (sizeClass) {
      AdaptiveSizeClass.compact => isLandscape ? 15.2 : 15.3,
      AdaptiveSizeClass.medium => isLandscape ? 16.8 : 16.2,
      AdaptiveSizeClass.expanded => isLandscape ? 18.2 : 17.0,
    };
    final growth = isLandscape
        ? ((availableWidth - 700.0) / 480.0).clamp(0.0, 2.4)
        : ((availableWidth - 380.0) / 560.0).clamp(0.0, 1.1);
    return (base + growth).clamp(
      isLandscape ? 15.0 : 15.0,
      isLandscape ? 21.0 : 18.5,
    );
  }

  double get footerPoemLineHeight {
    if (isPhoneLikeLandscape) return 1.5;
    return isLandscape ? 1.56 : 1.5;
  }

  double get footerAuthorFontSize {
    final base = switch (sizeClass) {
      AdaptiveSizeClass.compact => isLandscape ? 12.8 : 13.0,
      AdaptiveSizeClass.medium => isLandscape ? 13.5 : 13.4,
      AdaptiveSizeClass.expanded => isLandscape ? 14.2 : 14.0,
    };
    final growth = isLandscape
        ? ((availableWidth - 700.0) / 1000.0).clamp(0.0, 0.8)
        : ((availableWidth - 380.0) / 900.0).clamp(0.0, 0.6);
    return (base + growth).clamp(
      isLandscape ? 12.5 : 12.8,
      isLandscape ? 15.0 : 14.6,
    );
  }

  double get emptyStateFontSize {
    final base = switch (sizeClass) {
      AdaptiveSizeClass.compact => isLandscape ? 16.8 : 16.0,
      AdaptiveSizeClass.medium => isLandscape ? 18.2 : 17.0,
      AdaptiveSizeClass.expanded => isLandscape ? 19.6 : 17.8,
    };
    final growth = isLandscape
        ? ((availableWidth - 700.0) / 800.0).clamp(0.0, 1.4)
        : ((availableWidth - 380.0) / 700.0).clamp(0.0, 0.8);
    final computed = (base + growth).clamp(
      isLandscape ? 16.8 : 16.0,
      isLandscape ? 21.2 : 19.0,
    );
    final footerFloor = isLandscape ? 16.0 : 15.0;
    return computed < footerFloor ? footerFloor : computed;
  }

  double get emptyStateLineHeight => isLandscape ? 1.34 : 1.3;

  double get emptyStateMaxWidth {
    if (isCompact) return isLandscape ? 360 : 320;
    if (isMedium) return isLandscape ? 500 : 420;
    return isLandscape ? 620 : 500;
  }

  AdaptiveOverlayDimensions get overlayDimensions {
    if (isCompact) {
      return const AdaptiveOverlayDimensions(
        maxWidth: 340,
        horizontalPadding: 20,
        loaderSize: 44,
        gap: 12,
        textSize: 20,
        maxLines: 3,
      );
    }
    if (isMedium) {
      return const AdaptiveOverlayDimensions(
        maxWidth: 430,
        horizontalPadding: 24,
        loaderSize: 48,
        gap: 14,
        textSize: 20,
        maxLines: 4,
      );
    }
    return const AdaptiveOverlayDimensions(
      maxWidth: 520,
      horizontalPadding: 28,
      loaderSize: 56,
      gap: 16,
      textSize: 22,
      maxLines: 4,
    );
  }
}

extension AdaptiveLayoutBuildContextX on BuildContext {
  AdaptiveLayoutData get adaptiveLayout => AdaptiveLayoutData.of(this);
}

import 'package:flutter/material.dart';

enum AdaptiveSizeClass { compact, medium, expanded }

enum HomeLayoutMode { stacked, split }

enum HomeLandscapeGeometryClass {
  phoneLandscape,
  crampedWindowLandscape,
  regularTabletLandscape,
}

enum AdaptiveFooterMode { full, compact, minimal, hidden }

enum AdaptiveDensityMode { regular, compact, extremeCompact }

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
  final double maxTotalHeight;
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
    required this.maxTotalHeight,
    required this.maxTextWidth,
  });

  bool get isVisible => mode != AdaptiveFooterMode.hidden;
}

@immutable
class AdaptiveDetailLayoutStyle {
  final AdaptiveDensityMode densityMode;
  final EdgeInsets outerPadding;
  final double maxContentWidth;
  final double cardPadding;
  final double sectionGap;
  final double sectionGapLarge;
  final double sectionGapSmall;
  final double titleFontSize;
  final double appBarTitleFontSize;
  final double rowLabelWidth;
  final double rowGap;
  final double actionVerticalPadding;
  final double actionMinHeight;
  final double tableCellHorizontalPadding;
  final double tableCellVerticalPadding;
  final double dialogMaxWidth;
  final EdgeInsets dialogContentPadding;
  final EdgeInsets dialogTitlePadding;
  final EdgeInsets dialogActionsPadding;

  const AdaptiveDetailLayoutStyle({
    required this.densityMode,
    required this.outerPadding,
    required this.maxContentWidth,
    required this.cardPadding,
    required this.sectionGap,
    required this.sectionGapLarge,
    required this.sectionGapSmall,
    required this.titleFontSize,
    required this.appBarTitleFontSize,
    required this.rowLabelWidth,
    required this.rowGap,
    required this.actionVerticalPadding,
    required this.actionMinHeight,
    required this.tableCellHorizontalPadding,
    required this.tableCellVerticalPadding,
    required this.dialogMaxWidth,
    required this.dialogContentPadding,
    required this.dialogTitlePadding,
    required this.dialogActionsPadding,
  });

  bool get isExtremeCompact =>
      densityMode == AdaptiveDensityMode.extremeCompact;
}

@immutable
class AdaptiveAuthLayoutStyle {
  final AdaptiveDensityMode densityMode;
  final double contentMaxWidth;
  final double contentHorizontalPadding;
  final double titleFontSize;
  final double buttonFontSize;
  final double buttonIconSize;
  final double buttonVerticalPadding;
  final double buttonHorizontalPadding;
  final double blockGap;
  final double errorTopGap;
  final double errorPadding;
  final double footerBottomPadding;
  final double footerItemGap;
  final double topControlPadding;

  const AdaptiveAuthLayoutStyle({
    required this.densityMode,
    required this.contentMaxWidth,
    required this.contentHorizontalPadding,
    required this.titleFontSize,
    required this.buttonFontSize,
    required this.buttonIconSize,
    required this.buttonVerticalPadding,
    required this.buttonHorizontalPadding,
    required this.blockGap,
    required this.errorTopGap,
    required this.errorPadding,
    required this.footerBottomPadding,
    required this.footerItemGap,
    required this.topControlPadding,
  });

  bool get isExtremeCompact =>
      densityMode == AdaptiveDensityMode.extremeCompact;
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

  double get _landscapeAspectRatio {
    final safeHeight = availableHeight <= 0 ? 1.0 : availableHeight;
    return availableWidth / safeHeight;
  }

  HomeLandscapeGeometryClass get homeLandscapeGeometryClass {
    if (!isLandscape) {
      return HomeLandscapeGeometryClass.regularTabletLandscape;
    }

    final bool phoneLandscapeGeometry =
        availableHeight <= 460 &&
        availableWidth <= 1100 &&
        _landscapeAspectRatio >= 1.45;
    if (phoneLandscapeGeometry) {
      return HomeLandscapeGeometryClass.phoneLandscape;
    }

    final bool crampedWindowGeometry =
        homeUsableContentWidth < 860 || availableHeight < 700;
    if (crampedWindowGeometry) {
      return HomeLandscapeGeometryClass.crampedWindowLandscape;
    }

    return HomeLandscapeGeometryClass.regularTabletLandscape;
  }

  AdaptiveDensityMode get appDensityMode {
    final bool extremelyConstrained =
        availableWidth < 360 || availableHeight < 460;
    if (extremelyConstrained) return AdaptiveDensityMode.extremeCompact;

    final bool compactConstraint =
        availableWidth < 460 || availableHeight < 660;
    if (compactConstraint) return AdaptiveDensityMode.compact;

    return AdaptiveDensityMode.regular;
  }

  AdaptiveDetailLayoutStyle get detailLayoutStyle {
    final density = appDensityMode;
    final double verticalPadding;
    if (isLandscape) {
      verticalPadding = switch (density) {
        AdaptiveDensityMode.regular => 10.0,
        AdaptiveDensityMode.compact => 6.0,
        AdaptiveDensityMode.extremeCompact => 4.0,
      };
    } else {
      verticalPadding = switch (density) {
        AdaptiveDensityMode.regular => 24.0,
        AdaptiveDensityMode.compact => 16.0,
        AdaptiveDensityMode.extremeCompact => 12.0,
      };
    }
    final double horizontalPadding = switch (density) {
      AdaptiveDensityMode.regular => isLandscape ? 18.0 : 14.0,
      AdaptiveDensityMode.compact => 12.0,
      AdaptiveDensityMode.extremeCompact => 8.0,
    };
    final double cardPadding = switch (density) {
      AdaptiveDensityMode.regular => 20.0,
      AdaptiveDensityMode.compact => 16.0,
      AdaptiveDensityMode.extremeCompact => 12.0,
    };
    final double sectionGap = switch (density) {
      AdaptiveDensityMode.regular => 16.0,
      AdaptiveDensityMode.compact => 12.0,
      AdaptiveDensityMode.extremeCompact => 10.0,
    };
    final double sectionGapLarge = switch (density) {
      AdaptiveDensityMode.regular => 28.0,
      AdaptiveDensityMode.compact => 22.0,
      AdaptiveDensityMode.extremeCompact => 18.0,
    };
    final double sectionGapSmall = switch (density) {
      AdaptiveDensityMode.regular => 8.0,
      AdaptiveDensityMode.compact => 6.0,
      AdaptiveDensityMode.extremeCompact => 4.0,
    };
    final double titleFontSize = switch (density) {
      AdaptiveDensityMode.regular => isLandscape ? 20.0 : 21.0,
      AdaptiveDensityMode.compact => 19.0,
      AdaptiveDensityMode.extremeCompact => 17.5,
    };
    final double appBarTitleFontSize = switch (density) {
      AdaptiveDensityMode.regular => 20.0,
      AdaptiveDensityMode.compact => 18.5,
      AdaptiveDensityMode.extremeCompact => 17.0,
    };
    final double rowLabelWidth = ((availableWidth * 0.33).clamp(
      104.0,
      190.0,
    )).toDouble();
    final double tableCellHorizontalPadding = switch (density) {
      AdaptiveDensityMode.regular => isLandscape ? 12.0 : 16.0,
      AdaptiveDensityMode.compact => isLandscape ? 10.0 : 12.0,
      AdaptiveDensityMode.extremeCompact => 8.0,
    };
    final double tableCellVerticalPadding = switch (density) {
      AdaptiveDensityMode.regular => isLandscape ? 10.0 : 18.0,
      AdaptiveDensityMode.compact => isLandscape ? 8.0 : 12.0,
      AdaptiveDensityMode.extremeCompact => 7.0,
    };
    final double maxContentWidth = switch (sizeClass) {
      AdaptiveSizeClass.compact => isLandscape ? 700.0 : 620.0,
      AdaptiveSizeClass.medium => 840.0,
      AdaptiveSizeClass.expanded => 980.0,
    };

    return AdaptiveDetailLayoutStyle(
      densityMode: density,
      outerPadding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      maxContentWidth: maxContentWidth,
      cardPadding: cardPadding,
      sectionGap: sectionGap,
      sectionGapLarge: sectionGapLarge,
      sectionGapSmall: sectionGapSmall,
      titleFontSize: titleFontSize,
      appBarTitleFontSize: appBarTitleFontSize,
      rowLabelWidth: rowLabelWidth,
      rowGap: switch (density) {
        AdaptiveDensityMode.regular => 16.0,
        AdaptiveDensityMode.compact => 12.0,
        AdaptiveDensityMode.extremeCompact => 10.0,
      },
      actionVerticalPadding: switch (density) {
        AdaptiveDensityMode.regular => 16.0,
        AdaptiveDensityMode.compact => 14.0,
        AdaptiveDensityMode.extremeCompact => 12.0,
      },
      actionMinHeight: switch (density) {
        AdaptiveDensityMode.regular => 52.0,
        AdaptiveDensityMode.compact => 48.0,
        AdaptiveDensityMode.extremeCompact => 44.0,
      },
      tableCellHorizontalPadding: tableCellHorizontalPadding,
      tableCellVerticalPadding: tableCellVerticalPadding,
      dialogMaxWidth: switch (sizeClass) {
        AdaptiveSizeClass.compact => 420.0,
        AdaptiveSizeClass.medium => 520.0,
        AdaptiveSizeClass.expanded => 580.0,
      },
      dialogContentPadding: switch (density) {
        AdaptiveDensityMode.regular => const EdgeInsets.fromLTRB(
          24,
          20,
          24,
          24,
        ),
        AdaptiveDensityMode.compact => const EdgeInsets.fromLTRB(
          20,
          18,
          20,
          20,
        ),
        AdaptiveDensityMode.extremeCompact => const EdgeInsets.fromLTRB(
          16,
          14,
          16,
          16,
        ),
      },
      dialogTitlePadding: switch (density) {
        AdaptiveDensityMode.regular => const EdgeInsets.fromLTRB(24, 24, 24, 0),
        AdaptiveDensityMode.compact => const EdgeInsets.fromLTRB(20, 20, 20, 0),
        AdaptiveDensityMode.extremeCompact => const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          0,
        ),
      },
      dialogActionsPadding: switch (density) {
        AdaptiveDensityMode.regular => const EdgeInsets.fromLTRB(24, 0, 24, 24),
        AdaptiveDensityMode.compact => const EdgeInsets.fromLTRB(20, 0, 20, 20),
        AdaptiveDensityMode.extremeCompact => const EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16,
        ),
      },
    );
  }

  AdaptiveAuthLayoutStyle get authLayoutStyle {
    final density = appDensityMode;
    final double maxWidth = switch (sizeClass) {
      AdaptiveSizeClass.compact => 460.0,
      AdaptiveSizeClass.medium => 560.0,
      AdaptiveSizeClass.expanded => 640.0,
    };
    return AdaptiveAuthLayoutStyle(
      densityMode: density,
      contentMaxWidth: maxWidth,
      contentHorizontalPadding: switch (density) {
        AdaptiveDensityMode.regular => 24.0,
        AdaptiveDensityMode.compact => 18.0,
        AdaptiveDensityMode.extremeCompact => 12.0,
      },
      titleFontSize: switch (density) {
        AdaptiveDensityMode.regular => 40.0,
        AdaptiveDensityMode.compact => 35.0,
        AdaptiveDensityMode.extremeCompact => 30.0,
      },
      buttonFontSize: switch (density) {
        AdaptiveDensityMode.regular => 26.0,
        AdaptiveDensityMode.compact => 23.0,
        AdaptiveDensityMode.extremeCompact => 20.0,
      },
      buttonIconSize: switch (density) {
        AdaptiveDensityMode.regular => 24.0,
        AdaptiveDensityMode.compact => 21.0,
        AdaptiveDensityMode.extremeCompact => 19.0,
      },
      buttonVerticalPadding: switch (density) {
        AdaptiveDensityMode.regular => 10.0,
        AdaptiveDensityMode.compact => 9.0,
        AdaptiveDensityMode.extremeCompact => 8.0,
      },
      buttonHorizontalPadding: switch (density) {
        AdaptiveDensityMode.regular => 30.0,
        AdaptiveDensityMode.compact => 24.0,
        AdaptiveDensityMode.extremeCompact => 18.0,
      },
      blockGap: switch (density) {
        AdaptiveDensityMode.regular => 10.0,
        AdaptiveDensityMode.compact => 8.0,
        AdaptiveDensityMode.extremeCompact => 6.0,
      },
      errorTopGap: switch (density) {
        AdaptiveDensityMode.regular => 14.0,
        AdaptiveDensityMode.compact => 12.0,
        AdaptiveDensityMode.extremeCompact => 10.0,
      },
      errorPadding: switch (density) {
        AdaptiveDensityMode.regular => 12.0,
        AdaptiveDensityMode.compact => 10.0,
        AdaptiveDensityMode.extremeCompact => 8.0,
      },
      footerBottomPadding: switch (density) {
        AdaptiveDensityMode.regular => 24.0,
        AdaptiveDensityMode.compact => 18.0,
        AdaptiveDensityMode.extremeCompact => 14.0,
      },
      footerItemGap: switch (density) {
        AdaptiveDensityMode.regular => 8.0,
        AdaptiveDensityMode.compact => 6.0,
        AdaptiveDensityMode.extremeCompact => 4.0,
      },
      topControlPadding: switch (density) {
        AdaptiveDensityMode.regular => 16.0,
        AdaptiveDensityMode.compact => 12.0,
        AdaptiveDensityMode.extremeCompact => 8.0,
      },
    );
  }

  double get homeUsableContentWidth {
    final afterOuterPadding = availableWidth - (outerHorizontalPadding * 2);
    final clampedToViewport = afterOuterPadding < 0 ? 0.0 : afterOuterPadding;
    if (homeContentMaxWidth.isInfinite) return clampedToViewport;
    return clampedToViewport > homeContentMaxWidth
        ? homeContentMaxWidth
        : clampedToViewport;
  }

  double get homeMinPrimaryPaneWidth {
    if (isExpanded) return 440.0;
    if (isMedium) return 400.0;
    return 360.0;
  }

  double get homeMinSecondaryPaneWidth {
    if (isExpanded) return 320.0;
    if (isMedium) return 300.0;
    return 280.0;
  }

  double get homeMinSplitTotalWidth {
    return homeMinPrimaryPaneWidth + homeMinSecondaryPaneWidth;
  }

  double get _homeSplitDecisionMinPrimaryPaneWidth {
    if (homeLandscapeGeometryClass ==
        HomeLandscapeGeometryClass.phoneLandscape) {
      return switch (sizeClass) {
        AdaptiveSizeClass.compact => 308.0,
        AdaptiveSizeClass.medium => 346.0,
        AdaptiveSizeClass.expanded => 388.0,
      };
    }
    return homeMinPrimaryPaneWidth;
  }

  double get _homeSplitDecisionMinSecondaryPaneWidth {
    if (homeLandscapeGeometryClass ==
        HomeLandscapeGeometryClass.phoneLandscape) {
      return switch (sizeClass) {
        AdaptiveSizeClass.compact => 240.0,
        AdaptiveSizeClass.medium => 256.0,
        AdaptiveSizeClass.expanded => 286.0,
      };
    }
    return homeMinSecondaryPaneWidth;
  }

  double get _homeSplitDecisionMinTotalWidth {
    return _homeSplitDecisionMinPrimaryPaneWidth +
        _homeSplitDecisionMinSecondaryPaneWidth;
  }

  double get homePrimaryPaneWidthForSplit {
    final totalFlex = homeLandscapeListFlex + homeLandscapeSidebarFlex;
    if (totalFlex <= 0) return 0.0;
    return homeUsableContentWidth * (homeLandscapeListFlex / totalFlex);
  }

  double get homeSecondaryPaneWidthForSplit {
    final totalFlex = homeLandscapeListFlex + homeLandscapeSidebarFlex;
    if (totalFlex <= 0) return 0.0;
    return homeUsableContentWidth * (homeLandscapeSidebarFlex / totalFlex);
  }

  double get _homeSplitEnterBuffer {
    if (homeLandscapeGeometryClass ==
        HomeLandscapeGeometryClass.phoneLandscape) {
      return 6.0;
    }
    if (isExpanded) return 28.0;
    if (isMedium) return 24.0;
    return 18.0;
  }

  double get _homeSplitExitBuffer {
    if (homeLandscapeGeometryClass ==
        HomeLandscapeGeometryClass.phoneLandscape) {
      return 4.0;
    }
    if (isExpanded) return 14.0;
    if (isMedium) return 12.0;
    return 10.0;
  }

  bool _isSplitValidWithBuffer(double buffer) {
    if (!isLandscape) return false;
    if (homeUsableContentWidth < (_homeSplitDecisionMinTotalWidth + buffer)) {
      return false;
    }
    if (homePrimaryPaneWidthForSplit <
        (_homeSplitDecisionMinPrimaryPaneWidth + buffer)) {
      return false;
    }
    if (homeSecondaryPaneWidthForSplit <
        (_homeSplitDecisionMinSecondaryPaneWidth + buffer)) {
      return false;
    }
    return true;
  }

  bool get shouldUseHomeLandscapeSplit {
    if (!isLandscape) return false;
    if (homeUsableContentWidth < _homeSplitDecisionMinTotalWidth) return false;
    if (homePrimaryPaneWidthForSplit < _homeSplitDecisionMinPrimaryPaneWidth) {
      return false;
    }
    if (homeSecondaryPaneWidthForSplit <
        _homeSplitDecisionMinSecondaryPaneWidth) {
      return false;
    }
    return true;
  }

  HomeLayoutMode get homeLayoutMode {
    return shouldUseHomeLandscapeSplit
        ? HomeLayoutMode.split
        : HomeLayoutMode.stacked;
  }

  HomeLayoutMode resolveStableHomeLayoutMode({
    required HomeLayoutMode previousMode,
  }) {
    if (!isLandscape) return HomeLayoutMode.stacked;

    if (previousMode == HomeLayoutMode.split) {
      return _isSplitValidWithBuffer(-_homeSplitExitBuffer)
          ? HomeLayoutMode.split
          : HomeLayoutMode.stacked;
    }

    return _isSplitValidWithBuffer(_homeSplitEnterBuffer)
        ? HomeLayoutMode.split
        : HomeLayoutMode.stacked;
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

  double get homeMainContentRegionHeight {
    final height = availableHeight - _coreVerticalChromeHeight;
    return height <= 0 ? 0.0 : height;
  }

  double get _footerSplitContentReserve {
    return switch (homeLandscapeGeometryClass) {
      HomeLandscapeGeometryClass.phoneLandscape => 28.0,
      HomeLandscapeGeometryClass.crampedWindowLandscape => 36.0,
      HomeLandscapeGeometryClass.regularTabletLandscape => 44.0,
    };
  }

  double _votingContentProtectionForLayout(HomeLayoutMode layoutMode) {
    final bool splitSidebarFlow =
        isLandscape && layoutMode == HomeLayoutMode.split;
    if (splitSidebarFlow) {
      return _footerSplitContentReserve;
    }
    return minVotingListUsableHeight;
  }

  double get _splitVotingContentReferenceHeight {
    final votingHeight = availableHeight - (homeListSectionVerticalPadding * 2);
    return votingHeight <= 0 ? 0.0 : votingHeight;
  }

  double _footerNormalBudgetForLayout(HomeLayoutMode layoutMode) {
    final contentRegion = homeMainContentRegionHeight;
    if (contentRegion <= 0) return 0.0;
    final normalBudget =
        contentRegion - _votingContentProtectionForLayout(layoutMode);
    return normalBudget <= 0 ? 0.0 : normalBudget;
  }

  double footerReservedHeightCapForLayout(HomeLayoutMode layoutMode) {
    final bool splitSidebarFlow =
        isLandscape && layoutMode == HomeLayoutMode.split;
    if (splitSidebarFlow) {
      return _splitVotingContentReferenceHeight;
    }
    return homeMainContentRegionHeight * 0.5;
  }

  double votingContentHeightForLayout(HomeLayoutMode layoutMode) {
    final bool splitSidebarFlow =
        isLandscape && layoutMode == HomeLayoutMode.split;
    if (splitSidebarFlow) {
      return _splitVotingContentReferenceHeight;
    }
    final footerReserved = footerReservedHeightCapForLayout(layoutMode);
    final votingHeight = homeMainContentRegionHeight - footerReserved;
    return votingHeight <= 0 ? 0.0 : votingHeight;
  }

  double footerBudgetAfterContentProtectionForLayout(
    HomeLayoutMode layoutMode,
  ) {
    return _footerNormalBudgetForLayout(layoutMode);
  }

  double get footerBudgetAfterContentProtection {
    return footerBudgetAfterContentProtectionForLayout(homeLayoutMode);
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

  double get _footerModeStabilityBuffer {
    if (isLandscape) {
      return isExpanded ? 12.0 : 10.0;
    }
    return isExpanded ? 16.0 : 14.0;
  }

  AdaptiveFooterMode _footerModeFromBudget(double budget) {
    if (budget >= _footerFullMinBudget) return AdaptiveFooterMode.full;
    if (budget >= _footerCompactMinBudget) return AdaptiveFooterMode.compact;
    if (budget >= _footerMinimalMinBudget) return AdaptiveFooterMode.minimal;
    return AdaptiveFooterMode.hidden;
  }

  AdaptiveFooterMode footerModeForLayout({
    required HomeLayoutMode homeLayoutMode,
  }) {
    final budget = footerBudgetAfterContentProtectionForLayout(homeLayoutMode);
    return _footerModeFromBudget(budget);
  }

  AdaptiveFooterMode get footerMode {
    return footerModeForLayout(homeLayoutMode: homeLayoutMode);
  }

  bool get shouldCollapseFooterForContent {
    return footerMode == AdaptiveFooterMode.hidden;
  }

  AdaptiveFooterMode resolveStableFooterMode({
    required AdaptiveFooterMode previousMode,
    HomeLayoutMode? layoutMode,
  }) {
    final resolvedLayoutMode = layoutMode ?? homeLayoutMode;
    final budget = footerBudgetAfterContentProtectionForLayout(
      resolvedLayoutMode,
    );
    final buffer = _footerModeStabilityBuffer;

    switch (previousMode) {
      case AdaptiveFooterMode.full:
        if (budget >= (_footerFullMinBudget - buffer)) {
          return AdaptiveFooterMode.full;
        }
        if (budget >= (_footerCompactMinBudget - buffer)) {
          return AdaptiveFooterMode.compact;
        }
        if (budget >= (_footerMinimalMinBudget - buffer)) {
          return AdaptiveFooterMode.minimal;
        }
        return AdaptiveFooterMode.hidden;
      case AdaptiveFooterMode.compact:
        if (budget >= (_footerFullMinBudget + buffer)) {
          return AdaptiveFooterMode.full;
        }
        if (budget >= (_footerCompactMinBudget - buffer)) {
          return AdaptiveFooterMode.compact;
        }
        if (budget >= (_footerMinimalMinBudget - buffer)) {
          return AdaptiveFooterMode.minimal;
        }
        return AdaptiveFooterMode.hidden;
      case AdaptiveFooterMode.minimal:
        if (budget >= (_footerCompactMinBudget + buffer)) {
          return AdaptiveFooterMode.compact;
        }
        if (budget >= (_footerMinimalMinBudget - buffer)) {
          return AdaptiveFooterMode.minimal;
        }
        return AdaptiveFooterMode.hidden;
      case AdaptiveFooterMode.hidden:
        if (budget >= (_footerMinimalMinBudget + buffer)) {
          return AdaptiveFooterMode.minimal;
        }
        return AdaptiveFooterMode.hidden;
    }
  }

  AdaptiveFooterStyle footerStyleForMode(AdaptiveFooterMode mode) {
    return footerStyleForModeWithLayout(
      mode: mode,
      homeLayoutMode: homeLayoutMode,
    );
  }

  AdaptiveFooterStyle footerStyleForModeWithLayout({
    required AdaptiveFooterMode mode,
    required HomeLayoutMode homeLayoutMode,
  }) {
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
        maxTotalHeight: 0.0,
        maxTextWidth: 0.0,
      );
    }

    final basePoem = footerPoemFontSize;
    final baseAuthor = footerAuthorFontSize;
    final baseLineHeight = footerPoemLineHeight;
    final baseBottomPadding = isLandscape
        ? (isExpanded ? 12.0 : 8.0)
        : (isExpanded ? 30.0 : 24.0);
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
    final outerTopPadding = isLandscape ? 4.0 : 4.0;
    final outerBottomPadding = (baseBottomPadding * spacingScale)
        .clamp(isLandscape ? 4.0 : 10.0, baseBottomPadding)
        .toDouble();
    final contentPadding = (20.0 * spacingScale).clamp(10.0, 20.0).toDouble();
    final minContentHeightFloor = isLandscape ? 74.0 : 98.0;
    final resolvedContentFloor = baseMaxHeight < minContentHeightFloor
        ? baseMaxHeight
        : minContentHeightFloor;
    final normalDesiredContentHeight =
        (baseMaxHeight * (0.72 + (modeScale * 0.28)))
            .clamp(resolvedContentFloor, baseMaxHeight)
            .toDouble();
    final normalDesiredTotalHeight =
        outerTopPadding +
        outerBottomPadding +
        (contentPadding * 2) +
        normalDesiredContentHeight;
    final maxAllowedTotalHeight = footerReservedHeightCapForLayout(
      homeLayoutMode,
    );
    final resolvedMaxTotalHeight =
        normalDesiredTotalHeight > maxAllowedTotalHeight
        ? maxAllowedTotalHeight
        : normalDesiredTotalHeight;
    final maxInnerContentByInvariant =
        (resolvedMaxTotalHeight -
                outerTopPadding -
                outerBottomPadding -
                (contentPadding * 2))
            .clamp(0.0, resolvedMaxTotalHeight)
            .toDouble();
    final maxContentHeight =
        normalDesiredContentHeight > maxInnerContentByInvariant
        ? maxInnerContentByInvariant
        : normalDesiredContentHeight;

    return AdaptiveFooterStyle(
      mode: mode,
      poemFontSize: (basePoem * modeScale).clamp(11.8, basePoem).toDouble(),
      poemLineHeight: (baseLineHeight - ((1.0 - modeScale) * 0.5))
          .clamp(1.24, baseLineHeight)
          .toDouble(),
      authorFontSize: (baseAuthor * modeScale)
          .clamp(10.8, baseAuthor)
          .toDouble(),
      contentPadding: contentPadding,
      poemAuthorSpacing: (8.0 * spacingScale).clamp(4.0, 8.0).toDouble(),
      outerTopPadding: outerTopPadding,
      outerBottomPadding: outerBottomPadding,
      maxContentHeight: maxContentHeight,
      maxTotalHeight: resolvedMaxTotalHeight,
      maxTextWidth: (baseMaxTextWidth * (0.90 + (modeScale * 0.10)))
          .clamp(220.0, baseMaxTextWidth)
          .toDouble(),
    );
  }

  AdaptiveFooterStyle get footerStyle => footerStyleForModeWithLayout(
    mode: footerMode,
    homeLayoutMode: homeLayoutMode,
  );

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
    if (homeLandscapeGeometryClass ==
            HomeLandscapeGeometryClass.phoneLandscape &&
        isCompact) {
      return 6;
    }
    if (isExpanded) return 7;
    if (isMedium) return 6;
    return 1;
  }

  int get homeLandscapeSidebarFlex {
    if (homeLandscapeGeometryClass ==
            HomeLandscapeGeometryClass.phoneLandscape &&
        isCompact) {
      return 5;
    }
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
    final subtitleFontSize = (titleFontSize * 0.305)
        .clamp(11.8, 15.4)
        .toDouble();
    final subtitleLetterSpacing = (subtitleFontSize * 0.34)
        .clamp(2.8, 5.2)
        .toDouble();
    final subtitleOffsetY = -(subtitleFontSize * (isLandscape ? 0.14 : 0.30))
        .toDouble();

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
      final growth = ((availableWidth - 620.0) / 720.0)
          .clamp(0.0, 1.0)
          .toDouble();
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

import 'package:flutter/material.dart';

enum AdaptiveSizeClass {
  compact,
  medium,
  expanded,
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
      return AdaptiveNavDimensions(
        totalHeight: isLandscape ? 82 : 104,
        barHeight: isLandscape ? 62 : 90,
        bumpHeight: 17,
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
      return AdaptiveNavDimensions(
        totalHeight: isLandscape ? 96 : 118,
        barHeight: isLandscape ? 72 : 102,
        bumpHeight: 20,
        buttonRadius: isLandscape ? 24 : 30,
        verticalMargin: isLandscape ? 8 : 16,
        maxWidth: isLandscape ? 720 : 680,
        internalHorizontalPadding: isLandscape ? 34 : 42,
        selectedScale: isLandscape ? 1.24 : 1.26,
        unselectedScale: 0.92,
        iconScaleFactor: isLandscape ? 1.18 : 1.2,
      );
    }
    return AdaptiveNavDimensions(
      totalHeight: isLandscape ? 112 : 132,
      barHeight: isLandscape ? 86 : 114,
      bumpHeight: 22,
      buttonRadius: isLandscape ? 28 : 34,
      verticalMargin: isLandscape ? 10 : 18,
      maxWidth: isLandscape ? 820 : 760,
      internalHorizontalPadding: isLandscape ? 44 : 50,
      selectedScale: isLandscape ? 1.25 : 1.27,
      unselectedScale: 0.92,
      iconScaleFactor: isLandscape ? 1.2 : 1.22,
    );
  }

  double get headerTitleFontSize {
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

  double get headerSubtitleFontSize {
    final base = switch (sizeClass) {
      AdaptiveSizeClass.compact => 12.0,
      AdaptiveSizeClass.medium => 13.0,
      AdaptiveSizeClass.expanded => 14.0,
    };
    final growth = ((availableWidth - 700.0) / 800.0).clamp(0.0, 1.0);
    return (base + growth).clamp(
      12.0,
      15.0,
    );
  }

  double get headerSubtitleLetterSpacing => isLandscape ? 2.3 : 5.0;

  double get headerVerticalPadding => isLandscape ? 3.0 : 5.0;

  double get headerSubtitleOffsetY => isLandscape ? 0.0 : -4.0;

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

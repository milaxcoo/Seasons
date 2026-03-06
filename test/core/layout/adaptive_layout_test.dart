import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seasons/core/layout/adaptive_layout.dart';

AdaptiveLayoutData _layout({
  required Size size,
  EdgeInsets padding = EdgeInsets.zero,
}) {
  return AdaptiveLayoutData.fromMediaQuery(
    MediaQueryData(size: size, padding: padding),
  );
}

void main() {
  group('Adaptive home landscape layout', () {
    test('iPhone-like landscape keeps split and visible footer', () {
      final layout = _layout(
        size: const Size(844, 390),
        padding: const EdgeInsets.only(left: 47, right: 47),
      );

      expect(
        layout.homeLandscapeGeometryClass,
        HomeLandscapeGeometryClass.phoneLandscape,
      );
      expect(layout.homeLayoutMode, HomeLayoutMode.split);

      final stableLayout = layout.resolveStableHomeLayoutMode(
        previousMode: HomeLayoutMode.stacked,
      );
      expect(stableLayout, HomeLayoutMode.split);
      expect(
        layout.homePrimaryPaneWidthForSplit,
        greaterThan(layout.homeSecondaryPaneWidthForSplit),
      );

      final footerMode = layout.resolveStableFooterMode(
        previousMode: AdaptiveFooterMode.hidden,
        layoutMode: stableLayout,
      );
      expect(footerMode, isNot(AdaptiveFooterMode.hidden));
    });

    test('Android phone landscape keeps split and right column footer', () {
      final layout = _layout(size: const Size(915, 412));

      expect(
        layout.homeLandscapeGeometryClass,
        HomeLandscapeGeometryClass.phoneLandscape,
      );
      expect(layout.homeLayoutMode, HomeLayoutMode.split);

      final footerMode = layout.footerModeForLayout(
        homeLayoutMode: HomeLayoutMode.split,
      );
      expect(footerMode, isNot(AdaptiveFooterMode.hidden));
    });

    test('narrow iPad Stage Manager style window falls back to stacked', () {
      final layout = _layout(size: const Size(740, 700));

      expect(
        layout.homeLandscapeGeometryClass,
        HomeLandscapeGeometryClass.crampedWindowLandscape,
      );
      expect(layout.homeLayoutMode, HomeLayoutMode.stacked);
      expect(
        layout.resolveStableHomeLayoutMode(
          previousMode: HomeLayoutMode.stacked,
        ),
        HomeLayoutMode.stacked,
      );
    });

    test('stacked parity cap is a 50/50 upper bound', () {
      final layout = _layout(size: const Size(740, 700));
      final homeMode = layout.homeLayoutMode;
      final footerReserved = layout.footerReservedHeightCapForLayout(homeMode);
      final votingHeight = layout.votingContentHeightForLayout(homeMode);
      final contentRegion = layout.homeMainContentRegionHeight;

      expect(homeMode, HomeLayoutMode.stacked);
      expect(footerReserved, lessThanOrEqualTo(votingHeight));
      expect(footerReserved, lessThanOrEqualTo(contentRegion * 0.5));
    });

    test(
      'split mode keeps normal footer sizing unless parity clamp is needed',
      () {
        final layout = _layout(size: const Size(1194, 834));
        final homeMode = layout.homeLayoutMode;
        final footerMode = layout.footerModeForLayout(homeLayoutMode: homeMode);
        final style = layout.footerStyleForModeWithLayout(
          mode: footerMode,
          homeLayoutMode: homeMode,
        );
        final parityCap = layout.footerReservedHeightCapForLayout(homeMode);

        expect(homeMode, HomeLayoutMode.split);
        expect(style.maxTotalHeight, lessThan(parityCap));
      },
    );

    test('footer mode degrades in highly constrained landscape windows', () {
      final compact = _layout(size: const Size(740, 580));
      final minimal = _layout(size: const Size(700, 540));
      final hidden = _layout(size: const Size(680, 500));

      expect(
        compact.footerModeForLayout(homeLayoutMode: compact.homeLayoutMode),
        AdaptiveFooterMode.compact,
      );
      expect(
        minimal.footerModeForLayout(homeLayoutMode: minimal.homeLayoutMode),
        AdaptiveFooterMode.minimal,
      );
      expect(
        hidden.footerModeForLayout(homeLayoutMode: hidden.homeLayoutMode),
        AdaptiveFooterMode.hidden,
      );
    });

    test('regular iPad landscape remains split', () {
      final layout = _layout(size: const Size(1194, 834));

      expect(
        layout.homeLandscapeGeometryClass,
        HomeLandscapeGeometryClass.regularTabletLandscape,
      );
      expect(layout.homeLayoutMode, HomeLayoutMode.split);
    });

    test('portrait always uses stacked home layout', () {
      final layout = _layout(size: const Size(390, 844));

      expect(layout.isLandscape, isFalse);
      expect(layout.homeLayoutMode, HomeLayoutMode.stacked);
    });

    test('split/staked hysteresis remains active around the boundary', () {
      final layout = _layout(size: const Size(651, 390));

      expect(layout.homeLayoutMode, HomeLayoutMode.stacked);
      expect(
        layout.resolveStableHomeLayoutMode(previousMode: HomeLayoutMode.split),
        HomeLayoutMode.split,
      );
      expect(
        layout.resolveStableHomeLayoutMode(
          previousMode: HomeLayoutMode.stacked,
        ),
        HomeLayoutMode.stacked,
      );
    });
  });
}

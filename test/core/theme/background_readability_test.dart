import 'package:flutter_test/flutter_test.dart';
import 'package:seasons/core/theme/background_readability.dart';

void main() {
  group('BackgroundReadabilityProfile', () {
    test('keeps normal images effectively unchanged', () {
      const snapshot = BackgroundBrightnessSnapshot(
        overall: 0.58,
        top: 0.56,
        center: 0.60,
        bottom: 0.57,
      );

      final profile = BackgroundReadabilityProfile.fromBrightness(snapshot);

      expect(profile.level, BackgroundReadabilityLevel.normal);
      expect(profile.globalLiftAlpha, 0.0);
      expect(profile.topLiftAlpha, 0.0);
      expect(profile.centerLiftAlpha, 0.0);
      expect(profile.bottomLiftAlpha, 0.0);
    });

    test('applies bounded correction for dark images', () {
      const snapshot = BackgroundBrightnessSnapshot(
        overall: 0.35,
        top: 0.37,
        center: 0.33,
        bottom: 0.29,
      );

      final profile = BackgroundReadabilityProfile.fromBrightness(snapshot);

      expect(profile.level, BackgroundReadabilityLevel.dark);
      expect(profile.globalLiftAlpha, greaterThan(0.0));
      expect(profile.bottomLiftAlpha, greaterThan(profile.topLiftAlpha));
      expect(profile.bottomLiftAlpha, lessThanOrEqualTo(0.14));
    });

    test('clamps correction for very dark images', () {
      const snapshot = BackgroundBrightnessSnapshot(
        overall: 0.16,
        top: 0.18,
        center: 0.15,
        bottom: 0.12,
      );

      final profile = BackgroundReadabilityProfile.fromBrightness(snapshot);

      expect(profile.level, BackgroundReadabilityLevel.veryDark);
      expect(profile.globalLiftAlpha, lessThanOrEqualTo(0.085));
      expect(profile.topLiftAlpha, lessThanOrEqualTo(0.075));
      expect(profile.centerLiftAlpha, lessThanOrEqualTo(0.095));
      expect(profile.bottomLiftAlpha, lessThanOrEqualTo(0.14));
    });
  });
}

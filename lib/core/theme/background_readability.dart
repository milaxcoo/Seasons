import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum BackgroundReadabilityLevel {
  normal,
  dark,
  veryDark,
}

@immutable
class BackgroundBrightnessSnapshot {
  final double overall;
  final double top;
  final double center;
  final double bottom;

  const BackgroundBrightnessSnapshot({
    required this.overall,
    required this.top,
    required this.center,
    required this.bottom,
  });

  const BackgroundBrightnessSnapshot.neutral()
      : overall = 0.5,
        top = 0.5,
        center = 0.5,
        bottom = 0.5;
}

@immutable
class BackgroundReadabilityProfile {
  final BackgroundBrightnessSnapshot brightness;
  final BackgroundReadabilityLevel level;
  final double globalLiftAlpha;
  final double topLiftAlpha;
  final double centerLiftAlpha;
  final double bottomLiftAlpha;

  const BackgroundReadabilityProfile({
    required this.brightness,
    required this.level,
    required this.globalLiftAlpha,
    required this.topLiftAlpha,
    required this.centerLiftAlpha,
    required this.bottomLiftAlpha,
  });

  const BackgroundReadabilityProfile.neutral()
      : brightness = const BackgroundBrightnessSnapshot.neutral(),
        level = BackgroundReadabilityLevel.normal,
        globalLiftAlpha = 0.0,
        topLiftAlpha = 0.0,
        centerLiftAlpha = 0.0,
        bottomLiftAlpha = 0.0;

  @visibleForTesting
  factory BackgroundReadabilityProfile.fromBrightness(
    BackgroundBrightnessSnapshot snapshot,
  ) {
    final level = _resolveLevel(snapshot);
    final globalLift = ((0.40 - snapshot.overall) * 0.32).clamp(0.0, 0.085);
    final topLift = ((0.36 - snapshot.top) * 0.40).clamp(0.0, 0.075);
    final centerLift = ((0.40 - snapshot.center) * 0.44).clamp(0.0, 0.095);
    final bottomLift = ((0.46 - snapshot.bottom) * 0.54).clamp(0.0, 0.14);

    final multiplier = switch (level) {
      BackgroundReadabilityLevel.normal => 0.0,
      BackgroundReadabilityLevel.dark => 0.75,
      BackgroundReadabilityLevel.veryDark => 1.0,
    };

    return BackgroundReadabilityProfile(
      brightness: snapshot,
      level: level,
      globalLiftAlpha: globalLift * multiplier,
      topLiftAlpha: topLift * multiplier,
      centerLiftAlpha: centerLift * multiplier,
      bottomLiftAlpha: bottomLift * multiplier,
    );
  }

  static BackgroundReadabilityLevel _resolveLevel(
    BackgroundBrightnessSnapshot snapshot,
  ) {
    if (snapshot.overall <= 0.29 ||
        snapshot.bottom <= 0.24 ||
        snapshot.center <= 0.25) {
      return BackgroundReadabilityLevel.veryDark;
    }
    if (snapshot.overall <= 0.41 ||
        snapshot.bottom <= 0.34 ||
        snapshot.center <= 0.33) {
      return BackgroundReadabilityLevel.dark;
    }
    return BackgroundReadabilityLevel.normal;
  }
}

class BackgroundReadabilityAnalyzer {
  static final Map<String, BackgroundReadabilityProfile> _cache =
      <String, BackgroundReadabilityProfile>{};
  static final Map<String, Future<BackgroundReadabilityProfile>> _pending =
      <String, Future<BackgroundReadabilityProfile>>{};

  static Future<BackgroundReadabilityProfile> forAsset(String imagePath) {
    final cached = _cache[imagePath];
    if (cached != null) {
      return SynchronousFuture<BackgroundReadabilityProfile>(cached);
    }

    final running = _pending[imagePath];
    if (running != null) {
      return running;
    }

    final future = _analyzeAsset(imagePath).then((profile) {
      _cache[imagePath] = profile;
      _pending.remove(imagePath);
      return profile;
    }).catchError((_) {
      _pending.remove(imagePath);
      const fallback = BackgroundReadabilityProfile.neutral();
      _cache[imagePath] = fallback;
      return fallback;
    });

    _pending[imagePath] = future;
    return future;
  }

  static Future<BackgroundReadabilityProfile> _analyzeAsset(
    String imagePath,
  ) async {
    try {
      final byteData = await rootBundle.load(imagePath);
      final codec = await ui.instantiateImageCodec(
        byteData.buffer.asUint8List(),
        targetWidth: 64,
        targetHeight: 64,
      );
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final width = image.width;
      final height = image.height;
      final raw = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      codec.dispose();
      image.dispose();

      if (raw == null) {
        return const BackgroundReadabilityProfile.neutral();
      }

      final snapshot = _snapshotFromRgba(
        rgba: raw.buffer.asUint8List(),
        width: width,
        height: height,
      );

      return BackgroundReadabilityProfile.fromBrightness(snapshot);
    } catch (_) {
      return const BackgroundReadabilityProfile.neutral();
    }
  }

  @visibleForTesting
  static BackgroundBrightnessSnapshot snapshotFromRgbaForTest({
    required Uint8List rgba,
    required int width,
    required int height,
  }) {
    return _snapshotFromRgba(rgba: rgba, width: width, height: height);
  }

  static BackgroundBrightnessSnapshot _snapshotFromRgba({
    required Uint8List rgba,
    required int width,
    required int height,
  }) {
    if (width <= 0 || height <= 0 || rgba.length < width * height * 4) {
      return const BackgroundBrightnessSnapshot.neutral();
    }

    final topEnd = (height * 0.28).clamp(1, height - 1).toInt();
    final bottomStart = (height * 0.72).clamp(1, height - 1).toInt();

    double overallSum = 0;
    int overallCount = 0;
    double topSum = 0;
    int topCount = 0;
    double centerSum = 0;
    int centerCount = 0;
    double bottomSum = 0;
    int bottomCount = 0;

    int offset = 0;
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final r = rgba[offset] / 255.0;
        final g = rgba[offset + 1] / 255.0;
        final b = rgba[offset + 2] / 255.0;
        offset += 4;

        final luminance =
            (0.2126 * r + 0.7152 * g + 0.0722 * b).clamp(0.0, 1.0).toDouble();

        overallSum += luminance;
        overallCount++;

        if (y < topEnd) {
          topSum += luminance;
          topCount++;
        } else if (y >= bottomStart) {
          bottomSum += luminance;
          bottomCount++;
        } else {
          centerSum += luminance;
          centerCount++;
        }
      }
    }

    return BackgroundBrightnessSnapshot(
      overall: overallCount == 0 ? 0.5 : overallSum / overallCount,
      top: topCount == 0 ? 0.5 : topSum / topCount,
      center: centerCount == 0 ? 0.5 : centerSum / centerCount,
      bottom: bottomCount == 0 ? 0.5 : bottomSum / bottomCount,
    );
  }
}

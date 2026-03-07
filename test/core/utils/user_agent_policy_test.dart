import 'package:flutter_test/flutter_test.dart';
import 'package:seasons/core/utils/user_agent_policy.dart';

void main() {
  group('mobileUserAgentForPlatform', () {
    test('returns Android Chrome UA on Android', () {
      expect(
        mobileUserAgentForPlatform(operatingSystem: 'android'),
        androidChromeUserAgent,
      );
    });

    test('returns iOS Safari UA on iOS', () {
      expect(
        mobileUserAgentForPlatform(operatingSystem: 'ios'),
        iosSafariUserAgent,
      );
    });

    test('defaults to iOS Safari UA for other mobile-like platforms', () {
      expect(
        mobileUserAgentForPlatform(operatingSystem: 'macos'),
        iosSafariUserAgent,
      );
    });
  });
}

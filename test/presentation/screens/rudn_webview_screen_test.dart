import 'package:flutter_test/flutter_test.dart';
import 'package:seasons/presentation/screens/rudn_webview_screen.dart';

void main() {
  group('RudnWebview helpers', () {
    test('extractSessionCookieValue returns session value from cookie string',
        () {
      final value = extractSessionCookieValue(
        '"_ga=123; session=abc123==; lang=ru"',
      );

      expect(value, 'abc123==');
    });

    test('extractSessionCookieValue returns null for empty or null-like values',
        () {
      expect(extractSessionCookieValue(''), isNull);
      expect(extractSessionCookieValue('null'), isNull);
      expect(extractSessionCookieValue('""'), isNull);
    });

    test('shouldUpgradeToHttps and upgradeToHttps handle insecure redirects',
        () {
      const insecure = 'http://seasons.rudn.ru/account';

      expect(shouldUpgradeToHttps(insecure), isTrue);
      expect(upgradeToHttps(insecure), 'https://seasons.rudn.ru/account');
      expect(shouldUpgradeToHttps('https://seasons.rudn.ru/account'), isFalse);
    });

    test('isAllowedWebViewUrl allows only https seasons host', () {
      expect(
        isAllowedWebViewUrl(
            'https://seasons.rudn.ru/oauth/login_callback?code=abc'),
        isTrue,
      );
      expect(isAllowedWebViewUrl('https://seasons.rudn.ru/account'), isTrue);
      expect(isAllowedWebViewUrl('https://example.com/account'), isFalse);
      expect(isAllowedWebViewUrl('http://seasons.rudn.ru/account'), isFalse);
      expect(isAllowedWebViewUrl('https://sub.seasons.rudn.ru/account'), isFalse);
    });

    test('isAllowedWebViewUrl blocks dangerous schemes', () {
      for (final url in const [
        'file:///etc/passwd',
        'data:text/html,hello',
        'javascript:alert(1)',
        'intent://scan/#Intent;scheme=zxing;package=com.example;end',
        'about:blank',
        'chrome://settings',
        'blob:https://seasons.rudn.ru/abc',
      ]) {
        expect(isAllowedWebViewUrl(url), isFalse, reason: 'Expected deny: $url');
      }
    });
  });
}

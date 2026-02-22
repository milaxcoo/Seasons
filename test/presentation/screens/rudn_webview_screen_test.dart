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

    test('isAllowedWebViewUrl allows required https auth hosts', () {
      expect(
        isAllowedWebViewUrl(
            'https://seasons.rudn.ru/oauth/login_callback?code=abc'),
        isTrue,
      );
      expect(isAllowedWebViewUrl('https://seasons.rudn.ru/account'), isTrue);
      expect(isAllowedWebViewUrl('https://id.rudn.ru/sign-in'), isTrue);
    });

    test('isAllowedWebViewUrl blocks unknown hosts', () {
      expect(isAllowedWebViewUrl('https://example.com/account'), isFalse);
      expect(
          isAllowedWebViewUrl('https://sub.seasons.rudn.ru/account'), isFalse);
    });

    test('http scheme is blocked, except controlled seasons upgrade path', () {
      const insecureSeasons = 'http://seasons.rudn.ru/account';
      const insecureId = 'http://id.rudn.ru/sign-in';

      expect(isAllowedWebViewUrl(insecureSeasons), isFalse);
      expect(isAllowedWebViewUrl(insecureId), isFalse);
      expect(shouldUpgradeToHttps(insecureSeasons), isTrue);
      expect(shouldUpgradeToHttps(insecureId), isFalse);
    });

    test('isExpectedAuthCallbackUrl accepts only seasons callback URL', () {
      expect(
        isExpectedAuthCallbackUrl(
          'https://seasons.rudn.ru/oauth/login_callback?code=abc',
        ),
        isTrue,
      );
      expect(
        isExpectedAuthCallbackUrl('https://seasons.rudn.ru/account'),
        isFalse,
      );
      expect(
        isExpectedAuthCallbackUrl('https://id.rudn.ru/oauth/login_callback'),
        isFalse,
      );
      expect(
        isExpectedAuthCallbackUrl(
          'https://seasons.rudn.ru/oauth/login_callback/extra',
        ),
        isFalse,
      );
    });

    test('isAllowedWebViewUrl allows internal about:blank and about:srcdoc',
        () {
      expect(isAllowedWebViewUrl('about:blank'), isTrue);
      expect(isAllowedWebViewUrl('about:srcdoc'), isTrue);
    });

    test('isAllowedWebViewUrl blocks unsupported about URLs', () {
      expect(isAllowedWebViewUrl('about:config'), isFalse);
    });

    test('isAllowedWebViewUrl blocks dangerous schemes', () {
      for (final url in const [
        'file:///etc/passwd',
        'data:text/html,hello',
        'javascript:alert(1)',
        'intent://scan/#Intent;scheme=zxing;package=com.example;end',
        'chrome://settings',
        'blob:https://seasons.rudn.ru/abc',
      ]) {
        expect(isAllowedWebViewUrl(url), isFalse,
            reason: 'Expected deny: $url');
      }
    });
  });
}

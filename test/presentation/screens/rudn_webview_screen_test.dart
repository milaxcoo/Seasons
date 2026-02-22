import 'package:flutter_test/flutter_test.dart';
import 'package:seasons/presentation/screens/rudn_webview_screen.dart';

void main() {
  group('RudnWebview helpers', () {
    test(
        'WebViewFinalizationState keeps WebView hidden after callback across error and retry',
        () {
      const initial = WebViewFinalizationState.initial();
      final callbackDetected = initial.onCallbackDetected();
      final failed = callbackDetected.onError('temporary failure');
      final retried = failed.onRetry();

      expect(initial.webViewHiddenAfterCallback, isFalse);
      expect(callbackDetected.webViewHiddenAfterCallback, isTrue);
      expect(failed.webViewHiddenAfterCallback, isTrue);
      expect(retried.webViewHiddenAfterCallback, isTrue);
      expect(retried.isFinishing, isTrue);
      expect(retried.hasError, isFalse);
      expect(retried.errorMessage, isEmpty);
    });

    test('pollForSessionCookie supports injected clock/delay for slow networks',
        () async {
      var readAttempts = 0;
      var now = DateTime.utc(2026, 2, 22, 12, 0, 0);

      final cookie = await pollForSessionCookie(
        readCookie: () async {
          readAttempts += 1;
          if (readAttempts >= 6) {
            return 'vpn-session-cookie';
          }
          return null;
        },
        timeout: const Duration(seconds: 8),
        step: const Duration(milliseconds: 100),
        now: () => now,
        delay: (duration) async {
          now = now.add(duration);
        },
      );

      expect(cookie, 'vpn-session-cookie');
      expect(readAttempts, 6);
    });

    test(
        'pollForSessionCookie returns null when timeout is reached with injected clock',
        () async {
      var readAttempts = 0;
      var now = DateTime.utc(2026, 2, 22, 12, 0, 0);

      final cookie = await pollForSessionCookie(
        readCookie: () async {
          readAttempts += 1;
          return null;
        },
        timeout: const Duration(milliseconds: 300),
        step: const Duration(milliseconds: 100),
        now: () => now,
        delay: (duration) async {
          now = now.add(duration);
        },
      );

      expect(cookie, isNull);
      expect(readAttempts, 3);
    });

    test('pollForSessionCookie stops early when stop guard is true', () async {
      var readAttempts = 0;

      final cookie = await pollForSessionCookie(
        readCookie: () async {
          readAttempts += 1;
          return null;
        },
        timeout: const Duration(seconds: 8),
        step: const Duration(milliseconds: 100),
        shouldStop: () => true,
        delay: (_) async {},
      );

      expect(cookie, isNull);
      expect(readAttempts, 0);
    });

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

    test(
        'resolveWebViewNavigationAction marks callback as finish-login and allows navigation',
        () {
      expect(
        resolveWebViewNavigationAction(
          'https://seasons.rudn.ru/oauth/login_callback?code=abc',
        ),
        WebViewNavigationAction.navigateAndFinishLogin,
      );
    });

    test(
        'resolveWebViewNavigationAction upgrades insecure callback redirect first',
        () {
      expect(
        resolveWebViewNavigationAction(
          'http://seasons.rudn.ru/oauth/login_callback?code=abc',
        ),
        WebViewNavigationAction.preventAndUpgrade,
      );
    });

    test('resolveWebViewNavigationAction allows only safe host navigations',
        () {
      expect(
        resolveWebViewNavigationAction('https://id.rudn.ru/sign-in'),
        WebViewNavigationAction.navigate,
      );
      expect(
        resolveWebViewNavigationAction('https://example.com'),
        WebViewNavigationAction.prevent,
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

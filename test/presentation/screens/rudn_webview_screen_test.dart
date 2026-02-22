import 'package:flutter/foundation.dart';
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

    test(
        'shouldStartCallbackCompletion is idempotent when completion in progress',
        () {
      expect(
        shouldStartCallbackCompletion(
          isMounted: true,
          hasPopped: false,
          isFinishing: true,
          isCompletionInProgress: false,
        ),
        isTrue,
      );
      expect(
        shouldStartCallbackCompletion(
          isMounted: true,
          hasPopped: false,
          isFinishing: true,
          isCompletionInProgress: true,
        ),
        isFalse,
      );
    });

    test('shouldForceNavigation prevents duplicate forced load/reload actions',
        () {
      expect(
        shouldForceNavigation(
          'https://seasons.rudn.ru/oauth/login_callback',
          'https://seasons.rudn.ru/oauth/login_callback',
        ),
        isFalse,
      );
      expect(
        shouldForceNavigation(
          'https://seasons.rudn.ru/oauth/login_callback',
          '__reload__',
        ),
        isTrue,
      );
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

    test('shouldUpgradeToHttps upgrades only insecure callback URL', () {
      const insecureCallback =
          'http://seasons.rudn.ru/oauth/login_callback?code=abc';

      expect(shouldUpgradeToHttps(insecureCallback), isTrue);
      expect(
        upgradeToHttps(insecureCallback),
        'https://seasons.rudn.ru/oauth/login_callback?code=abc',
      );
      expect(shouldUpgradeToHttps('http://seasons.rudn.ru/account'), isFalse);
      expect(
        shouldUpgradeToHttps('https://seasons.rudn.ru/oauth/login_callback'),
        isFalse,
      );
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
      expect(shouldUpgradeToHttps(insecureSeasons), isFalse);
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

    test(
        'id sign-in URL with redirect_uri remains allowed and does not trigger upgrade',
        () {
      const idSignIn =
          'https://id.rudn.ru/sign-in?redirect_uri=http%3A%2F%2Fseasons.rudn.ru%2Foauth%2Flogin_callback';

      expect(shouldUpgradeToHttps(idSignIn), isFalse);
      expect(
        resolveWebViewNavigationAction(idSignIn),
        WebViewNavigationAction.navigate,
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

    test('shouldAutoClickEntryButton only applies to seasons root page', () {
      expect(
        shouldAutoClickEntryButton(
          url: 'https://seasons.rudn.ru/?lang=ru',
          webViewHiddenAfterCallback: false,
        ),
        isTrue,
      );
      expect(
        shouldAutoClickEntryButton(
          url: 'https://id.rudn.ru/sign-in',
          webViewHiddenAfterCallback: false,
        ),
        isFalse,
      );
      expect(
        shouldAutoClickEntryButton(
          url: 'https://seasons.rudn.ru/account',
          webViewHiddenAfterCallback: false,
        ),
        isFalse,
      );
      expect(
        shouldAutoClickEntryButton(
          url: 'https://seasons.rudn.ru/?lang=ru',
          webViewHiddenAfterCallback: true,
        ),
        isFalse,
      );
    });

    test('navigation replay shows callback-only upgrade avoids reload loops',
        () {
      const sequence = <String>[
        'https://seasons.rudn.ru/?lang=ru',
        'https://id.rudn.ru/sign-in?redirect_uri=http%3A%2F%2Fseasons.rudn.ru%2Foauth%2Flogin_callback',
        'http://seasons.rudn.ru/account',
        'http://seasons.rudn.ru/account',
        'http://seasons.rudn.ru/account',
        'http://seasons.rudn.ru/account',
        'http://seasons.rudn.ru/oauth/login_callback?code=abc',
        'http://seasons.rudn.ru/oauth/login_callback?code=abc',
        'http://seasons.rudn.ru/oauth/login_callback?code=abc',
        'http://seasons.rudn.ru/oauth/login_callback?code=abc',
        'https://id.rudn.ru/sign-in?redirect_uri=http%3A%2F%2Fseasons.rudn.ru%2Foauth%2Flogin_callback',
        'https://id.rudn.ru/sign-in?redirect_uri=http%3A%2F%2Fseasons.rudn.ru%2Foauth%2Flogin_callback',
        'https://seasons.rudn.ru/oauth/login_callback?code=abc',
      ];

      bool oldShouldUpgrade(String url) {
        final uri = Uri.tryParse(url);
        if (uri == null || !uri.hasScheme) return false;
        return uri.scheme.toLowerCase() == 'http' &&
            uri.host.toLowerCase() == 'seasons.rudn.ru';
      }

      var oldForcedLoads = 0;
      var newForcedLoads = 0;
      String? lastForcedUrl;

      for (final url in sequence) {
        final sanitized = _sanitizeForReplay(url);
        final oldAction = oldShouldUpgrade(url) ? 'upgrade' : 'non-upgrade';
        final newAction = navigationActionLabel(
          resolveWebViewNavigationAction(url),
        );
        debugPrint('replay nav=$sanitized old=$oldAction new=$newAction');

        if (oldShouldUpgrade(url)) {
          oldForcedLoads += 1;
          debugPrint(
            'replay old_forced_load=${_sanitizeForReplay(upgradeToHttps(url))}',
          );
        }

        if (resolveWebViewNavigationAction(url) ==
                WebViewNavigationAction.preventAndUpgrade &&
            shouldForceNavigation(lastForcedUrl, upgradeToHttps(url))) {
          lastForcedUrl = upgradeToHttps(url);
          newForcedLoads += 1;
          debugPrint(
            'replay new_forced_load=${_sanitizeForReplay(lastForcedUrl)}',
          );
        }
      }

      expect(oldForcedLoads, greaterThan(newForcedLoads));
      expect(newForcedLoads, 1);
    });
  });
}

String _sanitizeForReplay(String? rawUrl) {
  if (rawUrl == null) return 'n/a';
  final uri = Uri.tryParse(rawUrl);
  if (uri == null) return rawUrl;
  return uri.replace(query: '', fragment: '').toString();
}

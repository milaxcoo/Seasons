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
  });
}

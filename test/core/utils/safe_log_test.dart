import 'package:flutter_test/flutter_test.dart';
import 'package:seasons/core/utils/safe_log.dart';

void main() {
  group('safe_log', () {
    test('redactSensitive masks oauth code and token query params', () {
      const raw =
          'https://seasons.rudn.ru/oauth/login_callback?code=abc123&token=def456&state=ok';

      final redacted = redactSensitive(raw);

      expect(redacted, contains('code=<redacted>'));
      expect(redacted, contains('token=<redacted>'));
      expect(redacted, contains('state=ok'));
      expect(redacted, isNot(contains('abc123')));
      expect(redacted, isNot(contains('def456')));
    });

    test('redactSensitive masks Authorization and Cookie header values', () {
      const raw =
          'Authorization: Bearer very-secret-token Cookie: session=supersecret';

      final redacted = redactSensitive(raw);

      expect(redacted, contains('Authorization: <redacted>'));
      expect(redacted, contains('Cookie: <redacted>'));
      expect(redacted, isNot(contains('very-secret-token')));
      expect(redacted, isNot(contains('supersecret')));
    });

    test('sanitizeUrlForLog hides query by default', () {
      final sanitized = sanitizeUrlForLog(
        'https://seasons.rudn.ru/oauth/login_callback?code=abc123&state=ok',
      );

      expect(sanitized, 'https://seasons.rudn.ru/oauth/login_callback');
    });

    test('sanitizeUrlForLog can keep query but redact sensitive values', () {
      final sanitized = sanitizeUrlForLog(
        'https://seasons.rudn.ru/oauth/login_callback?code=abc123&state=ok',
        keepQuery: true,
      );

      expect(sanitized, contains('code=%3Credacted%3E'));
      expect(sanitized, contains('state=ok'));
      expect(sanitized, isNot(contains('abc123')));
    });
  });
}

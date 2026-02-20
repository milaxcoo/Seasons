import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:seasons/core/services/error_reporting_service.dart';

import '../../mocks.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(Uri.parse('https://example.com'));
  });

  // ─────────────────────────────────────────────────────────────────────────
  // escapeHtml
  // ─────────────────────────────────────────────────────────────────────────
  group('escapeHtml', () {
    test('escapes ampersand before other characters to prevent double-escaping',
        () {
      expect(
        ErrorReportingService.escapeHtml('a & b < c > d'),
        equals('a &amp; b &lt; c &gt; d'),
      );
    });

    test('escapes only ampersand when text contains only &', () {
      expect(ErrorReportingService.escapeHtml('&'), equals('&amp;'));
    });

    test('escapes < and > characters', () {
      expect(ErrorReportingService.escapeHtml('<tag>'), equals('&lt;tag&gt;'));
    });

    test('leaves plain text unchanged', () {
      expect(ErrorReportingService.escapeHtml('hello world'),
          equals('hello world'));
    });

    test('escapes combined special characters correctly', () {
      expect(
        ErrorReportingService.escapeHtml('<b>&amp;</b>'),
        equals('&lt;b&gt;&amp;amp;&lt;/b&gt;'),
      );
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // truncateTelegramHtml
  // ─────────────────────────────────────────────────────────────────────────
  group('truncateTelegramHtml', () {
    test('returns original when within maxLength', () {
      const html = 'Hello <b>world</b>';
      expect(
        ErrorReportingService.truncateTelegramHtml(html, 100),
        equals(html),
      );
    });

    test('truncates plain text and appends ellipsis', () {
      const html = 'abcdefghij';
      final result = ErrorReportingService.truncateTelegramHtml(html, 7);
      expect(result.length, lessThanOrEqualTo(7));
      expect(result, endsWith('...'));
    });

    test('closes open <b> tag after truncation', () {
      // Ensure a long string that cuts inside <b>...</b>
      final html = '<b>${'x' * 100}</b>';
      final result = ErrorReportingService.truncateTelegramHtml(html, 30);
      expect(result, endsWith('...</b>'));
      expect(result.length, lessThanOrEqualTo(30));
    });

    test('closes open <code> tag after truncation', () {
      final html = '<code>${'x' * 100}</code>';
      final result = ErrorReportingService.truncateTelegramHtml(html, 30);
      expect(result, endsWith('...</code>'));
      expect(result.length, lessThanOrEqualTo(30));
    });

    test('closes open <pre> tag after truncation', () {
      final html = '<pre>${'x' * 100}</pre>';
      final result = ErrorReportingService.truncateTelegramHtml(html, 30);
      expect(result, endsWith('...</pre>'));
      expect(result.length, lessThanOrEqualTo(30));
    });

    test('does not add extra closing tag when tag is already closed', () {
      final html = '<b>short</b>${'x' * 100}';
      final result = ErrorReportingService.truncateTelegramHtml(html, 30);
      // The <b> tag was closed before the truncation point, so no extra </b>
      expect(result, isNot(contains('</b>')));
      expect(result.length, lessThanOrEqualTo(30));
    });

    test('avoids cutting inside a partial HTML tag', () {
      // Build a string that, at baseLimit, falls inside a tag
      const int limit = 20;
      // Pre-fill so the '<' of the next tag starts near the cut point
      final html = 'a' * 14 + '<b>long text here</b>';
      final result = ErrorReportingService.truncateTelegramHtml(html, limit);
      // Result must not contain an unclosed '<'
      final lastLt = result.lastIndexOf('<');
      final lastGt = result.lastIndexOf('>');
      // Either there's no '<', or every '<' has a matching '>'
      if (lastLt != -1) {
        expect(lastGt, greaterThan(lastLt),
            reason: 'Result must not end with a partial tag');
      }
      expect(result.length, lessThanOrEqualTo(limit));
    });

    test('returns empty string when maxLength is too small', () {
      final result = ErrorReportingService.truncateTelegramHtml('hello', 3);
      // baseLimit = 3 - 3 (ellipsis) - 17 (closing tags) = -17, so returns ''
      expect(result, equals(''));
    });

    test('result length never exceeds maxLength', () {
      // Use a string with many open tags to force the safety truncation path
      final html = '<b><code><pre>${'x' * 4096}</pre></code></b>';
      final result = ErrorReportingService.truncateTelegramHtml(html, 4096);
      expect(result.length, lessThanOrEqualTo(4096));
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // detectPlatform / detectOsVersion
  // ─────────────────────────────────────────────────────────────────────────
  group('detectPlatform', () {
    test('returns a non-empty string', () {
      final platform = ErrorReportingService.detectPlatform();
      expect(platform, isNotEmpty);
    });

    test('returns one of the expected platform strings', () {
      final platform = ErrorReportingService.detectPlatform();
      expect(
        platform,
        anyOf([
          'ios',
          'android',
          'macos',
          'linux',
          'windows',
          'web',
          'unknown',
          Platform.operatingSystem
        ]),
      );
    });
  });

  group('detectOsVersion', () {
    test('returns a non-empty string', () {
      final version = ErrorReportingService.detectOsVersion();
      expect(version, isNotEmpty);
    });

    test('never throws', () {
      expect(() => ErrorReportingService.detectOsVersion(), returnsNormally);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // sendTestMessage (with mock HTTP client)
  // ─────────────────────────────────────────────────────────────────────────
  group('sendTestMessage', () {
    test('returns true when Telegram is not configured (no error thrown)',
        () async {
      // Default env has empty TELEGRAM_BOT_TOKEN / TELEGRAM_CHAT_ID,
      // so _sendToTelegram returns without calling the HTTP client.
      final mockClient = MockHttpClient();
      final service = ErrorReportingService.withHttpClient(mockClient);
      await service.initialize(appVersion: '1.0.0');

      final result = await service.sendTestMessage();

      // sendTestMessage wraps _sendToTelegram in a try/catch and always
      // returns true on no-throw, but _sendToTelegram returns early when
      // unconfigured – so no HTTP call is made.
      verifyNever(
        () => mockClient.post(any(),
            headers: any(named: 'headers'), body: any(named: 'body')),
      );
      // The service does not throw, so result is true (early return, no error)
      expect(result, isTrue);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // initialize
  // ─────────────────────────────────────────────────────────────────────────
  group('initialize', () {
    test('can be called multiple times without re-initialising', () async {
      final mockClient = MockHttpClient();
      final service = ErrorReportingService.withHttpClient(mockClient);

      await service.initialize(appVersion: '1.0.0');
      await service.initialize(appVersion: '2.0.0'); // second call is a no-op

      // No exception should be thrown
    });
  });
}

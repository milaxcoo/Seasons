import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:seasons/core/utils/safe_log.dart';

/// Maximum Telegram message length (API limit).
const int _kTelegramMaxLength = 4096;
const int _kMaxTelemetryMessageLength = 600;
const int _kMaxTelemetryContextLength = 400;
const int _kMaxTelemetryStackLength = 1200;
const int _kMaxTelemetryDetailLength = 120;

const Set<String> _allowedTelemetryDetailKeys = {
  'event_name',
  'version',
  'platform',
  'timestamp',
  'exception_type',
  'mounted',
  'haspopped',
  'success',
  'context_mounted',
  'cookie_length',
  'error_category',
};

/// Privacy-first error reporting service.
class ErrorReportingService {
  static final ErrorReportingService _instance =
      ErrorReportingService._internal();
  factory ErrorReportingService() => _instance;
  ErrorReportingService._internal() : _httpClient = http.Client();

  /// Named constructor for testing: creates a non-singleton instance with an
  /// injectable [http.Client] so network calls can be stubbed in unit tests.
  @visibleForTesting
  ErrorReportingService.withHttpClient(http.Client httpClient)
      : _httpClient = httpClient;

  // ═══════════════════════════════════════════════════════════════════════════
  // CONFIGURATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Telegram Bot Token for local debug telemetry.
  static const String _telegramBotToken = String.fromEnvironment(
    'TELEGRAM_BOT_TOKEN',
    defaultValue: '',
  );

  /// Telegram Chat ID for local debug telemetry.
  static const String _telegramChatId = String.fromEnvironment(
    'TELEGRAM_CHAT_ID',
    defaultValue: '',
  );

  /// Secure production relay URL for release/profile telemetry.
  static const String _errorReportRelayUrl = String.fromEnvironment(
    'ERROR_REPORT_RELAY_URL',
    defaultValue: '',
  );

  /// Optional bearer token for secure relay authentication.
  static const String _errorReportRelayApiKey = String.fromEnvironment(
    'ERROR_REPORT_RELAY_API_KEY',
    defaultValue: '',
  );

  /// Master switch for release error/crash reporting.
  /// Disabled by default to keep reporting explicitly opt-in.
  static const bool _enableErrorReporting = bool.fromEnvironment(
    'ENABLE_ERROR_REPORTING',
    defaultValue: false,
  );

  /// Diagnostic auth-flow telemetry switch (release mode only).
  /// Keep this off unless temporarily debugging production auth issues.
  static const bool _enableDiagnosticEvents = bool.fromEnvironment(
    'ENABLE_DIAGNOSTIC_EVENTS',
    defaultValue: false,
  );

  // ═══════════════════════════════════════════════════════════════════════════

  final http.Client _httpClient;
  String _appVersion = 'unknown';
  String _currentScreen = 'unknown';
  bool _isInitialized = false;
  ErrorReportTransport? _reportTransport;

  @visibleForTesting
  static String sanitizeTelemetryText(String value, {required int maxLength}) {
    final redacted = redactSensitive(value);
    if (redacted.length <= maxLength) return redacted;
    if (maxLength <= 3) return redacted.substring(0, maxLength);
    return '${redacted.substring(0, maxLength - 3)}...';
  }

  @visibleForTesting
  static Map<String, String> sanitizeTelemetryDetails(
    Map<String, String>? details,
  ) {
    if (details == null || details.isEmpty) return {};
    final sanitized = <String, String>{};
    for (final entry in details.entries) {
      final key = entry.key.trim();
      if (key.isEmpty) continue;
      final normalizedKey = key.toLowerCase();
      if (!_allowedTelemetryDetailKeys.contains(normalizedKey)) continue;
      sanitized[normalizedKey] = sanitizeTelemetryText(
        entry.value,
        maxLength: _kMaxTelemetryDetailLength,
      );
    }
    return sanitized;
  }

  /// Initialize the error reporting service.
  /// Call this in main() before runApp().
  Future<void> initialize({required String appVersion}) async {
    if (_isInitialized) return;

    _appVersion = appVersion;
    _reportTransport = _buildTransport();
    _isInitialized = true;

    if (kDebugMode) {
      debugPrint(
        'ErrorReportingService: Initialized (v$_appVersion, errors=$_enableErrorReporting, diagnostics=$_enableDiagnosticEvents, relay=${_errorReportRelayUrl.isNotEmpty}, transport=${_reportTransport.runtimeType})',
      );
    }
  }

  /// Set the current screen name for context in error reports.
  void setCurrentScreen(String screenName) {
    _currentScreen = screenName;
  }

  /// Send a test message to verify Telegram is configured correctly.
  /// Call this once to make sure notifications work.
  Future<bool> sendTestMessage() async {
    final testReport = ErrorReport(
      type: 'test',
      message:
          '✅ Telegram интеграция работает! Все краши будут приходить сюда.',
      stackTrace: null,
      context: 'Test message',
      timestamp: DateTime.now().toUtc().toIso8601String(),
      appVersion: _appVersion,
      platform: detectPlatform(),
      osVersion: detectOsVersion(),
      screenName: 'TestScreen',
    );

    try {
      await _sendViaTransport(testReport);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Report a caught error.
  Future<void> reportError(
    dynamic error,
    StackTrace? stackTrace, {
    String? context,
    ErrorSeverity severity = ErrorSeverity.error,
  }) async {
    if (!_enableErrorReporting) return;

    // Don't report in debug mode unless explicitly enabled
    if (kDebugMode) {
      final sanitizedError = sanitizeTelemetryText(
        error.toString(),
        maxLength: _kMaxTelemetryMessageLength,
      );
      debugPrint(
        'ErrorReportingService: ${severity.name.toUpperCase()} - $sanitizedError',
      );
      if (stackTrace != null) {
        debugPrint(
          sanitizeTelemetryText(
            stackTrace.toString().split('\n').take(5).join('\n'),
            maxLength: _kMaxTelemetryStackLength,
          ),
        );
      }
      return;
    }

    await _sendOrQueueReport(
      type: severity.name,
      message: error.toString(),
      stackTrace: stackTrace?.toString(),
      context: context,
    );
  }

  /// Report a diagnostic event (non-error telemetry for auth flow debugging).
  /// Works in both debug and release mode for testing visibility.
  Future<void> reportEvent(String event, {Map<String, String>? details}) async {
    final sanitizedEvent = sanitizeTelemetryText(event, maxLength: 120);
    final sanitizedDetails = sanitizeTelemetryDetails(details);
    final detailStr =
        sanitizedDetails.entries.map((e) => '${e.key}=${e.value}').join(', ');

    if (kDebugMode) {
      debugPrint(
        'ErrorReportingService: EVENT - $sanitizedEvent ${detailStr.isNotEmpty ? "($detailStr)" : ""}',
      );
      if (!_enableDiagnosticEvents) return;
    }

    if (!kDebugMode && !_enableDiagnosticEvents) return;

    await _sendOrQueueReport(
      type: 'auth_event',
      message: sanitizedEvent,
      context: detailStr.isNotEmpty ? detailStr : null,
    );
  }

  /// Report a fatal crash (unhandled exception).
  Future<void> reportCrash(dynamic error, StackTrace stackTrace) async {
    if (!_enableErrorReporting) return;

    if (kDebugMode) {
      debugPrint(
        'ErrorReportingService: CRASH - ${sanitizeTelemetryText(error.toString(), maxLength: _kMaxTelemetryMessageLength)}',
      );
      debugPrint(
        sanitizeTelemetryText(
          stackTrace.toString(),
          maxLength: _kMaxTelemetryStackLength,
        ),
      );
      return;
    }

    await _sendOrQueueReport(
      type: 'crash',
      message: error.toString(),
      stackTrace: stackTrace.toString(),
    );
  }

  /// Report a Flutter framework error.
  Future<void> reportFlutterError(FlutterErrorDetails details) async {
    if (!_enableErrorReporting) return;

    if (kDebugMode) {
      debugPrint(
        'ErrorReportingService: FLUTTER_ERROR - ${sanitizeTelemetryText(details.exceptionAsString(), maxLength: _kMaxTelemetryMessageLength)}',
      );
      return;
    }

    await _sendOrQueueReport(
      type: 'flutter_error',
      message: details.exceptionAsString(),
      stackTrace: details.stack?.toString(),
      context: details.context?.toDescription(),
    );
  }

  Future<void> _sendOrQueueReport({
    required String type,
    required String message,
    String? stackTrace,
    String? context,
  }) async {
    if (!_isReportingEnabledForType(type)) return;

    final sanitizedType = sanitizeTelemetryText(type, maxLength: 32);
    final sanitizedMessage = sanitizeTelemetryText(
      message,
      maxLength: _kMaxTelemetryMessageLength,
    );
    final sanitizedContext = context == null
        ? null
        : sanitizeTelemetryText(
            context,
            maxLength: _kMaxTelemetryContextLength,
          );
    final sanitizedStack = stackTrace == null
        ? null
        : sanitizeTelemetryText(
            stackTrace,
            maxLength: _kMaxTelemetryStackLength,
          );
    final sanitizedAppVersion = sanitizeTelemetryText(
      _appVersion,
      maxLength: 40,
    );
    final sanitizedPlatform = sanitizeTelemetryText(
      detectPlatform(),
      maxLength: 20,
    );
    final sanitizedOsVersion = sanitizeTelemetryText(
      detectOsVersion(),
      maxLength: 120,
    );
    final sanitizedScreen = sanitizeTelemetryText(
      _currentScreen,
      maxLength: 80,
    );

    final report = ErrorReport(
      type: sanitizedType,
      message: sanitizedMessage,
      stackTrace: sanitizedStack,
      context: sanitizedContext,
      timestamp: DateTime.now().toUtc().toIso8601String(),
      appVersion: sanitizedAppVersion,
      platform: sanitizedPlatform,
      osVersion: sanitizedOsVersion,
      screenName: sanitizedScreen,
    );

    // Send via configured transport (fire and forget, don't block).
    unawaited(_sendViaTransport(report));
  }

  bool _isReportingEnabledForType(String type) {
    if (type == 'auth_event') return _enableDiagnosticEvents;
    return _enableErrorReporting;
  }

  /// Detect OS version safely (works on mobile and desktop; returns 'web' on web
  /// because [Platform] APIs are unavailable there).
  @visibleForTesting
  static String detectOsVersion() {
    if (kIsWeb) return 'web';
    try {
      return Platform.operatingSystemVersion;
    } catch (_) {
      return 'unknown';
    }
  }

  /// Detect platform safely (works on mobile and desktop only; web is handled
  /// via [kIsWeb] before reaching [Platform] APIs, which are unavailable on web).
  @visibleForTesting
  static String detectPlatform() {
    if (kIsWeb) return 'web';
    try {
      if (Platform.isIOS) return 'ios';
      if (Platform.isAndroid) return 'android';
      if (Platform.isMacOS) return 'macos';
      if (Platform.isLinux) return 'linux';
      if (Platform.isWindows) return 'windows';
      return Platform.operatingSystem;
    } catch (_) {
      return 'unknown';
    }
  }

  bool get _isReleaseLike => kReleaseMode || kProfileMode;

  @visibleForTesting
  bool get isRelayConfigured => _errorReportRelayUrl.isNotEmpty;

  ErrorReportTransport _buildTransport() {
    if (_isReleaseLike) {
      if (_errorReportRelayUrl.isEmpty) {
        return const DisabledErrorReportTransport(
          reason: 'release_transport_not_configured',
        );
      }
      return HttpRelayErrorReportTransport(
        client: _httpClient,
        relayUrl: _errorReportRelayUrl,
        apiKey: _errorReportRelayApiKey,
      );
    }

    if (_telegramBotToken.isNotEmpty && _telegramChatId.isNotEmpty) {
      return TelegramErrorReportTransport(
        client: _httpClient,
        botToken: _telegramBotToken,
        chatId: _telegramChatId,
        maxContextLength: _kMaxTelemetryContextLength,
      );
    }

    if (_errorReportRelayUrl.isNotEmpty) {
      return HttpRelayErrorReportTransport(
        client: _httpClient,
        relayUrl: _errorReportRelayUrl,
        apiKey: _errorReportRelayApiKey,
      );
    }

    return const DisabledErrorReportTransport(
      reason: 'no_transport_configured',
    );
  }

  Future<void> _sendViaTransport(ErrorReport report) async {
    final transport = _reportTransport ?? _buildTransport();
    await transport.send(report);
  }

  /// Format the error report as an HTML message for Telegram.
  @visibleForTesting
  static String formatTelegramMessage(ErrorReport report) {
    final emoji = switch (report.type) {
      'crash' => '🔴',
      'flutter_error' => '🟠',
      'critical' => '🔴',
      'error' => '🟡',
      'auth_event' => '🔵',
      'warning' => '⚪',
      _ => '⚪',
    };

    final buffer = StringBuffer();
    buffer.writeln(
      '$emoji <b>${escapeHtml(report.type.toUpperCase())}</b> в Seasons',
    );
    buffer.writeln();
    buffer.writeln(
      '📱 ${escapeHtml(report.platform)} ${escapeHtml(report.osVersion)}',
    );
    buffer.writeln('📦 Версия: ${escapeHtml(report.appVersion)}');
    buffer.writeln('📍 Экран: ${escapeHtml(report.screenName)}');
    buffer.writeln('🕐 ${escapeHtml(report.timestamp)}');
    buffer.writeln();
    buffer.writeln('❌ <code>${escapeHtml(report.message)}</code>');

    if (report.context != null && report.context!.isNotEmpty) {
      buffer.writeln('📋 ${escapeHtml(report.context!)}');
    }

    if (report.stackTrace != null && report.stackTrace!.isNotEmpty) {
      final shortStack = report.stackTrace!.split('\n').take(5).join('\n');
      buffer.writeln();
      buffer.writeln('<pre>${escapeHtml(shortStack)}</pre>');
    }

    var message = buffer.toString();
    if (message.length > _kTelegramMaxLength) {
      message = truncateTelegramHtml(message, _kTelegramMaxLength);
    }
    return message;
  }

  /// Safely truncate HTML for Telegram parse_mode=HTML.
  ///
  /// - Avoids cutting inside an HTML tag.
  /// - Ensures all opened tags (<b>, <code>, <pre>) are properly closed.
  /// - Appends "..." to indicate truncation while staying within [maxLength].
  @visibleForTesting
  static String truncateTelegramHtml(String html, int maxLength) {
    if (html.length <= maxLength) return html;

    const String ellipsis = '...';
    // Maximum total length of closing tags we may need to add: </b></code></pre>
    const int maxClosingTagsLength = '</b></code></pre>'.length;

    // Reserve space for ellipsis and worst-case closing tags.
    final int baseLimit = maxLength - ellipsis.length - maxClosingTagsLength;
    if (baseLimit <= 0) {
      return '';
    }

    var truncated = html.substring(0, baseLimit);

    // Avoid cutting inside a tag: if the last '<' comes after the last '>',
    // we have a partial tag at the end and should cut it off.
    final lastLt = truncated.lastIndexOf('<');
    final lastGt = truncated.lastIndexOf('>');
    if (lastLt > lastGt) {
      truncated = truncated.substring(0, lastLt);
    }

    // Track which tags are still open at the end of `truncated`.
    final openTags = <String>[];
    final tagPattern = RegExp(r'<(/?)(b|code|pre)(\s+[^>]*)?>');
    for (final match in tagPattern.allMatches(truncated)) {
      final isClosing = match.group(1) == '/';
      final tagName = match.group(2)!;
      if (!isClosing) {
        openTags.add(tagName);
      } else {
        final index = openTags.lastIndexOf(tagName);
        if (index != -1) {
          openTags.removeAt(index);
        }
      }
    }

    // Build closing tags in reverse order of opening to preserve nesting.
    final resultBuffer = StringBuffer(truncated);
    resultBuffer.write(ellipsis);
    for (var i = openTags.length - 1; i >= 0; i--) {
      resultBuffer.write('</${openTags[i]}>');
    }

    var result = resultBuffer.toString();

    // Safety: hard truncate if we somehow exceeded maxLength.
    if (result.length > maxLength) {
      result = result.substring(0, maxLength);

      // After hard truncation, remove any partial opening HTML tag.
      final int lastLt = result.lastIndexOf('<');
      final int lastGt = result.lastIndexOf('>');
      if (lastLt > lastGt) {
        result = result.substring(0, lastLt);
      }

      // Remove any partial HTML entity.
      final int lastAmp = result.lastIndexOf('&');
      final int lastSemi = result.lastIndexOf(';');
      if (lastAmp > lastSemi) {
        result = result.substring(0, lastAmp);
      }
    }

    return result;
  }

  /// Escape HTML special characters for Telegram HTML parse mode.
  @visibleForTesting
  static String escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');
  }
}

abstract class ErrorReportTransport {
  Future<void> send(ErrorReport report);
}

class DisabledErrorReportTransport implements ErrorReportTransport {
  final String reason;

  const DisabledErrorReportTransport({required this.reason});

  @override
  Future<void> send(ErrorReport report) async {
    if (kDebugMode) {
      debugPrint(
        'ErrorReportingService: transport disabled ($reason), report=${report.type}',
      );
    }
  }
}

class TelegramErrorReportTransport implements ErrorReportTransport {
  final http.Client client;
  final String botToken;
  final String chatId;
  final int maxContextLength;

  TelegramErrorReportTransport({
    required this.client,
    required this.botToken,
    required this.chatId,
    required this.maxContextLength,
  });

  @override
  Future<void> send(ErrorReport report) async {
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final message = ErrorReportingService.formatTelegramMessage(report);
        final telegramUrl = Uri.parse(
          'https://api.telegram.org/bot$botToken/sendMessage',
        );

        final response = await client
            .post(
              telegramUrl,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'chat_id': chatId,
                'text': message,
                'parse_mode': 'HTML',
                'disable_notification': report.type == 'warning',
              }),
            )
            .timeout(const Duration(seconds: 10));

        if (response.statusCode >= 200 && response.statusCode < 300) {
          return;
        }

        final isRetryable =
            response.statusCode == 429 || response.statusCode >= 500;
        if (!isRetryable) {
          if (kDebugMode) {
            debugPrint(
              'ErrorReportingService: Telegram API error ${response.statusCode}: ${ErrorReportingService.sanitizeTelemetryText(response.body, maxLength: maxContextLength)}',
            );
          }
          return;
        }
      } on SocketException catch (e) {
        if (kDebugMode) {
          debugPrint(
            'ErrorReportingService: Telegram network error (attempt ${attempt + 1}): ${ErrorReportingService.sanitizeTelemetryText(e.toString(), maxLength: maxContextLength)}',
          );
        }
      } on TimeoutException catch (e) {
        if (kDebugMode) {
          debugPrint(
            'ErrorReportingService: Telegram timeout (attempt ${attempt + 1}): ${ErrorReportingService.sanitizeTelemetryText(e.toString(), maxLength: maxContextLength)}',
          );
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint(
            'ErrorReportingService: Telegram send failed: ${ErrorReportingService.sanitizeTelemetryText(e.toString(), maxLength: maxContextLength)}',
          );
        }
        return;
      }

      if (attempt == 0) {
        await Future<void>.delayed(const Duration(seconds: 2));
      }
    }
  }
}

class HttpRelayErrorReportTransport implements ErrorReportTransport {
  final http.Client client;
  final String relayUrl;
  final String apiKey;

  HttpRelayErrorReportTransport({
    required this.client,
    required this.relayUrl,
    required this.apiKey,
  });

  @override
  Future<void> send(ErrorReport report) async {
    final endpoint = Uri.tryParse(relayUrl);
    if (endpoint == null) {
      if (kDebugMode) {
        debugPrint('ErrorReportingService: invalid relay URL');
      }
      return;
    }
    if (endpoint.scheme != 'https') {
      if (kDebugMode) {
        debugPrint(
          'ErrorReportingService: insecure relay URL scheme "${endpoint.scheme}". Only "https" is allowed.',
        );
      }
      return;
    }
    if (endpoint.host.isEmpty) {
      if (kDebugMode) {
        debugPrint(
          'ErrorReportingService: relay URL must include a non-empty host.',
        );
      }
      return;
    }

    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final headers = <String, String>{'Content-Type': 'application/json'};
        if (apiKey.isNotEmpty) {
          headers['Authorization'] = 'Bearer $apiKey';
        }

        final response = await client
            .post(endpoint, headers: headers, body: jsonEncode(report.toJson()))
            .timeout(const Duration(seconds: 10));

        if (response.statusCode >= 200 && response.statusCode < 300) {
          return;
        }

        final isRetryable =
            response.statusCode == 429 || response.statusCode >= 500;
        if (!isRetryable) {
          if (kDebugMode) {
            debugPrint(
              'ErrorReportingService: relay error ${response.statusCode}: ${ErrorReportingService.sanitizeTelemetryText(response.body, maxLength: _kMaxTelemetryContextLength)}',
            );
          }
          return;
        }
      } on SocketException catch (e) {
        if (kDebugMode) {
          debugPrint(
            'ErrorReportingService: relay network error (attempt ${attempt + 1}): ${ErrorReportingService.sanitizeTelemetryText(e.toString(), maxLength: _kMaxTelemetryContextLength)}',
          );
        }
      } on TimeoutException catch (e) {
        if (kDebugMode) {
          debugPrint(
            'ErrorReportingService: relay timeout (attempt ${attempt + 1}): ${ErrorReportingService.sanitizeTelemetryText(e.toString(), maxLength: _kMaxTelemetryContextLength)}',
          );
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint(
            'ErrorReportingService: relay send failed: ${ErrorReportingService.sanitizeTelemetryText(e.toString(), maxLength: _kMaxTelemetryContextLength)}',
          );
        }
        return;
      }

      if (attempt == 0) {
        await Future<void>.delayed(const Duration(seconds: 2));
      }
    }
  }
}

/// Error severity levels.
enum ErrorSeverity { warning, error, critical }

/// Error report data model.
/// Contains only non-PII information.
class ErrorReport {
  final String type;
  final String message;
  final String? stackTrace;
  final String? context;
  final String timestamp;
  final String appVersion;
  final String platform;
  final String osVersion;
  final String screenName;

  ErrorReport({
    required this.type,
    required this.message,
    this.stackTrace,
    this.context,
    required this.timestamp,
    required this.appVersion,
    required this.platform,
    required this.osVersion,
    required this.screenName,
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        'message': message,
        if (stackTrace != null) 'stackTrace': stackTrace,
        if (context != null) 'context': context,
        'timestamp': timestamp,
        'appVersion': appVersion,
        'platform': platform,
        'osVersion': osVersion,
        'screenName': screenName,
      };

  factory ErrorReport.fromJson(Map<String, dynamic> json) => ErrorReport(
        type: json['type'] as String,
        message: json['message'] as String,
        stackTrace: json['stackTrace'] as String?,
        context: json['context'] as String?,
        timestamp: json['timestamp'] as String,
        appVersion: json['appVersion'] as String,
        platform: json['platform'] as String,
        osVersion: json['osVersion'] as String,
        screenName: json['screenName'] as String,
      );
}

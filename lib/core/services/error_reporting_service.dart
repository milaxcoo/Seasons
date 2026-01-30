import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Privacy-first error reporting service.
/// 
/// Sends error reports to RUDN backend and/or Telegram without collecting any PII.
/// Errors are queued locally when offline and sent when connection is restored.
class ErrorReportingService {
  static final ErrorReportingService _instance = ErrorReportingService._internal();
  factory ErrorReportingService() => _instance;
  ErrorReportingService._internal();

  // ═══════════════════════════════════════════════════════════════════════════
  // CONFIGURATION
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Enable sending to RUDN backend (requires backend endpoint)
  static const bool _enableBackend = false;  // Set to true when backend is ready
  
  /// Enable sending to Telegram bot
  static const bool _enableTelegram = true;
  
  /// Telegram Bot Token - passed via --dart-define=TELEGRAM_BOT_TOKEN=xxx
  /// To build: flutter build apk --dart-define=TELEGRAM_BOT_TOKEN=your_token
  static const String _telegramBotToken = String.fromEnvironment(
    'TELEGRAM_BOT_TOKEN',
    defaultValue: '',
  );
  
  /// Telegram Chat ID - passed via --dart-define=TELEGRAM_CHAT_ID=xxx
  static const String _telegramChatId = String.fromEnvironment(
    'TELEGRAM_CHAT_ID',
    defaultValue: '',
  );
  
  // ═══════════════════════════════════════════════════════════════════════════
  
  static const String _baseUrl = 'https://seasons.rudn.ru';
  static const String _endpoint = '/api/v1/errors';
  static const String _queueKey = 'error_queue';
  static const int _maxQueueSize = 50;
  
  String _appVersion = 'unknown';
  String _currentScreen = 'unknown';
  bool _isInitialized = false;

  /// Initialize the error reporting service.
  /// Call this in main() before runApp().
  Future<void> initialize({required String appVersion}) async {
    if (_isInitialized) return;
    
    _appVersion = appVersion;
    _isInitialized = true;
    
    // Try to send any queued errors
    await _flushQueue();
    
    if (kDebugMode) {
      debugPrint('ErrorReportingService: Initialized (v$_appVersion)');
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
      message: '✅ Telegram интеграция работает! Все краши будут приходить сюда.',
      stackTrace: null,
      context: 'Test message',
      timestamp: DateTime.now().toUtc().toIso8601String(),
      appVersion: _appVersion,
      platform: Platform.isIOS ? 'ios' : 'android',
      osVersion: Platform.operatingSystemVersion,
      screenName: 'TestScreen',
    );
    
    try {
      await _sendToTelegram(testReport);
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
    // Don't report in debug mode unless explicitly enabled
    if (kDebugMode) {
      debugPrint('ErrorReportingService: ${severity.name.toUpperCase()} - $error');
      if (stackTrace != null) {
        debugPrint(stackTrace.toString().split('\n').take(5).join('\n'));
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

  /// Report a fatal crash (unhandled exception).
  Future<void> reportCrash(
    dynamic error,
    StackTrace stackTrace,
  ) async {
    if (kDebugMode) {
      debugPrint('ErrorReportingService: CRASH - $error');
      debugPrint(stackTrace.toString());
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
    if (kDebugMode) {
      debugPrint('ErrorReportingService: FLUTTER_ERROR - ${details.exceptionAsString()}');
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
    final report = ErrorReport(
      type: type,
      message: message,
      stackTrace: stackTrace,
      context: context,
      timestamp: DateTime.now().toUtc().toIso8601String(),
      appVersion: _appVersion,
      platform: Platform.isIOS ? 'ios' : 'android',
      osVersion: Platform.operatingSystemVersion,
      screenName: _currentScreen,
    );

    // Send to Telegram (fire and forget, don't block)
    if (_enableTelegram) {
      _sendToTelegram(report);
    }

    // Send to backend (with queueing for offline)
    if (_enableBackend) {
      try {
        await _sendToBackend(report);
      } catch (e) {
        // Network error - queue for later
        await _queueReport(report);
      }
    }
  }

  /// Send error report to Telegram bot
  Future<void> _sendToTelegram(ErrorReport report) async {
    if (_telegramBotToken.isEmpty || _telegramChatId.isEmpty) {
      // Not configured - build without --dart-define flags
      if (kDebugMode) {
        debugPrint('ErrorReportingService: Telegram not configured (missing TELEGRAM_BOT_TOKEN or TELEGRAM_CHAT_ID)');
      }
      return;
    }

    try {
      // Format message for Telegram
      final emoji = switch (report.type) {
        'crash' => '🔴',
        'flutter_error' => '🟠',
        'critical' => '🔴',
        'error' => '🟡',
        'warning' => '⚪',
        _ => '⚪',
      };

      final buffer = StringBuffer();
      buffer.writeln('$emoji *${report.type.toUpperCase()}* в Seasons');
      buffer.writeln();
      buffer.writeln('📱 ${report.platform} ${report.osVersion}');
      buffer.writeln('📦 Версия: ${report.appVersion}');
      buffer.writeln('📍 Экран: ${report.screenName}');
      buffer.writeln('🕐 ${report.timestamp}');
      buffer.writeln();
      buffer.writeln('❌ `${_escapeMarkdown(report.message)}`');
      
      if (report.stackTrace != null && report.stackTrace!.isNotEmpty) {
        // Take first 5 lines of stack trace
        final shortStack = report.stackTrace!
            .split('\n')
            .take(5)
            .join('\n');
        buffer.writeln();
        buffer.writeln('```');
        buffer.writeln(shortStack);
        buffer.writeln('```');
      }

      final telegramUrl = Uri.parse(
        'https://api.telegram.org/bot$_telegramBotToken/sendMessage'
      );

      await http.post(
        telegramUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'chat_id': _telegramChatId,
          'text': buffer.toString(),
          'parse_mode': 'Markdown',
          'disable_notification': report.type == 'warning',
        }),
      ).timeout(const Duration(seconds: 5));
    } catch (e) {
      // Silently fail - Telegram is best effort
      if (kDebugMode) {
        debugPrint('ErrorReportingService: Failed to send to Telegram: $e');
      }
    }
  }

  /// Escape special Markdown characters for Telegram
  String _escapeMarkdown(String text) {
    return text
        .replaceAll('_', '\\_')
        .replaceAll('*', '\\*')
        .replaceAll('[', '\\[')
        .replaceAll('`', '\\`');
  }

  /// Send error report to RUDN backend
  Future<void> _sendToBackend(ErrorReport report) async {
    final response = await http.post(
      Uri.parse('$_baseUrl$_endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'X-Requested-With': 'XMLHttpRequest',
      },
      body: jsonEncode(report.toJson()),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to send error report: ${response.statusCode}');
    }
  }

  Future<void> _queueReport(ErrorReport report) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queue = prefs.getStringList(_queueKey) ?? [];
      
      // Limit queue size to prevent memory issues
      if (queue.length >= _maxQueueSize) {
        queue.removeAt(0); // Remove oldest
      }
      
      queue.add(jsonEncode(report.toJson()));
      await prefs.setStringList(_queueKey, queue);
    } catch (e) {
      // Silently fail - we tried our best
    }
  }

  Future<void> _flushQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queue = prefs.getStringList(_queueKey) ?? [];
      
      if (queue.isEmpty) return;

      final failedReports = <String>[];
      
      for (final reportJson in queue) {
        try {
          final report = ErrorReport.fromJson(jsonDecode(reportJson));
          await _sendToBackend(report);
        } catch (e) {
          failedReports.add(reportJson);
        }
      }
      
      // Keep only failed reports
      await prefs.setStringList(_queueKey, failedReports);
    } catch (e) {
      // Silently fail
    }
  }
}

/// Error severity levels.
enum ErrorSeverity {
  warning,
  error,
  critical,
}

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

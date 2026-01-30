import 'package:flutter/material.dart';
import 'package:seasons/core/services/error_reporting_service.dart';

/// Mixin for StatefulWidget States to automatically track screen name.
/// 
/// Usage:
/// ```dart
/// class _MyScreenState extends State<MyScreen> with ScreenTrackingMixin {
///   @override
///   String get screenName => 'MyScreen';
/// }
/// ```
mixin ScreenTrackingMixin<T extends StatefulWidget> on State<T> {
  /// Override this to provide the screen name.
  String get screenName;

  @override
  void initState() {
    super.initState();
    ErrorReportingService().setCurrentScreen(screenName);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    ErrorReportingService().setCurrentScreen(screenName);
  }
}

/// Extension to report errors from any widget easily.
extension ErrorReportingContext on BuildContext {
  /// Report an error with context from this widget.
  void reportError(dynamic error, StackTrace? stackTrace, {String? context}) {
    ErrorReportingService().reportError(
      error,
      stackTrace,
      context: context,
    );
  }

  /// Report a warning.
  void reportWarning(String message, {String? context}) {
    ErrorReportingService().reportError(
      message,
      null,
      context: context,
      severity: ErrorSeverity.warning,
    );
  }
}

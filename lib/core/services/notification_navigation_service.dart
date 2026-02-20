import 'dart:async';
import 'package:flutter/foundation.dart';

/// Service for handling notification navigation events.
/// Uses StreamController to signal HomeScreen to navigate to specific tabs.
class NotificationNavigationService {
  static NotificationNavigationService? _instance;

  factory NotificationNavigationService() {
    _instance ??= NotificationNavigationService._internal();
    return _instance!;
  }

  NotificationNavigationService._internal();

  /// For testing purposes only
  @visibleForTesting
  static void setMockInstance(NotificationNavigationService mock) {
    _instance = mock;
  }

  final _navigationController =
      StreamController<NotificationNavigationEvent>.broadcast();

  /// Stream that HomeScreen listens to for navigation events
  Stream<NotificationNavigationEvent> get onNavigate =>
      _navigationController.stream;

  /// Call this when notification is tapped
  void navigateToTab(int tabIndex, {bool shouldRefresh = true}) {
    _navigationController.add(NotificationNavigationEvent(
      tabIndex: tabIndex,
      shouldRefresh: shouldRefresh,
    ));
  }

  void dispose() {
    _navigationController.close();
  }
}

class NotificationNavigationEvent {
  final int tabIndex;
  final bool shouldRefresh;

  NotificationNavigationEvent({
    required this.tabIndex,
    this.shouldRefresh = true,
  });
}

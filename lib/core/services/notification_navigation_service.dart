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

  /// For testing purposes only
  @visibleForTesting
  static void resetInstance() {
    _instance = null;
  }

  final _navigationController =
      StreamController<NotificationNavigationEvent>.broadcast();
  NotificationNavigationEvent? _pendingEvent;

  /// Stream that HomeScreen listens to for navigation events
  Stream<NotificationNavigationEvent> get onNavigate =>
      _navigationController.stream;

  /// Call this when notification is tapped
  void navigateToTab(int tabIndex, {bool shouldRefresh = true}) {
    final event = NotificationNavigationEvent(
      tabIndex: tabIndex,
      shouldRefresh: shouldRefresh,
    );

    if (_navigationController.hasListener) {
      _pendingEvent = null;
      _navigationController.add(event);
      return;
    }

    _pendingEvent = event;
  }

  /// Returns and clears the pending event that arrived before listeners.
  NotificationNavigationEvent? consumePendingNavigation() {
    final event = _pendingEvent;
    _pendingEvent = null;
    return event;
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

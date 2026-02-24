import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:seasons/core/services/notification_navigation_service.dart';

void main() {
  setUp(() {
    NotificationNavigationService.resetInstance();
  });

  tearDown(() {
    NotificationNavigationService.resetInstance();
  });

  test('buffers a navigation event until consumer is ready', () {
    final service = NotificationNavigationService();

    service.navigateToTab(2, shouldRefresh: false);

    final pending = service.consumePendingNavigation();
    expect(pending, isNotNull);
    expect(pending!.tabIndex, 2);
    expect(pending.shouldRefresh, isFalse);
    expect(service.consumePendingNavigation(), isNull);
  });

  test('delivers event immediately when listener is active', () async {
    final service = NotificationNavigationService();
    final completer = Completer<NotificationNavigationEvent>();

    final subscription = service.onNavigate.listen((event) {
      if (!completer.isCompleted) {
        completer.complete(event);
      }
    });

    service.navigateToTab(1, shouldRefresh: true);

    final event = await completer.future.timeout(const Duration(seconds: 1));
    expect(event.tabIndex, 1);
    expect(event.shouldRefresh, isTrue);
    expect(service.consumePendingNavigation(), isNull);

    await subscription.cancel();
  });

  test('keeps only latest pending event before listener subscribes', () {
    final service = NotificationNavigationService();

    service.navigateToTab(0, shouldRefresh: false);
    service.navigateToTab(2, shouldRefresh: true);

    final pending = service.consumePendingNavigation();
    expect(pending, isNotNull);
    expect(pending!.tabIndex, 2);
    expect(pending.shouldRefresh, isTrue);
  });
}

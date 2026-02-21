import 'dart:async';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:seasons/core/services/background_service.dart';

class MockFlutterBackgroundService extends Mock
    implements FlutterBackgroundService {}

class MockServiceInstance extends Mock implements ServiceInstance {}

class MockNotificationsPlugin extends Mock
    implements FlutterLocalNotificationsPlugin {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue(const NotificationDetails());
    registerFallbackValue(
      AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'channel',
        initialNotificationTitle: 'title',
        initialNotificationContent: 'content',
        foregroundServiceNotificationId: 1,
      ),
    );
    registerFallbackValue(
      IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  });

  group('BackgroundService', () {
    late MockFlutterBackgroundService mockService;

    setUp(() {
      mockService = MockFlutterBackgroundService();
    });

    test('initialize configures service once and startService starts when idle',
        () async {
      when(() => mockService.configure(
            androidConfiguration: any(named: 'androidConfiguration'),
            iosConfiguration: any(named: 'iosConfiguration'),
          )).thenAnswer((_) async => true);
      when(() => mockService.isRunning()).thenAnswer((_) async => false);
      when(() => mockService.startService()).thenAnswer((_) async => true);

      final service = BackgroundService.forTesting(
        service: mockService,
        notificationsInitializer: (_) async {},
      );

      await service.initialize();
      await service.initialize();
      await service.startService();

      verify(() => mockService.configure(
            androidConfiguration: any(named: 'androidConfiguration'),
            iosConfiguration: any(named: 'iosConfiguration'),
          )).called(1);
      verify(() => mockService.startService()).called(1);
    });

    test('startService does not start when already running', () async {
      when(() => mockService.configure(
            androidConfiguration: any(named: 'androidConfiguration'),
            iosConfiguration: any(named: 'iosConfiguration'),
          )).thenAnswer((_) async => true);
      when(() => mockService.isRunning()).thenAnswer((_) async => true);

      final service = BackgroundService.forTesting(
        service: mockService,
        notificationsInitializer: (_) async {},
      );

      await service.initialize();
      await service.startService();

      verifyNever(() => mockService.startService());
    });

    test('stopService invokes stop command', () async {
      when(() => mockService.invoke(any(), any())).thenReturn(null);

      final service = BackgroundService.forTesting(
        service: mockService,
        notificationsInitializer: (_) async {},
      );

      await service.stopService();

      verify(() => mockService.invoke('stopService', any())).called(1);
    });

    test('on getter proxies update stream', () async {
      final controller = StreamController<Map<String, dynamic>?>();
      when(() => mockService.on('update')).thenAnswer((_) => controller.stream);

      final service = BackgroundService.forTesting(
        service: mockService,
        notificationsInitializer: (_) async {},
      );

      final expectation = expectLater(
        service.on,
        emitsInOrder([
          {'state': 'ok'},
          emitsDone,
        ]),
      );
      controller.add({'state': 'ok'});
      await controller.close();
      await expectation;
    });
  });

  group('BackgroundService top-level logic', () {
    late MockServiceInstance mockInstance;
    late MockNotificationsPlugin mockNotifications;

    setUp(() {
      mockInstance = MockServiceInstance();
      mockNotifications = MockNotificationsPlugin();
      when(() => mockInstance.invoke(any(), any())).thenReturn(null);
      when(() => mockNotifications.show(
            any(),
            any(),
            any(),
            any(),
            payload: any(named: 'payload'),
          )).thenAnswer((_) async {});
    });

    test('handleMessageForTest sends update and notification for known action',
        () async {
      await handleMessageForTest(
        '{"action":"VotingStarted","data":{"id":1}}',
        mockInstance,
        mockNotifications,
      );

      verify(() => mockInstance.invoke('update', {
            'action': 'VotingStarted',
            'data': {'id': 1},
          })).called(1);
      verify(() => mockNotifications.show(
            any(),
            'Голосование началось!',
            'Нажмите, чтобы проголосовать',
            any(),
            payload: 'Navigate:VotingList:1',
          )).called(1);
    });

    test('handleMessageForTest reports unknown action for invalid payload',
        () async {
      await handleMessageForTest('not a json', mockInstance, mockNotifications);

      verify(() => mockInstance.invoke('update', {
            'action': 'unknown',
            'raw': 'not a json',
          })).called(1);
      verifyNever(() => mockNotifications.show(
            any(),
            any(),
            any(),
            any(),
            payload: any(named: 'payload'),
          ));
    });

    test('showAlertNotificationForTest ignores unsupported actions', () async {
      await showAlertNotificationForTest(
          mockNotifications, 'UNSUPPORTED_ACTION');

      verifyNever(() => mockNotifications.show(
            any(),
            any(),
            any(),
            any(),
            payload: any(named: 'payload'),
          ));
    });

    test('scheduleReconnectForTest replaces previous timer', () {
      var called = false;
      final previousTimer = Timer(const Duration(minutes: 1), () {});

      final timer = scheduleReconnectForTest(
        previousTimer,
        () {
          called = true;
        },
        attempts: 1,
      );

      expect(previousTimer.isActive, isFalse);
      expect(timer.isActive, isTrue);
      expect(called, isFalse);
      timer.cancel();
    });

    test('onIosBackground returns true', () async {
      expect(await onIosBackground(mockInstance), isTrue);
    });
  });
}

import 'dart:async';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:seasons/core/services/background_service.dart';

class MockFlutterBackgroundService extends Mock
    implements FlutterBackgroundService {}

class MockServiceInstance extends Mock implements ServiceInstance {}

class MockNotificationsPlugin extends Mock
    implements FlutterLocalNotificationsPlugin {}

class MockHttpClient extends Mock implements http.Client {}

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
    late MockHttpClient mockHttpClient;

    setUp(() {
      mockInstance = MockServiceInstance();
      mockNotifications = MockNotificationsPlugin();
      mockHttpClient = MockHttpClient();
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

    test('negotiateWsUrlWithTimeout returns response before timeout', () async {
      final uri = Uri.parse('https://example.com/ws');
      final headers = {'Cookie': 'session=token'};

      when(() => mockHttpClient.get(uri, headers: headers))
          .thenAnswer((_) async => http.Response('{"url":"wss://x"}', 200));

      final response = await negotiateWsUrlWithTimeout(
        client: mockHttpClient,
        uri: uri,
        headers: headers,
        timeout: const Duration(seconds: 1),
      );

      expect(response.statusCode, 200);
    });

    test('negotiateWsUrlWithTimeout throws TimeoutException on slow response',
        () async {
      final uri = Uri.parse('https://example.com/ws');
      final headers = {'Cookie': 'session=token'};

      when(() => mockHttpClient.get(uri, headers: headers)).thenAnswer(
        (_) => Future<http.Response>.delayed(
          const Duration(milliseconds: 30),
          () => http.Response('{"url":"wss://x"}', 200),
        ),
      );

      await expectLater(
        () => negotiateWsUrlWithTimeout(
          client: mockHttpClient,
          uri: uri,
          headers: headers,
          timeout: const Duration(milliseconds: 1),
        ),
        throwsA(isA<TimeoutException>()),
      );
    });
  });
}

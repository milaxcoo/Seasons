import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:web_socket_channel/io.dart';
import 'package:http/http.dart' as http;
import 'package:seasons/core/services/rudn_auth_service.dart';
import 'package:seasons/core/utils/safe_log.dart';

/// Background Service for maintaining WebSocket connection 24/7 on Android.
/// On iOS, standard behavior applies (connection only while app is active).
class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();
  factory BackgroundService() => _instance;
  BackgroundService._internal({
    FlutterBackgroundService? service,
    FlutterLocalNotificationsPlugin? notificationsPlugin,
    Future<void> Function(FlutterLocalNotificationsPlugin plugin)?
        notificationsInitializer,
  })  : _service = service ?? FlutterBackgroundService(),
        _notificationsPlugin =
            notificationsPlugin ?? FlutterLocalNotificationsPlugin(),
        _notificationsInitializer = notificationsInitializer;

  @visibleForTesting
  factory BackgroundService.forTesting({
    required FlutterBackgroundService service,
    FlutterLocalNotificationsPlugin? notificationsPlugin,
    Future<void> Function(FlutterLocalNotificationsPlugin plugin)?
        notificationsInitializer,
  }) {
    return BackgroundService._internal(
      service: service,
      notificationsPlugin: notificationsPlugin,
      notificationsInitializer: notificationsInitializer,
    );
  }

  final FlutterBackgroundService _service;
  final FlutterLocalNotificationsPlugin _notificationsPlugin;
  final Future<void> Function(FlutterLocalNotificationsPlugin plugin)?
      _notificationsInitializer;

  // Notification channel IDs
  static const String serviceChannelId = 'seasons_service';
  static const String alertChannelId = 'seasons_alerts';

  // WebSocket URL for negotiation
  static const String _wsNegotiateUrl =
      'https://seasons.rudn.ru/api/v1/voters/ws_connect';

  // Completer to ensure config is done before starting
  final Completer<void> _initCompleter = Completer<void>();

  void _logLifecycle(
    String event, {
    required String reason,
    bool? isRunning,
  }) {
    if (!kDebugMode) return;
    final payload = <String, Object?>{
      'event': event,
      'reason': reason,
      if (isRunning != null) 'isRunning': isRunning,
    };
    debugPrint('BackgroundService.lifecycle ${jsonEncode(payload)}');
  }

  /// Initialize the background service
  Future<void> initialize() async {
    if (_initCompleter.isCompleted) return;

    // Initialize local notifications first
    await _initNotifications();

    // Configure the background service
    await _service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false, // Don't start until user is logged in
        isForegroundMode: true,
        notificationChannelId: serviceChannelId,
        initialNotificationTitle: 'Seasons',
        initialNotificationContent: 'Ожидание уведомлений...',
        foregroundServiceNotificationId: 888,
        foregroundServiceTypes: [AndroidForegroundType.dataSync],
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );

    if (!_initCompleter.isCompleted) {
      _initCompleter.complete();
    }
  }

  /// Initialize notification channels
  Future<void> _initNotifications() async {
    final notificationsInitializer = _notificationsInitializer;
    if (notificationsInitializer != null) {
      await notificationsInitializer(_notificationsPlugin);
      return;
    }

    // Service status channel (silent, low importance)
    const serviceChannel = AndroidNotificationChannel(
      serviceChannelId,
      'Фоновая служба',
      description: 'Позволяет приложению работать в фоне',
      importance: Importance.low,
      playSound: false,
      enableVibration: false,
    );

    // Alert channel (high importance for actual updates)
    const alertChannel = AndroidNotificationChannel(
      alertChannelId,
      'Уведомления о голосованиях',
      description: 'Важные уведомления о новых голосованиях',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(serviceChannel);

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(alertChannel);

    // Explicitly request permission for Android 13+
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// Start the background service (call after user logs in)
  Future<void> startService({
    String reason = 'unspecified',
  }) async {
    _logLifecycle('start.requested', reason: reason);

    // Lazily initialize to avoid app-start work before authentication.
    if (!_initCompleter.isCompleted) {
      await initialize();
    }

    final isRunning = await _service.isRunning();
    if (isRunning) {
      _logLifecycle('start.skipped_already_running',
          reason: reason, isRunning: true);
      return;
    }

    await _service.startService();
    _logLifecycle('start.completed', reason: reason, isRunning: true);
  }

  /// Stop the background service (call on logout)
  Future<void> stopService({
    String reason = 'unspecified',
  }) async {
    _logLifecycle('stop.requested', reason: reason);

    final isRunning = await _service.isRunning();
    if (!isRunning) {
      _logLifecycle('stop.skipped_not_running',
          reason: reason, isRunning: false);
      return;
    }

    _service.invoke('stopService', {'reason': reason});
    _logLifecycle('stop.signal_sent', reason: reason, isRunning: true);
  }

  /// Get the service stream for UI updates
  Stream<Map<String, dynamic>?> get on => _service.on('update');

  /// Check if service is running
  Future<bool> get isRunning => _service.isRunning();
}

// ============================================================================
// TOP-LEVEL FUNCTIONS (Required for background isolate)
// ============================================================================

/// iOS background handler
@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

/// Main entry point for the background service
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  if (kDebugMode) print("BackgroundService: onStart called");

  // WebSocket connection state
  IOWebSocketChannel? channel;
  StreamSubscription<dynamic>? websocketSubscription;
  StreamSubscription<Map<String, dynamic>?>? stopSubscription;
  Timer? reconnectTimer;
  Timer? foregroundNotificationTimer;
  bool isConnected = false;
  int reconnectAttempts = 0;
  bool isStopped = false;

  void cancelRuntimeResources() {
    reconnectTimer?.cancel();
    reconnectTimer = null;
    foregroundNotificationTimer?.cancel();
    foregroundNotificationTimer = null;
    unawaited(websocketSubscription?.cancel());
    websocketSubscription = null;

    try {
      channel?.sink.close();
    } catch (_) {}
    channel = null;
    isConnected = false;
  }

  // Handle stop request
  stopSubscription = service.on('stopService').listen((event) async {
    if (isStopped) return;
    isStopped = true;

    final reason = event is Map<String, dynamic>
        ? (event['reason'] as String? ?? 'unknown')
        : 'unknown';
    if (kDebugMode) {
      debugPrint("BackgroundService: Stop requested from UI (reason: $reason)");
    }

    cancelRuntimeResources();
    await stopSubscription?.cancel();
    service.stopSelf();

    if (kDebugMode) print("BackgroundService: Stopped by request");
  });

  // Initialize notifications plugin for this isolate
  final notificationsPlugin = FlutterLocalNotificationsPlugin();
  await notificationsPlugin.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ),
  );

  // Connect to WebSocket
  Future<void> connect() async {
    if (isStopped || isConnected) return;

    try {
      // Get auth cookie from secure storage (need to access it differently in isolate)
      final cookie = await RudnAuthService().getCookie();
      if (isStopped) return;

      if (cookie == null || cookie.isEmpty) {
        if (kDebugMode) {
          print("BackgroundService: No auth cookie, scheduling reconnect");
        }
        reconnectTimer = _scheduleReconnect(reconnectTimer, () {
          if (isStopped) return;
          unawaited(connect());
        }, attempts: reconnectAttempts++);
        return;
      }

      final headers = {
        'Cookie': 'session=$cookie',
        'User-Agent':
            'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1',
      };

      if (kDebugMode) print("BackgroundService: Negotiating WS connection...");

      // Step 1: Get the actual WebSocket URL
      final response = await http
          .get(
            Uri.parse(BackgroundService._wsNegotiateUrl),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception("Failed to negotiate WS URL: ${response.statusCode}");
      }

      final data = jsonDecode(response.body);
      final realWsUrl = data['url'] as String;

      if (kDebugMode) {
        print(
          "BackgroundService: Connecting to ${sanitizeUrlForLog(realWsUrl)}",
        );
      }

      // Step 2: Connect to the dynamic URL
      channel = IOWebSocketChannel.connect(
        Uri.parse(realWsUrl),
        headers: {
          ...headers,
          'Origin': 'https://seasons.rudn.ru',
        },
      );
      if (isStopped) {
        cancelRuntimeResources();
        return;
      }

      isConnected = true;
      reconnectTimer?.cancel();
      reconnectAttempts = 0; // Reset backoff on successful connection

      // Listen to messages
      websocketSubscription = channel!.stream.listen(
        (message) {
          if (isStopped) return;
          if (kDebugMode) {
            final sanitized = sanitizeObjectForLog(message)
                .replaceAll('\n', ' ')
                .replaceAll('\r', ' ');
            final preview = sanitized.length > 200
                ? '${sanitized.substring(0, 200)}...'
                : sanitized;
            debugPrint("BackgroundService: WS Received (preview): $preview");
          }
          _handleMessage(
            message,
            service,
            notificationsPlugin,
            isStopped: () => isStopped,
          );
        },
        onDone: () {
          if (isStopped) return;
          if (kDebugMode) print("BackgroundService: WS Connection closed");
          isConnected = false;
          channel = null;
          reconnectTimer = _scheduleReconnect(reconnectTimer, () {
            if (isStopped) return;
            unawaited(connect());
          }, attempts: reconnectAttempts++);
        },
        onError: (error) {
          if (isStopped) return;
          if (kDebugMode) {
            debugPrint(
                "BackgroundService: WS Error: ${sanitizeObjectForLog(error)}");
          }
          isConnected = false;
          channel = null;
          reconnectTimer = _scheduleReconnect(reconnectTimer, () {
            if (isStopped) return;
            unawaited(connect());
          }, attempts: reconnectAttempts++);
        },
      );
    } catch (e) {
      if (isStopped) return;
      if (kDebugMode) {
        debugPrint(
            "BackgroundService: Connection failed: ${sanitizeObjectForLog(e)}");
      }
      reconnectTimer = _scheduleReconnect(reconnectTimer, () {
        if (isStopped) return;
        unawaited(connect());
      }, attempts: reconnectAttempts++);
    }
  }

  // Initial connection
  await connect();

  // Keep service alive with periodic updates (Android foreground requirement)
  if (service is AndroidServiceInstance) {
    foregroundNotificationTimer =
        Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (isStopped) {
        timer.cancel();
        return;
      }
      try {
        if (await service.isForegroundService()) {
          if (isStopped) return;
          service.setForegroundNotificationInfo(
            title: 'Seasons',
            content: isConnected
                ? 'Подключено к серверу уведомлений'
                : 'Переподключение...',
          );
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint(
            "BackgroundService: Foreground notification update skipped: "
            "${sanitizeObjectForLog(e)}",
          );
        }
        timer.cancel();
      }
    });
  }
}

/// Handle incoming WebSocket message
Future<void> _handleMessage(dynamic message, ServiceInstance service,
    FlutterLocalNotificationsPlugin notificationsPlugin,
    {bool Function()? isStopped}) async {
  if (message is String) {
    // Skip control messages
    if (message.startsWith('Connection') || message.startsWith('Ping')) {
      return;
    }

    try {
      final json = jsonDecode(message);
      if (json is Map<String, dynamic> && json.containsKey('action')) {
        final action = json['action'] as String?;

        // Notify UI to refresh (if app is open)
        if (isStopped?.call() ?? false) return;
        try {
          service.invoke('update', {'action': action, 'data': json['data']});
        } catch (e) {
          if (kDebugMode) {
            debugPrint(
              "BackgroundService: update invoke skipped: "
              "${sanitizeObjectForLog(e)}",
            );
          }
          return;
        }

        // Show local notification
        if (isStopped?.call() ?? false) return;
        await _showAlertNotification(notificationsPlugin, action);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            "BackgroundService: Parse error: ${sanitizeObjectForLog(e)}");
      }
      // Still trigger refresh for unrecognized messages
      if (isStopped?.call() ?? false) return;
      try {
        service.invoke('update', {'action': 'unknown', 'raw': message});
      } catch (_) {
        // Ignore channel errors when isolate/service is already stopping.
      }
    }
  }
}

/// Show alert notification for important updates
Future<void> _showAlertNotification(
  FlutterLocalNotificationsPlugin plugin,
  String? action,
) async {
  // Default to null - we only show notifications for specific events
  String? title;
  String? body;
  String payload = 'Navigate:VotingList:0';

  if (action != null) {
    if (action.contains('VotingStarted')) {
      title = 'Голосование началось!';
      body = 'Нажмите, чтобы проголосовать';
      payload = 'Navigate:VotingList:1'; // Active voting tab
    } else if (action.contains('RegistrationStarted')) {
      title = 'Открыта регистрация!';
      body = 'Нажмите, чтобы зарегистрироваться';
      payload = 'Navigate:VotingList:0'; // Registration tab
    } else if (action.contains('VotingEnded')) {
      title = 'Голосование завершено';
      body = 'Доступны результаты';
      payload = 'Navigate:VotingList:2'; // Results tab
    } else if (action.contains('REFRESH_VOTES')) {
      title = 'Обновление голосований';
      body = 'Доступны новые голосования!';
      payload = 'Navigate:VotingList:0'; // Registration tab
    }
  }

  // If the action is unknown or not one of the above, DO NOT show a notification
  if (title == null || body == null) {
    if (kDebugMode) {
      debugPrint(
          "BackgroundService: Action '$action' ignored for notification");
    }
    return;
  }

  await plugin.show(
    DateTime.now().millisecondsSinceEpoch ~/ 1000,
    title,
    body,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        BackgroundService.alertChannelId,
        'Уведомления о голосованиях',
        channelDescription: 'Важные уведомления о новых голосованиях',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    ),
    payload: payload,
  );
}

/// Schedule reconnection with exponential backoff (5s, 10s, 20s, ... capped at 300s)
Timer _scheduleReconnect(Timer? timer, Function() connect, {int attempts = 0}) {
  timer?.cancel();
  final delaySec = (5 * (1 << attempts)).clamp(5, 300);
  if (kDebugMode) {
    debugPrint(
        "BackgroundService: Scheduling reconnect in ${delaySec}s (attempt ${attempts + 1})...");
  }
  return Timer(Duration(seconds: delaySec), connect);
}

@visibleForTesting
Future<http.Response> negotiateWsUrlWithTimeout({
  required http.Client client,
  required Uri uri,
  required Map<String, String> headers,
  Duration timeout = const Duration(seconds: 10),
}) {
  return client.get(uri, headers: headers).timeout(timeout);
}

@visibleForTesting
Future<void> handleMessageForTest(dynamic message, ServiceInstance service,
    FlutterLocalNotificationsPlugin notificationsPlugin,
    {bool Function()? isStopped}) {
  return _handleMessage(
    message,
    service,
    notificationsPlugin,
    isStopped: isStopped,
  );
}

@visibleForTesting
Future<void> showAlertNotificationForTest(
  FlutterLocalNotificationsPlugin plugin,
  String? action,
) {
  return _showAlertNotification(plugin, action);
}

@visibleForTesting
Timer scheduleReconnectForTest(
  Timer? timer,
  Function() connect, {
  int attempts = 0,
}) {
  return _scheduleReconnect(timer, connect, attempts: attempts);
}

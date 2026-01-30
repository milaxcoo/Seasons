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

/// Background Service for maintaining WebSocket connection 24/7 on Android.
/// On iOS, standard behavior applies (connection only while app is active).
class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();
  factory BackgroundService() => _instance;
  BackgroundService._internal();

  final FlutterBackgroundService _service = FlutterBackgroundService();
  
  // Notification channel IDs
  static const String serviceChannelId = 'seasons_service';
  static const String alertChannelId = 'seasons_alerts';
  
  // WebSocket URL for negotiation
  static const String _wsNegotiateUrl = 'https://seasons.rudn.ru/api/v1/voters/ws_connect';

  // Completer to ensure config is done before starting
  final Completer<void> _initCompleter = Completer<void>();

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
    final plugin = FlutterLocalNotificationsPlugin();
    
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
    
    await plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(serviceChannel);
    
    await plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(alertChannel);
        
    // Explicitly request permission for Android 13+
    await plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// Start the background service (call after user logs in)
  Future<void> startService() async {
    // Wait for initialization if needed
    if (!_initCompleter.isCompleted) {
      await _initCompleter.future;
    }

    final isRunning = await _service.isRunning();
    if (!isRunning) {
      await _service.startService();
      if (kDebugMode) print("BackgroundService: Service started");
    }
  }

  /// Stop the background service (call on logout)
  Future<void> stopService() async {
    _service.invoke('stopService');
    if (kDebugMode) print("BackgroundService: Service stopped");
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
  
  // Handle stop request
  service.on('stopService').listen((event) {
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
  
  // WebSocket connection state
  IOWebSocketChannel? channel;
  Timer? reconnectTimer;
  bool isConnected = false;
  
  // Connect to WebSocket
  Future<void> connect() async {
    if (isConnected) return;
    
    try {
      // Get auth cookie from secure storage (need to access it differently in isolate)
      final cookie = await RudnAuthService().getCookie();
      if (cookie == null || cookie.isEmpty) {
        if (kDebugMode) print("BackgroundService: No auth cookie, scheduling reconnect");
        reconnectTimer = _scheduleReconnect(reconnectTimer, () => connect());
        return;
      }

      final headers = {
        'Cookie': 'session=$cookie',
        'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1',
      };

      if (kDebugMode) print("BackgroundService: Negotiating WS connection...");

      // Step 1: Get the actual WebSocket URL
      final response = await http.get(
        Uri.parse(BackgroundService._wsNegotiateUrl),
        headers: headers,
      );

      if (response.statusCode != 200) {
        throw Exception("Failed to negotiate WS URL: ${response.statusCode}");
      }

      final data = jsonDecode(response.body);
      final realWsUrl = data['url'] as String;
      
      if (kDebugMode) print("BackgroundService: Connecting to $realWsUrl");

      // Step 2: Connect to the dynamic URL
      channel = IOWebSocketChannel.connect(
        Uri.parse(realWsUrl),
        headers: {
          ...headers,
          'Origin': 'https://seasons.rudn.ru',
        },
      );

      isConnected = true;
      reconnectTimer?.cancel();

      // Listen to messages
      channel!.stream.listen(
        (message) {
          if (kDebugMode) print("BackgroundService: WS Received: $message");
          _handleMessage(message, service, notificationsPlugin);
        },
        onDone: () {
          if (kDebugMode) print("BackgroundService: WS Connection closed");
          isConnected = false;
          channel = null;
          reconnectTimer = _scheduleReconnect(reconnectTimer, () => connect());
        },
        onError: (error) {
          if (kDebugMode) print("BackgroundService: WS Error: $error");
          isConnected = false;
          channel = null;
          reconnectTimer = _scheduleReconnect(reconnectTimer, () => connect());
        },
      );
    } catch (e) {
      if (kDebugMode) print("BackgroundService: Connection failed: $e");
      reconnectTimer = _scheduleReconnect(reconnectTimer, () => connect());
    }
  }
  
  // Initial connection
  await connect();
  
  // Keep service alive with periodic updates (Android foreground requirement)
  if (service is AndroidServiceInstance) {
    Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (await service.isForegroundService()) {
        service.setForegroundNotificationInfo(
          title: 'Seasons',
          content: isConnected 
              ? 'Подключено к серверу уведомлений' 
              : 'Переподключение...',
        );
      }
    });
  }
}

/// Handle incoming WebSocket message
void _handleMessage(
  dynamic message, 
  ServiceInstance service,
  FlutterLocalNotificationsPlugin notificationsPlugin,
) async {
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
        service.invoke('update', {'action': action, 'data': json['data']});
        
        // Show local notification
        await _showAlertNotification(notificationsPlugin, action);
      }
    } catch (e) {
      if (kDebugMode) print("BackgroundService: Parse error: $e");
      // Still trigger refresh for unrecognized messages
      service.invoke('update', {'action': 'unknown', 'raw': message});
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
    if (kDebugMode) print("BackgroundService: Action '$action' ignored for notification");
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

/// Schedule reconnection
Timer _scheduleReconnect(Timer? timer, Function() connect) {
  timer?.cancel();
  if (kDebugMode) print("BackgroundService: Scheduling reconnect in 5s...");
  return Timer(const Duration(seconds: 5), connect);
}

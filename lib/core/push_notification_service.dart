import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:seasons/core/services/rudn_auth_service.dart';

/// Top-level background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    print('Background message received: ${message.messageId}');
    print('Data: ${message.data}');
  }
}

/// Service class to manage Firebase Cloud Messaging (FCM) logic
class PushNotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Navigation callback - set this from your app to handle notification taps
  Function(String votingId)? onNotificationTap;

  Future<void> initialize() async {
    // Initialize local notifications
    await _initializeLocalNotifications();

    // Request permissions for iOS and web
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      if (kDebugMode) {
        print('FCM: User granted permission');
      }
    } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
      if (kDebugMode) {
        print('FCM: User declined permission');
      }
      return; // Don't proceed if permission denied
    }

    // Get and handle FCM token
    await _handleToken();

    // Listen for token refresh
    _fcm.onTokenRefresh.listen((newToken) {
      if (kDebugMode) {
        print('FCM Token Refreshed: $newToken');
      }
      _sendTokenToServer(newToken);
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Foreground message received: ${message.messageId}');
      }

      if (message.notification != null) {
        _showLocalNotification(
          title: message.notification!.title ?? 'Новое уведомление',
          body: message.notification!.body ?? '',
          data: message.data,
        );
      }
    });

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Notification tapped (background): ${message.data}');
      }
      _handleNotificationTap(message.data);
    });

    // Handle notification tap when app was terminated
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      if (kDebugMode) {
        print('App opened from notification (terminated): ${initialMessage.data}');
      }
      // Delay to ensure navigation context is ready
      Future.delayed(const Duration(seconds: 1), () {
        _handleNotificationTap(initialMessage.data);
      });
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          if (kDebugMode) {
            print('Local notification tapped: ${response.payload}');
          }
          // Parse payload and handle navigation
          try {
            final data = response.payload!.split('|');
            if (data.isNotEmpty && data[0].isNotEmpty) {
              _handleNotificationTap({'votingId': data[0]});
            }
          } catch (e) {
            if (kDebugMode) {
              print('Error parsing notification payload: $e');
            }
          }
        }
      },
    );

    // Create Android notification channel
    if (Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        'seasons_notifications',
        'Голосования',
        description: 'Уведомления о новых голосованиях и результатах',
        importance: Importance.high,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  Future<void> _handleToken() async {
    String? fcmToken;

    // Platform-specific token generation
    if (!kIsWeb && Platform.isIOS) {
      // iOS requires APNS token first
      final apnsToken = await _fcm.getAPNSToken();
      if (apnsToken != null) {
        fcmToken = await _fcm.getToken();
      } else {
        if (kDebugMode) {
          print('FCM: Running on iOS simulator, APNS token not available');
        }
      }
    } else if (!kIsWeb && Platform.isAndroid) {
      fcmToken = await _fcm.getToken();
    }

    if (fcmToken != null) {
      if (kDebugMode) {
        print('FCM Token: $fcmToken');
      }
      await _sendTokenToServer(fcmToken);
    }
  }

  Future<void> _sendTokenToServer(String token) async {
    try {
      final cookie = await RudnAuthService().getCookie();
      if (cookie == null) {
        if (kDebugMode) {
          print('FCM: No auth cookie, skipping token upload');
        }
        return;
      }

      final response = await http.post(
        Uri.parse('https://seasons.rudn.ru/api/v1/fcm/register'),
        headers: {
          'Cookie': 'session=$cookie',
          'Content-Type': 'application/json',
          'X-Requested-With': 'XMLHttpRequest',
        },
        body: '{"fcm_token": "$token", "platform": "${Platform.operatingSystem}"}',
      );

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('FCM: Token successfully sent to server');
        }
      } else {
        if (kDebugMode) {
          print('FCM: Failed to send token (${response.statusCode}): ${response.body}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('FCM: Error sending token to server: $e');
      }
    }
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    final votingId = data['votingId']?.toString() ?? '';

    const androidDetails = AndroidNotificationDetails(
      'seasons_notifications',
      'Голосования',
      channelDescription: 'Уведомления о новых голосованиях и результатах',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch % 100000, // Unique ID
      title,
      body,
      details,
      payload: votingId, // Pass votingId for tap handling
    );
  }

  void _handleNotificationTap(Map<String, dynamic> data) {
    final votingId = data['votingId']?.toString();

    if (votingId != null && votingId.isNotEmpty) {
      if (kDebugMode) {
        print('FCM: Navigating to voting: $votingId');
      }
      // Call the navigation callback if set
      onNotificationTap?.call(votingId);
    }
  }
}

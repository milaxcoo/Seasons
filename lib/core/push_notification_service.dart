import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

// A dedicated service class to manage all Firebase Cloud Messaging (FCM) logic.
class PushNotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future<void> initialize() async {
    // Request permissions for iOS and web
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // User granted permission
    } else {
      // User declined or has not accepted permission
    }

    // FIXED: Only try to get the FCM token on real devices, not simulators.
    // kIsWeb is a compile-time constant that checks if the app is running on the web.
    // Platform.isIOS checks for the iOS platform at runtime.
    if (!kIsWeb && Platform.isIOS) {
      // On a real iOS device, you can get the APNS token.
      final apnsToken = await _fcm.getAPNSToken();
      if (apnsToken != null) {
        // APNS and FCM tokens obtained
        await _fcm.getToken();
      } else {
        // This will run on a simulator, preventing the crash.
        // This will run on a simulator, preventing the crash.
      }
    } else if (!kIsWeb && Platform.isAndroid) {
      // Android doesn't need an APNS token.
      await _fcm.getToken();
      // print('Firebase Cloud Messaging Token: $fcmToken');
    }

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        // Handle notification
      }
    });

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // Handle notification tap
    });

    // Handle notification tap when app is terminated
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      // Handle initial message
    }
  }
}

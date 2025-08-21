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
      print('User granted permission for notifications.');
    } else {
      print('User declined or has not accepted permission.');
    }

    // FIXED: Only try to get the FCM token on real devices, not simulators.
    // kIsWeb is a compile-time constant that checks if the app is running on the web.
    // Platform.isIOS checks for the iOS platform at runtime.
    if (!kIsWeb && Platform.isIOS) {
      // On a real iOS device, you can get the APNS token.
      final apnsToken = await _fcm.getAPNSToken();
      if (apnsToken != null) {
        final fcmToken = await _fcm.getToken();
        print('Firebase Cloud Messaging Token: $fcmToken');
      } else {
        // This will run on a simulator, preventing the crash.
        print('Could not get APNS token, probably running on a simulator.');
      }
    } else if (!kIsWeb && Platform.isAndroid) {
      // Android doesn't need an APNS token.
      final fcmToken = await _fcm.getToken();
      print('Firebase Cloud Messaging Token: $fcmToken');
    }


    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification!.title}');
      }
    });

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Message opened from background: ${message.notification!.title}');
    });

    // Handle notification tap when app is terminated
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      print('Message opened from terminated state: ${initialMessage.notification!.title}');
    }
  }
}

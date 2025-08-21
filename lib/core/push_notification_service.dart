
import 'package:firebase_messaging/firebase_messaging.dart';

class PushNotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future<void> initialize() async {
    // Request permissions for iOS and web
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('User granted permission: ${settings.authorizationStatus}');

    // Get the FCM token
    final fcmToken = await _fcm.getToken();
    print('FCM Token: $fcmToken');

    // Listen for token refreshes
    _fcm.onTokenRefresh.listen((newToken) {
      print('FCM Token Refreshed: $newToken');
      // In a real app, send this new token to your server
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification!= null) {
        print('Message also contained a notification: ${message.notification}');
      }
    });

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('A new onMessageOpenedApp event was published!');
      print('Message data: ${message.data}');
      // Here you can navigate to a specific screen based on message data
    });

    // Handle notification tap when app is terminated
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage!= null) {
      print('App was opened from a terminated state by a notification');
      print('Message data: ${initialMessage.data}');
      // Handle initial message
    }
  }
}
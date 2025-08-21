import 'package:firebase_messaging/firebase_messaging.dart';

// A dedicated service class to manage all Firebase Cloud Messaging (FCM) logic.
// This keeps the notification code organized and decoupled from the UI.
class PushNotificationService {
  // Get an instance of the FirebaseMessaging service.
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future<void> initialize() async {
    // --- 1. Request Permissions ---
    // On iOS, the user must explicitly grant permission to receive notifications.
    // This has no effect on Android, where permission is granted by default.
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

    // --- 2. Get the FCM Token ---
    // This unique token identifies the device. In a real application, you would
    // send this token to your backend server to associate it with the user.
    final fcmToken = await _fcm.getToken();
    print('Firebase Cloud Messaging Token: $fcmToken');

    // --- 3. Set up Message Handlers ---
    // These listeners handle incoming messages in different app states.

    // FORGROUND: When the app is open and in view.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification!.title}');
      }
    });

    // BACKGROUND: When the app is in the background (but not terminated) and the user
    // taps on the notification.
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Message opened from background: ${message.notification!.title}');
      // Here you could navigate to a specific screen based on message data.
    });

    // TERMINATED: When the app has been closed completely and is opened by the user
    // tapping on the notification.
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      print('Message opened from terminated state: ${initialMessage.notification!.title}');
      // Handle the initial message here as well.
    }
  }
}

import 'dart:io' show Platform;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM] Background message: ${message.notification?.title}');
}

/// Returns true if the current platform supports firebase_messaging.
/// FCM is NOT supported on Windows, Linux, or macOS desktop.
bool get _fcmSupported =>
    !kIsWeb && (Platform.isAndroid || Platform.isIOS);

class FcmService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> init() async {
    if (!_fcmSupported) {
      debugPrint('[FCM] Skipped — not supported on this platform.');
      return;
    }

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('[FCM] Foreground: ${message.notification?.title}');
      // GetX snackbar or local notification can be shown here
    });

    // Notification tap (app in background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('[FCM] Opened from: ${message.data}');
      _handleNotificationNavigation(message.data);
    });

    // Check if app was opened from a terminated state notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationNavigation(initialMessage.data);
    }
  }

  void _handleNotificationNavigation(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    if (type == 'new_match') {
      // Get.toNamed(AppRoutes.devDashboard);
    } else if (type == 'project_update') {
      // Get.toNamed(AppRoutes.ownerDashboard);
    }
  }
}


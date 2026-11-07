import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Top-level background message handler for FCM.
/// Executed even when the application is terminated or in background.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Platform.isWindows || Platform.isLinux) return;
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  if (kDebugMode) {
    print('[PushNotificationService] Background message received: ${message.messageId}');
  }
}

class PushNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static bool _initialized = false;

  /// Call once during application startup.
  static Future<void> initialize() async {
    if (_initialized) return;
    if (Platform.isWindows || Platform.isLinux) return;

    try {
      // 1. Request user permission (prompts on iOS and Android 13+)
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (kDebugMode) {
        print('[PushNotificationService] Authorization status: ${settings.authorizationStatus}');
      }

      // 2. Set foreground presentation options (so notifications show alert/sound while in-app)
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 3. Subscribe to broadcast topics
      // In Firebase Console, you can simply send to Topic: 'all' or 'updates'
      // and it will reach ALL installed devices without needing any server database!
      try {
        await _messaging.subscribeToTopic('all');
        await _messaging.subscribeToTopic('updates');
        if (kDebugMode) {
          print('[PushNotificationService] Subscribed to topics: all, updates');
        }
      } catch (e) {
        if (kDebugMode) {
          print('[PushNotificationService] Topic subscription note: $e');
        }
      }

      // 4. Handle notification tap when application was closed / terminated
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageAction(initialMessage);
      }

      // 5. Handle notification tap when application is in background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleMessageAction(message);
      });

      // 6. Log foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (kDebugMode) {
          print('[PushNotificationService] Foreground notification: ${message.notification?.title}');
        }
      });

      _initialized = true;
    } catch (e) {
      if (kDebugMode) {
        print('[PushNotificationService] Initialization error: $e');
      }
    }
  }

  static Future<void> _handleMessageAction(RemoteMessage message) async {
    final url = message.data['url'] as String?;
    if (url != null && url.trim().isNotEmpty) {
      final uri = Uri.tryParse(url.trim());
      if (uri != null) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  static Future<String?> getToken() async {
    if (Platform.isWindows || Platform.isLinux) return null;
    try {
      return await _messaging.getToken();
    } catch (e) {
      return null;
    }
  }
}

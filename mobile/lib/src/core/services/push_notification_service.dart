import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final pushNotificationServiceProvider =
    Provider<PushNotificationService>((ref) => PushNotificationService());

class PushNotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> init(String? uid) async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      if (kDebugMode) print('[FCM] Permission denied');
      return;
    }

    final token = await _messaging.getToken();
    if (kDebugMode) print('[FCM] Token: $token');

    if (uid != null && token != null) {
      await _saveToken(uid, token);
    }

    _messaging.onTokenRefresh.listen((newToken) {
      if (uid != null) _saveToken(uid, newToken);
    });

    await _messaging.subscribeToTopic('all_users');
    await _messaging.subscribeToTopic('app_updates');

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);
  }

  Future<void> _saveToken(String uid, String token) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'fcmToken': token, 'fcmTokenUpdatedAt': FieldValue.serverTimestamp()});
    } catch (e) {
      if (kDebugMode) print('[FCM] Token save error: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      print('[FCM] Foreground message: ${message.notification?.title}');
    }
  }

  void _handleMessageTap(RemoteMessage message) {
    if (kDebugMode) {
      print('[FCM] Message tap: ${message.data}');
    }
  }
}

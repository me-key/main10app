import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  // Singleton
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  String? _token;
  String? get token => _token;

  Future<void> initialize() async {
    // 1. Request permissions (especially for iOS)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('🔔 User granted notification permission');
    } else {
      debugPrint('🔔 User declined or has not accepted notification permission');
    }

    // 2. Initialize Flutter Local Notifications for foreground messages
    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsIOS = DarwinInitializationSettings();
    
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('🔔 Notification clicked: ${response.payload}');
        // Handle notification click here (deep linking)
      },
    );

    // 3. Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('🔔 Got a message whilst in the foreground!');
      debugPrint('🔔 Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('🔔 Message also contained a notification: ${message.notification}');
        _showLocalNotification(message);
      }
    });

    // 4. Get the token
    _token = await _fcm.getToken();
    debugPrint('🔔 FCM Token: $_token');

    // 5. Listen for token refresh
    _fcm.onTokenRefresh.listen((newToken) {
      _token = newToken;
      debugPrint('🔔 FCM Token refreshed: $newToken');
      // If user is logged in, we should update this in Firestore
    });
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'main_channel',
      'Main Notifications',
      channelDescription: 'Main notification channel for Maintens app',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );
    
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      platformChannelSpecifics,
      payload: message.data.toString(),
    );
  }

  Future<void> saveTokenToFirestore(String userId) async {
    if (_token == null) return;
    
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'fcmToken': _token,
      });
      debugPrint('🔔 Token saved to Firestore for user $userId');
    } catch (e) {
      debugPrint('🔔 Error saving token to Firestore: $e');
    }
  }

  Future<void> deleteToken() async {
    await _fcm.deleteToken();
    _token = null;
  }
}

// lib/services/notification_service.dart (FINAL & CORRECTED)
import 'dart:convert';
import 'package:apna_thekedar_specialist/main.dart';
import 'package:apna_thekedar_specialist/profile/screens/kyc_screen.dart';
import 'package:apna_thekedar_specialist/projects/screens/project_details_screen.dart';
import 'package:apna_thekedar_specialist/projects/screens/requirement_list_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    await messaging.requestPermission(
      alert: true, badge: true, sound: true,
    );

    await _createAndroidNotificationChannels();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    
    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        if (details.payload != null) {
          handleNotificationTap(json.decode(details.payload!));
        }
      },
    );

    // Jab app foreground mein ho, tab Firebase se notification handle karein
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground Firebase Message Received: ${message.notification?.title}');
      showFirebaseNotification(message);
    });
  }

  Future<void> _createAndroidNotificationChannels() async {
    // Channel 1: Normal notifications ke liye (default sound)
    const AndroidNotificationChannel defaultChannel = AndroidNotificationChannel(
      'default_channel', 'General Notifications',
      description: 'Channel for general app notifications.',
      importance: Importance.max,
    );

    // Channel 2: Requirement ke liye (custom sound)
    const AndroidNotificationChannel requirementChannel = AndroidNotificationChannel(
      'requirement_channel', 'New Requirement Alerts',
      description: 'Channel for new job alerts with a special sound.',
      importance: Importance.max,
      sound: RawResourceAndroidNotificationSound('notification_sound'), // Aapki custom bell
    );

    final plugin = _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await plugin?.createNotificationChannel(defaultChannel);
    await plugin?.createNotificationChannel(requirementChannel);
  }

  // YEH FUNCTION SIRF FIREBASE PUSH NOTIFICATIONS KE LIYE HAI
  Future<void> showFirebaseNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    // Backend se aa rahe data ke anusaar channel select karein
    String channelId = (message.data['notification_type'] == 'NEW_REQUIREMENT')
        ? 'requirement_channel' // Custom bell wala channel
        : 'default_channel';    // Normal sound wala channel

    if (notification != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelId == 'requirement_channel' ? 'New Job Alerts' : 'General Notifications',
            icon: '@mipmap/ic_launcher',
            priority: Priority.high,
            importance: Importance.max,
          ),
        ),
        payload: json.encode(message.data),
      );
    }
  }

  // YEH NAYA FUNCTION SIRF WEBSOCKET SE AAYE LIVE NOTIFICATIONS KE LIYE HAI
  Future<void> showWebSocketNotification({
    required int id,
    required String title,
    required String body,
    required String notificationType,
    String? projectId,
  }) async {
     // Yahan bhi wahi logic hai: Sirf NEW_REQUIREMENT par special sound bajega
     String channelId = (notificationType == 'NEW_REQUIREMENT')
        ? 'requirement_channel' // Custom bell wala channel
        : 'default_channel';    // Normal sound wala channel
    
    await _localNotifications.show(
        id,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelId == 'requirement_channel' ? 'New Job Alerts' : 'General Notifications',
            icon: '@mipmap/ic_launcher',
            priority: Priority.high,
            importance: Importance.max,
          ),
        ),
        payload: json.encode({
          'notification_type': notificationType,
          'related_project_id': projectId,
        }),
      );
  }

  // Notification par tap hone par yeh function sahi screen par le jaayega
  void handleNotificationTap(Map<String, dynamic> data) {
    final String? type = data['notification_type'];
    final String? projectIdStr = data['related_project_id'];

    if (type == null) return;
    
    final BuildContext? context = navigatorKey.currentContext;
    if (context == null) {
        print("Navigator context is null, cannot navigate.");
        return;
    }

    if (type == 'NEW_REQUIREMENT') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const RequirementListScreen()));
    } else if (type == 'KYC_PENDING') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const KycScreen()));
    }
    else if (projectIdStr != null && projectIdStr.isNotEmpty) {
      final int projectId = int.parse(projectIdStr);
      Navigator.push(context, MaterialPageRoute(builder: (_) => ProjectDetailScreen(projectId: projectId)));
    }
  }

  Future<String?> getFCMToken() async {
    return await FirebaseMessaging.instance.getToken();
  }
}
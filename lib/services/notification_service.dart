import 'dart:convert';
import 'package:apna_thekedar_specialist/chat/chat_screen.dart';
import 'package:apna_thekedar_specialist/notifications/broadcast_message_screen.dart';
import 'package:apna_thekedar_specialist/onboarding/screens/select_services_screen.dart';
import 'package:apna_thekedar_specialist/profile/screens/kyc_screen.dart';
import 'package:apna_thekedar_specialist/profile/screens/profile_verified_screen.dart';
import 'package:apna_thekedar_specialist/projects/screens/project_details_screen.dart';
import 'package:apna_thekedar_specialist/projects/screens/requirement_details_view_screen.dart';
import 'package:apna_thekedar_specialist/projects/screens/view_phase_plan_screen.dart';
import 'package:apna_thekedar_specialist/providers/notification_provider.dart';
import 'package:apna_thekedar_specialist/reviews_feedback_progress/screens/update_history_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'package:apna_thekedar_specialist/services/auth_service.dart';
import 'package:apna_thekedar_specialist/notifications/notification_screen.dart'; // Isse import karein

class NotificationService {
  final GlobalKey<NavigatorState> navigatorKey;
  final NotificationProvider notificationProvider;
  IOWebSocketChannel? _channel;
  final AuthService _authService = AuthService(); // AuthService ka instance

  NotificationService(this.navigatorKey, this.notificationProvider);

  // --- Step 1: Push Notifications ko Initialize karna ---
  Future<void> initialize() async {
    // 1. App jab band ho, tab notification se kholne par
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print("App opened from terminated state by notification");
        // 'data' payload se details nikal kar navigation handle karein
        _handleNotificationNavigation(message.data);
      }
    });

    // 2. App background mein ho aur notification par tap karein
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('App opened from background by notification');
      _handleNotificationNavigation(message.data);
    });

    // 3. Jab app khula ho aur notification aaye (In-App / Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Foreground push notification received: ${message.notification?.title}");
      // List ko refresh karo taaki nayi notification turant dikhe
      notificationProvider.fetchNotifications();
    });
  }

  // --- Step 2: WebSocket se Connect karna ---
  Future<void> connectWebSocket() async {
    // Agar pehle se connection hai toh dobara na banayein
    if (_channel != null && _channel?.closeCode == null) {
      print("WebSocket already connected.");
      return;
    }
    
    final token = await _authService.getToken();
    if (token == null) {
      print("No token found, cannot connect to WebSocket.");
      return;
    }

    final wsUrl = 'wss://apna-thekedar-backend.onrender.com/ws/notifications/?token=$token';
    
    try {
      _channel = IOWebSocketChannel.connect(Uri.parse(wsUrl));
      print("Connecting to WebSocket...");
      _channel?.stream.listen(
        (message) {
          // Jab bhi WebSocket se koi message aaye, list ko refresh karo
          print("WebSocket message received: $message");
          notificationProvider.fetchNotifications();
        },
        onError: (error) {
          print('WebSocket Error: $error');
          // 5 second baad dobara connect karne ki koshish karein
          Future.delayed(Duration(seconds: 5), () => connectWebSocket());
        },
        onDone: () {
          print('WebSocket connection closed. Reconnecting...');
          // Connection band hone par dobara connect karein
          Future.delayed(Duration(seconds: 5), () => connectWebSocket());
        },
      );
      print("WebSocket Connected successfully!");
    } catch (e) {
      print("WebSocket connection failed: $e. Retrying in 5 seconds...");
      Future.delayed(Duration(seconds: 5), () => connectWebSocket());
    }
  }

  // --- Step 3: Yahi hai saara clickable logic ---
  void handleNotificationClick(Map<String, dynamic> notificationData) {
    
    final notificationId = int.tryParse(notificationData['id'].toString());
    final notificationType = notificationData['notification_type']?.toString();
    final projectIdString = notificationData['related_project_id']?.toString();
    final projectId = projectIdString != null && projectIdString.isNotEmpty 
                    ? int.tryParse(projectIdString) 
                    : null;
    
    // Rule: Notification ko "Read" mark karo
    if (notificationId != null) {
      notificationProvider.markAsRead(notificationId);
    }
    
    // Rule: Sahi screen par navigate karo
    final BuildContext? context = navigatorKey.currentContext;
    if (context == null || notificationType == null) return;

    switch (notificationType) {
      case 'NEW_REQUIREMENT':
        if (projectId != null) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => RequirementDetailsViewScreen(requirementId: projectId)));
        }
        break;

      case 'QUOTATION_CONFIRMED':
      case 'QUOTATION_CANCELLED':
      case 'PROJECT_CANCELLED':
      case 'PHASE_PLAN_ACCEPTED':
      case 'PHASE_PLAN_REJECTED':
      case 'PHASE_COMPLETION_ACCEPTED':
      case 'PHASE_COMPLETION_REJECTED':
        if (projectId != null) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => ProjectDetailsScreen(projectId: projectId)));
        }
        break;
      
      case 'PHASE_PAYMENT_RECEIVED':
         if (projectId != null) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => ViewPhasePlanScreen(projectId: projectId)));
        }
        break;

      case 'NEW_SERVICE':
        Navigator.push(context, MaterialPageRoute(builder: (_) => SelectServicesScreen(isUpdating: true)));
        break;

      case 'KYC_PENDING':
        Navigator.push(context, MaterialPageRoute(builder: (_) => KycScreen()));
        break;
      
      case 'PROFILE_VERIFIED':
        Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileVerifiedScreen()));
        break;

      case 'BROADCAST_MESSAGE':
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => BroadcastMessageScreen(
            title: notificationData['title'] ?? 'Message',
            message: notificationData['message'] ?? 'You have a new message from Admin.',
          ),
        ));
        break;

      case 'NEW_CHAT_MESSAGE':
        if (projectId != null) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(projectId: projectId)));
        }
        break;

      case 'RATING_GIVEN':
        if (projectId != null) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => UpdateHistoryScreen(projectId: projectId)));
        }
        break;

      default:
        print("Unknown notification type for navigation: $notificationType");
        // Default behaviour: Agar kuch samajh na aaye toh notification page par le jao
        Navigator.push(context, MaterialPageRoute(builder: (_) => NotificationScreen()));
    }
  }

  // --- Helper function jo Push Notification data ko handle karega ---
  void _handleNotificationNavigation(Map<String, dynamic> data) {
    // Backend se notification ka poora data bhejne ki zaroorat hai
    // Hum assume kar rahe hain ki backend `data` payload mein saari zaroori cheezein bhej raha hai
    
    // Isliye hum backend ke 'data' payload ko hi 'handleNotificationClick' mein bhej denge
    handleNotificationClick(data);
  }

  void disconnect() {
    _channel?.sink.close();
  }
}
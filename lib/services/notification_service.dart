import 'dart:convert';
import 'package:apna_thekedar_specialist/chat/chat_screen.dart';
import 'package:apna_thekedar_specialist/notifications/broadcast_message_screen.dart';
import 'package:apna_thekedar_specialist/notifications/notification_model.dart';
import 'package:apna_thekedar_specialist/notifications/notification_screen.dart';
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

class NotificationService {
  final GlobalKey<NavigatorState> navigatorKey;
  final NotificationProvider notificationProvider;
  IOWebSocketChannel? _channel;
  final AuthService _authService = AuthService();

  NotificationService(this.navigatorKey, this.notificationProvider);

  Future<void> initialize() async {
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        _handleNotificationNavigation(message.data);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationNavigation(message.data);
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      notificationProvider.fetchNotifications();
    });
  }

  Future<void> connectWebSocket() async {
    if (_channel != null && _channel?.closeCode == null) return;
    
    final token = await _authService.getToken();
    if (token == null) return;

    final wsUrl = 'wss://apna-thekedar-backend.onrender.com/ws/notifications/?token=$token';
    
    try {
      _channel = IOWebSocketChannel.connect(Uri.parse(wsUrl));
      _channel?.stream.listen(
        (message) {
          notificationProvider.fetchNotifications();
        },
        onError: (error) => Future.delayed(Duration(seconds: 5), connectWebSocket),
        onDone: () => Future.delayed(Duration(seconds: 5), connectWebSocket),
      );
    } catch (e) {
      Future.delayed(Duration(seconds: 5), connectWebSocket);
    }
  }

  void handleNotificationClick(NotificationModel notification) {
    notificationProvider.markAsRead(notification.id);
    
    final BuildContext? context = navigatorKey.currentContext;
    if (context == null) return;

    // Yahan hum NotificationModel se data le rahe hain
    _navigateToScreen(
      context,
      notification.notificationType,
      notification.relatedProjectId,
      notification.title,
      notification.message,
    );
  }

  void _handleNotificationNavigation(Map<String, dynamic> data) {
    // Push notification se 'id' aayega, use parse karna zaroori hai
    final notificationId = int.tryParse(data['id']?.toString() ?? '');
    if (notificationId != null) {
      notificationProvider.markAsRead(notificationId);
    }

    final notificationType = data['notification_type']?.toString();
    final projectIdString = data['related_project_id']?.toString();
    final projectId = projectIdString != null && projectIdString.isNotEmpty 
                    ? int.tryParse(projectIdString) 
                    : null;
    
    final title = data['title']?.toString();
    final message = data['message']?.toString();

    final BuildContext? context = navigatorKey.currentContext;
    if (context == null || notificationType == null) return;
    
    _navigateToScreen(context, notificationType, projectId, title, message);
  }

  void _navigateToScreen(BuildContext context, String type, int? projectId, String? title, String? message) {
    switch (type) {
      case 'NEW_REQUIREMENT':
        if (projectId != null) Navigator.push(context, MaterialPageRoute(builder: (_) => RequirementDetailsViewScreen(requirementId: projectId)));
        break;

      case 'QUOTATION_CONFIRMED':
      case 'QUOTATION_CANCELLED':
      case 'PROJECT_CANCELLED':
      case 'PHASE_PLAN_ACCEPTED':
      case 'PHASE_PLAN_REJECTED':
      case 'PHASE_COMPLETION_ACCEPTED':
      case 'PHASE_COMPLETION_REJECTED':
        if (projectId != null) Navigator.push(context, MaterialPageRoute(builder: (_) => ProjectDetailsScreen(projectId: projectId)));
        break;
      
      case 'PHASE_PAYMENT_RECEIVED':
         if (projectId != null) Navigator.push(context, MaterialPageRoute(builder: (_) => ViewPhasePlanScreen(projectId: projectId)));
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
            title: title ?? 'Message',
            message: message ?? 'You have a new message from Admin.',
          ),
        ));
        break;

      case 'NEW_CHAT_MESSAGE':
        if (projectId != null) Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(projectId: projectId)));
        break;

      case 'RATING_GIVEN':
        if (projectId != null) Navigator.push(context, MaterialPageRoute(builder: (_) => UpdateHistoryScreen(projectId: projectId)));
        break;

      default:
        Navigator.push(context, MaterialPageRoute(builder: (_) => NotificationScreen()));
    }
  }

  void disconnect() {
    _channel?.sink.close();
  }
}
// lib/services/notification_service.dart
import 'dart:convert';
import 'package:apna_thekedar_specialist/api/api_service.dart';
import 'package:apna_thekedar_specialist/chat/chat_screen.dart';
import 'package:apna_thekedar_specialist/core/models/user_profile.dart';
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
import 'package:apna_thekedar_specialist/reviews_feedback_progress/models/project_update.dart';
import 'package:apna_thekedar_specialist/reviews_feedback_progress/screens/update_history_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/io.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  final GlobalKey<NavigatorState> navigatorKey;
  final NotificationProvider notificationProvider;
  IOWebSocketChannel? _channel;

  NotificationService(this.navigatorKey, this.notificationProvider);

  Future<void> initialize() async {
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) _handlePushNotificationNavigation(message.data);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handlePushNotificationNavigation(message.data);
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Jab app khula ho aur notification aaye, to list refresh karein
      notificationProvider.fetchNotifications();
    });
  }

  Future<void> connectWebSocket() async {
    if (_channel != null && _channel?.closeCode == null) return;
    
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    if (token == null) return;
    final wsUrl = 'wss://apna-thekedar-backend.onrender.com/ws/notifications/?token=$token';
    
    try {
      _channel = IOWebSocketChannel.connect(Uri.parse(wsUrl));
      _channel?.stream.listen(
        (message) => notificationProvider.fetchNotifications(),
        onError: (error) => Future.delayed(const Duration(seconds: 5), connectWebSocket),
        onDone: () => Future.delayed(const Duration(seconds: 5), connectWebSocket),
      );
    } catch (e) {
      Future.delayed(const Duration(seconds: 5), connectWebSocket);
    }
  }
  
  void _handlePushNotificationNavigation(Map<String, dynamic> data) {
    // Push notification ke data se ek temporary model banayein
    final tempNotification = NotificationModel.fromJson(data);
    handleNotificationClick(tempNotification);
  }

  // YEH CENTRAL FUNCTION HAI JO HAR JAGAH SE CALL HOGA
  Future<void> handleNotificationClick(NotificationModel notification) async {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    // Loading indicator dikhayein
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => const Center(child: CircularProgressIndicator()),
    );

    // Notification ko read mark karein
    await notificationProvider.markAsRead(notification.id);
    
    // API call ke liye ApiService ka instance lein
    final apiService = Provider.of<ApiService>(context, listen: false);

    try {
      switch (notification.notificationType) {
        case 'NEW_REQUIREMENT':
          if (notification.relatedProjectId != null) {
            // Requirement details fetch karke screen par bhejein
            final reqData = await apiService.get('/projects/requirements/${notification.relatedProjectId}/');
            Navigator.pop(context); // Loading indicator hatayein
            Navigator.push(context, MaterialPageRoute(builder: (_) => RequirementDetailViewScreen(requirementData: json.decode(reqData.body))));
          }
          break;

        case 'QUOTATION_CONFIRMED':
        case 'QUOTATION_CANCELLED':
        case 'PROJECT_CANCELLED':
        case 'PHASE_PLAN_ACCEPTED':
        case 'PHASE_PLAN_REJECTED':
        case 'PHASE_COMPLETION_ACCEPTED':
        case 'PHASE_COMPLETION_REJECTED':
          if (notification.relatedProjectId != null) {
            Navigator.pop(context); // Loading indicator hatayein
            Navigator.push(context, MaterialPageRoute(builder: (_) => ProjectDetailScreen(projectId: notification.relatedProjectId!)));
          }
          break;
        
        case 'PHASE_PAYMENT_RECEIVED':
          if (notification.relatedProjectId != null) {
            final projectData = await apiService.get('/projects/${notification.relatedProjectId}/details/');
            final phases = json.decode(projectData.body)['phases'];
            Navigator.pop(context); // Loading indicator hatayein
            Navigator.push(context, MaterialPageRoute(builder: (_) => ViewPhasePlanScreen(phases: phases)));
          }
          break;

        case 'NEW_SERVICE':
          Navigator.pop(context); // Loading indicator hatayein
          Navigator.push(context, MaterialPageRoute(builder: (_) => SelectServicesScreen(isUpdating: true)));
          break;

        case 'KYC_PENDING':
          Navigator.pop(context); // Loading indicator hatayein
          Navigator.push(context, MaterialPageRoute(builder: (_) => KycScreen()));
          break;
        
        case 'PROFILE_VERIFIED':
          Navigator.pop(context); // Loading indicator hatayein
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileVerifiedScreen()));
          break;

        case 'BROADCAST_MESSAGE':
          Navigator.pop(context); // Loading indicator hatayein
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => BroadcastMessageScreen(title: notification.title, message: notification.message),
          ));
          break;

        case 'NEW_CHAT_MESSAGE':
          if (notification.relatedProjectId != null) {
            final projectData = await apiService.get('/projects/${notification.relatedProjectId}/details/');
            final profile = await UserProfile.loadFromApi();
            Navigator.pop(context); // Loading indicator hatayein
            Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(
              projectId: notification.relatedProjectId!,
              customerName: json.decode(projectData.body)['customer']['name'] ?? 'Customer',
              myName: profile?.name ?? 'Me',
            )));
          }
          break;

        case 'RATING_GIVEN':
          if (notification.relatedProjectId != null) {
            final updatesData = await apiService.get('/feedback/projects/${notification.relatedProjectId}/updates/');
            final updates = (json.decode(updatesData.body) as List).map((data) => ProjectUpdate.fromJson(data)).toList();
            Navigator.pop(context); // Loading indicator hatayein
            Navigator.push(context, MaterialPageRoute(builder: (_) => UpdateHistoryScreen(updates: updates)));
          }
          break;

        default:
          Navigator.pop(context); // Loading indicator hatayein
          Navigator.push(context, MaterialPageRoute(builder: (_) => NotificationScreen()));
      }
    } catch (e) {
      Navigator.pop(context); // Error aane par bhi loading indicator hatayein
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not load details: $e')));
    }
  }

  void disconnect() {
    _channel?.sink.close();
  }
}
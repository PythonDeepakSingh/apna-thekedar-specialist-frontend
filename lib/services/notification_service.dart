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
import 'package:apna_thekedar_specialist/projects/screens/requirement_acceptance_screen.dart';
import 'package:apna_thekedar_specialist/projects/screens/view_phase_plan_screen.dart';
import 'package:apna_thekedar_specialist/providers/notification_provider.dart';
import 'package:apna_thekedar_specialist/reviews_feedback_progress/models/project_update.dart';
import 'package:apna_thekedar_specialist/reviews_feedback_progress/screens/update_history_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/io.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:apna_thekedar_specialist/onboarding/screens/welcome_screen.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../main.dart'; // flutterLocalNotificationsPlugin ko access karne ke liye
import 'package:apna_thekedar_specialist/projects/screens/requirement_unavailable_screen.dart';

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

    // lib/services/notification_service.dart
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground message received: ${message.notification?.title}');
      notificationProvider.fetchNotifications(); // List abhi bhi refresh hogi
    
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;
    
      // Agar notification hai, to local notification dikhao
      if (notification != null && android != null) {
        // Zaroori: Requirement channel ke liye sound
        AndroidNotificationDetails androidPlatformChannelSpecifics;
        if (message.data['notification_type'] == 'NEW_REQUIREMENT') {
          androidPlatformChannelSpecifics = const AndroidNotificationDetails(
            'requirement_channel', // Channel ID jo MainActivity.kt mein banaya tha
            'New Requirements', // Channel Name
            channelDescription: 'Channel for new job requirement alerts',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            // Custom sound (agar MainActivity.kt mein set kiya hai)
            sound: RawResourceAndroidNotificationSound('notification_sound'),
            ticker: 'ticker',
          );
        } else {
          // Baaki sabke liye default channel
           androidPlatformChannelSpecifics = const AndroidNotificationDetails(
            'default_channel', // Default Channel ID
            'General Notifications',
            channelDescription: 'Default channel for app notifications',
            importance: Importance.defaultImportance, // Default importance
            priority: Priority.defaultPriority,
            playSound: true, // Default sound bajega
            ticker: 'ticker',
          );
        }
    
        NotificationDetails platformChannelSpecifics =
            NotificationDetails(android: androidPlatformChannelSpecifics);
    
        flutterLocalNotificationsPlugin.show(
          notification.hashCode, // Unique ID
          notification.title,
          notification.body,
          platformChannelSpecifics,
          payload: json.encode(message.data), // Click action ke liye data
        );
      }
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
            try {
              // Project details fetch karein
              final projectResponse = await apiService.get('/projects/${notification.relatedProjectId}/details/');
              if (projectResponse.statusCode != 200) {
                 // Agar project details hi na mile (ho sakta hai delete ho gaya ho)
                 Navigator.pop(context); // Loading hatayein
                 Navigator.push(context, MaterialPageRoute(builder: (_) => const RequirementUnavailableScreen()));
                 break; // Aage kuch na karein
              }
              final projectData = json.decode(projectResponse.body);
              final requirementData = projectData['requirement'];

              // === YEH NAYA CHECK ADD KIYA GAYA HAI ===
              // Check karo ki project ka status abhi bhi REQ_SENT hai ya nahi
              if (projectData['status'] != 'REQ_SENT' || projectData['specialist'] != null) {
                 Navigator.pop(context); // Loading hatayein
                 // Agar status REQ_SENT nahi hai, to Unavailable screen dikhao
                 Navigator.push(context, MaterialPageRoute(builder: (_) => const RequirementUnavailableScreen()));
                 break; // Aage kuch na karein
              }
              // ===========================================

              if (requirementData == null || requirementData['id'] == null) {
                throw Exception('Requirement data not found in project details');
              }

              final Map<String, dynamic> dataForAcceptanceScreen = {
                ...requirementData, // Requirement ki saari keys (id, description, etc.)
                'project': {      // Project ki details ko 'project' key ke andar nest karein
                  'id': projectData['id'],
                  'title': projectData['title'],
                  'address': projectData['address'],
                  'pincode': projectData['pincode'],
                  'property_type': projectData['property_type'], // Poora object bhej dein ya sirf naam
                  'customer': projectData['customer'], // Poora customer object
                  // Add any other project details needed by AcceptanceScreen
                }
              };
              // ===================================
              
              Navigator.pop(context); // Loading indicator hatayein
              
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RequirementAcceptanceScreen(
                    requirementId: requirementData['id'],
                    projectId: notification.relatedProjectId!,
                    initialData: dataForAcceptanceScreen, // <-- Ab sahi structure wala data jayega
                  ),
                ),
              );

            } catch (e) {
               Navigator.pop(context); // Error aane par bhi loading hatayein
               ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not load requirement details: $e')));
               // Optionally navigate to unavailable screen on error too
               // Navigator.push(context, MaterialPageRoute(builder: (_) => const RequirementUnavailableScreen()));
            }
          } else {
             Navigator.pop(context); // Agar project ID hi na ho
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
        case 'WELCOME':
          Navigator.pop(context); // Loading indicator hatayein
          // Ab Welcome Screen par le jayein
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const WelcomeScreen()),
          );
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
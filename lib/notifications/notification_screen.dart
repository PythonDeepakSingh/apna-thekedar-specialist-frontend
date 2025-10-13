// lib/notifications/notification_screen.dart
import 'package:flutter/material.dart';
import 'package:apna_thekedar_specialist/api/api_service.dart';
import 'dart:convert';
import 'package:iconsax/iconsax.dart';
import 'package:apna_thekedar_specialist/providers/notification_provider.dart';
import 'package:apna_thekedar_specialist/services/notification_service.dart';
import 'package:provider/provider.dart';


class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _notifications = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchAndMarkRead();
  }

  Future<void> _fetchAndMarkRead() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _error = null; });
    try {
      // Step 1: Backend se saari notifications fetch karein (sirf unread nahi)
      final response = await _apiService.get('/notifications/');
      if (mounted) {
        if (response.statusCode == 200) {
          final List<dynamic> fetched = json.decode(response.body);
          setState(() {
            _notifications = fetched;
          });

          // Step 2: Sirf unread notifications ki IDs nikaalein
          final List<int> unreadIds = fetched
              .where((notif) => notif['is_read'] == false)
              .map<int>((notif) => notif['id'])
              .toList();
          
          // Step 3: Agar unread notifications hain, toh unhein read mark karein
          if (unreadIds.isNotEmpty) {
            await _apiService.post('/notifications/mark-as-read/', {
              'notification_ids': unreadIds,
            });
          }
        } else {
          _error = "Failed to load notifications.";
        }
      }
    } catch (e) {
      if (mounted) _error = "An error occurred: $e";
    }
    if (mounted) setState(() { _isLoading = false; });
  }

  // Har notification type ke liye alag icon
  IconData _getIconForType(String type) {
    switch (type) {
      case 'NEW_REQUIREMENT':
        return Iconsax.document_download;
      case 'NEW_CHAT_MESSAGE':
        return Iconsax.message;
      case 'QUOTATION_CONFIRMED':
        return Iconsax.like_1;
      case 'QUOTATION_CANCELLED':
        return Iconsax.dislike;
      case 'RATING_GIVEN':
        return Iconsax.star;
      case 'PROJECT_CANCELLED':
        return Iconsax.close_circle;
      default:
        return Iconsax.notification;
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificationProvider = Provider.of<NotificationProvider>(context);
    // NotificationService ko yahan get karein
    final notificationService = Provider.of<NotificationService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
      ),
      body: notificationProvider.isLoading
          ? Center(child: CircularProgressIndicator())
          : notificationProvider.notifications.isEmpty
              ? Center(child: Text('No notifications yet.'))
              : RefreshIndicator(
                  onRefresh: () => notificationProvider.fetchNotifications(),
                  child: ListView.builder(
                    itemCount: notificationProvider.notifications.length,
                    itemBuilder: (context, index) {
                      final notification = notificationProvider.notifications[index];
                      return ListTile(
                        leading: Icon(
                          notification.isRead ? Icons.check_circle : Icons.circle,
                          color: notification.isRead ? Colors.green : Colors.orange,
                        ),
                        title: Text(notification.title, style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(notification.message),
                        onTap: () {
                          // Corrected way to call the navigation logic
                          notificationService.handleNotificationClick(notification);
                        },
                      );
                    },
                  ),
                ),
    );
  }
}
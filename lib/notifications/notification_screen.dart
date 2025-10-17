// lib/notifications/notification_screen.dart
import 'package:flutter/material.dart';
import 'package:apna_thekedar_specialist/api/api_service.dart';
import 'dart:convert';
import 'package:iconsax/iconsax.dart';
import 'package:flutter/material.dart';
import 'package:apna_thekedar_specialist/providers/notification_provider.dart';
import 'package:apna_thekedar_specialist/services/notification_service.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';

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
  @override
  @override
  Widget build(BuildContext context) {
    // Data ab provider se aayega
    return Consumer<NotificationProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Notifications'),
            actions: [
              IconButton(
                icon: const Icon(Iconsax.refresh),
                onPressed: () => provider.fetchNotifications(),
              )
            ],
          ),
          body: provider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : provider.notifications.isEmpty
                  ? const Center(child: Text("You don't have any notifications yet."))
                  : RefreshIndicator(
                      onRefresh: () => provider.fetchNotifications(),
                      child: ListView.builder(
                        itemCount: provider.notifications.length,
                        itemBuilder: (context, index) {
                          final notification = provider.notifications[index];
                          return ListTile(
                            // Yahan se 'leading' icon hata diya gaya hai
                            title: Text(
                              notification.title,
                              style: TextStyle(
                                fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(notification.message),
                            // Green tick waise hi rahega
                            trailing: notification.isRead
                                ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
                                : null,
                            onTap: () {
                              // Click karne par navigation waise hi kaam karega
                              Provider.of<NotificationService>(context, listen: false).handleNotificationClick(notification);
                            },
                          );
                        },
                      ),
                    ),
        );
      },
    );
  }
}
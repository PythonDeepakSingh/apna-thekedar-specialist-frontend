// lib/notifications/notification_screen.dart (Updated with Error Handling)
import 'package:flutter/material.dart';
import 'package:apna_thekedar_specialist/providers/notification_provider.dart';
import 'package:apna_thekedar_specialist/services/notification_service.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:apna_thekedar_specialist/core/widgets/attractive_error_widget.dart'; // Naya import


class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {

  @override
  Widget build(BuildContext context) {
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
          body: _buildBody(provider), // Naya function
        );
      },
    );
  }

  // Naya function UI manage karne ke liye
  Widget _buildBody(NotificationProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorType != null) {
      return AttractiveErrorWidget(
        imagePath: provider.errorType == 'no_internet' ? 'assets/no_internet.png' : 'assets/server_error.png',
        title: provider.errorType == 'no_internet' ? "No Internet" : "Server Error",
        message: "We couldn't load your notifications. Please check your connection and try again.",
        buttonText: "Retry",
        onRetry: () => provider.fetchNotifications(),
      );
    }

    if (provider.notifications.isEmpty) {
      return AttractiveErrorWidget(
        imagePath: 'assets/no_jobs.png', // Aap 'no_notifications.png' bhi bana sakte hain
        title: "All Caught Up!",
        message: "You don't have any notifications right now.",
        buttonText: "Refresh",
        onRetry: () => provider.fetchNotifications(),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.fetchNotifications(),
      child: ListView.builder(
        itemCount: provider.notifications.length,
        itemBuilder: (context, index) {
          final notification = provider.notifications[index];
          return ListTile(
            title: Text(
              notification.title,
              style: TextStyle(
                fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
              ),
            ),
            subtitle: Text(notification.message),
            trailing: notification.isRead
                ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
                : null,
            onTap: () {
              Provider.of<NotificationService>(context, listen: false).handleNotificationClick(notification);
            },
          );
        },
      ),
    );
  }
}
// lib/providers/notification_provider.dart (Updated with Error Handling)
import 'package:flutter/material.dart';
import 'package:apna_thekedar_specialist/api/api_service.dart';
import 'package:apna_thekedar_specialist/notifications/notification_model.dart';
import 'dart:io'; // Naya import

class NotificationProvider with ChangeNotifier {
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _errorType; // Naya variable
  final ApiService _apiService;

  NotificationProvider(this._apiService) {
    fetchNotifications();
  }

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get errorType => _errorType; // Naya getter

  NotificationModel? findNotificationById(int? id) {
    if (id == null) return null;
    try {
      return _notifications.firstWhere((n) => n.id == id);
    } catch (e) {
      return null;
    }
  }

  // Is function ko update kiya gaya hai
  Future<void> fetchNotifications() async {
    _isLoading = true;
    _errorType = null;
    notifyListeners();

    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isEmpty || result[0].rawAddress.isEmpty) {
        throw 'no_internet';
      }
      _notifications = await _apiService.getNotifications();
    } on SocketException catch (_) {
      _errorType = 'no_internet';
    } catch (e) {
      _errorType = 'server_error';
      print("Error fetching notifications: $e");
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> markAsRead(int notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index].isRead = true;
      notifyListeners();
      try {
        await _apiService.markNotificationAsRead([notificationId]);
      } catch (e) {
        _notifications[index].isRead = false; // Rollback on error
        notifyListeners();
        print("Error marking notification as read on backend: $e");
      }
    }
  }
}
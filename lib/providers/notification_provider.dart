import 'package:flutter/material.dart';
import 'package:apna_thekedar_specialist/api/api_service.dart';
import 'package:apna_thekedar_specialist/notifications/notification_model.dart';

class NotificationProvider with ChangeNotifier {
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  final ApiService _apiService;

  NotificationProvider(this._apiService) {
    fetchNotifications();
  }

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;

  NotificationModel? findNotificationById(int? id) {
    if (id == null) return null;
    try {
      return _notifications.firstWhere((n) => n.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> fetchNotifications() async {
    _isLoading = true;
    notifyListeners();
    try {
      _notifications = await _apiService.getNotifications();
    } catch (e) {
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
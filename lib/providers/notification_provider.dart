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
    try {
      // API call to mark as read on the backend
      await _apiService.markNotificationAsRead([notificationId]);
      
      // Update local state
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index].isRead = true;
        notifyListeners();
      }
    } catch (e) {
      print("Error marking notification as read: $e");
    }
  }

  void removeNotificationById(int id) {
    _notifications.removeWhere((notification) => notification.id == id);
    notifyListeners();
  }
}
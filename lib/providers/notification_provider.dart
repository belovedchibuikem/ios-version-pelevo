import 'package:flutter/material.dart';
import '../models/notification.dart';
import '../services/library_api_service.dart';

class NotificationProvider extends ChangeNotifier {
  final LibraryApiService _api = LibraryApiService();
  List<NotificationModel> _notifications = [];
  bool _loading = false;

  List<NotificationModel> get notifications => _notifications;
  bool get loading => _loading;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> fetchNotifications() async {
    _loading = true;
    notifyListeners();
    try {
      _notifications = await _api.getNotifications();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(int id) async {
    await _api.markNotificationAsRead(id);
    await fetchNotifications();
  }

  Future<void> markAllAsRead() async {
    await _api.markAllNotificationsAsRead();
    await fetchNotifications();
  }

  void handleIncomingNotification(NotificationModel notification) {
    _notifications.insert(0, notification);
    notifyListeners();
  }
}

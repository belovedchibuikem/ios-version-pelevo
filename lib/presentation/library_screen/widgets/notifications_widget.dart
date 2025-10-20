import 'package:flutter/material.dart';
import '../../../models/notification.dart';
import '../../../services/library_api_service.dart';

class NotificationsWidget extends StatefulWidget {
  const NotificationsWidget({Key? key}) : super(key: key);

  @override
  State<NotificationsWidget> createState() => _NotificationsWidgetState();
}

class _NotificationsWidgetState extends State<NotificationsWidget> {
  late Future<List<NotificationModel>> _notificationsFuture;
  final _api = LibraryApiService();

  @override
  void initState() {
    super.initState();
    _notificationsFuture = _api.getNotifications();
  }

  void _markAsRead(int id) async {
    await _api.markNotificationAsRead(id);
    setState(() {
      _notificationsFuture = _api.getNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<NotificationModel>>(
      future: _notificationsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Failed to load notifications'));
        }
        final notifications = snapshot.data ?? [];
        if (notifications.isEmpty) {
          return Center(child: Text('No notifications'));
        }
        return ListView.separated(
          itemCount: notifications.length,
          separatorBuilder: (_, __) => Divider(height: 1),
          itemBuilder: (context, i) {
            final n = notifications[i];
            return ListTile(
              title: Text(n.title),
              subtitle: Text(n.message),
              trailing: n.isRead
                  ? null
                  : IconButton(
                      icon: Icon(Icons.mark_email_read),
                      tooltip: 'Mark as read',
                      onPressed: () => _markAsRead(n.id),
                    ),
              onTap: () {
                // Optionally show details or navigate to episode
              },
            );
          },
        );
      },
    );
  }
}

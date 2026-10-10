import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  int _lastSeenMs = 0;

  @override
  void initState() {
    super.initState();
    _loadAndMarkSeen();
  }

  Future<void> _loadAndMarkSeen() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getInt('notif_last_seen') ?? 0;
    if (mounted) setState(() => _lastSeenMs = stored);
    await prefs.setInt('notif_last_seen', DateTime.now().millisecondsSinceEpoch);
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day} · $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1D2E),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE8EAF0), height: 1),
        ),
      ),
      body: StreamBuilder<List<AppNotification>>(
        stream: NotificationService().getNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_off_outlined,
                      size: 56, color: Color(0xFFD1D5DB)),
                  SizedBox(height: 14),
                  Text('No notifications yet.',
                      style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 15)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: notifications.length,
            separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
            itemBuilder: (context, i) {
              final n = notifications[i];
              final createdMs = n.createdAt?.millisecondsSinceEpoch ?? 0;
              final isUnread = createdMs > _lastSeenMs;

              return Container(
                color: isUnread
                    ? const Color(0xFFEEF0FB)
                    : Colors.white,
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFF3B4CCA),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.notifications_rounded,
                        color: Colors.white, size: 22),
                  ),
                  title: Text(
                    n.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          isUnread ? FontWeight.w700 : FontWeight.w600,
                      color: const Color(0xFF1A1D2E),
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 3),
                      Text(
                        n.body,
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF6B7280)),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _formatDate(n.createdAt),
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF9CA3AF)),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

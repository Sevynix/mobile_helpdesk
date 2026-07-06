import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/notification_provider.dart';

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return const Center(child: Text('No notifications yet.'));
          }
          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notif = notifications[index];
              final isRead = notif['is_read'] == true;

              return ListTile(
                tileColor: isRead ? null : Theme.of(context).colorScheme.primary.withOpacity(0.1),
                leading: Icon(
                  isRead ? Icons.notifications_none : Icons.notifications_active,
                  color: isRead ? Colors.grey : Theme.of(context).colorScheme.primary,
                ),
                title: Text(
                  notif['message'],
                  style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.bold),
                ),
                subtitle: Text(
                  DateTime.parse(notif['created_at']).toLocal().toString().substring(0, 16),
                ),
                onTap: () {
                  if (!isRead) {
                    ref.read(notificationRepositoryProvider).markAsRead(notif['id']);
                  }
                  if (notif['ticket_id'] != null) {
                    context.push('/tickets/${notif['ticket_id']}');
                  }
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

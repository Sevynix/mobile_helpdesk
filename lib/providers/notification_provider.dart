import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/notification_repository.dart';
import 'supabase_provider.dart';
import 'auth_provider.dart';
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return NotificationRepository(client);
});

final notificationStreamProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  ref.watch(authStateProvider);
  final repo = ref.watch(notificationRepositoryProvider);
  return repo.getNotificationsStream();
});

final unreadNotificationCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationStreamProvider).value ?? [];
  return notifications.where((n) => n['is_read'] != true).length;
});

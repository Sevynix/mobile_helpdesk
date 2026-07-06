import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationRepository {
  final SupabaseClient _supabase;

  NotificationRepository(this._supabase);

  Future<List<Map<String, dynamic>>> getNotifications() async {
    final response = await _supabase
        .from('notifications')
        .select('*')
        .order('created_at', ascending: false);
    
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> markAsRead(String notificationId) async {
    await _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
  }

  Stream<List<Map<String, dynamic>>> getNotificationsStream() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return const Stream.empty();

    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false);
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';

class UserRepository {
  final SupabaseClient _supabase;

  UserRepository(this._supabase);

  Future<List<Map<String, dynamic>>> getUsers() async {
    final response = await _supabase
        .from('users')
        .select('*')
        .order('created_at', ascending: false);
    
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> updateUserStatus(String userId, bool isActive) async {
    await _supabase
        .from('users')
        .update({'is_active': isActive})
        .eq('id', userId);
  }

  Future<void> updateUserRole(String userId, String role) async {
    await _supabase
        .from('users')
        .update({'role': role})
        .eq('id', userId);
  }
  
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;
    
    final response = await _supabase
        .from('users')
        .select('*')
        .eq('id', userId)
        .single();
        
    return response;
  }
}

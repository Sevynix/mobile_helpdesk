import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/user_model.dart';

class AuthRepository {
  final SupabaseClient _supabase;

  AuthRepository(this._supabase);

  Future<AuthResponse> login(String email, String password) async {
    return await _supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> register(String email, String password, String name) async {
    return await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'name': name}, // Will be caught by handle_new_user trigger
    );
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
  }
  
  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  Future<UserModel?> getCurrentUser() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    
    final response = await _supabase.from('users').select().eq('id', user.id).maybeSingle();
    if (response == null) return null;
    return UserModel.fromJson(response);
  }

  Future<List<UserModel>> getHelpdesks() async {
    final response = await _supabase.from('users').select().eq('role', 'helpdesk');
    return (response as List).map((json) => UserModel.fromJson(json)).toList();
  }
}

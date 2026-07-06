import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/user_model.dart';
import '../../main.dart';

class AuthRepository {
  final SupabaseClient _supabase;

  AuthRepository(this._supabase);

  Future<AuthResponse> login(String email, String password) async {
    final response = await _supabase.auth.signInWithPassword(email: email, password: password);
    if (response.user != null) {
      final userResponse = await _supabase.from('users').select('is_active').eq('id', response.user!.id).maybeSingle();
      if (userResponse != null && userResponse['is_active'] == false) {
        await _supabase.auth.signOut();
        rootScaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(
            content: Text('Akun Anda telah dinonaktifkan oleh Admin.', style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.redAccent,
          ),
        );
        throw Exception('Akun Anda telah dinonaktifkan oleh Admin.');
      }
    }
    return response;
  }

  Future<AuthResponse> register(String email, String password, String name) async {
    return await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'name': name},
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
    
    final userModel = UserModel.fromJson(response);
    if (!userModel.isActive) {
      await logout();
      rootScaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('Sesi diakhiri: Akun Anda telah dinonaktifkan.', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.redAccent,
        ),
      );
      throw Exception('Akun Anda telah dinonaktifkan oleh Admin.');
    }
    return userModel;
  }

  Future<List<UserModel>> getHelpdesks() async {
    final response = await _supabase.from('users').select().eq('role', 'helpdesk');
    return (response as List).map((json) => UserModel.fromJson(json)).toList();
  }
}

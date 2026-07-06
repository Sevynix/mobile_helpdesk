import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../providers/supabase_provider.dart';
import '../../../core/theme/app_colors.dart';

class UpdatePasswordScreen extends ConsumerStatefulWidget {
  final String? email;
  
  const UpdatePasswordScreen({super.key, this.email});

  @override
  ConsumerState<UpdatePasswordScreen> createState() => _UpdatePasswordScreenState();
}

class _UpdatePasswordScreenState extends ConsumerState<UpdatePasswordScreen> {
  final _newPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscureNew = true;

  @override
  void dispose() {
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    final newPassword = _newPasswordController.text;
    
    if (widget.email == null || widget.email!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email tidak valid.')),
      );
      return;
    }

    if (newPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password harus diisi')),
      );
      return;
    }

    if (newPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password baru minimal 6 karakter')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final supabase = ref.read(supabaseClientProvider);
    
    try {
      await supabase.rpc('reset_password_bypass', params: {
        'p_email': widget.email!,
        'p_new_password': newPassword,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password berhasil direset! Silakan login.', style: TextStyle(color: Colors.white)),
          backgroundColor: AppColors.statusClose,
        ),
      );
      context.go('/login');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Reset password untuk akun:\n${widget.email ?? ""}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _newPasswordController,
              obscureText: _obscureNew,
              decoration: InputDecoration(
                labelText: 'Password Baru',
                suffixIcon: IconButton(
                  icon: Icon(_obscureNew ? Icons.visibility : Icons.visibility_off),
                  onPressed: () {
                    setState(() => _obscureNew = !_obscureNew);
                  },
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updatePassword,
                child: _isLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
                  : const Text('Reset Password'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

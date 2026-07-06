import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/user_provider.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);
    final authState = ref.watch(authStateProvider);
    final email = authState.value?.session?.user.email ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.settings),
            onPressed: () => context.push('/settings'),
          )
        ],
      ),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) return const Center(child: Text('Profile not found'));
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 50,
                  child: Icon(LucideIcons.user, size: 50),
                ),
                const SizedBox(height: 24),
                _buildProfileItem(context, 'Name', profile['name']),
                _buildProfileItem(context, 'Email', email),
                _buildProfileItem(context, 'Role', (profile['role'] as String).toUpperCase()),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () async {
                      await ref.read(authRepositoryProvider).logout();
                      ref.invalidate(currentUserProvider);
                      if (context.mounted) context.go('/login');
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                      side: BorderSide(color: Theme.of(context).colorScheme.error),
                    ),
                    child: const Text('Logout'),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildProfileItem(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}

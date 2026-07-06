import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/user_provider.dart';

class UserManagementScreen extends ConsumerWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(userNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Users')),
      body: usersAsync.when(
        data: (users) {
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final isActive = user['is_active'] == true;
              final isCurrentUser = ref.watch(currentUserProfileProvider).value?['id'] == user['id'];

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: isActive ? Colors.green : Colors.red,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                title: Text(user['name']),
                subtitle: Text(user['email']),
                trailing: isCurrentUser
                  ? const Text('YOU', style: TextStyle(fontWeight: FontWeight.bold))
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButton<String>(
                          value: user['role'],
                          items: const [
                            DropdownMenuItem(value: 'user', child: Text('User')),
                            DropdownMenuItem(value: 'helpdesk', child: Text('Helpdesk')),
                            DropdownMenuItem(value: 'admin', child: Text('Admin')),
                          ],
                          onChanged: (newRole) {
                            if (newRole != null && newRole != user['role']) {
                              ref.read(userNotifierProvider.notifier).updateUserRole(user['id'], newRole);
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        Switch(
                          value: isActive,
                          onChanged: (val) {
                            ref.read(userNotifierProvider.notifier).toggleUserStatus(user['id'], isActive);
                          },
                        ),
                      ],
                    ),
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

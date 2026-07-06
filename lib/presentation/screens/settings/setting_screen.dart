import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/theme_provider.dart';
import '../../../providers/user_provider.dart';

class SettingScreen extends ConsumerWidget {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final profileAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Appearance', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          SwitchListTile(
            title: const Text('Dark Mode'),
            value: themeMode == ThemeMode.dark,
            onChanged: (val) {
              ref.read(themeProvider.notifier).setTheme(val ? ThemeMode.dark : ThemeMode.light);
            },
          ),
          const Divider(),
          profileAsync.when(
            data: (profile) {
              if (profile?['role'] == 'admin') {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Administration', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    ),
                    ListTile(
                      leading: const Icon(Icons.people),
                      title: const Text('Manage Users'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/admin/users'),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

class ThemeNotifier extends Notifier<ThemeMode> {
  late SharedPreferences prefs;

  @override
  ThemeMode build() {
    prefs = ref.watch(sharedPreferencesProvider);
    final theme = prefs.getString('theme_mode');
    if (theme == 'dark') {
      return ThemeMode.dark;
    } else if (theme == 'light') {
      return ThemeMode.light;
    } else {
      return ThemeMode.system;
    }
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    if (mode == ThemeMode.dark) {
      await prefs.setString('theme_mode', 'dark');
    } else if (mode == ThemeMode.light) {
      await prefs.setString('theme_mode', 'light');
    } else {
      await prefs.remove('theme_mode');
    }
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(() {
  return ThemeNotifier();
});

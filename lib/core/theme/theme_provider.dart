import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for the current theme mode
final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

/// Manages theme mode persistence and switching
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  static const _key = 'theme_mode';

  ThemeModeNotifier() : super(ThemeMode.dark) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key);
    if (value == 'light') {
      state = ThemeMode.light;
    } else if (value == 'system') {
      state = ThemeMode.system;
    } else {
      state = ThemeMode.dark;
    }
  }

  Future<void> toggleTheme() async {
    final newMode =
        state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    state = newMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, newMode == ThemeMode.light ? 'light' : 'dark');
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
  }
}

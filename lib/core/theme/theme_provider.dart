import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode {
  system,
  light,
  dark,
  cyberpunkNeon,
}

class ThemeNotifier extends Notifier<AppThemeMode> {
  static const _themePrefKey = 'user_theme_preference';

  @override
  AppThemeMode build() {
    // Synchronous state initialization from SharedPreferences
    final prefs = _prefsInstance;
    if (prefs != null) {
      final stored = prefs.getString(_themePrefKey);
      if (stored != null) {
        return AppThemeMode.values.firstWhere(
          (e) => e.name == stored,
          orElse: () => AppThemeMode.cyberpunkNeon,
        );
      }
    }
    return AppThemeMode.cyberpunkNeon; // Default theme
  }

  // SharedPreferences cache initialized in main
  static SharedPreferences? _prefsInstance;
  
  static void init(SharedPreferences prefs) {
    _prefsInstance = prefs;
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themePrefKey, mode.name);
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, AppThemeMode>(
  ThemeNotifier.new,
);

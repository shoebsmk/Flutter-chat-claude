import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for persisting and loading theme preferences.
class ThemeService {
  ThemeService._();

  static const String _themeModeKey = 'theme_mode';

  /// Loads the saved theme mode from SharedPreferences.
  /// Returns ThemeMode.system if no preference is saved.
  static Future<ThemeMode> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeString = prefs.getString(_themeModeKey);
    
    if (themeModeString == null) {
      return ThemeMode.system;
    }
    
    switch (themeModeString) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  /// Saves the theme mode to SharedPreferences.
  static Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeString = _themeModeToString(mode);
    await prefs.setString(_themeModeKey, themeModeString);
  }

  /// Converts ThemeMode to string for storage.
  static String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
      default:
        return 'system';
    }
  }
}


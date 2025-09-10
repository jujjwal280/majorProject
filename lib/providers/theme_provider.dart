// lib/providers/theme_provider.dart (Updated)

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode;

  // The key we'll use to store the theme setting
  static const String _themePreferenceKey = 'isDarkMode';

  // Constructor now accepts an initial value
  ThemeProvider(this._isDarkMode);

  bool get isDarkMode => _isDarkMode;

  // Toggles the theme and saves the preference
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await _saveThemePreference();
    notifyListeners();
  }

  // Saves the current theme preference to shared_preferences
  Future<void> _saveThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themePreferenceKey, _isDarkMode);
  }
}
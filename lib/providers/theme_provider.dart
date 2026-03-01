import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode;
  static const String _themePreferenceKey = 'isDarkMode';

  ThemeProvider(this._isDarkMode);

  bool get isDarkMode => _isDarkMode;

  // --- ADD THESE GETTERS TO FIX THE ERRORS ---

  // Main Text Color (Navy in light, White in dark)
  Color get textColor => _isDarkMode ? Colors.white : const Color(0xFF053F5C);

  // Subtitle/Hint Text Color
  Color get subTextColor => _isDarkMode ? Colors.white54 : Colors.grey.shade600;

  // Background for Cards/Tiles (Dark Grey in dark mode)
  Color get cardColor => _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;

  // Global Background Color
  Color get scaffoldBg => _isDarkMode ? const Color(0xFF0F0F0F) : const Color(0xFFF8FEFF);

  // ------------------------------------------

  ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF8FEFF),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF053F5C),
    ),
  );

  ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0F0F0F),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF429EBD),
      brightness: Brightness.dark,
    ),
  );

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themePreferenceKey, _isDarkMode);
  }
}
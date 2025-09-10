import 'package:flutter/material.dart';

// A class that holds the theme state and can notify listeners when it changes.
class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;

  // A "getter" to allow other widgets to read the current theme mode.
  bool get isDarkMode => _isDarkMode;

  // A method to toggle the theme and notify all listening widgets to rebuild.
  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }
}

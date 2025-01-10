import 'package:flutter/material.dart';
import 'package:kantin/Themes/dark_mode.dart';
import 'package:kantin/Themes/light_mode.dart';

class ThemeProviders with ChangeNotifier {
  bool _isDarkMode = false; // Gunakan flag untuk melacak mode gelap/terang
  ThemeData _themeData = light; // Default adalah Light Mode

  ThemeData get themeData => _themeData;
  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _themeData = _isDarkMode ? dark : light;
    notifyListeners(); // Notifikasi untuk update UI
  }
}

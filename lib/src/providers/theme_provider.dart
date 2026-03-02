import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../theme/app_theme.dart';

class ThemeProvider extends ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;
  ThemeData get currentTheme => _isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final savedTheme = await _storage.read(key: 'theme_mode');
    _isDarkMode = savedTheme == 'dark';
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await _storage.write(key: 'theme_mode', value: _isDarkMode ? 'dark' : 'light');
    notifyListeners();
  }
} 
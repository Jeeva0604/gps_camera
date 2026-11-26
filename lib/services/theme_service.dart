import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Centralized Theme Service managing Light and Dark theme modes with persistence
class ThemeService extends ChangeNotifier with WidgetsBindingObserver {
  static final ThemeService instance = ThemeService._internal();

  ThemeService._internal();

  static const String _prefThemeKey = 'selected_theme_mode';

  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  /// Returns whether the effective theme is currently dark (explicit or system)
  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  /// Whether user has explicitly saved a theme preference
  bool get hasUserCustomTheme => _hasUserCustomTheme;
  bool _hasUserCustomTheme = false;

  /// Initializes theme from SharedPreferences or defaults to device system theme
  Future<void> init() async {
    WidgetsBinding.instance.addObserver(this);
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_prefThemeKey);

      if (savedTheme == 'light') {
        _themeMode = ThemeMode.light;
        _hasUserCustomTheme = true;
      } else if (savedTheme == 'dark') {
        _themeMode = ThemeMode.dark;
        _hasUserCustomTheme = true;
      } else {
        // 1st time opening app: No stored preference.
        // Set default app theme following device brightness (ThemeMode.system)
        _themeMode = ThemeMode.system;
        _hasUserCustomTheme = false;
      }
      notifyListeners();
    } catch (_) {}
  }

  @override
  void didChangePlatformBrightness() {
    // If user has not chosen an explicit theme, adapt when system brightness changes
    if (_themeMode == ThemeMode.system) {
      notifyListeners();
    }
  }

  /// Toggles between Light and Dark mode, saves preference, and applies it
  Future<void> toggleTheme() async {
    // If currently dark (from system or explicit), switch to light, else dark
    if (isDarkMode) {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = ThemeMode.dark;
    }
    _hasUserCustomTheme = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _prefThemeKey,
        _themeMode == ThemeMode.light ? 'light' : 'dark',
      );
    } catch (_) {}
  }

  /// Sets a specific theme mode and stores user choice
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode && _hasUserCustomTheme) return;
    _themeMode = mode;
    _hasUserCustomTheme = mode != ThemeMode.system;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      if (mode == ThemeMode.system) {
        await prefs.remove(_prefThemeKey);
      } else {
        await prefs.setString(
          _prefThemeKey,
          mode == ThemeMode.light ? 'light' : 'dark',
        );
      }
    } catch (_) {}
  }
}

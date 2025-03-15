import 'package:editto_flutter/utilities/design.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.system) {
    _loadTheme();
  }

  void _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt('themeMode') ?? 0;
    state = ThemeMode.values[themeIndex];
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
          systemNavigationBarColor:
              ThemeMode.values[themeIndex] == ThemeMode.dark
                  ? darkTheme.colorScheme.surface
                  : lightTheme.colorScheme.surface),
    );
  }

  Future<void> toggleTheme(bool isDarkMode) async {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
          systemNavigationBarColor: isDarkMode
              ? darkTheme.colorScheme.surface
              : lightTheme.colorScheme.surface),
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', isDarkMode ? 2 : 1);
    state = isDarkMode ? ThemeMode.dark : ThemeMode.light;
  }
}

final themeNotifierProvider =
    StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

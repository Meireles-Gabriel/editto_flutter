// Required imports for theme management
// Importações necessárias para gerenciamento de tema
import 'package:editto_flutter/utilities/design.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Theme state management class using Riverpod
// Classe de gerenciamento de estado do tema usando Riverpod
class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.system) {
    _loadTheme();
  }

  // Load saved theme from local storage
  // Carrega o tema salvo do armazenamento local
  void _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt('themeMode') ?? 0;
    state = ThemeMode.values[themeIndex];
    // Update system UI colors based on theme
    // Atualiza as cores da UI do sistema com base no tema
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
          systemNavigationBarColor:
              ThemeMode.values[themeIndex] == ThemeMode.dark
                  ? darkTheme.colorScheme.surface
                  : lightTheme.colorScheme.surface),
    );
  }

  // Toggle between light and dark theme
  // Alterna entre tema claro e escuro
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

// Global provider for theme state
// Provedor global para o estado do tema
final themeNotifierProvider =
    StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

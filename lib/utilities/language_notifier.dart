// Required imports for language management
// Importações necessárias para gerenciamento de idioma
import 'dart:ui';

import 'package:editto_flutter/utilities/texts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Language state management class using Riverpod
// Classe de gerenciamento de estado do idioma usando Riverpod
class LanguageNotifier extends StateNotifier<Map<String, dynamic>> {
  // Initialize with system language or English as default
  // Inicializa com o idioma do sistema ou inglês como padrão
  LanguageNotifier()
      : super({
          'language': PlatformDispatcher.instance.locale.languageCode,
          'texts': englishTexts
        }) {
    _loadSettings();
  }

  // Load saved language settings from local storage
  // Carrega as configurações de idioma salvas do armazenamento local
  void _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('language') ??
        (PlatformDispatcher.instance.locale.languageCode == 'pt' ? 'pt' : 'en');

    state = {
      'language': languageCode,
      'texts': languageCode == 'pt' ? portugueseTexts : englishTexts
    };
  }

  // Toggle between English and Portuguese
  // Alterna entre inglês e português
  void toggleLanguage(bool isEnglish) {
    final languageCode = isEnglish ? 'en' : 'pt';
    state = {
      'language': languageCode,
      'texts': isEnglish ? englishTexts : portugueseTexts
    };
  }
}

// Global provider for language state
// Provedor global para o estado do idioma
final languageNotifierProvider =
    StateNotifierProvider<LanguageNotifier, Map<String, dynamic>>(
  (ref) {
    return LanguageNotifier();
  },
);

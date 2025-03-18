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
    final hasLanguagePreference = prefs.containsKey('language');

    // If no language preference is saved, detect from system locale
    // Se nenhuma preferência de idioma estiver salva, detecta do locale do sistema
    if (!hasLanguagePreference) {
      final systemLocale = PlatformDispatcher.instance.locale;
      final languageCode = systemLocale.languageCode == 'pt' ? 'pt' : 'en';

      // Save the detected language preference
      // Salva a preferência de idioma detectada
      await prefs.setString('language', languageCode);

      state = {
        'language': languageCode,
        'texts': languageCode == 'pt' ? portugueseTexts : englishTexts
      };
    } else {
      // Load saved language preference
      // Carrega a preferência de idioma salva
      final languageCode = prefs.getString('language')!;
      state = {
        'language': languageCode,
        'texts': languageCode == 'pt' ? portugueseTexts : englishTexts
      };
    }
  }

  // Toggle between English and Portuguese
  // Alterna entre inglês e português
  Future<void> toggleLanguage(bool isEnglish) async {
    final languageCode = isEnglish ? 'en' : 'pt';

    // Save the new language preference
    // Salva a nova preferência de idioma
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', languageCode);

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

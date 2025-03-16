// Required imports for language switching
// Importações necessárias para alternância de idioma
import 'package:editto_flutter/utilities/language_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Widget for switching between English and Portuguese
// Widget para alternar entre inglês e português
class LanguageSwitch extends StatelessWidget {
  const LanguageSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    // Consumer widget to watch language changes
    // Widget Consumer para observar mudanças de idioma
    return Consumer(builder: (context, ref, child) {
      final currentLanguage = ref.watch(languageNotifierProvider)['language'];
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Popup menu for language selection
          // Menu popup para seleção de idioma
          PopupMenuButton<String>(
            tooltip:
                currentLanguage == 'pt' ? 'Change Language' : 'Mudar Idioma',
            color: Theme.of(context).colorScheme.surface,
            // Handle language selection and save preference
            // Manipula a seleção de idioma e salva a preferência
            onSelected: (value) async {
              final isEnglish = value == 'en';
              ref
                  .read(languageNotifierProvider.notifier)
                  .toggleLanguage(isEnglish);
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('language', value);
            },
            // Build language menu items
            // Constrói itens do menu de idiomas
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'en',
                child: Center(
                  child: Text(
                    'English',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
              PopupMenuItem(
                value: 'pt',
                child: Center(
                  child: Text(
                    'Português',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
            ],
            // Current language indicator with icon
            // Indicador do idioma atual com ícone
            icon: Row(
              children: [
                Text(
                  currentLanguage == 'en' ? 'EN' : 'PT',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(
                  width: 7,
                ),
                const Icon(Icons.language),
              ],
            ),
          ),
        ],
      );
    });
  }
}

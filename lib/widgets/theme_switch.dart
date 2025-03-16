// Required imports for theme switching
// Importações necessárias para alternância de tema
import 'package:editto_flutter/utilities/theme_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Widget for switching between light and dark themes
// Widget para alternar entre temas claro e escuro
class ThemeSwitch extends StatelessWidget {
  const ThemeSwitch({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // Consumer widget to watch theme changes
    // Widget Consumer para observar mudanças de tema
    return Consumer(builder: (context, ref, child) {
      final isDarkMode = ref.watch(themeNotifierProvider) == ThemeMode.dark;
      // Icon button that changes based on current theme
      // Botão de ícone que muda com base no tema atual
      return IconButton(
        icon: Icon(
          isDarkMode ? Icons.nightlight : Icons.sunny,
        ),
        onPressed: () {
          ref.read(themeNotifierProvider.notifier).toggleTheme(!isDarkMode);
        },
      );
    });
  }
}

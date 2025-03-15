import 'package:editto_flutter/utilities/theme_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ThemeSwitch extends StatelessWidget {
  const ThemeSwitch({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, ref, child) {
      final isDarkMode = ref.watch(themeNotifierProvider) == ThemeMode.dark;
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

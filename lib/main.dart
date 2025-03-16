// Import required packages and local files
// Importação dos pacotes e arquivos locais necessários
import 'package:editto_flutter/pages/intro_page.dart';
import 'package:editto_flutter/pages/newsstand_page.dart';
import 'package:editto_flutter/utilities/theme_notifier.dart';
import 'package:editto_flutter/utilities/design.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'utilities/firebase_options.dart';

// Entry point: Initialize Firebase and run the app
// Ponto de entrada: Inicializa o Firebase e executa o aplicativo
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const ProviderScope(child: MyApp()));
}

// Main app widget with theme management using Riverpod
// Widget principal do app com gerenciamento de tema usando Riverpod
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch for theme changes
    // Observa mudanças no tema
    final isDarkMode = ref.watch(themeNotifierProvider) == ThemeMode.dark;

    return MaterialApp(
      title: 'Éditto Magazine',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      // Authentication state management: Show IntroPage or NewsstandPage
      // Gerenciamento de estado de autenticação: Mostra IntroPage ou NewsstandPage
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasData) {
            return const NewsstandPage();
          }

          return const IntroPage();
        },
      ),
    );
  }
}

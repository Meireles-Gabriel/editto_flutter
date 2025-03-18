// Import required packages and local files
// Importação dos pacotes e arquivos locais necessários
import 'package:editto_flutter/pages/intro_page.dart';
import 'package:editto_flutter/pages/newsstand_page.dart';
import 'package:editto_flutter/utilities/theme_notifier.dart';
import 'package:editto_flutter/utilities/design.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    // Update system UI colors when platform brightness changes
    // Atualiza as cores da UI do sistema quando o brilho da plataforma muda
    final isDarkMode = ref.read(themeNotifierProvider) == ThemeMode.dark;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        systemNavigationBarColor: isDarkMode
            ? darkTheme.colorScheme.surface
            : lightTheme.colorScheme.surface,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch for theme changes
    // Observa mudanças no tema
    final isDarkMode = ref.watch(themeNotifierProvider) == ThemeMode.dark;

    return AnimatedTheme(
      duration: const Duration(milliseconds: 200),
      data: isDarkMode ? darkTheme : lightTheme,
      child: MaterialApp(
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
      ),
    );
  }
}

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
    // Force rebuild when system brightness changes to update theme if using system theme
    // Força reconstrução quando o brilho do sistema mudar para atualizar o tema se estiver usando o tema do sistema
    final themeMode = ref.read(themeNotifierProvider);
    if (themeMode == ThemeMode.system) {
      setState(() {});
    }

    // Update system UI colors when platform brightness changes
    // Atualiza as cores da UI do sistema quando o brilho da plataforma muda
    final Brightness systemBrightness =
        MediaQuery.platformBrightnessOf(context);
    final bool isDarkMode = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system && systemBrightness == Brightness.dark);

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
    final themeMode = ref.watch(themeNotifierProvider);

    // Check if we should use dark mode:
    // 1. Explicit dark mode selected OR
    // 2. System theme is being used AND system is in dark mode
    // Verifica se devemos usar o modo escuro:
    // 1. Modo escuro explicitamente selecionado OU
    // 2. Tema do sistema está sendo usado E sistema está em modo escuro
    final Brightness systemBrightness =
        MediaQuery.platformBrightnessOf(context);
    final bool isDarkMode = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system && systemBrightness == Brightness.dark);

    return AnimatedTheme(
      duration: const Duration(milliseconds: 200),
      data: isDarkMode ? darkTheme : lightTheme,
      child: MaterialApp(
        title: 'Éditto Magazine',
        debugShowCheckedModeBanner: false,
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: themeMode,
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

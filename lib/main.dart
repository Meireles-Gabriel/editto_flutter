import 'package:editto_flutter/utilities/design.dart';
import 'package:editto_flutter/utilities/language_notifier.dart';
import 'package:editto_flutter/utilities/theme_notifier.dart';
import 'package:editto_flutter/widgets/language_switch.dart';
import 'package:editto_flutter/widgets/theme_switch.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'utilities/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    const ProviderScope(
      child: MainApp(),
    ),
  );
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeNotifierProvider);
    final languageConfig = ref.watch(languageNotifierProvider);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Éditto Magazine',
      themeMode: themeMode,
      theme: lightTheme,
      darkTheme: darkTheme,
      locale: Locale(languageConfig['language']),
      home: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            appBar: AppBar(
              title: const Text('Éditto Magazine'),
              actions: const [
                LanguageSwitch(),
                ThemeSwitch(),
              ],
            ),
            body: const Center(
              child: Text('Hello World!'),
            ),
          );
        },
      ),
    );
  }
}

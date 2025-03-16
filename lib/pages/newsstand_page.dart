// Required imports for newsstand functionality
// Importações necessárias para funcionalidade da banca
import 'package:editto_flutter/pages/login_page.dart';
import 'package:editto_flutter/utilities/language_notifier.dart';
import 'package:editto_flutter/widgets/default_bottom_app_bar.dart';
import 'package:editto_flutter/widgets/language_switch.dart';
import 'package:editto_flutter/widgets/theme_switch.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:editto_flutter/utilities/helper_class.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Newsstand page widget with state management
// Widget da página da banca com gerenciamento de estado
class NewsstandPage extends ConsumerStatefulWidget {
  const NewsstandPage({super.key});

  @override
  ConsumerState<NewsstandPage> createState() => _NewsstandPageState();
}

class _NewsstandPageState extends ConsumerState<NewsstandPage> {
  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for responsive layout
    // Obtém dimensões da tela para layout responsivo
    final size = MediaQuery.of(context).size;
    final paddingWidth = size.width * 0.1;

    // Build main content of the page
    // Constrói conteúdo principal da página
    Widget buildContent(BuildContext context) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Hello World!',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            // Logout button with Firebase authentication
            // Botão de logout com autenticação Firebase
            ElevatedButton(
              onPressed: () {
                FirebaseAuth.instance.signOut();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const LoginPage(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Log Out',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      );
    }

    // Get localized texts
    // Obtém textos localizados
    final texts = ref.watch(languageNotifierProvider)['texts'];

    // Build scaffold with responsive layout
    // Constrói scaffold com layout responsivo
    return Scaffold(
      appBar: AppBar(
        title: Text(texts['newsstand'][0]),
        actions: const [
          ThemeSwitch(),
          LanguageSwitch(),
        ],
      ),
      bottomNavigationBar: const DefaultBottomAppBar(),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: HelperClass(
          mobile: buildContent(context),
          tablet: buildContent(context),
          desktop: buildContent(context),
          paddingWidth: paddingWidth,
          bgColor: Theme.of(context).colorScheme.surface,
        ),
      ),
    );
  }
}

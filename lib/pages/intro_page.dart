// Required imports for the intro page
// Importações necessárias para a página de introdução
import 'package:editto_flutter/utilities/language_notifier.dart';
import 'package:editto_flutter/widgets/language_switch.dart';
import 'package:editto_flutter/widgets/theme_switch.dart';
import 'package:flutter/material.dart';
import 'package:editto_flutter/utilities/helper_class.dart';
import 'package:editto_flutter/pages/login_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Intro page widget with state management
// Widget da página de introdução com gerenciamento de estado
class IntroPage extends ConsumerStatefulWidget {
  const IntroPage({super.key});

  @override
  ConsumerState<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends ConsumerState<IntroPage> {
  @override
  Widget build(BuildContext context) {
    // Get localized texts and screen dimensions
    // Obtém textos localizados e dimensões da tela
    final texts = ref.watch(languageNotifierProvider)['texts'];
    final size = MediaQuery.of(context).size;
    final paddingWidth = size.width * 0.1;

    // Build the main content of the page
    // Constrói o conteúdo principal da página
    Widget buildContent(BuildContext context) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo and title section
            // Seção do logo e título do app
            Theme.of(context).brightness == Brightness.light
                ? Image.asset(
                    'assets/logo_light.png',
                    height: 120,
                  )
                : Image.asset(
                    'assets/logo_dark.png',
                    height: 120,
                  ),
            const SizedBox(height: 24),
            Text(
              'Éditto', // texts['intro'][0] - "Éditto" / "Éditto"
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
              textAlign: TextAlign.center,
            ),
            Text(
              texts['intro'][
                  1], // "Truly Yours Magazine" / "Verdadeiramente Sua Magazine"
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 64),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const LoginPage(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 48,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                texts['intro'][2], // "Get Started" / "Começar"
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      );
    }

    // Responsive layout scaffold
    // Scaffold com layout responsivo
    return Scaffold(
      appBar: AppBar(
        actions: const [
          ThemeSwitch(),
          LanguageSwitch(),
        ],
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        // Responsive layout helper
        // Auxiliar de layout responsivo
        child: HelperClass(
          mobile: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: buildContent(context),
          ),
          tablet: Center(
            child: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: buildContent(context),
              ),
            ),
          ),
          desktop: Center(
            child: SizedBox(
              width: 600,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: buildContent(context),
              ),
            ),
          ),
          paddingWidth: paddingWidth,
          bgColor: Theme.of(context).colorScheme.surface,
        ),
      ),
    );
  }
}

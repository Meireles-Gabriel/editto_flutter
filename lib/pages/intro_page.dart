// Required imports for the intro page
// Importações necessárias para a página de introdução
import 'package:editto_flutter/utilities/language_notifier.dart';
import 'package:editto_flutter/widgets/language_switch.dart';
import 'package:editto_flutter/widgets/theme_switch.dart';
import 'package:flutter/material.dart';
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
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get localized texts and screen dimensions
    // Obtém textos localizados e dimensões da tela
    final texts = ref.watch(languageNotifierProvider)['texts'];
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Build the main content of the page (center section)
    // Constrói o conteúdo principal da página (seção central)
    Widget buildCenterContent(BuildContext context) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo and title section
            // Seção do logo e título do app
            isDarkMode
                ? Image.asset(
                    'assets/logo_dark.png',
                    height: 120,
                  )
                : Image.asset(
                    'assets/logo_light.png',
                    height: 120,
                  ),
            const SizedBox(height: 24),
            Text(
              texts['intro'][0], // "Éditto" / "Éditto"
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

    // Build the left section with image and text
    // Constrói a seção esquerda com imagem e texto
    Widget buildLeftContent(BuildContext context) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Background image based on theme
          // Imagem de fundo baseada no tema
          Image.asset(
            isDarkMode
                ? 'assets/intro_left_dark.png'
                : 'assets/intro_left_light.png',
            height: 500,
            fit: BoxFit.cover,
          ),
          // Text positioned above bottom right
          // Texto posicionado acima da parte inferior direita
          Text(
            texts['intro'][
                3], // "Create Magazines based on any theme" / "Crie Revistas baseadas em qualquer tema"
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    // Build the right section with image and text
    // Constrói a seção direita com imagem e texto
    Widget buildRightContent(BuildContext context) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Text positioned above bottom left
          // Texto posicionado acima da parte inferior esquerda
          Text(
            texts['intro']
                [4], // "Make your own collection" / "Faça sua própria coleção"
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
            textAlign: TextAlign.center,
          ),
          // Background image based on theme
          // Imagem de fundo baseada no tema
          Image.asset(
            isDarkMode
                ? 'assets/intro_right_dark.png'
                : 'assets/intro_right_light.png',
            height: 500,
            fit: BoxFit.cover,
          ),
        ],
      );
    }

    // Build mobile view with Column layout
    // Constrói a visão para celular com layout em Coluna
    Widget buildMobileView() {
      return SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            buildCenterContent(context),
            const SizedBox(height: 100),
            buildLeftContent(context),
            const SizedBox(height: 100),
            buildRightContent(context),
            const SizedBox(height: 100),
            // Floating action button for scrolling to top
            // Botão de ação flutuante para rolar para o topo
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: FloatingActionButton(
                backgroundColor: isDarkMode ? Colors.black : Colors.white,
                onPressed: () {
                  _scrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                  );
                },
                child: Icon(
                  Icons.arrow_upward,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Build tablet view with CenterContent on top and Left/Right in Row below
    // Constrói a visão para tablet com CenterContent no topo e Left/Right em Row abaixo
    Widget buildTabletView() {
      return SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            buildCenterContent(context),
            const SizedBox(height: 100),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: buildLeftContent(context)),
                Expanded(child: buildRightContent(context)),
              ],
            ),
            const SizedBox(height: 100),
            // Floating action button for scrolling to top
            // Botão de ação flutuante para rolar para o topo
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: FloatingActionButton(
                backgroundColor: isDarkMode ? Colors.black : Colors.white,
                onPressed: () {
                  _scrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                  );
                },
                child: Icon(
                  Icons.arrow_upward,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Build desktop view with Row layout
    // Constrói a visão para desktop com layout em Row
    Widget buildDesktopView() {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left section
          // Seção esquerda
          buildLeftContent(context),
          // Center section
          // Seção central
          buildCenterContent(context),
          // Right section
          // Seção direita
          buildRightContent(context),
        ],
      );
    }

    // Custom HelperClass without padding for IntroPage
    // HelperClass personalizada sem padding para IntroPage
    Widget customHelperClass() {
      // Using LayoutBuilder directly instead of padding from HelperClass
      // Usando LayoutBuilder diretamente em vez do padding do HelperClass
      return LayoutBuilder(
        builder: (context, constraints) {
          // Mobile layout (< 768px)
          // Layout móvel (< 768px)
          if (constraints.maxWidth < 768) {
            return buildMobileView();
          }
          // Tablet layout (768px - 1200px)
          // Layout tablet (768px - 1200px)
          else if (constraints.maxWidth < 1200) {
            return buildTabletView();
          }
          // Desktop layout (>= 1200px)
          // Layout desktop (>= 1200px)
          else {
            return buildDesktopView();
          }
        },
      );
    }

    // Responsive layout scaffold
    // Scaffold com layout responsivo
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        scrolledUnderElevation: 0,
        actions: const [
          ThemeSwitch(),
          LanguageSwitch(),
        ],
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: customHelperClass(),
      ),
    );
  }
}

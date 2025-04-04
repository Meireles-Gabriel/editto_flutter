// Required imports for creation page functionality
// Importações necessárias para funcionalidade da página de criação
import 'dart:math';
import 'package:editto_flutter/utilities/language_notifier.dart';
import 'package:editto_flutter/utilities/magazine_creation.dart';
import 'package:editto_flutter/widgets/default_bottom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:editto_flutter/utilities/helper_class.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider for tracking magazine creation progress
// Provedor para acompanhar o progresso da criação da revista

// Creation page widget with state management
// Widget da página de criação com gerenciamento de estado
class CreationPage extends ConsumerStatefulWidget {
  final String language;
  final String topic;
  final int coins;

  const CreationPage({
    super.key,
    required this.language,
    required this.topic,
    required this.coins,
  });

  @override
  ConsumerState<CreationPage> createState() => _CreationPageState();
}

class _CreationPageState extends ConsumerState<CreationPage>
    with SingleTickerProviderStateMixin {
  // Animation controller for progress indicators
  // Controlador de animação para indicadores de progresso
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Start magazine creation process
    // Inicia o processo de criação da revista
    _startCreationProcess(
      widget.language,
      widget.topic,
      widget.coins,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Simulates the magazine creation process
  // Simula o processo de criação da revista
  Future<void> _startCreationProcess(language, theme, coins) async {
    dynamic data = createMagazine(ref, language, theme, coins);

    // Once complete, navigate to magazine view (to be implemented)
    // Uma vez concluído, navega para a visualização da revista (a ser implementado)
    if (mounted) {
      // TODO: Navigate to magazine view
      // TODO: Navegar para a visualização da revista
    }
  }

  // Build main content with loading indicators
  // Constrói conteúdo principal com indicadores de carregamento
  Widget buildContent(BuildContext context) {
    final texts = ref.watch(languageNotifierProvider)['texts'];
    final progress = ref.watch(creationProgressProvider);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Topic title
            // Título do tópico
            Text(
              //widget.topic,
              ref.watch(magazineRawDataProvider).toString(),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),

            // Circular progress indicator
            // Indicador de progresso circular
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 8,
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 48),

            // Animated dots to show activity
            // Pontos animados para mostrar atividade
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      texts['creation']?[0] ?? 'Creating your magazine',
                      // "Creating your magazine" / "Criando sua revista"
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    _buildAnimatedDots(),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Build animated dots for loading indicator
  // Constrói pontos animados para indicador de carregamento
  Widget _buildAnimatedDots() {
    return SizedBox(
      width: 40,
      child: Row(
        children: List.generate(3, (index) {
          final delay = index * 0.2;
          final sinValue =
              sin((_animationController.value * 2 * 3.14159) + delay);
          final opacityValue = (sinValue + 1) / 2; // Transform to 0.0-1.0 range
          return Opacity(
            opacity: opacityValue,
            child: const Text(
              '.',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for responsive layout
    // Obtém dimensões da tela para layout responsivo
    final size = MediaQuery.of(context).size;
    final paddingWidth = size.width * 0.1;

    // Build scaffold with responsive layout
    // Constrói scaffold com layout responsivo
    return Scaffold(
      appBar: AppBar(
        title: Text(ref.watch(languageNotifierProvider)['texts']['creation']
                ?[1] ??
            'Magazine Creation'),
        // "Magazine Creation" / "Criação de Revista"
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

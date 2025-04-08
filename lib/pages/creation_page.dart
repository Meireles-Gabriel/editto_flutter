// Required imports for creation page functionality
// Importações necessárias para funcionalidade da página de criação
import 'dart:math';
import 'package:editto_flutter/pages/error_page.dart';
import 'package:editto_flutter/utilities/language_notifier.dart';
import 'package:editto_flutter/utilities/magazine_creation_flow.dart';
import 'package:editto_flutter/utilities/raw_magazine_data_flow.dart';
import 'package:flutter/material.dart';
import 'package:editto_flutter/utilities/helper_class.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

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
    _creationProcess(
      widget.language == 'pt' ? 'pt_BR' : 'en_US',
      widget.topic,
      widget.coins,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _creationProcess(language, theme, coins) async {
    try {
      // Create magazine
      await createMagazine(ref, language, theme, coins);

      // Check if we have PDF data
      final pdfData = ref.read(pdfBytesProvider);
      if (pdfData == null) {
        throw Exception('PDF generation failed');
      }

      // If creation is successful and not currently disposed, show the PDF preview
      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Dialog.fullscreen(
            child: Scaffold(
              appBar: AppBar(
                title: Text(widget.topic),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              body: PdfPreview(
                build: (format) => pdfData,
                canChangeOrientation: false,
                canChangePageFormat: false,
                allowPrinting: true,
                allowSharing: true,
              ),
            ),
          ),
        );

        // Return to previous screen after dialog is closed
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      // If an error occurs and not currently disposed, navigate to error page
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ErrorPage(
              errorMessage: e.toString(),
              onRetry: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => CreationPage(
                      language: widget.language,
                      topic: widget.topic,
                      coins: widget.coins,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      }
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
        automaticallyImplyLeading: false,
        title: Text(ref.watch(languageNotifierProvider)['texts']['creation']
                ?[1] ??
            'Magazine Creation'),
        // "Magazine Creation" / "Criação de Revista"
      ),
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

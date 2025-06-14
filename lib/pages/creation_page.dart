// Required imports for creation page functionality
// Importações necessárias para funcionalidade da página de criação
import 'dart:convert';
import 'package:editto_flutter/pages/error_page.dart';
import 'package:editto_flutter/pages/pdf_viewer_page.dart';
import 'package:editto_flutter/utilities/language_notifier.dart';
import 'package:editto_flutter/utilities/magazine_creation_flow.dart';
import 'package:editto_flutter/utilities/raw_magazine_data_flow.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:editto_flutter/utilities/helper_class.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import 'package:animate_do/animate_do.dart';

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
  // Animation controller for animations
  // Controlador de animação para animações
  late AnimationController _animationController;

  // Current description based on progress
  // Descrição atual baseada no progresso
  String _currentDescription = '';
  double _lastProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Initialize with the first description text
    // Inicializa com o primeiro texto de descrição
    final texts = ref.read(languageNotifierProvider)['texts'];
    _currentDescription =
        texts['creation'][6]; // Show first description (0% progress)

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

  /// Process for creating and uploading the magazine
  /// Processo de criação e upload da revista
  Future<void> _creationProcess(language, theme, coins) async {
    try {
      // Start magazine creation in background
      // Inicia a criação da revista em segundo plano
      await Future.microtask(() async {
        ref.read(creationProgressProvider.notifier).state = 0.05;
        await createMagazine(ref, language, theme, coins);
      });

      // Check PDF data in background
      // Verifica os dados do PDF em segundo plano
      final pdfData = await Future.microtask(() {
        ref.read(creationProgressProvider.notifier).state = 0.50;
        return ref.read(pdfBytesProvider);
      });

      if (pdfData == null) {
        throw Exception('PDF generation failed');
      }

      // Get magazine data in background
      // Obtém os dados da revista em segundo plano
      final magazineData = await Future.microtask(() {
        ref.read(creationProgressProvider.notifier).state = 0.55;
        return ref.read(processDataProvider);
      });

      if (magazineData == null) {
        throw Exception('Magazine data not available');
      }

      final userID = FirebaseAuth.instance.currentUser?.uid;
      if (userID == null) {
        throw Exception('User not authenticated');
      }

      final now = DateTime.now();
      final dateFolder =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}-${now.minute.toString().padLeft(2, '0')}-${now.second.toString().padLeft(2, '0')}';

      // Sanitize topic name for file system compatibility
      // Sanitiza o nome do tópico para compatibilidade com o sistema de arquivos
      final sanitizedTopic =
          widget.topic.replaceAll(RegExp(r'[^\w\s]+'), '').replaceAll(' ', '_');

      // Create base path for storing all magazine files
      // Cria caminho base para armazenar todos os arquivos da revista
      final basePath = 'users/$userID/$dateFolder';

      // Upload all files in parallel for better performance
      // Faz upload de todos os arquivos em paralelo para melhor desempenho
      await Future.wait([
        // Upload PDF file to Firebase Storage
        // Faz upload do arquivo PDF para o Firebase Storage
        Future(() async {
          ref.read(creationProgressProvider.notifier).state = 0.60;
          final pdfFileName = '$sanitizedTopic.pdf';
          final pdfRef =
              FirebaseStorage.instance.ref().child('$basePath/$pdfFileName');

          // Create a copy of PDF data to avoid memory issues
          // Cria uma cópia dos dados do PDF para evitar problemas de memória
          final pdfDataCopy = Uint8List.fromList(pdfData);
          await pdfRef.putData(
              pdfDataCopy, SettableMetadata(contentType: 'application/pdf'));
        }),

        // Upload magazine cover image if it exists
        // Faz upload da imagem de capa da revista se existir
        if (magazineData['cover_image'] != null)
          Future(() async {
            ref.read(creationProgressProvider.notifier).state = 0.70;

            // Decode base64 image data to bytes
            // Decodifica dados da imagem em base64 para bytes
            final coverImageBytes = base64Decode(magazineData['cover_image']);
            final imageFileName = '${sanitizedTopic}_cover.jpg';
            final imageRef = FirebaseStorage.instance
                .ref()
                .child('$basePath/$imageFileName');
            await imageRef.putData(
                coverImageBytes, SettableMetadata(contentType: 'image/jpeg'));
          }),

        // Upload first page image if it exists
        // Faz upload da imagem da primeira página se existir
        if (magazineData['first_page_image'] != null)
          Future(() async {
            ref.read(creationProgressProvider.notifier).state = 0.80;

            // Decode base64 image data to bytes
            // Decodifica dados da imagem em base64 para bytes
            final firstPageImageBytes =
                base64Decode(magazineData['first_page_image']);
            final firstPageFileName = '${sanitizedTopic}_first_page.jpg';
            final firstPageRef = FirebaseStorage.instance
                .ref()
                .child('$basePath/$firstPageFileName');
            await firstPageRef.putData(firstPageImageBytes,
                SettableMetadata(contentType: 'image/jpeg'));
          }),
      ]);

      // Save metadata in background
      // Salva os metadados em segundo plano
      await Future.microtask(() async {
        ref.read(creationProgressProvider.notifier).state = 0.90;
        final magazineMetadata = {
          'theme': widget.topic,
          'language': language,
          'date': now.toIso8601String(),
          'coins': coins,
          'folderPath': basePath,
          'pdfFileName': '$sanitizedTopic.pdf',
          'coverImageFileName': '${sanitizedTopic}_cover.jpg',
          'firstPageImageFileName': '${sanitizedTopic}_first_page.jpg',
          'createdAt': FieldValue.serverTimestamp(),
        };

        // Run Firestore operations in transaction
        // Executa operações do Firestore em transação
        final batch = FirebaseFirestore.instance.batch();

        // Save magazine metadata
        // Salva os metadados da revista
        final magazineRef = FirebaseFirestore.instance
            .collection('Users')
            .doc(userID)
            .collection('Magazines')
            .doc(dateFolder);
        batch.set(magazineRef, magazineMetadata);

        // Update user coins
        // Atualiza as moedas do usuário
        final userRef =
            FirebaseFirestore.instance.collection('Users').doc(userID);
        final userDoc = await userRef.get();
        if (!userDoc.exists) {
          throw Exception('User document does not exist');
        }

        final currentCoins = userDoc.data()?['coins'] ?? 0;
        if (currentCoins < coins) {
          throw Exception('Insufficient coins');
        }

        batch.update(userRef, {'coins': currentCoins - coins});
        await batch.commit();
      });

      // Navigate to PDF viewer
      // Navega para o visualizador de PDF
      if (mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PdfViewerPage(
              title: widget.topic,
              initialPdfData: pdfData,
            ),
          ),
        );

        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      // If an error occurs and not currently disposed, navigate to error page
      // Se ocorrer um erro e não estiver atualmente descartado, navega para a página de erro
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

  // Get description text based on progress
  // Obtém texto de descrição baseado no progresso
  String _getDescriptionText(double progress, List<String> texts) {
    if (progress == 0.0 || progress < 0.05) {
      return texts[6]; // At 0% show editorial team brainstorming
    }
    if (progress < 0.15) return texts[7]; // Journalists interviewing experts
    if (progress < 0.25) return texts[8]; // Writers drafting articles
    if (progress < 0.35) return texts[9]; // Editor reviewing content
    if (progress < 0.45) return texts[10]; // Design team creating cover layout
    if (progress < 0.55) {
      return texts[11]; // Photographers capturing cover image
    }
    if (progress < 0.65) return texts[12]; // Layout artists arranging interior
    if (progress < 0.75) return texts[13]; // Finalizing graphics and images
    if (progress < 0.85) return texts[14]; // Printing copies
    if (progress < 0.95) return texts[15]; // Quality control checking
    return texts[16]; // Final product is ready
  }

  // Build main content with loading indicators
  // Constrói conteúdo principal com indicadores de carregamento
  Widget buildContent(BuildContext context) {
    final texts = ref.watch(languageNotifierProvider)['texts'];
    final progress = ref.watch(creationProgressProvider);

    // Check if progress has changed enough to update description
    // Verifica se o progresso mudou o suficiente para atualizar a descrição
    if ((progress - _lastProgress).abs() >= 0.05) {
      _lastProgress = progress;
      _currentDescription = _getDescriptionText(progress, texts['creation']);
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Topic title
            // Título do tópico
            Text(
              widget.topic,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),

            // Magazine creation animation
            // Animação de criação de revista
            SizedBox(
              height: 200,
              width: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Custom circular progress indicator
                  // Indicador de progresso circular personalizado
                  SizedBox(
                    height: 150,
                    width: 150,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 5,
                      backgroundColor:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  // White background circle for the animation
                  // Círculo de fundo branco para a animação
                  Container(
                    width: 130,
                    height: 130,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  // Magazine loading animation
                  // Animação de carregamento da revista
                  Lottie.asset(
                    'assets/lottie/magazine_loading.json',
                    width: 120,
                    height: 120,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),

            // Description text that changes with progress
            // Texto de descrição que muda com o progresso
            FadeIn(
              key: ValueKey(_currentDescription),
              duration: const Duration(milliseconds: 500),
              child: Text(
                _currentDescription,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
          ],
        ),
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

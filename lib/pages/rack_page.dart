// Required imports for rack functionality
// Importações necessárias para funcionalidade da estante
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:editto_flutter/pages/pdf_viewer_page.dart';
import 'package:editto_flutter/utilities/language_notifier.dart';
import 'package:editto_flutter/widgets/default_bottom_app_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:editto_flutter/utilities/helper_class.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:async';

// Rack page widget with state management
// Widget da página da estante com gerenciamento de estado
class RackPage extends ConsumerStatefulWidget {
  const RackPage({super.key});

  @override
  ConsumerState<RackPage> createState() => _RackPageState();
}

class _RackPageState extends ConsumerState<RackPage> {
  late Stream<QuerySnapshot> _magazinesStream;
  bool _showCoverImage = false; // Control whether to show cover or first page
  // Controla se mostra capa ou primeira página

  @override
  void initState() {
    super.initState();

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      // Set up stream to listen for magazine documents ordered by createdAt
      _magazinesStream = FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .collection('Magazines')
          .orderBy('createdAt', descending: true)
          .snapshots();
    }
  }

  // Format date based on selected language
  // Formata data com base na linguagem selecionada
  String _formatDate(DateTime date, String language) {
    if (language == 'pt') {
      return DateFormat('dd/MM/yyyy').format(date);
    } else {
      return DateFormat('MM-dd-yyyy').format(date);
    }
  }

  // Load magazine PDF and open the PDF viewer
  // Carrega o PDF da revista e abre o visualizador de PDF
  Future<void> _openMagazine(
      BuildContext context, Map<String, dynamic> magazineData) async {
    try {
      final storageRef = FirebaseStorage.instance.ref().child(
          '${magazineData['folderPath']}/${magazineData['pdfFileName']}');

      // Show loading indicator
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      // Download the PDF with a timeout
      final pdfBytes = await storageRef.getData().timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw TimeoutException('Download timed out');
        },
      );

      // Close loading indicator
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Open PDF viewer if download successful
      if (pdfBytes != null && pdfBytes.isNotEmpty && context.mounted) {
        try {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => PdfViewerPage(
                title: magazineData['theme'],
                initialPdfData: pdfBytes,
              ),
            ),
          );
        } catch (viewerError) {
          if (context.mounted) {
            final texts = ref.watch(languageNotifierProvider)['texts'];
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      '${texts['pdfViewer']?[1] ?? "Failed to load PDF"}: $viewerError')),
            );
          }
        }
      } else {
        throw Exception('Downloaded PDF data is empty or null');
      }
    } catch (e) {
      // Close loading indicator if error occurs
      if (context.mounted) {
        // Make sure dialog is closed
        try {
          Navigator.of(context).pop();
        } catch (_) {
          // Dialog might not be showing
        }

        final texts = ref.watch(languageNotifierProvider)['texts'];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  '${texts['rack']?[1] ?? "Error loading your magazines."}: $e')),
        );
      }
    }
  }

  // Get the appropriate image path based on user preference
  // Obtém o caminho de imagem apropriado com base na preferência do usuário
  String? _getImagePath(Map<String, dynamic> magazineData) {
    if (magazineData['folderPath'] == null) return null;

    if (_showCoverImage) {
      return magazineData['coverImageFileName'] != null
          ? '${magazineData['folderPath']}/${magazineData['coverImageFileName']}'
          : null;
    } else {
      return magazineData['firstPageImageFileName'] != null
          ? '${magazineData['folderPath']}/${magazineData['firstPageImageFileName']}'
          : null;
    }
  }

  // Build main content with grid of magazines
  // Constrói conteúdo principal com grade de revistas
  Widget buildContent(BuildContext context) {
    final texts = ref.watch(languageNotifierProvider)['texts'];
    final language = ref.watch(languageNotifierProvider)['language'];

    return StreamBuilder<QuerySnapshot>(
      stream: _magazinesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('${texts['rack'][1]}'), // Error text
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text('${texts['rack'][2]}'), // No magazines text
          );
        }

        final magazines = snapshot.data!.docs;

        return CustomScrollView(
          slivers: [
            // Floating app bar with search
            // Barra de app flutuante com busca
            SliverAppBar(
              floating: true,
              title: Text(texts['rack'][0]), // "My Rack" / "Minha Estante"
              actions: [
                // Toggle button for cover/first page display
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    children: [
                      Text(
                        '${texts['rack'][5]}:', // "Display as" / "Exibir como"
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(width: 8),
                      ToggleButtons(
                        borderRadius: BorderRadius.circular(8),
                        constraints: const BoxConstraints(
                          minHeight: 32,
                          minWidth: 72,
                        ),
                        isSelected: [!_showCoverImage, _showCoverImage],
                        onPressed: (index) {
                          setState(() {
                            _showCoverImage = index == 0;
                          });
                        },
                        children: [
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text(texts['rack'][3]), // "Cover" / "Capa"
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text(texts['rack']
                                [4]), // "First Page" / "Primeira Página"
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Grid of magazine cards
            // Grade de cards de revistas
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 200.0,
                  mainAxisSpacing: 16.0,
                  crossAxisSpacing: 16.0,
                  childAspectRatio: 0.55,
                ),
                delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                    // Get magazine data from document
                    final magazineData =
                        magazines[index].data() as Map<String, dynamic>;
                    final magazineDate = magazineData['date'] != null
                        ? DateTime.parse(magazineData['date'])
                        : DateTime.now();
                    final theme = magazineData['theme'] ?? texts['rack'][6];
                    final coverPath = _getImagePath(magazineData);

                    // Magazine card with cover and details
                    // Card de revista com capa e detalhes
                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => _openMagazine(context, magazineData),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Magazine cover
                            // Capa da revista
                            Expanded(
                              child: coverPath != null
                                  ? FutureBuilder<String>(
                                      future: FirebaseStorage.instance
                                          .ref()
                                          .child(coverPath)
                                          .getDownloadURL(),
                                      builder: (context, urlSnapshot) {
                                        if (urlSnapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return Container(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withOpacity(0.1),
                                            child: const Center(
                                                child:
                                                    CircularProgressIndicator()),
                                          );
                                        }

                                        if (urlSnapshot.hasError ||
                                            !urlSnapshot.hasData) {
                                          return Container(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withOpacity(0.1),
                                            child: Center(
                                              child: Icon(
                                                Icons.book,
                                                size: 48,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                              ),
                                            ),
                                          );
                                        }

                                        return CachedNetworkImage(
                                          imageUrl: urlSnapshot.data!,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: double.infinity,
                                          placeholder: (context, url) =>
                                              Container(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withOpacity(0.1),
                                            child: const Center(
                                                child:
                                                    CircularProgressIndicator()),
                                          ),
                                          errorWidget: (context, url, error) =>
                                              Container(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withOpacity(0.1),
                                            child: Center(
                                              child: Icon(
                                                Icons.book,
                                                size: 48,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    )
                                  : Container(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withOpacity(0.1),
                                      child: Center(
                                        child: Icon(
                                          Icons.book,
                                          size: 48,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                      ),
                                    ),
                            ),
                            // Magazine details section
                            // Seção de detalhes da revista
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    theme,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatDate(magazineDate, language),
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: magazines.length,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for responsive layout
    // Obtém dimensões da tela para layout responsivo
    final size = MediaQuery.of(context).size;
    final paddingWidth = size.width * 0.0;

    // Build scaffold with responsive layout
    // Constrói scaffold com layout responsivo
    return Scaffold(
      bottomNavigationBar: const DefaultBottomAppBar(),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: HelperClass(
          mobile: buildContent(context),
          tablet: Center(
            child: SizedBox(
              width: 720,
              child: buildContent(context),
            ),
          ),
          desktop: Center(
            child: SizedBox(
              width: 1200,
              child: buildContent(context),
            ),
          ),
          paddingWidth: paddingWidth,
          bgColor: Theme.of(context).colorScheme.surface,
        ),
      ),
    );
  }
}

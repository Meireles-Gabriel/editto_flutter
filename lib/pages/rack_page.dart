// Required imports for rack functionality
// Importações necessárias para funcionalidade da estante
import 'dart:io';

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
import 'package:file_saver/file_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

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
      // Configura stream para ouvir documentos de revistas ordenados por createdAt
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

  // Handle file downloads from Firebase Storage
  // Gerencia downloads de arquivos do Firebase Storage
  Future<void> _downloadFile(
      BuildContext context, String filePath, String type) async {
    final texts = ref.watch(languageNotifierProvider)['texts'];
    try {
      if (filePath.isEmpty) {
        throw Exception('File path not found');
      }

      // Request storage permission for mobile devices
      if (!kIsWeb) {
        final permission = await Permission.storage.request();
        if (!permission.isGranted) {
          throw Exception('Storage permission denied');
        }
      }

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

      final storageRef = FirebaseStorage.instance.ref().child(filePath);
      final bytes = await storageRef.getData();

      // Close loading indicator
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (bytes == null || bytes.isEmpty) {
        throw Exception('Downloaded file is empty');
      }

      // Get file name from path
      final fileName = filePath.split('/').last.split('.').first;

      // Save file based on platform
      if (kIsWeb) {
        // Web platform - use FileSaver
        await FileSaver.instance.saveFile(
          name: fileName,
          bytes: bytes,
          ext: type.toLowerCase() == 'pdf' ? 'pdf' : 'jpg',
          mimeType: type.toLowerCase() == 'pdf' ? MimeType.pdf : MimeType.jpeg,
        );
      } else {
        // Mobile/Desktop platforms
        Directory? directory;
        if (Platform.isAndroid) {
          // Use downloads directory for Android
          directory = Directory('/storage/emulated/0/Download');
          // Create directory if it doesn't exist
          if (!await directory.exists()) {
            directory = await getExternalStorageDirectory();
          }
        } else {
          directory = await getApplicationDocumentsDirectory();
        }

        if (directory == null) {
          throw Exception('Could not access storage directory');
        }

        final fullPath =
            '${directory.path}/$fileName.${type.toLowerCase() == 'pdf' ? 'pdf' : 'jpg'}';
        final file = File(fullPath);
        await file.writeAsBytes(bytes);
      }

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${texts['rack'][7]} $type'),
          ),
        );
      }
    } catch (e) {
      // Close loading indicator if error occurs
      if (context.mounted) {
        try {
          Navigator.of(context).pop();
        } catch (_) {
          // Dialog might not be showing
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${texts['rack'][8]} $type: $e'), // "Error downloading" / "Erro ao baixar"
          ),
        );
      }
    }
  }

  // Add delete magazine function
  // Adiciona função de excluir revista
  Future<void> _deleteMagazine(
      BuildContext context, Map<String, dynamic> magazineData) async {
    final texts = ref.watch(languageNotifierProvider)['texts'];

    // Show confirmation dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(texts['rack'][13]),
          content: Text(texts['rack'][14]),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(texts['rack'][15]),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(texts['rack'][16]),
            ),
          ],
        );
      },
    );

    if (confirm != true || !context.mounted) return;

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      // Delete files from Storage
      final storageRef = FirebaseStorage.instance.ref();
      final filesToDelete = [
        '${magazineData['folderPath']}/${magazineData['pdfFileName']}',
        '${magazineData['folderPath']}/${magazineData['coverImageFileName']}',
        '${magazineData['folderPath']}/${magazineData['firstPageImageFileName']}'
      ];

      // Delete all files in parallel
      await Future.wait(
        filesToDelete
            .map((path) => storageRef.child(path).delete().catchError((e) {
                  // Ignore if file doesn't exist
                  if (e.code != 'object-not-found') throw e;
                })),
      );

      // Delete document from Firestore
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .collection('Magazines')
          .doc(magazineData['folderPath'].split('/').last)
          .delete();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(texts['rack'][17])),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${texts['rack'][18]}: $e')),
        );
      }
    }
  }

  // Get the appropriate image path based on user preference
  // Obtém o caminho da imagem apropriado com base na preferência do usuário
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
              backgroundColor: Theme.of(context).colorScheme.surface,
              scrolledUnderElevation: 0,
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
                      child: Stack(
                        children: [
                          InkWell(
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
                                              errorWidget:
                                                  (context, url, error) =>
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Add popup menu button
                          Positioned(
                            top: 0,
                            right: 0,
                            child: PopupMenuButton<String>(
                              icon: Icon(
                                Icons.more_vert,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'pdf',
                                  child: Text(texts['rack'][
                                      9]), // "Download Magazine" / "Baixar Revista"
                                ),
                                PopupMenuItem(
                                  value: 'cover',
                                  child: Text(texts['rack']
                                      [10]), // "Download Cover" / "Baixar Capa"
                                ),
                                PopupMenuItem(
                                  value: 'image',
                                  child: Text(texts['rack'][
                                      11]), // "Download Image" / "Baixar Imagem"
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text(texts['rack'][12]),
                                ),
                              ],
                              onSelected: (value) {
                                switch (value) {
                                  case 'pdf':
                                    _downloadFile(
                                      context,
                                      '${magazineData['folderPath']}/${magazineData['pdfFileName']}',
                                      'PDF',
                                    );
                                    break;
                                  case 'cover':
                                    _downloadFile(
                                      context,
                                      '${magazineData['folderPath']}/${magazineData['coverImageFileName']}',
                                      'Cover',
                                    );
                                    break;
                                  case 'image':
                                    _downloadFile(
                                      context,
                                      '${magazineData['folderPath']}/${magazineData['firstPageImageFileName']}',
                                      'Image',
                                    );
                                    break;
                                  case 'delete':
                                    _deleteMagazine(context, magazineData);
                                    break;
                                }
                              },
                            ),
                          ),
                        ],
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

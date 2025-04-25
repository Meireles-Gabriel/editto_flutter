import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:editto_flutter/utilities/helper_class.dart';
import 'package:editto_flutter/utilities/language_notifier.dart';
import 'package:flutter/foundation.dart';

// Provider to hold the PDF data
// Provedor para armazenar os dados do PDF
final pdfDataProvider = StateProvider<Uint8List?>((ref) => null);

// PDF Viewer page widget with state management
// Widget da página do visualizador de PDF com gerenciamento de estado
class PdfViewerPage extends ConsumerStatefulWidget {
  final String title;
  final Uint8List? initialPdfData;
  final Future<Uint8List> Function()? pdfDataLoader;

  // Store a copy of the data immediately
  // Armazena uma cópia dos dados imediatamente
  late final Uint8List? _pdfDataCopy;

  PdfViewerPage({
    super.key,
    required this.title,
    this.initialPdfData,
    this.pdfDataLoader,
  }) : assert(initialPdfData != null || pdfDataLoader != null,
            'Either initialPdfData or pdfDataLoader must be provided') {
    // Make a copy immediately if we have initialPdfData
    // Faz uma cópia imediatamente se tivermos initialPdfData
    _pdfDataCopy =
        initialPdfData != null ? Uint8List.fromList(initialPdfData!) : null;
  }

  @override
  ConsumerState<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends ConsumerState<PdfViewerPage> {
  @override
  void initState() {
    super.initState();

    // Initialize with already copied data if available
    // Inicializa com dados já copiados, se disponíveis
    if (widget._pdfDataCopy != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(pdfDataProvider.notifier).state = widget._pdfDataCopy;
      });
    }
    // Load PDF if loader is provided
    // Carrega o PDF se o carregador for fornecido
    else if (widget.pdfDataLoader != null) {
      _loadPdf();
    }
  }

  // Load PDF data using the provided loader
  // Carrega dados do PDF usando o carregador fornecido
  Future<void> _loadPdf() async {
    try {
      final pdfData = await widget.pdfDataLoader!();
      if (pdfData.isNotEmpty && mounted) {
        // Create a fresh copy of the PDF data
        // Cria uma nova cópia dos dados do PDF
        final pdfDataCopy = Uint8List.fromList(pdfData);
        ref.read(pdfDataProvider.notifier).state = pdfDataCopy;
      }
    } catch (e) {
      if (mounted) {
        final texts = ref.read(languageNotifierProvider)['texts'];
        if (kDebugMode) {
          print('PDF loading error: $e');
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${texts['pdfViewer']?[1] ?? 'Failed to load PDF'}: ${e.toString()}'),
          ),
        );
      }
    }
  }

  // Build content for different screen sizes
  // Constrói conteúdo para diferentes tamanhos de tela
  Widget buildContent(BuildContext context) {
    final pdfData = ref.watch(pdfDataProvider);

    return pdfData == null
        ? const Center(
            child: CircularProgressIndicator(),
          )
        : PdfPreview(
            build: (format) => pdfData,
            canChangeOrientation: false,
            canChangePageFormat: false,
            allowPrinting: true,
            allowSharing: true,
          );
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for responsive layout
    // Obtém dimensões da tela para layout responsivo
    final size = MediaQuery.of(context).size;
    final paddingWidth = size.width * 0.05;

    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Theme.of(context).colorScheme.secondary,
        title: Text(widget.title),
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

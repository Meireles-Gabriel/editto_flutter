import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:editto_flutter/utilities/helper_class.dart';

// Provider to hold the PDF data
final pdfDataProvider = StateProvider<Uint8List?>((ref) => null);

class PdfViewerPage extends ConsumerStatefulWidget {
  final String title;
  final Uint8List? initialPdfData;
  final Future<Uint8List> Function()? pdfDataLoader;

  // Store a copy of the data immediately
  late final Uint8List? _pdfDataCopy;

  PdfViewerPage({
    super.key,
    required this.title,
    this.initialPdfData,
    this.pdfDataLoader,
  }) : assert(initialPdfData != null || pdfDataLoader != null,
            'Either initialPdfData or pdfDataLoader must be provided') {
    // Make a copy immediately if we have initialPdfData
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
    if (widget._pdfDataCopy != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(pdfDataProvider.notifier).state = widget._pdfDataCopy;
      });
    }
    // Load PDF if loader is provided
    else if (widget.pdfDataLoader != null) {
      _loadPdf();
    }
  }

  Future<void> _loadPdf() async {
    try {
      final pdfData = await widget.pdfDataLoader!();
      if (pdfData.isNotEmpty && mounted) {
        // Create a fresh copy of the PDF data
        final pdfDataCopy = Uint8List.fromList(pdfData);
        ref.read(pdfDataProvider.notifier).state = pdfDataCopy;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load PDF: ${e.toString()}')),
        );
      }
    }
  }

  // Build content for different screen sizes
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
    final size = MediaQuery.of(context).size;
    final paddingWidth = size.width * 0.05;

    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Theme.of(context).colorScheme.secondary,
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
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

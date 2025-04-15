import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider to hold the PDF data
final pdfDataProvider = StateProvider<Uint8List?>((ref) => null);

class PdfViewerPage extends ConsumerStatefulWidget {
  final String title;
  final Uint8List? initialPdfData;
  final Future<Uint8List> Function()? pdfDataLoader;

  const PdfViewerPage({
    super.key,
    required this.title,
    this.initialPdfData,
    this.pdfDataLoader,
  }) : assert(initialPdfData != null || pdfDataLoader != null,
            'Either initialPdfData or pdfDataLoader must be provided');

  @override
  ConsumerState<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends ConsumerState<PdfViewerPage> {
  @override
  void initState() {
    super.initState();

    // Initialize with initial data if available
    if (widget.initialPdfData != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(pdfDataProvider.notifier).state = widget.initialPdfData;
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
        ref.read(pdfDataProvider.notifier).state = pdfData;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load PDF: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pdfData = ref.watch(pdfDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: pdfData == null
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : PdfPreview(
              build: (format) => pdfData,
              canChangeOrientation: false,
              canChangePageFormat: false,
              allowPrinting: true,
              allowSharing: true,
            ),
    );
  }
}

import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';

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
  String? _pdfFilePath;
  bool _isLoading = true;
  String? _errorMessage;
  int _totalPages = 0;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _initPdf();
  }

  Future<void> _initPdf() async {
    if (kIsWeb) {
      setState(() {
        _errorMessage = 'Web platform is not supported with this viewer';
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      Uint8List? pdfData;

      // Get PDF data from initial data or loader
      if (widget.initialPdfData != null) {
        pdfData = widget.initialPdfData;
      } else if (widget.pdfDataLoader != null) {
        pdfData = await widget.pdfDataLoader!();
      }

      if (pdfData == null || pdfData.isEmpty) {
        throw Exception('No PDF data available');
      }

      // Update provider state safely after the build phase
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(pdfDataProvider.notifier).state = pdfData;
      });

      // For flutter_pdfview, we need to save the PDF to a temporary file
      final tempDir = await getTemporaryDirectory();
      final tempFilePath =
          '${tempDir.path}/temp_viewer_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final tempFile = File(tempFilePath);
      await tempFile.writeAsBytes(pdfData);

      if (mounted) {
        setState(() {
          _pdfFilePath = tempFilePath;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load PDF: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          // Add page indicator if we have pages
          if (_totalPages > 0)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  'Page ${_currentPage + 1} of $_totalPages',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
        ],
      ),
      body: _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error loading PDF',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(_errorMessage!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _initPdf,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : _isLoading || _pdfFilePath == null
              ? const Center(child: CircularProgressIndicator())
              : PDFView(
                  filePath: _pdfFilePath!,
                  enableSwipe: true,
                  swipeHorizontal: true,
                  autoSpacing: true,
                  pageFling: true,
                  pageSnap: true,
                  defaultPage: 0,
                  fitPolicy: FitPolicy.BOTH,
                  preventLinkNavigation: false,
                  onRender: (pages) {
                    if (mounted) {
                      setState(() {
                        _totalPages = pages!;
                      });
                    }
                  },
                  onError: (error) {
                    if (mounted) {
                      setState(() {
                        _errorMessage = error.toString();
                      });
                    }
                  },
                  onPageError: (page, error) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error loading page $page: $error'),
                        ),
                      );
                    }
                  },
                  onViewCreated: (PDFViewController controller) {
                    // You can save the controller for future use
                  },
                  onPageChanged: (page, total) {
                    if (mounted) {
                      setState(() {
                        _currentPage = page!;
                      });
                    }
                  },
                ),
    );
  }
}

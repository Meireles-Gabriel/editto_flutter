import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'raw_magazine_data_flow.dart';

// Provider for the generated PDF bytes
final pdfBytesProvider = StateProvider<Uint8List?>((ref) => null);

// Create the magazine PDF
Future<Uint8List> createMagazinePDF(Map<String, dynamic> magazineData) async {
  // Validate required data
  if (magazineData['cover_image'] == null) {
    throw Exception('Cover image is missing');
  }
  if (magazineData['cover_content'] == null) {
    throw Exception('Cover content is missing');
  }
  if (magazineData['articles'] == null) {
    throw Exception('Articles are missing');
  }

  // Create a new PDF document
  final pdf = pw.Document();

  // Load the icon image from assets
  final iconBytes = await rootBundle.load('assets/icon.png');
  final iconImage = pw.MemoryImage(iconBytes.buffer.asUint8List());

  // Decode the cover image from base64
  final coverImageBytes = base64Decode(magazineData['cover_image']);
  final coverImage = pw.MemoryImage(coverImageBytes);

  // Get cover content with null checks
  final coverContent = magazineData['cover_content'];
  final mainHeadline = coverContent['main_headline'];
  final subheading = coverContent['subheading'];
  final summary1 = coverContent['summary1'];
  final summary2 = coverContent['summary2'];

  // Create cover page
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return pw.Stack(
          children: [
            // Cover image as background
            pw.Container(
              decoration: pw.BoxDecoration(
                image: pw.DecorationImage(
                  image: coverImage,
                  fit: pw.BoxFit.cover,
                ),
              ),
            ),
            // Content overlay
            pw.Padding(
              padding: const pw.EdgeInsets.all(40),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  // Top section with icon and title
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Image(iconImage, width: 50, height: 50),
                      pw.SizedBox(width: 10),
                      pw.Text(
                        'ÉDITTO',
                        style: pw.TextStyle(
                          fontSize: 40,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 200),
                  // Bottom section with main headline and subheading
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        mainHeadline,
                        style: pw.TextStyle(
                          fontSize: 32,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        subheading,
                        style: const pw.TextStyle(
                          fontSize: 18,
                          color: PdfColors.white,
                        ),
                      ),
                    ],
                  ),
                  // Side summaries
                  pw.Positioned(
                    left: 40,
                    top: 300,
                    child: pw.Container(
                      width: 200,
                      child: pw.Text(
                        summary1,
                        style: const pw.TextStyle(
                          fontSize: 14,
                          color: PdfColors.white,
                        ),
                      ),
                    ),
                  ),
                  pw.Positioned(
                    right: 40,
                    top: 300,
                    child: pw.Container(
                      width: 200,
                      child: pw.Text(
                        summary2,
                        style: const pw.TextStyle(
                          fontSize: 14,
                          color: PdfColors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );

  // Add article pages
  final articles = magazineData['articles'];
  for (var article in articles) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(40),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  article['title'],
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Left column
                    pw.Expanded(
                      child: pw.Text(
                        article['content'],
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                    ),
                    pw.SizedBox(width: 20),
                    // Right column
                    pw.Expanded(
                      child: pw.Text(
                        article['content'],
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Return the PDF as bytes
  return pdf.save();
}

// Execute the full magazine creation process
Future<void> createMagazine(
    WidgetRef ref, String language, String theme, int coins) async {
  try {
    // Get the raw magazine data
    final magazineData = await rawMagazineDataFlow(ref, language, theme, coins);
    if (kDebugMode) {
      print(magazineData);
    }
    // Generate the PDF
    ref.read(creationProgressProvider.notifier).state = 1.0;
    final pdfBytes = await createMagazinePDF(magazineData);

    // Store the PDF bytes in the provider
    ref.read(pdfBytesProvider.notifier).state = pdfBytes;
  } catch (e) {
    if (kDebugMode) {
      print('Error creating magazine PDF: $e');
    }
    rethrow;
  }
}

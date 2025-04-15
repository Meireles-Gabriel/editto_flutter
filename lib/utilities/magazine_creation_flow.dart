import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/widgets.dart';
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'raw_magazine_data_flow.dart';

// Provider for the generated PDF bytes
final pdfBytesProvider = StateProvider<Uint8List?>((ref) => null);

// Provider for the first page image bytes
final firstPageImageProvider = StateProvider<String?>((ref) => null);

final summaryPosition = Random().nextInt(3);

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
  final iconBytes = await rootBundle.load('assets/logo_outline_white.png');
  final iconImage = pw.MemoryImage(iconBytes.buffer.asUint8List());

  // Decode the cover image from base64
  final coverImageBytes = base64Decode(magazineData['cover_image']);
  final coverImage = pw.MemoryImage(coverImageBytes);

  // Get cover content
  final coverContent = magazineData['cover_content'];
  final mainHeadline = coverContent['main_headline'].toString().toUpperCase();
  final subheading = coverContent['subheading'];
  final summary1 = coverContent['summary1'];
  final summary2 = coverContent['summary2'];

  Font fontMagazineName = await PdfGoogleFonts.montserratRegular();
  Font fontCoverTitle = await PdfGoogleFonts.montserratBold();
  Font fontArticleTitle = await PdfGoogleFonts.montserratMedium();
  Font fontBody = await PdfGoogleFonts.montserratRegular();

  // Create cover page
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4.copyWith(
        marginLeft: 0,
        marginRight: 0,
        marginTop: 0,
        marginBottom: 0,
      ),
      build: (pw.Context context) {
        return pw.Stack(
          children: [
            // Cover image as background (full page)
            pw.Positioned.fill(
              child: pw.Container(
                decoration: pw.BoxDecoration(
                  image: pw.DecorationImage(
                    image: coverImage,
                    fit: pw.BoxFit.cover,
                  ),
                ),
              ),
            ),
            // Content overlay
            pw.Padding(
              padding: const pw.EdgeInsets.all(40),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
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
                          font: fontMagazineName,
                          fontSize: 40,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                    ],
                  ),
                  if (summaryPosition == 0)
                    pw.Column(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Container(
                              width: 100,
                              child: pw.Text(
                                summary1,
                                style: pw.TextStyle(
                                  background: pw.BoxDecoration(
                                    border: pw.Border.all(
                                      width: 5,
                                    ),
                                  ),
                                  font: fontBody,
                                  fontSize: 14,
                                  color: PdfColors.white,
                                ),
                                textAlign: TextAlign.left,
                              ),
                            ),
                            pw.Container(
                              width: 100,
                              child: pw.Text(
                                summary2,
                                style: pw.TextStyle(
                                  background: pw.BoxDecoration(
                                    border: pw.Border.all(
                                      width: 5,
                                    ),
                                  ),
                                  font: fontBody,
                                  fontSize: 14,
                                  color: PdfColors.white,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  if (summaryPosition == 1)
                    pw.Column(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.end,
                          children: [
                            pw.Container(
                              width: 100,
                              child: pw.Text(
                                summary2,
                                style: pw.TextStyle(
                                  background: pw.BoxDecoration(
                                    border: pw.Border.all(
                                      width: 10,
                                    ),
                                  ),
                                  font: fontBody,
                                  fontSize: 14,
                                  color: PdfColors.white,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.start,
                          children: [
                            pw.Container(
                              width: 100,
                              child: pw.Text(
                                summary1,
                                style: pw.TextStyle(
                                  background: pw.BoxDecoration(
                                    border: pw.Border.all(
                                      width: 10,
                                    ),
                                  ),
                                  font: fontBody,
                                  fontSize: 14,
                                  color: PdfColors.white,
                                ),
                                textAlign: TextAlign.left,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  if (summaryPosition == 2)
                    pw.Column(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.start,
                          children: [
                            pw.Container(
                              width: 100,
                              child: pw.Text(
                                summary1,
                                style: pw.TextStyle(
                                  background: pw.BoxDecoration(
                                    border: pw.Border.all(
                                      width: 10,
                                    ),
                                  ),
                                  font: fontBody,
                                  fontSize: 14,
                                  color: PdfColors.white,
                                ),
                                textAlign: TextAlign.left,
                              ),
                            ),
                          ],
                        ),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.end,
                          children: [
                            pw.Container(
                              width: 100,
                              child: pw.Text(
                                summary2,
                                style: pw.TextStyle(
                                  background: pw.BoxDecoration(
                                    border: pw.Border.all(
                                      width: 10,
                                    ),
                                  ),
                                  font: fontBody,
                                  fontSize: 14,
                                  color: PdfColors.white,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  // Bottom section with main headline and subheading
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text(
                        mainHeadline,
                        style: pw.TextStyle(
                          font: fontCoverTitle,
                          fontSize: mainHeadline.length <= 10 ? 68 : 54,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.SizedBox(
                        width: 300,
                        child: Divider(
                          color: PdfColors.white,
                        ),
                      ),
                      pw.SizedBox(
                        height: 2,
                      ),
                      pw.Text(
                        subheading,
                        style: pw.TextStyle(
                          font: fontBody,
                          fontSize: 18,
                          color: PdfColors.white,
                        ),
                      ),
                    ],
                  ),
                  // Side summaries
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
    String content = article['content'];
    List<String> paragraphs = content.split('\n');
    for (String paragraph in paragraphs) {
      if (paragraph.trim() == '') {
        paragraphs.remove(paragraph);
      }
    }
    int firstPartN = (paragraphs.length / 2).ceil();
    String firstPart = paragraphs.sublist(0, firstPartN).join('\n\n');
    String secondPart = paragraphs.sublist(firstPartN).join('\n\n');
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.copyWith(
          marginLeft: 50,
          marginRight: 50,
          marginTop: 50,
          marginBottom: 50,
        ),
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        build: (pw.Context context) => [
          pw.Text(
            article['title'],
            style: pw.TextStyle(
              font: fontArticleTitle,
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 20),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
            children: [
              pw.SizedBox(
                height: 600,
                width: 230,
                child: pw.Text(
                  firstPart,
                  style: pw.TextStyle(
                    font: fontBody,
                    fontSize: 14,
                  ),
                ),
              ),
              pw.SizedBox(
                height: 600,
                child: pw.VerticalDivider(),
              ),
              pw.SizedBox(
                height: 600,
                width: 230,
                child: pw.Text(
                  secondPart,
                  style: pw.TextStyle(
                    font: fontBody,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          pw.Spacer(),
          pw.Text(
            article['source'].toString().replaceAll(';', '\n'),
            maxLines: 3,
          ),
        ],
        footer: (context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 10),
            child: pw.Text(
              '${context.pageNumber - 1}',
              style: pw.TextStyle(
                font: fontBody,
                fontSize: 10,
              ),
            ),
          );
        },
      ),
    );
  }

  // Return the PDF as bytes
  return pdf.save();
}

// Extract the first page of the PDF as an image
Future<String?> extractFirstPageImage(Uint8List pdfBytes) async {
  try {
    // Method 1: Use the printing package to render the first page
    // This works on most platforms including web
    final doc = await Printing.raster(
      pdfBytes,
      pages: [0], // Extract only the first page (index 0)
      dpi: 150, // Lower DPI to save memory
    ).first;

    // Convert to PNG
    final img = await doc.toPng();

    // Return as base64
    return base64Encode(img);
  } catch (e) {
    if (kDebugMode) {
      print('Error extracting first page with printing package: $e');
    }

    // Fallback method for mobile/desktop
    try {
      if (!kIsWeb) {
        // Save PDF to a temporary file
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/temp_extract.pdf');
        await tempFile.writeAsBytes(pdfBytes);

        // Use the printing package with the file path
        final doc = await Printing.raster(
          pdfBytes,
          pages: [0],
          dpi: 120,
        ).first;

        // Convert to PNG
        final img = await doc.toPng();

        // Clean up
        await tempFile.delete();

        // Return as base64
        return base64Encode(img);
      }
    } catch (fallbackError) {
      if (kDebugMode) {
        print('Fallback extraction also failed: $fallbackError');
      }
    }

    return null;
  }
}

// Execute the full magazine creation process
Future<void> createMagazine(
    WidgetRef ref, String language, String theme, int coins) async {
  try {
    // Get the raw magazine data
    final magazineData = await rawMagazineDataFlow(ref, language, theme, coins);

    // Safely update progress provider
    Future<void> updateProgress(double value) async {
      ref.read(creationProgressProvider.notifier).state = value;
    }

    // Update progress
    await updateProgress(0.90);

    // Generate the PDF
    final pdfBytes = await createMagazinePDF(magazineData);

    // Extract the first page as an image
    final firstPageImage = await extractFirstPageImage(pdfBytes);

    // Update the magazine data with the first page image
    if (firstPageImage != null) {
      magazineData['first_page_image'] = firstPageImage;
    }

    // Now update all providers at once in a safe way
    // This is an async function so we're not in a build phase
    ref.read(firstPageImageProvider.notifier).state = firstPageImage;
    ref.read(processDataProvider.notifier).state = magazineData;
    ref.read(pdfBytesProvider.notifier).state = pdfBytes;

    // Set progress to complete
    await updateProgress(1.0);
  } catch (e) {
    if (kDebugMode) {
      print('Error creating magazine PDF: $e');
    }
    rethrow;
  }
}

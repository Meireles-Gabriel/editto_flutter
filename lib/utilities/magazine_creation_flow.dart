import 'dart:convert';
import 'dart:math';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'raw_magazine_data_flow.dart';

// Provider for the generated PDF bytes
// Provedor para os bytes do PDF gerado
final pdfBytesProvider = StateProvider<Uint8List?>((ref) => null);

// Provider for the first page image bytes
// Provedor para os bytes da imagem da primeira página
final firstPageImageProvider = StateProvider<String?>((ref) => null);

// Random position for summary elements on cover
// Posição aleatória para os elementos de resumo na capa
final summaryPosition = Random().nextInt(3);

// No need for Flutter clipper, we'll use a simpler approach with PDF
// Não precisamos de clipper do Flutter, usaremos uma abordagem mais simples com PDF

// Create the magazine PDF
// Cria o PDF da revista
Future<Uint8List> createMagazinePDF(Map<String, dynamic> magazineData) async {
  // Validate required data
  // Validar dados necessários
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
  // Criar um novo documento PDF
  final pdf = pw.Document();

  // Load the icon image from assets
  // Carregar a imagem do ícone dos assets
  final iconBytes = await rootBundle.load('assets/logo_outline_white.png');
  final iconImage = pw.MemoryImage(iconBytes.buffer.asUint8List());

  // Decode the cover image from base64
  // Decodificar a imagem de capa a partir de base64
  final coverImageBytes = base64Decode(magazineData['cover_image']);
  final coverImage = pw.MemoryImage(coverImageBytes);

  // Get cover content
  // Obter conteúdo da capa
  final coverContent = magazineData['cover_content'];
  final mainHeadline = coverContent['main_headline'].toString().toUpperCase();
  final subheading = coverContent['subheading'];
  final summary1 = coverContent['summary1'];
  final summary2 = coverContent['summary2'];

  // Load fonts for the magazine
  // Carregar fontes para a revista
  final fontMagazineName = await PdfGoogleFonts.montserratRegular();
  final fontCoverTitle = await PdfGoogleFonts.montserratBold();
  final fontCoverSummary = await PdfGoogleFonts.montserratMedium();
  final fontArticleTitle = await PdfGoogleFonts.montserratMedium();
  final fontBody = await PdfGoogleFonts.montserratRegular();

  // Create cover page
  // Criar página de capa
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
            // Imagem de capa como fundo (página inteira)
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
            // Sobreposição de conteúdo
            pw.Padding(
              padding: const pw.EdgeInsets.all(40),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  // Top section with icon and title
                  // Seção superior com ícone e título
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Image(iconImage, width: 50, height: 50),
                      pw.SizedBox(width: 10),
                      pw.Stack(
                        children: [
                          pw.Positioned(
                            left: 2,
                            top: 2,
                            child: pw.Text(
                              'ÉDITTO',
                              style: pw.TextStyle(
                                font: fontMagazineName,
                                fontSize: 40,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.black,
                              ),
                            ),
                          ),
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
                    ],
                  ),
                  // Layout 1: Summaries side by side
                  // Layout 1: Resumos lado a lado
                  if (summaryPosition == 0)
                    pw.Column(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Container(
                              width: 100,
                              child: pw.Stack(
                                children: [
                                  pw.Positioned(
                                    left: 1,
                                    top: 1,
                                    child: pw.Text(
                                      summary1,
                                      style: pw.TextStyle(
                                        font: fontCoverSummary,
                                        fontSize: 14,
                                        color: PdfColors.black,
                                      ),
                                    ),
                                  ),
                                  pw.Text(
                                    summary1,
                                    style: pw.TextStyle(
                                      font: fontCoverSummary,
                                      fontSize: 14,
                                      color: PdfColors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            pw.Container(
                              width: 100,
                              child: pw.Stack(
                                children: [
                                  pw.Positioned(
                                    left: 1,
                                    top: 1,
                                    child: pw.Text(
                                      summary2,
                                      textAlign: pw.TextAlign.right,
                                      style: pw.TextStyle(
                                        font: fontCoverSummary,
                                        fontSize: 14,
                                        color: PdfColors.black,
                                      ),
                                    ),
                                  ),
                                  pw.Text(
                                    summary2,
                                    textAlign: pw.TextAlign.right,
                                    style: pw.TextStyle(
                                      font: fontCoverSummary,
                                      fontSize: 14,
                                      color: PdfColors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  // Layout 2: Summary2 at top-right, summary1 at bottom-left
                  // Layout 2: Resumo2 no canto superior direito, resumo1 no canto inferior esquerdo
                  if (summaryPosition == 1)
                    pw.Column(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.end,
                          children: [
                            pw.Container(
                              width: 100,
                              child: pw.Stack(
                                children: [
                                  pw.Positioned(
                                    left: 1,
                                    top: 1,
                                    child: pw.Text(
                                      summary2,
                                      textAlign: pw.TextAlign.right,
                                      style: pw.TextStyle(
                                        font: fontCoverSummary,
                                        fontSize: 14,
                                        color: PdfColors.black,
                                      ),
                                    ),
                                  ),
                                  pw.Text(
                                    summary2,
                                    textAlign: pw.TextAlign.right,
                                    style: pw.TextStyle(
                                      font: fontCoverSummary,
                                      fontSize: 14,
                                      color: PdfColors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.start,
                          children: [
                            pw.Container(
                              width: 100,
                              child: pw.Stack(
                                children: [
                                  pw.Positioned(
                                    left: 1,
                                    top: 1,
                                    child: pw.Text(
                                      summary1,
                                      style: pw.TextStyle(
                                        font: fontCoverSummary,
                                        fontSize: 14,
                                        color: PdfColors.black,
                                      ),
                                    ),
                                  ),
                                  pw.Text(
                                    summary1,
                                    style: pw.TextStyle(
                                      font: fontCoverSummary,
                                      fontSize: 14,
                                      color: PdfColors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  // Layout 3: Summary1 at top-left, summary2 at bottom-right
                  // Layout 3: Resumo1 no canto superior esquerdo, resumo2 no canto inferior direito
                  if (summaryPosition == 2)
                    pw.Column(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.start,
                          children: [
                            pw.Container(
                              width: 100,
                              child: pw.Stack(
                                children: [
                                  pw.Positioned(
                                    left: 1,
                                    top: 1,
                                    child: pw.Text(
                                      summary1,
                                      style: pw.TextStyle(
                                        font: fontCoverSummary,
                                        fontSize: 14,
                                        color: PdfColors.black,
                                      ),
                                    ),
                                  ),
                                  pw.Text(
                                    summary1,
                                    style: pw.TextStyle(
                                      font: fontCoverSummary,
                                      fontSize: 14,
                                      color: PdfColors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.end,
                          children: [
                            pw.Container(
                              width: 100,
                              child: pw.Stack(
                                children: [
                                  pw.Positioned(
                                    left: 1,
                                    top: 1,
                                    child: pw.Text(
                                      summary2,
                                      textAlign: pw.TextAlign.right,
                                      style: pw.TextStyle(
                                        font: fontCoverSummary,
                                        fontSize: 14,
                                        color: PdfColors.black,
                                      ),
                                    ),
                                  ),
                                  pw.Text(
                                    summary2,
                                    textAlign: pw.TextAlign.right,
                                    style: pw.TextStyle(
                                      font: fontCoverSummary,
                                      fontSize: 14,
                                      color: PdfColors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  // Bottom section with main headline and subheading
                  // Seção inferior com manchete principal e subtítulo
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Stack(
                        children: [
                          pw.Positioned(
                            left: 2,
                            top: 2,
                            child: pw.Text(
                              mainHeadline,
                              textAlign: pw.TextAlign.center,
                              style: pw.TextStyle(
                                font: fontCoverTitle,
                                fontSize: mainHeadline.length <= 10 ? 68 : 54,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.black,
                              ),
                            ),
                          ),
                          pw.Text(
                            mainHeadline,
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(
                              font: fontCoverTitle,
                              fontSize: mainHeadline.length <= 10 ? 68 : 54,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white,
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(
                        width: 300,
                        child: pw.Divider(
                          color: PdfColors.white,
                        ),
                      ),
                      pw.Stack(
                        children: [
                          pw.Positioned(
                            left: 1,
                            top: 1,
                            child: pw.Text(
                              subheading,
                              textAlign: pw.TextAlign.center,
                              style: pw.TextStyle(
                                font: fontCoverSummary,
                                fontSize: 18,
                                color: PdfColors.black,
                              ),
                            ),
                          ),
                          pw.Text(
                            subheading,
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(
                              font: fontCoverSummary,
                              fontSize: 18,
                              color: PdfColors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Side summaries
                  // Resumos laterais
                ],
              ),
            ),
          ],
        );
      },
    ),
  );

  // Add article pages
  // Adicionar páginas de artigos
  final articles = magazineData['articles'];
  for (var article in articles) {
    // Split content into paragraphs and divide into two columns
    // Dividir conteúdo em parágrafos e em duas colunas
    String content = article['content'];
    List<String> paragraphs = content.split('\n');
    paragraphs.removeWhere((paragraph) => paragraph.trim().isEmpty);
    int firstPartN = (paragraphs.length / 2).ceil();
    String firstPart = paragraphs.sublist(0, firstPartN).join('\n\n');
    String secondPart = paragraphs.sublist(firstPartN).join('\n\n');

    // Create the article page with two-column layout
    // Criar a página do artigo com layout de duas colunas
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
          // Display article sources at the bottom
          // Exibir fontes do artigo na parte inferior
          pw.Text(
            article['source'].toString().replaceAll(';', '\n'),
            maxLines: 3,
          ),
        ],
        // Add page number in footer
        // Adicionar número da página no rodapé
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
  // Retornar o PDF como bytes
  final pdfBytes = await pdf.save();
  // Create a new Uint8List to ensure we have a fresh copy of the data
  // Criar uma cópia nova do Uint8List para garantir que temos dados atualizados
  return Uint8List.fromList(pdfBytes);
}

// Extract the first page of the PDF as an image
// Extrair a primeira página do PDF como uma imagem
Future<String?> extractFirstPageImage(Uint8List pdfBytes) async {
  try {
    // Create a fresh copy to avoid using a potentially detached ArrayBuffer
    // Criar uma cópia para evitar usar um ArrayBuffer potencialmente desanexado
    final pdfBytesCopy = Uint8List.fromList(pdfBytes);

    // Method 1: Use the printing package to render the first page
    // This works on most platforms including web
    // Método 1: Usar o pacote printing para renderizar a primeira página
    // Funciona na maioria das plataformas, incluindo web
    final doc = await Printing.raster(
      pdfBytesCopy,
      pages: [0], // Extract only the first page (index 0)
      // Extrair apenas a primeira página (índice 0)
      dpi: 150, // Lower DPI to save memory
      // DPI mais baixo para economizar memória
    ).first;

    // Convert to PNG
    // Converter para PNG
    final img = await doc.toPng();

    // Return as base64
    // Retornar como base64
    return base64Encode(img);
  } catch (e) {
    if (kDebugMode) {
      print('Error extracting first page with printing package: $e');
    }

    // Fallback method for mobile/desktop
    // Método alternativo para dispositivos móveis/desktop
    try {
      if (!kIsWeb) {
        // Create another fresh copy for the fallback method
        // Criar outra cópia para o método alternativo
        final fallbackPdfBytesCopy = Uint8List.fromList(pdfBytes);

        // Save PDF to a temporary file
        // Salvar PDF em um arquivo temporário
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/temp_extract.pdf');
        await tempFile.writeAsBytes(fallbackPdfBytesCopy);

        // Use the printing package with the file path
        // Usar o pacote printing com o caminho do arquivo
        final doc = await Printing.raster(
          fallbackPdfBytesCopy,
          pages: [0],
          dpi: 120,
        ).first;

        // Convert to PNG
        // Converter para PNG
        final img = await doc.toPng();

        // Clean up
        // Limpar
        await tempFile.delete();

        // Return as base64
        // Retornar como base64
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
// Executar o processo completo de criação da revista
Future<void> createMagazine(
    WidgetRef ref, String language, String theme, int coins) async {
  try {
    // Get the raw magazine data
    // Obter os dados brutos da revista
    final magazineData = await rawMagazineDataFlow(ref, language, theme, coins);

    if (kDebugMode) {
      print('Magazine data received, generating PDF...');
    }

    // Generate the PDF
    // Gerar o PDF
    final pdfBytes = await createMagazinePDF(magazineData);

    if (kDebugMode) {
      print('PDF generated successfully, size: ${pdfBytes.length} bytes');
    }

    // Create a copy for extraction to prevent detachment issues
    // Criar uma cópia para extração para evitar problemas de desanexação
    final pdfBytesForExtraction = Uint8List.fromList(pdfBytes);

    // Extract the first page as an image
    // Extrair a primeira página como uma imagem
    final firstPageImage = await extractFirstPageImage(pdfBytesForExtraction);

    // Update the magazine data with the first page image
    // Atualizar os dados da revista com a imagem da primeira página
    if (firstPageImage != null) {
      magazineData['first_page_image'] = firstPageImage;
    }

    // Now update all providers at once in a safe way and wait for completion
    // Agora atualizar todos os provedores de uma vez de forma segura e aguardar a conclusão
    await _safeUpdateProviders(ref, () {
      // Create a fresh copy for the provider to avoid detachment
      final pdfBytesForProvider = Uint8List.fromList(pdfBytes);
      ref.read(pdfBytesProvider.notifier).state = pdfBytesForProvider;
      ref.read(firstPageImageProvider.notifier).state = firstPageImage;
      ref.read(processDataProvider.notifier).state = magazineData;

      if (kDebugMode) {
        print('Provider states updated with PDF and magazine data');
      }
    });
  } catch (e) {
    if (kDebugMode) {
      print('Error creating magazine PDF: $e');
    }
    rethrow;
  }
}

// Helper function to safely update providers and wait for completion
// Função auxiliar para atualizar provedores com segurança e aguardar a conclusão
Future<void> _safeUpdateProviders(WidgetRef ref, Function() updateFn) async {
  final completer = Completer<void>();

  Future.microtask(() {
    try {
      updateFn();
      completer.complete();
    } catch (e) {
      if (kDebugMode) {
        print('Error updating providers: $e');
      }
      completer.completeError(e);
    }
  });

  return completer.future;
}

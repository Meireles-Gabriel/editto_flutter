import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'dart:async';

// Base URL for API calls
// URL base para chamadas de API
const bool useLocalServer = true; // Set to false for production
const String localApiBaseUrl = 'http://192.168.1.2:8080';
const String productionApiBaseUrl =
    'https://editto-backend-572616648599.us-central1.run.app';
const String apiBaseUrl =
    useLocalServer ? localApiBaseUrl : productionApiBaseUrl;

// Create a persistent HTTP client with custom configuration
// Cria um cliente HTTP persistente com configuração personalizada
final httpClient = http.Client();

// Provider for tracking magazine creation progress
// Provedor para acompanhar o progresso da criação da revista
final creationProgressProvider = StateProvider<double>((ref) => 0.0);

// Provider for storing process data between API calls
// Provedor para armazenar dados do processo entre chamadas de API
final processDataProvider = StateProvider<Map<String, dynamic>?>((ref) => null);

// Provider for storing the final magazine data
// Provedor para armazenar os dados finais da revista
final magazineRawDataProvider =
    StateProvider<Map<String, dynamic>?>((ref) => null);

// Initialize the magazine creation process
// Inicializa o processo de criação da revista
Future<Map<String, dynamic>> initMagazineProcess(
    String language, String theme, int coins) async {
  // Call init_magazine_process using the language, theme and coins
  // Chama init_magazine_process usando o idioma, tema e moedas
  final response = await http.get(Uri.parse(
      '$apiBaseUrl/init-magazine-process-endpoint/$language/$theme/$coins'));

  if (response.statusCode == 200) {
    final responseData = jsonDecode(response.body);
    return responseData;
  } else {
    throw Exception('Failed to initialize magazine process: ${response.body}');
  }
}

// Fetch news articles based on the topic
// Busca artigos de notícias com base no tópico
Future<Map<String, dynamic>> fetchArticles(
    Map<String, dynamic> processData) async {
  // Call fetch_articles with the processData from initMagazineProcess
  // Chama fetch_articles com os dados do processo de initMagazineProcess
  final response = await http.post(
      Uri.parse('$apiBaseUrl/fetch-articles-endpoint'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'process_data': processData}));

  if (response.statusCode == 200) {
    final responseData = jsonDecode(response.body);
    return responseData;
  } else {
    throw Exception('Failed to fetch articles: ${response.body}');
  }
}

// Rewrite articles into magazine style
// Reescreve artigos no estilo de revista
Future<Map<String, dynamic>> rewriteArticles(
    Map<String, dynamic> processData) async {
  // Call rewrite_articles with the processData from fetchArticles
  // Chama rewrite_articles com os dados do processo de fetchArticles
  final response = await http.post(
      Uri.parse('$apiBaseUrl/rewrite-articles-endpoint'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'process_data': processData}));

  if (response.statusCode == 200) {
    final responseData = jsonDecode(response.body);
    return responseData;
  } else {
    throw Exception('Failed to rewrite articles: ${response.body}');
  }
}

// Generate cover text content (title, subtitle, highlights)
// Gera conteúdo de texto da capa (título, subtítulo, destaques)
Future<Map<String, dynamic>> generateCoverText(
    Map<String, dynamic> processData) async {
  // Call generate-cover-text with the processData from rewriteArticles
  // Chama generate-cover-text com os dados do processo de rewriteArticles
  final response = await http.post(
      Uri.parse('$apiBaseUrl/generate-cover-text-endpoint'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'process_data': processData}));

  if (response.statusCode == 200) {
    final responseData = jsonDecode(response.body);
    return responseData;
  } else {
    throw Exception('Failed to generate cover text: ${response.body}');
  }
}

// Generate cover image
// Gera imagem da capa
Future<Map<String, dynamic>> generateImage(
    Map<String, dynamic> processData) async {
  try {
    // Call generate_image with the processData from generateCoverText
    // Chama generate_image com os dados do processo de generateCoverText
    final response = await httpClient
        .post(
          Uri.parse('$apiBaseUrl/generate-image-endpoint'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Connection': 'keep-alive',
          },
          body: jsonEncode({'process_data': processData}),
        )
        .timeout(
            const Duration(seconds: 120)); // Increased timeout to 120 seconds

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      return responseData;
    } else {
      throw Exception('Failed to generate image: ${response.body}');
    }
  } on http.ClientException catch (e) {
    throw Exception('Connection error while generating image: $e');
  } on TimeoutException catch (e) {
    throw Exception('Request timed out while generating image: $e');
  } catch (e) {
    throw Exception('Unexpected error while generating image: $e');
  }
}

// Finalize the magazine creation and get the raw data
// Finaliza a criação da revista e obtém os dados brutos
Future<Map<String, dynamic>> finalizeMagazineRawData(
    Map<String, dynamic> processData) async {
  // Call finalize-magazine-raw-data with the processData from generateImage
  // Chama finalize-magazine-raw-data com os dados do processo de generateImage
  final response = await http.post(
      Uri.parse('$apiBaseUrl/finalize-magazine-raw-data-endpoint'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'process_data': processData}));

  if (response.statusCode == 200) {
    final responseData = jsonDecode(response.body);
    return responseData;
  } else {
    throw Exception('Failed to finalize magazine: ${response.body}');
  }
}

// Execute the full magazine creation process from start to finish
// Executa o processo completo de criação da revista do início ao fim
Future<Map<String, dynamic>> rawMagazineDataFlow(
    WidgetRef ref, String language, String theme, int coins) async {
  // Track the current step being processed
  // Acompanha o passo atual sendo processado
  int currentStep = 0;

  // Maximum retry attempts for each step
  // Número máximo de tentativas para cada passo
  const int maxRetries = 3;

  // Track retry counts for each step
  // Acompanha o número de tentativas para cada passo
  Map<int, int> retryCount = {
    0: 0, // init
    1: 0, // fetch articles
    2: 0, // rewrite articles
    3: 0, // cover text
    4: 0, // cover image
    5: 0, // finalize
  };

  try {
    // Set progress to 0%
    // Define progresso para 0%
    ref.read(creationProgressProvider.notifier).state = 0.0;

    while (currentStep <= 5) {
      try {
        if (currentStep == 0) {
          // Step 1: Initialize magazine process
          // Passo 1: Inicializa o processo da revista
          if (kDebugMode) {
            print("Starting step 1: Initialize magazine process");
          }
          final initData = await initMagazineProcess(language, theme, coins);
          ref.read(processDataProvider.notifier).state =
              initData['process_data'];
          ref.read(creationProgressProvider.notifier).state = 0.15;
          currentStep++;
        } else if (currentStep == 1) {
          // Step 2: Fetch news articles
          // Passo 2: Busca artigos de notícias
          if (kDebugMode) {
            print("Starting step 2: Fetch news articles");
          }
          final articlesData =
              await fetchArticles(ref.read(processDataProvider)!);
          ref.read(processDataProvider.notifier).state =
              articlesData['process_data'];
          ref.read(creationProgressProvider.notifier).state = 0.30;
          currentStep++;
        } else if (currentStep == 2) {
          // Step 3: Rewrite articles for magazine style
          // Passo 3: Reescreve artigos no estilo de revista
          if (kDebugMode) {
            print("Starting step 3: Rewrite articles");
          }
          final rewrittenData =
              await rewriteArticles(ref.read(processDataProvider)!);
          ref.read(processDataProvider.notifier).state =
              rewrittenData['process_data'];
          ref.read(creationProgressProvider.notifier).state = 0.45;
          currentStep++;
        } else if (currentStep == 3) {
          // Step 4: Generate cover text
          // Passo 4: Gera texto da capa
          if (kDebugMode) {
            print("Starting step 4: Generate cover text");
          }
          final coverTextData =
              await generateCoverText(ref.read(processDataProvider)!);
          ref.read(processDataProvider.notifier).state =
              coverTextData['process_data'];
          ref.read(creationProgressProvider.notifier).state = 0.60;
          currentStep++;
        } else if (currentStep == 4) {
          // Step 5: Generate cover image
          // Passo 5: Gera imagem da capa
          if (kDebugMode) {
            print("Starting step 5: Generate cover image");
          }
          final imageData = await generateImage(ref.read(processDataProvider)!);
          ref.read(processDataProvider.notifier).state =
              imageData['process_data'];
          ref.read(creationProgressProvider.notifier).state = 0.75;
          currentStep++;
        } else if (currentStep == 5) {
          // Step 6: Finalize magazine and get raw data
          // Passo 6: Finaliza a revista e obtém dados brutos
          if (kDebugMode) {
            print("Starting step 6: Finalize magazine");
          }
          final finalData =
              await finalizeMagazineRawData(ref.read(processDataProvider)!);

          // Store the final magazine data
          // Armazena os dados finais da revista
          ref.read(creationProgressProvider.notifier).state = 0.90;

          return finalData['magazine_data'];
        }

        // Reset retry count for successful step
        // Redefine o contador de tentativas para o passo bem-sucedido
        retryCount[currentStep - 1] = 0;
      } catch (e) {
        // Handle error with retry logic
        // Trata erro com lógica de nova tentativa
        if (kDebugMode) {
          print("Error at step $currentStep: $e");
        }

        // Increment retry count for current step
        // Incrementa o contador de tentativas para o passo atual
        retryCount[currentStep] = (retryCount[currentStep] ?? 0) + 1;

        // Check if we've exceeded max retries for this step
        // Verifica se excedemos o número máximo de tentativas para este passo
        if (retryCount[currentStep]! >= maxRetries) {
          if (kDebugMode) {
            print(
                "Max retries ($maxRetries) exceeded for step $currentStep, propagating error");
          }
          rethrow; // Give up after max retries
        }

        // Go back one step to get new input (if possible)
        // Volta um passo para obter nova entrada (se possível)
        if (currentStep > 0) {
          if (kDebugMode) {
            print(
                "Retrying step ${currentStep - 1} to get new input for step $currentStep (attempt ${retryCount[currentStep]})");
          }
          currentStep--;

          // Adjust progress indicator to show we're redoing a step
          // Ajusta o indicador de progresso para mostrar que estamos refazendo um passo
          ref.read(creationProgressProvider.notifier).state =
              [0.0, 0.15, 0.30, 0.50, 0.65, 0.85][currentStep];
        } else {
          // Can't go back from step 0
          // Não é possível voltar do passo 0
          if (kDebugMode) {
            print("Error in initial step, cannot retry with different input");
          }
          rethrow;
        }
      }
    }

    // Should never reach here as we return inside the loop
    // Nunca deve chegar aqui, pois retornamos dentro do loop
    throw Exception("Unexpected end of magazine creation process");
  } catch (e) {
    // Error handling for the whole process
    // Tratamento de erro para todo o processo
    if (kDebugMode) {
      print('Error creating magazine: $e');
    }
    // Clean up the HTTP client
    httpClient.close();
    rethrow;
  }
}

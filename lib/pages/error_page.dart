// Required imports for error page functionality
// Importações necessárias para funcionalidade da página de erro
import 'package:editto_flutter/pages/newsstand_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:editto_flutter/utilities/language_notifier.dart';
import 'package:lottie/lottie.dart';

// Error page widget that displays error information and retry option
// Widget da página de erro que exibe informações de erro e opção de tentar novamente
class ErrorPage extends ConsumerWidget {
  final String errorMessage;
  final VoidCallback? onRetry;

  const ErrorPage({
    super.key,
    required this.errorMessage,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get localized texts
    // Obter textos localizados
    final texts = ref.watch(languageNotifierProvider)['texts'];

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(texts['error']?[0] ?? 'Error'),
        // Removed the back button as requested
        // Removido o botão de voltar conforme solicitado
      ),
      // Use the app's surface color for background
      // Usar a cor de superfície do aplicativo para o fundo
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Title - using app's primary color
              // Título - usando a cor primária do aplicativo
              Text(
                texts['error']?[1] ?? 'Something went wrong',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Error animation
              // Animação de erro
              SizedBox(
                height: 150,
                width: 150,
                child: Lottie.asset(
                  'assets/lottie/error.json',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 48),

              // Error message - using standard text style
              // Mensagem de erro - usando estilo de texto padrão
              Text(
                texts['error']?[2] ??
                    'Something unexpected happened. Please, try again.',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Action buttons - retry and go back to newsstand
              // Botões de ação - tentar novamente e voltar para a banca
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Go back button - always visible
                  // Botão de voltar - sempre visível
                  // Show retry button if callback provided
                  // Mostrar botão de tentar novamente se callback fornecido
                  if (onRetry != null) ...[
                    const SizedBox(width: 24),
                    TextButton(
                      onPressed: onRetry,
                      child: Text(texts['error']?[4] ?? 'Try Again'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const NewsstandPage(),
                        ),
                      ),
                      child: Text(texts['error']?[3] ?? 'Go Back'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

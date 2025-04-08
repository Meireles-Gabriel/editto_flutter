import 'package:editto_flutter/pages/newsstand_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:editto_flutter/utilities/language_notifier.dart';

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
    final texts = ref.watch(languageNotifierProvider)['texts'];

    return Scaffold(
      appBar: AppBar(
        title: Text(texts['error']?[0] ?? 'Error'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 80,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 24),
              Text(
                texts['error']?[1] ?? 'Something went wrong',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                errorMessage,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              if (onRetry != null)
                ElevatedButton(
                  onPressed: onRetry,
                  child: Text(texts['error']?[2] ?? 'Try Again'),
                ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const NewsstandPage(),
                  ),
                ),
                child: Text(texts['error']?[3] ?? 'Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

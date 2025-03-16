// Required imports for rack functionality
// Importações necessárias para funcionalidade da estante
import 'package:editto_flutter/utilities/language_notifier.dart';
import 'package:editto_flutter/widgets/default_bottom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:editto_flutter/utilities/helper_class.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Rack page widget with state management
// Widget da página da estante com gerenciamento de estado
class RackPage extends ConsumerStatefulWidget {
  const RackPage({super.key});

  @override
  ConsumerState<RackPage> createState() => _RackPageState();
}

class _RackPageState extends ConsumerState<RackPage> {
  // Build main content with grid of magazines
  // Constrói conteúdo principal com grade de revistas
  Widget buildContent(BuildContext context) {
    final texts = ref.watch(languageNotifierProvider)['texts'];
    return CustomScrollView(
      slivers: [
        // Floating app bar with search
        // Barra de app flutuante com busca
        SliverAppBar(
          floating: true,
          title: Text(texts['rack'][0]),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                // TODO: Implement search functionality
                // TODO: Implementar funcionalidade de busca
              },
            ),
          ],
        ),
        // Grid of magazine cards
        // Grade de cards de revistas
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 200.0,
              mainAxisSpacing: 16.0,
              crossAxisSpacing: 16.0,
              childAspectRatio: 0.75,
            ),
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                // Magazine card with cover and details
                // Card de revista com capa e detalhes
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Magazine cover placeholder
                      // Placeholder para capa da revista
                      Expanded(
                        child: Container(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.1),
                          child: Center(
                            child: Icon(
                              Icons.book,
                              size: 48,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                      // Magazine details section
                      // Seção de detalhes da revista
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Magazine Title ${index + 1}',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Issue #${index + 1}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
              childCount: 20, // Example count
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for responsive layout
    // Obtém dimensões da tela para layout responsivo
    final size = MediaQuery.of(context).size;
    final paddingWidth = size.width * 0.0;

    // Build scaffold with responsive layout
    // Constrói scaffold com layout responsivo
    return Scaffold(
      bottomNavigationBar: const DefaultBottomAppBar(),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: HelperClass(
          mobile: buildContent(context),
          tablet: Center(
            child: SizedBox(
              width: 720,
              child: buildContent(context),
            ),
          ),
          desktop: Center(
            child: SizedBox(
              width: 1200,
              child: buildContent(context),
            ),
          ),
          paddingWidth: paddingWidth,
          bgColor: Theme.of(context).colorScheme.surface,
        ),
      ),
    );
  }
}

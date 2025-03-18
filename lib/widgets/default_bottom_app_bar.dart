// Required imports for bottom app bar functionality
// Importações necessárias para funcionalidade da barra inferior
import 'package:editto_flutter/pages/newsstand_page.dart';
import 'package:editto_flutter/pages/rack_page.dart';
import 'package:editto_flutter/utilities/language_notifier.dart';
import 'package:editto_flutter/widgets/default_bottom_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Global state provider for current page index
// Provedor de estado global para índice da página atual
final currentPageProvider = StateProvider<int>((ref) => 0);

// Bottom app bar widget with navigation
// Widget de barra inferior com navegação
class DefaultBottomAppBar extends ConsumerWidget {
  const DefaultBottomAppBar({super.key});

  // Handle navigation between pages with animation
  // Manipula navegação entre páginas com animação
  void _navigateToPage(BuildContext context, int index, int currentIndex) {
    if (index == currentIndex) return;

    final page = index == 0 ? const NewsstandPage() : const RackPage();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        // Custom slide transition animation
        // Animação personalizada de transição deslizante
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          var offsetAnimation = animation.drive(tween);

          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get localized texts and current page index
    // Obtém textos localizados e índice da página atual
    final texts = ref.watch(languageNotifierProvider)['texts'];
    final currentIndex = ref.watch(currentPageProvider);

    // Build bottom bar with shadow and buttons
    // Constrói barra inferior com sombra e botões
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Newsstand navigation button
              // Botão de navegação para banca
              DefaultBottomButton(
                text: texts['newsstand']
                    [0], // "Newsstand" / "Banca de Revistas"
                icon: currentIndex == 0 ? Icons.store : Icons.store_outlined,
                isSelected: currentIndex == 0,
                action: () {
                  ref.read(currentPageProvider.notifier).state = 0;
                  _navigateToPage(context, 0, currentIndex);
                },
              ),
              const SizedBox(width: 16),
              // Rack navigation button
              // Botão de navegação para estante
              DefaultBottomButton(
                text: texts['rack'][0], // "My Rack" / "Minha Estante"
                icon: currentIndex == 1
                    ? Icons.collections_bookmark
                    : Icons.collections_bookmark_outlined,
                isSelected: currentIndex == 1,
                action: () {
                  ref.read(currentPageProvider.notifier).state = 1;
                  _navigateToPage(context, 1, currentIndex);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

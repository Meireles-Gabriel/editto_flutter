// Required imports for button widget
// Importações necessárias para widget de botão
import 'package:flutter/material.dart';

// Custom bottom button widget with selection state
// Widget de botão inferior personalizado com estado de seleção
class DefaultBottomButton extends StatelessWidget {
  // Button properties
  // Propriedades do botão
  final String text;
  final IconData? icon;
  final VoidCallback action;
  final bool isSelected;

  const DefaultBottomButton({
    super.key,
    required this.text,
    required this.icon,
    required this.action,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    // Expanded widget to fill available space
    // Widget expandido para preencher espaço disponível
    return Expanded(
      child: Material(
        color: Colors.transparent,
        // Rounded corners for the button
        // Cantos arredondados para o botão
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          // Interactive button with ink effect
          // Botão interativo com efeito de tinta
          child: InkWell(
            onTap: action,
            customBorder: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            // Animated container for selection state
            // Container animado para estado de seleção
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              // Button content layout
              // Layout do conteúdo do botão
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated icon with scale effect
                  // Ícone animado com efeito de escala
                  AnimatedScale(
                    duration: const Duration(milliseconds: 200),
                    scale: isSelected ? 1.1 : 1.0,
                    child: Icon(
                      icon,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Button text with dynamic styling
                  // Texto do botão com estilo dinâmico
                  Text(
                    text,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.7),
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

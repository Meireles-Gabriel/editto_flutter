// Required imports for responsive layout
// Importações necessárias para layout responsivo
import 'package:flutter/material.dart';

// Helper class for responsive layout management
// Classe auxiliar para gerenciamento de layout responsivo
class HelperClass extends StatelessWidget {
  // Widget properties for different screen sizes
  // Propriedades de widget para diferentes tamanhos de tela
  final Widget mobile;
  final Widget tablet;
  final Widget desktop;
  final double paddingWidth;
  final Color bgColor;
  const HelperClass({
    super.key,
    required this.mobile,
    required this.tablet,
    required this.desktop,
    required this.paddingWidth,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    // Layout builder for responsive design
    // Construtor de layout para design responsivo
    return LayoutBuilder(
      builder: (context, constraints) {
        // Mobile layout (< 768px)
        // Layout móvel (< 768px)
        if (constraints.maxWidth < 768) {
          return Container(
            // height: size.height,
            width: size.width,
            alignment: Alignment.center,
            color: bgColor,
            padding: EdgeInsets.fromLTRB(10, 0, 10, size.height * 0.03),
            child: mobile,
          );
        }
        // Tablet layout (768px - 1200px)
        // Layout tablet (768px - 1200px)
        else if (constraints.maxWidth < 1200) {
          return Container(
            // height: size.height,
            width: size.width,
            alignment: Alignment.center,
            color: bgColor,
            padding: EdgeInsets.fromLTRB(10, 0, 10, size.height * 0.03),
            child: tablet,
          );
        }
        // Desktop layout (>= 1200px)
        // Layout desktop (>= 1200px)
        else {
          return Container(
            // height: size.height,
            width: size.width,
            alignment: Alignment.center,
            color: bgColor,
            padding:
                EdgeInsets.fromLTRB(paddingWidth * 2, 0, paddingWidth * 2, 0),
            child: desktop,
          );
        }
      },
    );
  }
}

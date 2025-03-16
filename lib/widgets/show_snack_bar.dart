// Required imports for snackbar functionality
// Importações necessárias para funcionalidade do snackbar
import 'package:flutter/material.dart';

// Helper function to show a themed snackbar with custom text
// Função auxiliar para mostrar um snackbar temático com texto personalizado
showSnackBar(BuildContext context, String text) {
  return ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: Theme.of(context).colorScheme.secondary,
      content: Text(text),
    ),
  );
}

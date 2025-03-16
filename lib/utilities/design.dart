// Required imports for design system
// Importações necessárias para o sistema de design
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Light theme color palette
// Paleta de cores do tema claro
Color unkWhite = const Color.fromARGB(255, 241, 241, 248);
Color squidInk = const Color.fromARGB(255, 53, 59, 69);
Color queenBlue = const Color.fromARGB(255, 101, 117, 130);
Color unkBlack = const Color.fromARGB(255, 38, 38, 38);

// Dark theme color palette
// Paleta de cores do tema escuro
Color darkGunmetal = const Color.fromARGB(255, 31, 34, 41);
Color pastelBlue = const Color.fromARGB(255, 189, 200, 207);
Color airForceBlue = const Color.fromARGB(255, 122, 139, 155);
Color antiFlashWhite = const Color.fromARGB(255, 241, 241, 241);

// Light theme configuration with Montserrat font
// Configuração do tema claro com fonte Montserrat
ThemeData lightTheme = ThemeData.light().copyWith(
  colorScheme: const ColorScheme.light().copyWith(
    surface: unkWhite,
    onSurface: unkBlack,
    primary: squidInk,
    onPrimary: unkWhite,
    secondary: queenBlue,
    onSecondary: unkWhite,
  ),
  textTheme: GoogleFonts.montserratTextTheme(ThemeData.light().textTheme).apply(
    bodyColor: unkBlack,
    displayColor: unkBlack,
  ),
);

// Dark theme configuration with Montserrat font
// Configuração do tema escuro com fonte Montserrat
ThemeData darkTheme = ThemeData.dark().copyWith(
  colorScheme: const ColorScheme.dark().copyWith(
    surface: darkGunmetal,
    onSurface: antiFlashWhite,
    primary: pastelBlue,
    onPrimary: darkGunmetal,
    secondary: airForceBlue,
    onSecondary: antiFlashWhite,
  ),
  textTheme: GoogleFonts.montserratTextTheme(ThemeData.dark().textTheme).apply(
    bodyColor: antiFlashWhite,
    displayColor: antiFlashWhite,
  ),
);

// Status colors for different states
// Cores de status para diferentes estados
class MyColors {
  Color statusPastelBlue = const Color.fromARGB(255, 179, 235, 242);
  Color statusPastelYellow = const Color.fromARGB(255, 255, 238, 140);
  Color statusPastelOrange = const Color.fromARGB(255, 255, 192, 103);
  Color statusPastelRed = const Color.fromARGB(255, 255, 116, 108);
}

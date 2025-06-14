// File generated by FlutterFire CLI.
// Arquivo gerado pelo FlutterFire CLI.
// ignore_for_file: type=lint

// Required imports for Firebase configuration
// Importações necessárias para configuração do Firebase
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart' show BuildContext;
import 'package:editto_flutter/utilities/language_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Default [FirebaseOptions] for use with your Firebase apps.
/// Opções padrão do [FirebaseOptions] para uso com seus apps Firebase.
///
/// Example/Exemplo:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  // Get Firebase options for current platform
  // Obtém opções do Firebase para a plataforma atual
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // Get localized error message for unsupported platforms
  // Obtém mensagem de erro localizada para plataformas não suportadas
  static String getErrorMessage(
      BuildContext context, WidgetRef ref, int index) {
    final texts = ref.read(languageNotifierProvider)['texts'];
    return texts['firebase']?[index] ?? firebaseEN[index];
  }

  // Default English error messages if localization fails
  // Mensagens de erro em inglês padrão se a localização falhar
  static const List<String> firebaseEN = [
    'Firebase options not configured for iOS - you can reconfigure by running the FlutterFire CLI again.',
    'Firebase options not configured for macOS - you can reconfigure by running the FlutterFire CLI again.',
    'Firebase options not configured for Linux - you can reconfigure by running the FlutterFire CLI again.',
    'Firebase options not supported for this platform.',
  ];

  // Firebase configuration for web platform
  // Configuração do Firebase para plataforma web
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC2MpzK7L48lqKcMqBd3suCKRTswOxZtwU',
    appId: '1:21157069349:web:002441ae850fbf3bb175cc',
    messagingSenderId: '21157069349',
    projectId: 'edittomagazine',
    authDomain: 'edittomagazine.firebaseapp.com',
    storageBucket: 'edittomagazine.firebasestorage.app',
    measurementId: 'G-YKXSQ7PBEQ',
  );

  // Firebase configuration for Android platform
  // Configuração do Firebase para plataforma Android
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBYemv-R-6h1XZ5B8ixXxxsfNylEbr4Pak',
    appId: '1:21157069349:android:8d35ef867fc271a1b175cc',
    messagingSenderId: '21157069349',
    projectId: 'edittomagazine',
    storageBucket: 'edittomagazine.firebasestorage.app',
  );

  // Firebase configuration for Windows platform
  // Configuração do Firebase para plataforma Windows
  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyC2MpzK7L48lqKcMqBd3suCKRTswOxZtwU',
    appId: '1:21157069349:web:509ef9cb5dcb74fbb175cc',
    messagingSenderId: '21157069349',
    projectId: 'edittomagazine',
    authDomain: 'edittomagazine.firebaseapp.com',
    storageBucket: 'edittomagazine.firebasestorage.app',
    measurementId: 'G-FKSYHTMZDQ',
  );
}

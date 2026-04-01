import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/settings_screen.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Vérifier si l'application est configurée (Poste + IP Serveur définis)
  final isConfigured = await StorageService.isConfigured();
  
  runApp(MyApp(isConfigured: isConfigured));
}

class MyApp extends StatelessWidget {
  final bool isConfigured;

  const MyApp({Key? key, required this.isConfigured}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IHM Poste',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Inter',
        // Styles globaux
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
        ),
      ),
      // Si l'application n'est pas encore configurée, on force l'écran de Settings
      // Sinon on démarre sur l'écran de Login Opérateur
      home: isConfigured ? LoginScreen() : SettingsScreen(isInitialSetup: true),
    );
  }
}
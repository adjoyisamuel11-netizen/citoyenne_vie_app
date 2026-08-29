import 'package:flutter/material.dart';
import 'screens/auth/login_screen.dart';
import 'core/network/navigation_service.dart';

void main() {
  // Redirection automatique vers le login quand une requête API renvoie 401
  // (jeton expiré/invalide), déclenchée depuis ApiClient sans BuildContext.
  NavigationService.onSessionExpired = () {
    final navigator = NavigationService.navigatorKey.currentState;
    navigator?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  };

  runApp(const CitoyenneVieApp());
}

class CitoyenneVieApp extends StatelessWidget {
  const CitoyenneVieApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: NavigationService.navigatorKey,
      title: 'La Citoyenne Vie',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}
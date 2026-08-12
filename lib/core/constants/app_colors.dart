import 'package:flutter/material.dart';

/// Charte graphique de La Citoyenne Vie S.A.
/// Dégradé Vert - Blanc - Rouge
class AppColors {
  AppColors._();

  // Couleurs principales
  static const Color primaryGreen = Color(0xFF0A8A3C);
  static const Color darkGreen = Color(0xFF066329);
  static const Color lightGreen = Color(0xFFE6F5EC);

  static const Color primaryRed = Color(0xFFD32F2F);
  static const Color lightRed = Color(0xFFFDEAEA);

  static const Color white = Color(0xFFFFFFFF);
  static const Color offWhite = Color(0xFFF5F6F8);

  // Couleurs neutres / texte
  static const Color textDark = Color(0xFF1E1E1E);
  static const Color textGrey = Color(0xFF757575);
  static const Color border = Color(0xFFE0E0E0);

  // Couleurs d'état
  static const Color success = primaryGreen;
  static const Color warning = Color(0xFFF9A825);
  static const Color danger = primaryRed;
  static const Color info = Color(0xFF1976D2);

  // ── Alias français (compatibilité avec les écrans existants : login, cotisations) ──
  static const Color vertPrincipal = primaryGreen;
  static const Color vertClair = lightGreen;
  static const Color rougeErreur = primaryRed;

  // Dégradé principal utilisé sur AppBar / en-têtes
  static const LinearGradient mainGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryGreen, white, primaryRed],
    stops: [0.0, 0.5, 1.0],
  );

  // Dégradé doux pour les fonds de carte / headers de dashboard
  static const LinearGradient softHeaderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [darkGreen, primaryGreen],
  );
}
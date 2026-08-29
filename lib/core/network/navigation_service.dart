import 'package:flutter/material.dart';

/// Permet de naviguer et de transmettre un message depuis n'importe où dans
/// l'app — notamment depuis [ApiClient], qui n'a pas de BuildContext —
/// sans créer d'import circulaire vers les écrans.
class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Callback défini par main.dart au démarrage : redirige vers l'écran de
  /// connexion et vide toute la pile de navigation.
  static void Function()? onSessionExpired;

  /// Message à afficher une fois sur le prochain écran de connexion
  /// (ex: "Votre session a expiré"), lu puis effacé par LoginScreen.
  static String? flashMessage;
}
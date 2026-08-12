import 'package:flutter/foundation.dart';

class ApiConstants {
  // ⚡ URL dynamique : détecte automatiquement si vous êtes sur Chrome/Web ou Téléphone/Émulateur
  static String get baseUrl {
    if (kIsWeb) {
      // Si l'application tourne dans Chrome (Navigateur Web)
      return 'http://localhost:3000/api';
    } else {
      // Si l'application tourne sur Émulateur Android
      return 'http://10.0.2.2:3000/api';

      // 💡 Astuce : Si vous branchez votre VRAI téléphone en Wi-Fi / USB plus tard,
      // il suffira de remplacer '10.0.2.2' par l'IP de votre PC (ex: 'http://192.168.1.XX:3000/api')
    }
  }

  // Routes Authentification
  static String get login => '$baseUrl/auth/login';

  // Routes Clients (Assurés)
  static String get clients => '$baseUrl/clients';

  // Routes Primes (Contrats d'assurance en cours de cotisation)
  static String get primes => '$baseUrl/primes';
  static String primesByClient(int clientId) => '$baseUrl/primes/client/$clientId';
  static String primeDetails(int primeId) => '$baseUrl/primes/$primeId';

  // Routes Grilles (Carnets de 31 cases)
  static String get grilles => '$baseUrl/grilles';
  static String grillesByPrime(int primeId) => '$baseUrl/grilles/prime/$primeId';
  static String grilleDetails(int grilleId) => '$baseUrl/grilles/$grilleId';

  // Routes Paiements / Encaissements
  static String get encaisser => '$baseUrl/paiements/encaisser';
  static String historiqueGrille(int grilleId) => '$baseUrl/paiements/grille/$grilleId';
}
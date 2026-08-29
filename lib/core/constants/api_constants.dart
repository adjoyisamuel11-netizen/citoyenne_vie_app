import 'package:flutter/foundation.dart';

class ApiConstants {
  /// URL de base configurable au lancement, SANS toucher au code.
  ///   flutter run --dart-define=API_BASE_URL=http://192.168.1.42:3000/api
  static const String _override = String.fromEnvironment('API_BASE_URL');

  // 🌐 Une fois l'API déployée (Render, etc.), mets l'URL publique ici : ça
  // devient le comportement par défaut, plus besoin de réseau local du tout.
  static const String _productionUrl = ''; //'https://citoyenne-vie-api.onrender.com/api' <-- URL de prod ici quand prête

  static String get baseUrl {
    if (_override.isNotEmpty) return _override;
    if (_productionUrl.isNotEmpty) return _productionUrl;
    if (kIsWeb) {
      return 'http://localhost:3000/api';
    }
    // Par défaut : suppose un émulateur Android. Sur un vrai téléphone,
    // lancer avec --dart-define=API_BASE_URL=http://TON_IP_LOCALE:3000/api
    return 'http://10.0.2.2:3000/api';
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

  // Routes Statistiques
  static String get statsDashboard => '$baseUrl/stats/dashboard';
  static String statsExport(String format) => '$baseUrl/stats/export?format=$format';

  // Routes Admin (gestion des agents) — réservées au rôle admin
  static String get adminAgents => '$baseUrl/admin/agents';
  static String adminAgentDetails(int agentId) => '$baseUrl/admin/agents/$agentId';
  static String adminAgentStatut(int agentId) => '$baseUrl/admin/agents/$agentId/statut';
}

import 'dart:convert';
import '../core/network/api_client.dart';
import '../core/utils/storage_service.dart';
import '../models/user_model.dart';

class AuthService {
  // On crée une instance de ApiClient
  final ApiClient _apiClient = ApiClient();

  /// Méthode de connexion de l'utilisateur
  Future<UserModel?> login(String email, String password) async {
    try {
      final response = await _apiClient.post('/auth/login', {
        'email': email,
        'mot_de_passe': password,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // 🔑 Sauvegarde effective du token JWT reçu, indispensable pour
        // toutes les requêtes protégées (stats, clients, primes, etc.)
        final token = data['token'];
        if (token != null) {
          await StorageService.saveToken(token);
        }

        return UserModel.fromJson(data['user']);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
}
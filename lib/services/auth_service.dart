import 'dart:convert';
import '../core/network/api_client.dart';
import '../models/user_model.dart';

class AuthService {
  // On crée une instance de ApiClient
  final ApiClient _apiClient = ApiClient();

  /// Méthode de connexion de l'utilisateur
  Future<UserModel?> login(String email, String password) async {
    try {
      final response = await _apiClient.post('/auth/login', {
        'email': email,
        'mot_de_passe': password, // 👈 CORRECTION ICI ('mot_de_passe' au lieu de 'password')
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Optionnel : Si vous stockez le token JWT reçu, vous pouvez le sauvegarder ici
        // final token = data['token'];

        return UserModel.fromJson(data['user']);
      } else {
        print('Erreur API (${response.statusCode}) : ${response.body}');
        return null;
      }
    } catch (e) {
      print('Erreur lors de la connexion : $e');
      return null;
    }
  }
}
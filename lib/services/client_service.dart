import 'dart:convert';
import '../core/network/api_client.dart';
import '../models/client_model.dart';

class ClientService {
  final ApiClient _apiClient = ApiClient();

  /// Récupérer la liste de tous les clients
  Future<List<ClientModel>> getClients() async {
    final response = await _apiClient.get('/clients');

    if (response.statusCode == 200) {
      final List<dynamic> body = jsonDecode(response.body);
      return body.map((dynamic item) => ClientModel.fromJson(item)).toList();
    } else {
      throw Exception('Erreur lors de la récupération des clients');
    }
  }

  /// Ajouter un nouveau client
  Future<bool> ajouterClient({
    required String nom,
    required String prenom,
    required String telephone,
    String? adresse,
  }) async {
    final response = await _apiClient.post('/clients', {
      'nom': nom,
      'prenom': prenom,
      'telephone': telephone,
      'adresse': adresse,
    });

    return response.statusCode == 201 || response.statusCode == 200;
  }
}
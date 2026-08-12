import 'dart:convert';
import '../core/network/api_client.dart';
import '../models/grille_model.dart';
import '../models/case_model.dart';

class GrilleService {
  final ApiClient _apiClient = ApiClient();

  Future<List<GrilleModel>> getGrillesParClient(int clientId) async {
    final response = await _apiClient.get('/grilles/client/$clientId');

    if (response.statusCode == 200) {
      final List<dynamic> body = jsonDecode(response.body);
      return body.map((dynamic item) => GrilleModel.fromJson(item)).toList();
    } else {
      throw Exception('Erreur lors du chargement des grilles du client');
    }
  }

  Future<Map<String, dynamic>> getGrilleDetails(int grilleId) async {
    final response = await _apiClient.get('/grilles/$grilleId');

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final grille = GrilleModel.fromJson(data['grille']);
      final List<CaseModel> cases = (data['cases'] as List)
          .map((item) => CaseModel.fromJson(item))
          .toList();

      return {
        'grille': grille,
        'cases': cases,
      };
    } else {
      throw Exception('Erreur lors de la récupération des détails de la grille');
    }
  }

  Future<bool> creerGrille({
    required int clientId,
    required String typeCotisation,
    required double montantCase,
  }) async {
    final response = await _apiClient.post('/grilles', {
      'client_id': clientId,
      'type_cotisation': typeCotisation,
      'montant_case': montantCase,
      'nombre_total_cases': 31,
    });

    return response.statusCode == 201 || response.statusCode == 200;
  }
}
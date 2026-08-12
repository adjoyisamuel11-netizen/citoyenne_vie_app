import '../core/network/api_client.dart';

class PaiementService {
  final ApiClient _apiClient = ApiClient();

  Future<bool> encaisserPaiement({
    required int grilleId,
    required List<int> caseIds,
    required double montantTotal,
    required String modePaiement,
    String? referenceTransaction,
  }) async {
    final response = await _apiClient.post('/paiements/encaisser', {
      'grille_id': grilleId,
      'case_ids': caseIds,
      'montant_total': montantTotal,
      'mode_paiement': modePaiement,
      'reference_transaction': referenceTransaction,
    });

    return response.statusCode == 201 || response.statusCode == 200;
  }
}
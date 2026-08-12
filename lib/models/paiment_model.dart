class PaiementModel {
  final int id;
  final String referenceRecu;
  final int grilleId;
  final int agentId;
  final double montantTotal;
  final String modePaiement;
  final String? referenceTransaction;
  final String datePaiement;

  PaiementModel({
    required this.id,
    required this.referenceRecu,
    required this.grilleId,
    required this.agentId,
    required this.montantTotal,
    required this.modePaiement,
    this.referenceTransaction,
    required this.datePaiement,
  });

  factory PaiementModel.fromJson(Map<String, dynamic> json) {
    return PaiementModel(
      id: json['id'],
      referenceRecu: json['reference_reçu'],
      grilleId: json['grille_id'],
      agentId: json['agent_id'],
      montantTotal: double.parse(json['montant_total'].toString()),
      modePaiement: json['mode_paiement'],
      referenceTransaction: json['reference_transaction'],
      datePaiement: json['date_paiement'],
    );
  }
}
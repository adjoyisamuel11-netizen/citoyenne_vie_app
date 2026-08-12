class CaseModel {
  final int id;
  final int grilleId;
  final int numeroCase;
  final bool estPayee;
  final String? datePaiement;

  CaseModel({
    required this.id,
    required this.grilleId,
    required this.numeroCase,
    required this.estPayee,
    this.datePaiement,
  });

  factory CaseModel.fromJson(Map<String, dynamic> json) {
    return CaseModel(
      id: json['id'],
      grilleId: json['grille_id'],
      numeroCase: json['numero_case'],
      estPayee: json['est_payee'] == 1 || json['est_payee'] == true,
      datePaiement: json['date_paiement'],
    );
  }
}
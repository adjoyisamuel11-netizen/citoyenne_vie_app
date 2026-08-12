class GrilleModel {
  final int id;
  final String codeGrille;
  final int clientId;
  final String? nomCompletClient;
  final String? telephoneClient;
  final String typeCotisation;
  final double montantCase;
  final int nombreTotalCases;
  final int casesPayees;
  final int casesRestantes;
  final double montantTotalCollecte;
  final double montantRestant;
  final String statut;

  GrilleModel({
    required this.id,
    required this.codeGrille,
    required this.clientId,
    this.nomCompletClient,
    this.telephoneClient,
    required this.typeCotisation,
    required this.montantCase,
    required this.nombreTotalCases,
    required this.casesPayees,
    required this.casesRestantes,
    required this.montantTotalCollecte,
    required this.montantRestant,
    required this.statut,
  });

  factory GrilleModel.fromJson(Map<String, dynamic> json) {
    return GrilleModel(
      id: json['grille_id'] ?? json['id'],
      codeGrille: json['code_grille'],
      clientId: json['client_id'],
      nomCompletClient: json['nom_complet_client'],
      telephoneClient: json['telephone_client'],
      typeCotisation: json['type_cotisation'],
      montantCase: double.parse(json['montant_case'].toString()),
      nombreTotalCases: json['nombre_total_cases'] ?? 31,
      casesPayees: json['cases_payees'] ?? 0,
      casesRestantes: json['cases_restantes'] ?? 31,
      montantTotalCollecte: double.parse((json['montant_total_collecte'] ?? 0).toString()),
      montantRestant: double.parse((json['montant_restant'] ?? 0).toString()),
      statut: json['statut_grille'] ?? json['statut'] ?? 'en_cours',
    );
  }
}
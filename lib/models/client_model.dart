class ClientModel {
  final int id;
  final String codeClient;
  final String nom;
  final String prenom;
  final String telephone;
  final String? adresse;
  final String statut;

  ClientModel({
    required this.id,
    required this.codeClient,
    required this.nom,
    required this.prenom,
    required this.telephone,
    this.adresse,
    required this.statut,
  });

  factory ClientModel.fromJson(Map<String, dynamic> json) {
    return ClientModel(
      id: json['id'],
      codeClient: json['code_client'],
      nom: json['nom'],
      prenom: json['prenom'],
      telephone: json['telephone'],
      adresse: json['adresse'],
      statut: json['statut'] ?? 'actif',
    );
  }
}
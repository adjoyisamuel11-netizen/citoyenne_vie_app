class UserModel {
  final int id;
  final String nom;
  final String prenom;
  final String email;
  final String role; // 'admin', 'agent', 'superviseur'
  final String statut;

  UserModel({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.role,
    required this.statut,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      nom: json['nom'],
      prenom: json['prenom'],
      email: json['email'],
      role: json['role'] ?? 'agent',
      statut: json['statut'] ?? 'actif',
    );
  }
}
import 'package:flutter/material.dart';
import 'package:citoyenne_vie_app/screens/LoginScreen.dart';
import 'package:citoyenne_vie_app/screens/HomeScreen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  // Fonction pour afficher la boîte de dialogue de confirmation de déconnexion
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // L'utilisateur doit obligatoirement cliquer sur un bouton
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 8),
              Text("Déconnexion"),
            ],
          ),
          content: const Text("Êtes-vous sûr de vouloir vous déconnecter réellement ?"),
          actions: [
            // Bouton pour annuler
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Ferme juste la boîte de dialogue
              },
              child: const Text(
                "Annuler",
                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
              ),
            ),
            // Bouton pour confirmer
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(context).pop(); // Ferme la boîte de dialogue

                // Redirige vers le LoginScreen et efface tout l'historique des pages précédentes
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (Route<dynamic> route) => false, // Supprime toutes les routes de la pile
                );
              },
              child: const Text("Oui, me déconnecter"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isDesktop = screenWidth > 600;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "Tableau de Bord - Collecte",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => _showLogoutDialog(context), // Appel de la boîte de dialogue
          ),
        ],
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: isDesktop ? 900 : double.infinity),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Bienvenue, Agent !",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const Text(
                  "Voici le résumé de vos activités aujourd'hui.",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        title: "Collecté (F CFA)",
                        value: "45 000 XOF",
                        icon: Icons.account_balance_wallet,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        title: "Assurés Suivis",
                        value: "12",
                        icon: Icons.people,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                const Text(
                  "Raccourcis et Actions",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                isDesktop
                    ? Row(
                  children: [
                    Expanded(child: _buildActionCard(context)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildCollecteCard()),
                  ],
                )
                    : Column(
                  children: [
                    _buildActionCard(context),
                    const SizedBox(height: 12),
                    _buildCollecteCard(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.green[100], shape: BoxShape.circle),
          child: const Icon(Icons.assignment, color: Colors.green, size: 30),
        ),
        title: const Text(
          "Gestion des Assurés",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: const Text("Consulter la liste, ajouter, modifier ou supprimer des assurés"),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.green),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        },
      ),
    );
  }

  Widget _buildCollecteCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.orange[100], shape: BoxShape.circle),
          child: const Icon(Icons.monetization_on, color: Colors.orange, size: 30),
        ),
        title: const Text(
          "Encaisser une Cotisation",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: const Text("Enregistrer rapidement le paiement d'une taxe/prime"),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.orange),
        onTap: () {},
      ),
    );
  }

  Widget _buildStatCard({required String title, required String value, required IconData icon, required Color color}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

}
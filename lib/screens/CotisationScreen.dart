import 'package:flutter/material.dart';

class CotisationScreen extends StatefulWidget {
  final Map<String, String> assure;

  const CotisationScreen({super.key, required this.assure});

  @override
  State<CotisationScreen> createState() => _CotisationScreenState();
}

class _CotisationScreenState extends State<CotisationScreen> {
  // Les couleurs officielles
  static const Color brandBlue = Color(0xFF1E88E5);   // Bleu La Citoyenne
  static const Color brandOrange = Color(0xFFFF9800); // Orange La Citoyenne
  static const Color textDark = Color(0xFF263238);    // Gris anthracite du slogan

  // Historique local dynamique
  final List<Map<String, dynamic>> _cotisations = [
    {"periode": "Janvier 2026", "montant": "5 000 FCFA", "valide": true},
    {"periode": "Février 2026", "montant": "5 000 FCFA", "valide": true},
    {"periode": "Mars 2026", "montant": "5 000 FCFA", "valide": false},
  ];

  int _selectedCotisationIndex = -1;

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isDesktop = screenWidth > 750;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        title: Text(
          "Suivi Cotisations : ${widget.assure['nom']}",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: brandBlue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isDesktop
          ? Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 360,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  _buildProfileCard(),
                  const SizedBox(height: 20),
                  _buildActionToolbar(),
                ],
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Historique des versements",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark),
                  ),
                  const SizedBox(height: 16),
                  Expanded(child: _buildCotisationsList()),
                ],
              ),
            ),
          )
        ],
      )
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildProfileCard(),
          ),
          _buildActionToolbar(),
          const SizedBox(height: 10),
          Expanded(
            child: _buildCotisationsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: brandBlue.withAlpha(25),
              child: const Icon(Icons.person, size: 32, color: brandBlue),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.assure['nom'] ?? "Nom Inconnu",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: brandOrange.withAlpha(30),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      widget.assure['status'] ?? "Aucun statut",
                      style: const TextStyle(fontSize: 11, color: brandOrange, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.phone_in_talk_outlined, color: brandBlue, size: 22),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline, color: Colors.green, size: 22),
                  onPressed: () {},
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildActionToolbar() {
    bool hasSelection = _selectedCotisationIndex != -1;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: brandBlue.withAlpha(40), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildToolbarButton(Icons.add, "Ajouter", true, brandBlue, _ajouterCotisationDialog),
          _buildToolbarButton(Icons.edit_outlined, "Modifier", hasSelection, brandOrange, _modifierCotisationDialog),
          _buildToolbarButton(Icons.delete_outline, "Supprimer", hasSelection, Colors.red, _supprimerCotisation),
          _buildToolbarButton(Icons.check_circle_outline, "Valider", hasSelection, brandBlue, _validerCotisation),
          _buildToolbarButton(Icons.highlight_off, "Annuler", hasSelection, brandOrange, _annulerValidation),
          _buildToolbarButton(Icons.search, "Chercher", true, textDark, () {}),
        ],
      ),
    );
  }

  Widget _buildToolbarButton(IconData icon, String label, bool enabled, Color activeColor, VoidCallback? onTap) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: enabled ? 1.0 : 0.25,
      child: Tooltip(
        message: label,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            key: ValueKey("$label-$enabled"),
            child: Icon(
                icon,
                color: enabled ? activeColor : textDark,
                size: 24
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCotisationsList() {
    return ListView.builder(
      itemCount: _cotisations.length,
      itemBuilder: (context, index) {
        final cotis = _cotisations[index];
        final isSelected = index == _selectedCotisationIndex;
        final bool isValide = cotis['valide'];

        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.fastOutSlowIn,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? brandBlue.withAlpha(12) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: isSelected ? brandBlue : Colors.grey.withAlpha(35),
                width: isSelected ? 1.5 : 1
            ),
          ),
          child: ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            leading: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isValide ? brandBlue.withAlpha(25) : brandOrange.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isValide ? Icons.check : Icons.hourglass_empty,
                color: isValide ? brandBlue : brandOrange,
                size: 20,
              ),
            ),
            title: Text(
                cotis['periode'],
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSelected ? brandBlue : textDark
                )
            ),
            subtitle: Text(
              "Montant : ${cotis['montant']}",
              style: const TextStyle(color: Colors.black54, fontSize: 13),
            ),
            trailing: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                isValide ? "Validé" : "En attente",
                key: ValueKey(isValide),
                style: TextStyle(
                  color: isValide ? brandBlue : brandOrange,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            onTap: () {
              setState(() {
                _selectedCotisationIndex = (_selectedCotisationIndex == index) ? -1 : index;
              });
            },
          ),
        );
      },
    );
  }

  // --- ACTIONS FONCTIONNELLES DE LA BARRE D'OUTILS ---

  void _validerCotisation() {
    setState(() {
      _cotisations[_selectedCotisationIndex]['valide'] = true;
      _selectedCotisationIndex = -1;
    });
  }

  void _annulerValidation() {
    setState(() {
      _cotisations[_selectedCotisationIndex]['valide'] = false;
      _selectedCotisationIndex = -1;
    });
  }

  void _supprimerCotisation() {
    setState(() {
      _cotisations.removeAt(_selectedCotisationIndex);
      _selectedCotisationIndex = -1;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Cotisation supprimée"), backgroundColor: textDark),
    );
  }

  void _ajouterCotisationDialog() {
    final periodeController = TextEditingController();
    final montantController = TextEditingController(text: "5 000 FCFA");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Ajouter une cotisation", style: TextStyle(color: textDark, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: periodeController, decoration: const InputDecoration(labelText: "Période (ex: Avril 2026)")),
            TextField(controller: montantController, decoration: const InputDecoration(labelText: "Montant")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: brandBlue),
            onPressed: () {
              if (periodeController.text.isNotEmpty && montantController.text.isNotEmpty) {
                setState(() {
                  _cotisations.add({
                    "periode": periodeController.text,
                    "montant": montantController.text,
                    "valide": false,
                  });
                });
                Navigator.pop(context);
              }
            },
            child: const Text("Ajouter", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  void _modifierCotisationDialog() {
    final current = _cotisations[_selectedCotisationIndex];
    final periodeController = TextEditingController(text: current['periode']);
    final montantController = TextEditingController(text: current['montant']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Modifier la cotisation", style: TextStyle(color: textDark, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: periodeController, decoration: const InputDecoration(labelText: "Période")),
            TextField(controller: montantController, decoration: const InputDecoration(labelText: "Montant")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: brandOrange),
            onPressed: () {
              if (periodeController.text.isNotEmpty && montantController.text.isNotEmpty) {
                setState(() {
                  _cotisations[_selectedCotisationIndex]['periode'] = periodeController.text;
                  _cotisations[_selectedCotisationIndex]['montant'] = montantController.text;
                  _selectedCotisationIndex = -1;
                });
                Navigator.pop(context);
              }
            },
            child: const Text("Enregistrer", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }
}
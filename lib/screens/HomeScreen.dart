import 'package:flutter/material.dart';
import 'package:citoyenne_vie_app/screens/LoginScreen.dart';
import 'package:citoyenne_vie_app/screens/AddAssureScreen.dart';
import 'package:citoyenne_vie_app/screens/CotisationScreen.dart'; // ✅ Import de l'écran de cotisation ajouté

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Liste principale d'assurés (la base de données fictive)
  final List<Map<String, String>> _allAssures = [
    {"nom": "Koffi Amédée", "status": "Assurance Inclusive Active"},
    {"nom": "Adjoa Mensah", "status": "Cotisation à jour"},
    {"nom": "Yao Akossi", "status": "En attente de paiement"},
  ];

  // Liste filtrée qui sera réellement affichée à l'écran
  List<Map<String, String>> _filteredAssures = [];

  // Contrôleur pour le texte de recherche
  final _searchController = TextEditingController();

  // Variables d'état
  int _selectedIndex = -1;
  bool _isSearching = false; // Permet de savoir si la barre de recherche est ouverte

  @override
  void initState() {
    super.initState();
    // Au démarrage, la liste affichée contient tous les assurés
    _filteredAssures = _allAssures;
  }

  // Fonction de filtrage Frontend
  void _filterAssures(String enteredKeyword) {
    List<Map<String, String>> results = [];
    if (enteredKeyword.isEmpty) {
      results = _allAssures;
    } else {
      // Cherche dans les noms en ignorant les majuscules/minuscules
      results = _allAssures
          .where((assure) => assure["nom"]!
          .toLowerCase()
          .contains(enteredKeyword.toLowerCase()))
          .toList();
    }

    setState(() {
      _filteredAssures = results;
      _selectedIndex = -1; // Réinitialise la sélection si la liste change
    });
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
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
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Annuler", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (Route<dynamic> route) => false,
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
    bool isDesktop = screenWidth > 750;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        // Si _isSearching est vrai, on affiche un champ texte, sinon le titre de l'entreprise
        title: _isSearching
            ? TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Rechercher un assuré...",
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
          onChanged: (value) => _filterAssures(value), // Filtre à chaque lettre tapée
        )
            : const Text(
          "La Citoyenne Vie S.A.",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
        actions: [
          // Bouton Loupe dynamique
          IconButton(
            icon: Icon(_isSearching ? Icons.clear : Icons.search, color: Colors.white),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _searchController.clear();
                  _filterAssures(""); // Réinitialise la liste
                  _isSearching = false;
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
        ],
      ),
      body: isDesktop
          ? Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 300,
            child: Card(
              margin: const EdgeInsets.all(16.0),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      "Actions disponibles",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    _buildAddButton(),
                    if (_selectedIndex != -1) ...[
                      const SizedBox(height: 12),
                      _buildEditButton(),
                      const SizedBox(height: 12),
                      _buildDeleteButton(),
                    ],
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildListHeader(),
                Expanded(child: _buildAssuresList()),
              ],
            ),
          ),
        ],
      )
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(child: _buildAddButton()),
                if (_selectedIndex != -1) ...[
                  const SizedBox(width: 8),
                  Expanded(child: _buildEditButton()),
                  const SizedBox(width: 8),
                  Expanded(child: _buildDeleteButton()),
                ],
              ],
            ),
          ),
          const Divider(),
          _buildListHeader(),
          Expanded(child: _buildAssuresList()),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(backgroundColor: Colors.green[100], padding: const EdgeInsets.symmetric(vertical: 12)),
      onPressed: () async {
        final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const AddAssureScreen()));
        if (result != null && result is Map<String, String>) {
          setState(() {
            _allAssures.add(result);
            _filterAssures(_searchController.text); // Met à jour l'affichage filtré
          });
        }
      },
      icon: const Icon(Icons.add, color: Colors.green),
      label: const Text("Ajouter", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildEditButton() {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[100], padding: const EdgeInsets.symmetric(vertical: 12)),
      onPressed: () async {
        final assureSelectionne = _filteredAssures[_selectedIndex];
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AddAssureScreen(assureData: assureSelectionne, isEditing: true)),
        );

        if (result != null && result is Map<String, String>) {
          setState(() {
            // Trouver l'index original dans la vraie liste complète pour appliquer la modification
            int indexOriginal = _allAssures.indexOf(assureSelectionne);
            if (indexOriginal != -1) _allAssures[indexOriginal] = result;

            _filterAssures(_searchController.text);
            _selectedIndex = -1;
          });
        }
      },
      icon: const Icon(Icons.edit, color: Colors.orange),
      label: const Text("Modifier", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildDeleteButton() {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(backgroundColor: Colors.red[100], padding: const EdgeInsets.symmetric(vertical: 12)),
      onPressed: () {
        final assureSelectionne = _filteredAssures[_selectedIndex];
        final nomAssure = assureSelectionne["nom"];

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Row(
                children: [Icon(Icons.warning_amber_rounded, color: Colors.red), SizedBox(width: 8), Text("Confirmer la suppression")],
              ),
              content: Text("Voulez-vous réellement supprimer l'assuré(e) \"$nomAssure\" ?"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Annuler", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() {
                      _allAssures.remove(assureSelectionne); // Supprime de la vraie liste
                      _filterAssures(_searchController.text); // Actualise le filtre
                      _selectedIndex = -1;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("L'assuré(e) $nomAssure a été supprimé(e)"), backgroundColor: Colors.red[700]),
                    );
                  },
                  child: const Text("Oui, supprimer"),
                ),
              ],
            );
          },
        );
      },
      icon: const Icon(Icons.delete, color: Colors.red),
      label: const Text("Supprimer", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildListHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Liste des Assurés (Infos personnelles)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          if (_selectedIndex != -1)
            TextButton(
              onPressed: () => setState(() => _selectedIndex = -1),
              child: const Text("Annuler la sélection", style: TextStyle(color: Colors.grey)),
            ),
        ],
      ),
    );
  }

  Widget _buildAssuresList() {
    if (_filteredAssures.isEmpty) {
      return const Center(child: Text("Aucun assuré ne correspond à votre recherche.", style: TextStyle(color: Colors.grey)));
    }

    return ListView.builder(
      itemCount: _filteredAssures.length,
      itemBuilder: (context, index) {
        final assure = _filteredAssures[index];
        final isSelected = index == _selectedIndex;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
          color: isSelected ? Colors.green[50] : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: isSelected ? Colors.green : Colors.transparent, width: 1.5),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isSelected ? Colors.green : Colors.grey[400],
              child: const Icon(Icons.person, color: Colors.white),
            ),
            title: Text(assure["nom"]!, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(assure["status"]!),
            trailing: Icon(
              isSelected ? Icons.check_circle : Icons.arrow_forward_ios,
              color: isSelected ? Colors.green : Colors.grey,
              size: isSelected ? 24 : 16,
            ),
            // ✅ Logique OnTap modifiée pour intégrer la redirection
            onTap: () {
              setState(() {
                if (_selectedIndex == index) {
                  // Si on reclique sur la ligne déjà sélectionnée, on désélectionne
                  _selectedIndex = -1;
                } else {
                  // Sinon, on sélectionne pour afficher la barre d'outils
                  _selectedIndex = index;
                }
              });

              // Si la ligne n'est pas sélectionnée et qu'on clique sur la flèche, on bascule vers l'historique
              if (!isSelected) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CotisationScreen(assure: assure),
                  ),
                );
              }
            },
          ),
        );
      },
    );
  }
}
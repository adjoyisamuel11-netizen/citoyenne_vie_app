import 'package:flutter/material.dart';

class AddAssureScreen extends StatefulWidget {
  // On ajoute deux paramètres optionnels : les données de l'assuré et un indicateur de modification
  final Map<String, String>? assureData;
  final bool isEditing;

  const AddAssureScreen({
    super.key,
    this.assureData,
    this.isEditing = false,
  });

  @override
  State<AddAssureScreen> createState() => _AddAssureScreenState();
}

class _AddAssureScreenState extends State<AddAssureScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nomController;
  late TextEditingController _prenomController;
  final _telephoneController = TextEditingController(); // Facultatif pour l'instant

  String _selectedStatus = "Assurance Inclusive Active";
  final List<String> _statusOptions = [
    "Assurance Inclusive Active",
    "Cotisation à jour",
    "En attente de paiement"
  ];

  @override
  void initState() {
    super.initState();

    // Si on est en mode modification, on sépare le nom et le prénom pour remplir les champs
    String initialNom = "";
    String initialPrenom = "";

    if (widget.isEditing && widget.assureData != null) {
      _selectedStatus = widget.assureData!["status"] ?? "Assurance Inclusive Active";

      // Découpage simple du nom complet (ex: "Koffi Amédée" -> "Koffi" et "Amédée")
      String nomComplet = widget.assureData!["nom"] ?? "";
      List<String> parts = nomComplet.split(" ");
      if (parts.isNotEmpty) initialNom = parts[0];
      if (parts.length > 1) initialPrenom = parts.sublist(1).join(" ");
    }

    _nomController = TextEditingController(text: initialNom);
    _prenomController = TextEditingController(text: initialPrenom);
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _telephoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        // Le titre change dynamiquement selon l'action !
        title: Text(
          widget.isEditing ? "Modifier l'Assuré" : "Ajouter un Assuré",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.isEditing ? "Modification des informations" : "Informations Personnelles",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                      const SizedBox(height: 20),

                      // Champ Nom
                      TextFormField(
                        controller: _nomController,
                        decoration: const InputDecoration(
                          labelText: "Nom",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person, color: Colors.green),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return "Veuillez entrer le nom";
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Champ Prénom
                      TextFormField(
                        controller: _prenomController,
                        decoration: const InputDecoration(
                          labelText: "Prénom",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person_outline, color: Colors.green),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return "Veuillez entrer le prénom";
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Champ Téléphone
                      TextFormField(
                        controller: _telephoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: "Numéro de téléphone",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone, color: Colors.green),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Menu déroulant pour le Statut
                      DropdownButtonFormField<String>(
                        value: _selectedStatus,
                        decoration: const InputDecoration(
                          labelText: "Statut",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.info_outline, color: Colors.green),
                        ),
                        items: _statusOptions.map((String status) {
                          return DropdownMenuItem<String>(
                            value: status,
                            child: Text(status),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            _selectedStatus = newValue!;
                          });
                        },
                      ),
                      const SizedBox(height: 30),

                      // Bouton Enregistrer / Mettre à jour
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            String nomComplet = "${_nomController.text} ${_prenomController.text}".trim();

                            Navigator.pop(context, {
                              "nom": nomComplet,
                              "status": _selectedStatus,
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    widget.isEditing
                                        ? "Assuré mis à jour avec succès !"
                                        : "Assuré ajouté avec succès !"
                                ),
                              ),
                            );
                          }
                        },
                        child: Text(
                          widget.isEditing ? "Mettre à jour" : "Enregistrer l'Assuré",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
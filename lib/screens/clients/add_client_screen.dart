import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';

/// Formulaire de création OU modification d'un client (assuré).
///
/// - Création : POST /api/clients { nom, prenom, telephone, adresse }
/// - Modification : PUT /api/clients/:id { nom, prenom, telephone, adresse, mot_de_passe }
class AddClientScreen extends StatefulWidget {
  final Map<String, dynamic>? clientData; // fourni uniquement si isEditing = true
  final bool isEditing;

  const AddClientScreen({super.key, this.clientData, this.isEditing = false});

  @override
  State<AddClientScreen> createState() => _AddClientScreenState();
}

class _AddClientScreenState extends State<AddClientScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiClient _apiClient = ApiClient();

  late TextEditingController _nomController;
  late TextEditingController _prenomController;
  late TextEditingController _telephoneController;
  late TextEditingController _adresseController;
  final _passwordController = TextEditingController();

  bool _isSubmitting = false;
  bool _obscurePassword = true;
  String? _erreurServeur;

  @override
  void initState() {
    super.initState();
    final c = widget.clientData;
    _nomController = TextEditingController(text: c?['nom'] ?? '');
    _prenomController = TextEditingController(text: c?['prenom'] ?? '');
    _telephoneController = TextEditingController(text: c?['telephone']?.toString() ?? '');
    _adresseController = TextEditingController(text: c?['adresse']?.toString() ?? '');
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _telephoneController.dispose();
    _adresseController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _soumettre() async {
    if (!_formKey.currentState!.validate()) return;

    if (widget.isEditing && _passwordController.text.trim().isEmpty) {
      setState(() => _erreurServeur = "Le mot de passe est requis pour modifier ce client.");
      return;
    }

    setState(() {
      _isSubmitting = true;
      _erreurServeur = null;
    });

    try {
      final body = {
        "nom": _nomController.text.trim(),
        "prenom": _prenomController.text.trim(),
        "telephone": _telephoneController.text.trim(),
        "adresse": _adresseController.text.trim(),
      };

      late final http.Response response;
      if (widget.isEditing) {
        body["mot_de_passe"] = _passwordController.text.trim();
        response = await _apiClient.put('/clients/${widget.clientData!['id']}', body);
      } else {
        response = await _apiClient.post('/clients', body);
      }

      final data = _decodeJson(response.body);

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        Navigator.pop(context, true); // true = signal de rafraîchissement pour la liste
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? (widget.isEditing ? "Client mis à jour." : "Client créé.")),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
      } else {
        setState(() {
          _isSubmitting = false;
          _erreurServeur = data['message'] ?? "Erreur (${response.statusCode}).";
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _erreurServeur = "Impossible de contacter le serveur.";
        });
      }
    }
  }

  Map<String, dynamic> _decodeJson(String body) {
    if (body.isEmpty) return {};
    try {
      return Map<String, dynamic>.from(jsonDecode(body) as Map);
    } catch (_) {
      return {};
    }
  }

  // 📱 Format togolais : 8 chiffres commençant par 7 ou 9, avec +228/00228 optionnel.
  // Même règle que côté backend (défense en profondeur : on bloque déjà côté saisie).
  static final RegExp _togoPhoneRegex = RegExp(r'^(\+228|00228)?[79]\d{7}$');

  String? _validerTelephoneTogolais(String? value) {
    if (value == null || value.trim().isEmpty) return "Champ obligatoire";
    final normalise = value.replaceAll(RegExp(r'[\s.-]'), '');
    if (!_togoPhoneRegex.hasMatch(normalise)) {
      return "Numéro invalide (ex: 90 12 34 56, format togolais requis)";
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        title: Text(widget.isEditing ? "Modifier l'Assuré" : "Nouvel Assuré"),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Informations de l'assuré",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryGreen)),
              const SizedBox(height: 14),

              TextFormField(
                controller: _nomController,
                decoration: const InputDecoration(
                  labelText: "Nom *",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person, color: AppColors.primaryGreen),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? "Champ obligatoire" : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _prenomController,
                decoration: const InputDecoration(
                  labelText: "Prénom *",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline, color: AppColors.primaryGreen),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? "Champ obligatoire" : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _telephoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: "Téléphone *",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone, color: AppColors.primaryGreen),
                  hintText: "ex: 90 12 34 56",
                ),
                validator: _validerTelephoneTogolais,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _adresseController,
                decoration: const InputDecoration(
                  labelText: "Adresse",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on, color: AppColors.primaryGreen),
                ),
              ),

              if (widget.isEditing) ...[
                const SizedBox(height: 20),
                const Text("Confirmation",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryGreen)),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: "Votre mot de passe *",
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock, color: AppColors.primaryGreen),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),
              ],

              if (_erreurServeur != null) ...[
                const SizedBox(height: 14),
                Text(_erreurServeur!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
              ],

              const SizedBox(height: 28),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _isSubmitting ? null : _soumettre,
                child: _isSubmitting
                    ? const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : Text(
                  widget.isEditing ? "Mettre à jour" : "Enregistrer l'Assuré",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
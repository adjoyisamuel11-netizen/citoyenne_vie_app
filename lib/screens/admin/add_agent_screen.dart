import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';

/// Formulaire de création OU modification d'un agent (compte utilisateur).
/// Réservé à l'administrateur.
///
/// - Création : POST /api/admin/agents { nom, prenom, email, mot_de_passe, role }
/// - Modification : PUT /api/admin/agents/:id { ..., mot_de_passe (mdp ADMIN), nouveau_mot_de_passe (optionnel) }
class AddAgentScreen extends StatefulWidget {
  final Map<String, dynamic>? agentData; // fourni uniquement si isEditing = true
  final bool isEditing;

  const AddAgentScreen({super.key, this.agentData, this.isEditing = false});

  @override
  State<AddAgentScreen> createState() => _AddAgentScreenState();
}

class _AddAgentScreenState extends State<AddAgentScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiClient _apiClient = ApiClient();

  late TextEditingController _nomController;
  late TextEditingController _prenomController;
  late TextEditingController _emailController;
  final _motDePasseController = TextEditingController(); // création, ou nouveau mdp en édition
  final _motDePasseAdminController = TextEditingController(); // confirmation admin en édition

  String _roleSelectionne = 'agent';
  bool _isSubmitting = false;
  bool _obscure1 = true;
  bool _obscure2 = true;
  String? _erreurServeur;

  @override
  void initState() {
    super.initState();
    final a = widget.agentData;
    _nomController = TextEditingController(text: a?['nom'] ?? '');
    _prenomController = TextEditingController(text: a?['prenom'] ?? '');
    _emailController = TextEditingController(text: a?['email'] ?? '');
    _roleSelectionne = a?['role'] ?? 'agent';
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _motDePasseController.dispose();
    _motDePasseAdminController.dispose();
    super.dispose();
  }

  Future<void> _soumettre() async {
    if (!_formKey.currentState!.validate()) return;

    if (!widget.isEditing && _motDePasseController.text.trim().length < 6) {
      setState(() => _erreurServeur = "Le mot de passe doit contenir au moins 6 caractères.");
      return;
    }
    if (widget.isEditing && _motDePasseAdminController.text.trim().isEmpty) {
      setState(() => _erreurServeur = "Votre mot de passe (admin) est requis pour confirmer.");
      return;
    }

    setState(() {
      _isSubmitting = true;
      _erreurServeur = null;
    });

    try {
      late final http.Response response;

      if (widget.isEditing) {
        final body = <String, dynamic>{
          "nom": _nomController.text.trim(),
          "prenom": _prenomController.text.trim(),
          "email": _emailController.text.trim(),
          "role": _roleSelectionne,
          "mot_de_passe": _motDePasseAdminController.text.trim(),
        };
        if (_motDePasseController.text.trim().isNotEmpty) {
          body["nouveau_mot_de_passe"] = _motDePasseController.text.trim();
        }
        response = await _apiClient.put('/admin/agents/${widget.agentData!['id']}', body);
      } else {
        response = await _apiClient.post('/admin/agents', {
          "nom": _nomController.text.trim(),
          "prenom": _prenomController.text.trim(),
          "email": _emailController.text.trim(),
          "mot_de_passe": _motDePasseController.text.trim(),
          "role": _roleSelectionne,
        });
      }

      final data = _decodeJson(response.body);

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? (widget.isEditing ? "Agent mis à jour." : "Agent créé.")),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        title: Text(widget.isEditing ? "Modifier l'Agent" : "Nouvel Agent"),
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
              const Text("Informations du compte",
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
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "Email *",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined, color: AppColors.primaryGreen),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return "Champ obligatoire";
                  if (!v.contains('@') || !v.contains('.')) return "Email invalide";
                  return null;
                },
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _roleSelectionne,
                decoration: const InputDecoration(
                  labelText: "Rôle *",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.badge_outlined, color: AppColors.primaryGreen),
                ),
                items: const [
                  DropdownMenuItem(value: 'agent', child: Text("Agent")),
                  DropdownMenuItem(value: 'superviseur', child: Text("Superviseur")),
                  DropdownMenuItem(value: 'admin', child: Text("Administrateur")),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _roleSelectionne = v);
                },
              ),
              const SizedBox(height: 20),

              Text(widget.isEditing ? "Nouveau mot de passe (optionnel)" : "Mot de passe *",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryGreen)),
              const SizedBox(height: 14),

              TextFormField(
                controller: _motDePasseController,
                obscureText: _obscure1,
                decoration: InputDecoration(
                  labelText: widget.isEditing ? "Laisser vide pour ne pas changer" : "Mot de passe *",
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primaryGreen),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure1 ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscure1 = !_obscure1),
                  ),
                ),
                validator: (v) {
                  if (!widget.isEditing && (v == null || v.trim().isEmpty)) return "Champ obligatoire";
                  return null;
                },
              ),

              if (widget.isEditing) ...[
                const SizedBox(height: 20),
                const Text("Confirmation",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryGreen)),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _motDePasseAdminController,
                  obscureText: _obscure2,
                  decoration: InputDecoration(
                    labelText: "Votre mot de passe (admin) *",
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock, color: AppColors.primaryGreen),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure2 ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscure2 = !_obscure2),
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
                        widget.isEditing ? "Mettre à jour" : "Créer l'agent",
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

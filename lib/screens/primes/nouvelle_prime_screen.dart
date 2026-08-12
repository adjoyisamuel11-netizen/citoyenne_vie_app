import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';

/// Formulaire de création OU modification d'une prime (contrat).
///
/// - Création : POST /api/primes  { client_id, type_assurance, prix_prime, mise, date_debut }
/// - Modification : PUT /api/primes/:id { type_assurance, prix_prime, mise, date_debut, mot_de_passe }
///   (mise/date_debut refusés par le serveur si des cases ont déjà été payées)
class NouvellePrimeScreen extends StatefulWidget {
  final Map<String, dynamic> clientData; // { id, nom, prenom, telephone, adresse }
  final Map<String, dynamic>? primeData; // fourni uniquement si isEditing = true
  final bool isEditing;

  const NouvellePrimeScreen({
    super.key,
    required this.clientData,
    this.primeData,
    this.isEditing = false,
  });

  @override
  State<NouvellePrimeScreen> createState() => _NouvellePrimeScreenState();
}

class _NouvellePrimeScreenState extends State<NouvellePrimeScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiClient _apiClient = ApiClient();

  late TextEditingController _typeAssuranceController;
  late TextEditingController _prixPrimeController;
  late TextEditingController _miseController;
  final _passwordController = TextEditingController();

  DateTime _dateDebut = DateTime.now();
  bool _isSubmitting = false;
  bool _obscurePassword = true;
  String? _erreurServeur;

  @override
  void initState() {
    super.initState();
    final p = widget.primeData;
    _typeAssuranceController = TextEditingController(text: p?['type_assurance'] ?? '');
    _prixPrimeController = TextEditingController(text: p?['prix_prime']?.toString() ?? '');
    _miseController = TextEditingController(text: p?['mise']?.toString() ?? '');
    if (widget.isEditing && p?['date_debut'] != null) {
      _dateDebut = DateTime.tryParse(p!['date_debut'].toString()) ?? DateTime.now();
    }
  }

  @override
  void dispose() {
    _typeAssuranceController.dispose();
    _prixPrimeController.dispose();
    _miseController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _choisirDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dateDebut,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      setState(() => _dateDebut = date);
    }
  }

  Future<void> _soumettre() async {
    if (!_formKey.currentState!.validate()) return;

    if (widget.isEditing && _passwordController.text.trim().isEmpty) {
      setState(() => _erreurServeur = "Le mot de passe est requis pour modifier la prime.");
      return;
    }

    setState(() {
      _isSubmitting = true;
      _erreurServeur = null;
    });

    final dateStr =
        "${_dateDebut.year.toString().padLeft(4, '0')}-${_dateDebut.month.toString().padLeft(2, '0')}-${_dateDebut.day.toString().padLeft(2, '0')}";

    try {
      final body = {
        "type_assurance": _typeAssuranceController.text.trim(),
        "prix_prime": double.parse(_prixPrimeController.text.trim()),
        "mise": double.parse(_miseController.text.trim()),
        "date_debut": dateStr,
      };

      late final http.Response response;
      if (widget.isEditing) {
        body["mot_de_passe"] = _passwordController.text.trim();
        response = await _apiClient.put('/primes/${widget.primeData!['id']}', body);
      } else {
        body["client_id"] = widget.clientData['id'];
        response = await _apiClient.post('/primes', body);
      }

      final data = _decodeJson(response.body);

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        Navigator.pop(context, true); // true = signal de rafraîchissement pour la liste
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? (widget.isEditing ? "Prime mise à jour." : "Prime créée.")),
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
    final nomComplet = "${widget.clientData['nom'] ?? ''} ${widget.clientData['prenom'] ?? ''}".trim();
    final adresse = widget.clientData['adresse']?.toString() ?? '';

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        title: Text(widget.isEditing ? "Modifier la Prime" : "Nouvelle Prime"),
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
              // ── Rappel client (lecture seule) ──
              Card(
                color: AppColors.lightGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nomComplet.isEmpty ? "Client" : nomComplet,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 2),
                      Text(
                        adresse.isEmpty ? "Adresse non renseignée" : adresse,
                        style: const TextStyle(color: AppColors.textGrey, fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              const Text("Détails de la prime",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryGreen)),
              const SizedBox(height: 14),

              TextFormField(
                controller: _typeAssuranceController,
                decoration: const InputDecoration(
                  labelText: "Type d'assurance *",
                  hintText: "ex: Épargne, Prévoyance...",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.shield_outlined, color: AppColors.primaryGreen),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? "Champ obligatoire" : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _prixPrimeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Montant visé / Prix de la prime (FCFA) *",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.flag_outlined, color: AppColors.primaryGreen),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return "Champ obligatoire";
                  final val = double.tryParse(v.trim());
                  if (val == null || val <= 0) return "Montant invalide";
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _miseController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Mise par case (FCFA) — min. 200 *",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.payments_outlined, color: AppColors.primaryGreen),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return "Champ obligatoire";
                  final val = double.tryParse(v.trim());
                  if (val == null || val < 200) return "Minimum 200 FCFA";
                  final prix = double.tryParse(_prixPrimeController.text.trim());
                  if (prix != null && val > prix) return "Ne peut pas dépasser le prix de la prime";
                  return null;
                },
              ),
              const SizedBox(height: 16),

              InkWell(
                onTap: _choisirDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: "Date de début",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today, color: AppColors.primaryGreen),
                  ),
                  child: Text(
                    "${_dateDebut.day.toString().padLeft(2, '0')}/${_dateDebut.month.toString().padLeft(2, '0')}/${_dateDebut.year}",
                  ),
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
                  widget.isEditing ? "Mettre à jour" : "Créer la prime",
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
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import 'grille_screen.dart';
import 'nouvelle_prime_screen.dart';

/// Écran Prime : affiche les infos du client + la liste de ses primes souscrites.
///
/// Consomme :
///   GET    /api/primes/client/:clientId
///   DELETE /api/primes/:id  { mot_de_passe }
class PrimesListeScreen extends StatefulWidget {
  final Map<String, dynamic> clientData; // { id, nom, prenom, telephone, adresse }

  const PrimesListeScreen({super.key, required this.clientData});

  @override
  State<PrimesListeScreen> createState() => _PrimesListeScreenState();
}

class _PrimesListeScreenState extends State<PrimesListeScreen> {
  final ApiClient _apiClient = ApiClient();

  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _primes = [];

  @override
  void initState() {
    super.initState();
    _chargerPrimes();
  }

  Future<void> _chargerPrimes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final clientId = widget.clientData['id'];
      final response = await _apiClient.get('/primes/client/$clientId');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (mounted) setState(() { _primes = data; _isLoading = false; });
      } else {
        final data = _decodeJson(response.body);
        if (mounted) {
          setState(() {
            _errorMessage = data['message'] ?? "Erreur ${response.statusCode}";
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() { _errorMessage = "Impossible de contacter le serveur."; _isLoading = false; });
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

  Future<void> _appelerClient(String telephone) async {
    final cleanPhone = telephone.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri(scheme: 'tel', path: cleanPhone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Impossible d'appeler $telephone"), backgroundColor: AppColors.danger),
      );
    }
  }

  Future<void> _ouvrirCreationPrime() async {
    final resultat = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NouvellePrimeScreen(clientData: widget.clientData),
      ),
    );
    if (resultat == true) _chargerPrimes();
  }

  Future<void> _ouvrirModificationPrime(Map<String, dynamic> prime) async {
    final resultat = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NouvellePrimeScreen(
          clientData: widget.clientData,
          primeData: prime,
          isEditing: true,
        ),
      ),
    );
    if (resultat == true) _chargerPrimes();
  }

  void _confirmerSuppression(Map<String, dynamic> prime) {
    final passwordController = TextEditingController();
    bool isSubmitting = false;
    String? erreur;
    bool obscure = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: AppColors.danger),
                  SizedBox(width: 8),
                  Text("Supprimer la prime"),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Prime ${prime['code_prime']} — cette action est irréversible."),
                  const SizedBox(height: 14),
                  TextField(
                    controller: passwordController,
                    obscureText: obscure,
                    decoration: InputDecoration(
                      labelText: "Mot de passe",
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setModalState(() => obscure = !obscure),
                      ),
                    ),
                  ),
                  if (erreur != null) ...[
                    const SizedBox(height: 8),
                    Text(erreur!, style: const TextStyle(color: AppColors.danger, fontSize: 12.5)),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext),
                  child: const Text("Annuler", style: TextStyle(color: AppColors.textGrey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: AppColors.white),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                    if (passwordController.text.trim().isEmpty) {
                      setModalState(() => erreur = "Mot de passe requis.");
                      return;
                    }
                    setModalState(() { isSubmitting = true; erreur = null; });

                    try {
                      final response = await _apiClient.delete(
                        '/primes/${prime['id']}',
                        body: {"mot_de_passe": passwordController.text.trim()},
                      );
                      final data = _decodeJson(response.body);

                      if (!mounted || !dialogContext.mounted) return;

                      if (response.statusCode == 200) {
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(data['message'] ?? "Prime supprimée."), backgroundColor: AppColors.primaryGreen),
                        );
                        _chargerPrimes();
                      } else {
                        setModalState(() {
                          isSubmitting = false;
                          erreur = data['message'] ?? "Erreur (${response.statusCode}).";
                        });
                      }
                    } catch (e) {
                      if (mounted && dialogContext.mounted) {
                        setModalState(() { isSubmitting = false; erreur = "Impossible de contacter le serveur."; });
                      }
                    }
                  },
                  child: isSubmitting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("Supprimer"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final nomComplet = "${widget.clientData['nom'] ?? ''} ${widget.clientData['prenom'] ?? ''}".trim();
    final telephone = widget.clientData['telephone']?.toString() ?? '';
    final adresse = widget.clientData['adresse']?.toString() ?? '';

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        title: const Text("Primes du Client"),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _isLoading ? null : _chargerPrimes),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _ouvrirCreationPrime,
        backgroundColor: AppColors.primaryGreen,
        icon: const Icon(Icons.add, color: AppColors.white),
        label: const Text("Nouvelle Prime", style: TextStyle(color: AppColors.white)),
      ),
      body: Column(
        children: [
          // ── En-tête client : avatar à gauche, infos à droite ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: AppColors.white,
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.lightGreen,
                  child: Icon(Icons.person, color: AppColors.primaryGreen, size: 30),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nomComplet.isEmpty ? "Client" : nomComplet,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      if (telephone.isNotEmpty)
                        Text(telephone, style: const TextStyle(color: AppColors.textGrey, fontSize: 12.5)),
                      if (adresse.isNotEmpty)
                        Text(adresse, style: const TextStyle(color: AppColors.textGrey, fontSize: 12.5)),
                    ],
                  ),
                ),
                if (telephone.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.phone, color: AppColors.primaryGreen, size: 26),
                    tooltip: "Appeler $telephone",
                    onPressed: () => _appelerClient(telephone),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── Liste des primes ──
          Expanded(child: _buildCorps()),
        ],
      ),
    );
  }

  Widget _buildCorps() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.danger, size: 42),
              const SizedBox(height: 10),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 14),
              ElevatedButton(onPressed: _chargerPrimes, child: const Text("Réessayer")),
            ],
          ),
        ),
      );
    }
    if (_primes.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text("Aucune prime souscrite pour le moment.\nUtilisez le bouton ci-dessous pour en créer une.",
              textAlign: TextAlign.center, style: TextStyle(color: AppColors.textGrey)),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _chargerPrimes,
      color: AppColors.primaryGreen,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        itemCount: _primes.length,
        itemBuilder: (context, index) {
          final prime = _primes[index] as Map<String, dynamic>;
          return _buildPrimeCard(prime);
        },
      ),
    );
  }

  Widget _buildPrimeCard(Map<String, dynamic> prime) {
    final statut = prime['statut']?.toString() ?? 'en_cours';
    final prixPrime = double.tryParse((prime['prix_prime'] ?? 0).toString()) ?? 0;
    final mise = double.tryParse((prime['mise'] ?? 0).toString()) ?? 0;

    final Map<String, Color> couleurStatut = {
      'en_cours': AppColors.warning,
      'validee': AppColors.primaryGreen,
      'annulee': AppColors.textGrey,
    };
    final Map<String, String> libelleStatut = {
      'en_cours': "⏳ En cours",
      'validee': "🟢 Validée",
      'annulee': "⚪ Annulée",
    };
    final couleur = couleurStatut[statut] ?? AppColors.textGrey;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => GrilleScreen(primeId: prime['id'])),
          ).then((_) => _chargerPrimes());
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      prime['type_assurance'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: couleur.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                    child: Text(libelleStatut[statut] ?? statut,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: couleur)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text("Code : ${prime['code_prime']}", style: const TextStyle(fontSize: 11.5, color: AppColors.textGrey)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: Text("Objectif : ${_formatMontant(prixPrime)}", style: const TextStyle(fontSize: 13))),
                  Expanded(child: Text("Mise : ${_formatMontant(mise)}", style: const TextStyle(fontSize: 13))),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _ouvrirModificationPrime(prime),
                    icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.info),
                    label: const Text("Modifier", style: TextStyle(color: AppColors.info, fontSize: 12.5)),
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                  ),
                  TextButton.icon(
                    onPressed: () => _confirmerSuppression(prime),
                    icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.danger),
                    label: const Text("Supprimer", style: TextStyle(color: AppColors.danger, fontSize: 12.5)),
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatMontant(double montant) {
    final str = montant.toInt().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i != 0 && (str.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(str[i]);
    }
    return "$buffer FCFA";
  }
}
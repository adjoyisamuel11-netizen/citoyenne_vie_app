import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';

/// Écran Grille : la grille de 31 cases d'un carnet, rattachée à une prime.
///
/// Consomme :
///   GET  /api/primes/:id            -> prime + progression + grille_active + cases
///   POST /api/paiements/encaisser   -> { grille_id, cases_ids, mode_paiement, mot_de_passe }
class GrilleScreen extends StatefulWidget {
  final int primeId;

  const GrilleScreen({super.key, required this.primeId});

  @override
  State<GrilleScreen> createState() => _GrilleScreenState();
}

class _GrilleScreenState extends State<GrilleScreen> {
  final ApiClient _apiClient = ApiClient();

  bool _isLoading = true;
  String? _errorMessage;

  Map<String, dynamic>? _prime;
  Map<String, dynamic>? _progression;
  Map<String, dynamic>? _grilleActive;
  List<dynamic> _cases = [];

  @override
  void initState() {
    super.initState();
    _chargerDonnees();
  }

  Future<void> _chargerDonnees() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiClient.get('/primes/${widget.primeId}');

      if (response.statusCode == 200) {
        final data = _decodeJson(response.body);
        if (mounted) {
          setState(() {
            _prime = data['prime'];
            _progression = data['progression'];
            _grilleActive = data['grille_active'];
            _cases = data['cases'] ?? [];
            _isLoading = false;
          });
        }
      } else {
        final data = _decodeJson(response.body);
        if (mounted) {
          setState(() {
            _errorMessage = data['message'] ?? 'Erreur ${response.statusCode}';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Impossible de contacter le serveur.";
          _isLoading = false;
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

  // ─────────────────────── Appel téléphonique direct ───────────────────────
  Future<void> _appelerClient(String telephone) async {
    final cleanPhone = telephone.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri(scheme: 'tel', path: cleanPhone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Impossible d'appeler $telephone"),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  // ─────────────────────── Validation d'une case (modale mot de passe) ───────────────────────
  void _ouvrirModaleValidation(Map<String, dynamic> caseData) {
    final passwordController = TextEditingController();
    String modePaiement = 'especes';
    bool isSubmitting = false;
    String? erreurLocale;
    bool obscure = true;

    final dateCase = DateTime.parse(caseData['date_case']);
    final dateFormatee = _formatDateFr(dateCase);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: AppColors.primaryGreen),
                  const SizedBox(width: 8),
                  Expanded(child: Text("Valider le $dateFormatee")),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Mise : ${_formatMontant(_getMiseMontant())}",
                    style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: modePaiement,
                    decoration: const InputDecoration(
                      labelText: "Mode de paiement",
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'especes', child: Text("Espèces")),
                      DropdownMenuItem(value: 'mobile_money', child: Text("Mobile Money")),
                      DropdownMenuItem(value: 'virement', child: Text("Virement")),
                    ],
                    onChanged: (value) {
                      if (value != null) setModalState(() => modePaiement = value);
                    },
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: passwordController,
                    obscureText: obscure,
                    decoration: InputDecoration(
                      labelText: "Confirmer avec votre mot de passe",
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock, color: AppColors.primaryGreen),
                      suffixIcon: IconButton(
                        icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setModalState(() => obscure = !obscure),
                      ),
                    ),
                  ),
                  if (erreurLocale != null) ...[
                    const SizedBox(height: 10),
                    Text(erreurLocale!, style: const TextStyle(color: AppColors.danger, fontSize: 12.5)),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext),
                  child: const Text("Annuler", style: TextStyle(color: AppColors.textGrey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: AppColors.white,
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                    if (passwordController.text.trim().isEmpty) {
                      setModalState(() => erreurLocale = "Le mot de passe est requis.");
                      return;
                    }
                    setModalState(() {
                      isSubmitting = true;
                      erreurLocale = null;
                    });

                    final result = await _validerCase(
                      caseId: caseData['id'],
                      modePaiement: modePaiement,
                      motDePasse: passwordController.text.trim(),
                    );

                    if (!mounted || !dialogContext.mounted) return;

                    if (result['success'] == true) {
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(result['message']),
                          backgroundColor: AppColors.primaryGreen,
                        ),
                      );
                      _chargerDonnees();
                    } else {
                      setModalState(() {
                        isSubmitting = false;
                        erreurLocale = result['message'];
                      });
                    }
                  },
                  child: isSubmitting
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                      : const Text("Valider"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<Map<String, dynamic>> _validerCase({
    required dynamic caseId,
    required String modePaiement,
    required String motDePasse,
  }) async {
    try {
      final response = await _apiClient.post('/paiements/encaisser', {
        "grille_id": _grilleActive?['grille_id'],
        "cases_ids": [caseId],
        "mode_paiement": modePaiement,
        "mot_de_passe": motDePasse,
      });

      final data = _decodeJson(response.body);

      if (response.statusCode == 201) {
        return {
          "success": true,
          "message": data['message'] ?? "Paiement enregistré avec succès.",
        };
      } else {
        return {
          "success": false,
          "message": data['message'] ?? "Erreur lors de la validation (${response.statusCode}).",
        };
      }
    } catch (e) {
      return {"success": false, "message": "Impossible de contacter le serveur."};
    }
  }

  double _getMiseMontant() {
    final mise = _prime?['mise'] ?? _grilleActive?['mise'] ?? 0;
    return double.tryParse(mise.toString()) ?? 0;
  }

  // Vraie soit parce que la prime a le statut 'validee', soit parce qu'aucune
  // grille active n'existe plus (le backend n'en recrée pas après validation).
  bool get _estPrimeValidee => _prime?['statut'] == 'validee' || _grilleActive == null;

  Widget _buildMessageFinCotisation() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.lightGreen,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryGreen, width: 1.5),
      ),
      child: Column(
        children: [
          const Icon(Icons.verified_rounded, color: AppColors.primaryGreen, size: 56),
          const SizedBox(height: 14),
          const Text(
            "Fin de cotisation, prime validée",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
          ),
          const SizedBox(height: 8),
          const Text(
            "L'objectif de cette prime a été atteint. Le carnet est définitivement clos, "
            "plus aucune saisie n'est possible sur cette grille.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textDark),
          ),
        ],
      ),
    );
  }

  // ─────────────────────── UI ───────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        title: Text(_prime != null ? "Prime ${_prime!['code_prime']}" : "Grille de cotisation"),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _chargerDonnees,
            tooltip: "Rafraîchir",
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
          : _errorMessage != null
          ? _buildErreur()
          : RefreshIndicator(
        onRefresh: _chargerDonnees,
        color: AppColors.primaryGreen,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoClient(),
              const SizedBox(height: 16),
              _buildProgression(),
              const SizedBox(height: 20),
              if (_estPrimeValidee) ...[
                _buildMessageFinCotisation(),
              ] else ...[
                _buildEnTeteGrille(),
                const SizedBox(height: 12),
                _buildGrilleCases(),
              ],
              const SizedBox(height: 20),
              _buildTotaux(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErreur() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.danger, size: 48),
            const SizedBox(height: 12),
            Text(_errorMessage ?? "Une erreur est survenue.", textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _chargerDonnees, child: const Text("Réessayer")),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoClient() {
    final nom = _prime?['nom_complet_client'] ?? '';
    final telephone = (_prime?['telephone'] ?? '').toString();
    final adresse = _prime?['adresse'] ?? '';
    final typeAssurance = _prime?['type_assurance'] ?? '';

    return Card(
      color: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.lightGreen,
              child: Icon(Icons.person, color: AppColors.primaryGreen),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nom, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 2),
                  Text(typeAssurance, style: const TextStyle(color: AppColors.textGrey, fontSize: 12.5)),
                  if (adresse.toString().isNotEmpty)
                    Text(adresse.toString(), style: const TextStyle(color: AppColors.textGrey, fontSize: 12.5)),
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
    );
  }

  Widget _buildProgression() {
    final prixPrime = double.tryParse((_progression?['prix_prime'] ?? 0).toString()) ?? 0;
    final montantCredite = double.tryParse((_progression?['montant_credite_total'] ?? 0).toString()) ?? 0;
    final pourcentage = ((_progression?['pourcentage_progression'] ?? 0) as num).toDouble() / 100;

    return Card(
      color: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Progression vers la prime", style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  "${(pourcentage * 100).toStringAsFixed(0)}%",
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: pourcentage.clamp(0, 1),
                minHeight: 10,
                backgroundColor: AppColors.lightGreen,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "${_formatMontant(montantCredite)} / ${_formatMontant(prixPrime)}",
              style: const TextStyle(fontSize: 12.5, color: AppColors.textGrey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnTeteGrille() {
    final numeroSequence = _grilleActive?['numero_sequence'] ?? '-';
    final aujourdHui = _formatDateFr(DateTime.now());

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text("Grille n°$numeroSequence", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        Text("Aujourd'hui : $aujourdHui", style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
      ],
    );
  }

  Widget _buildGrilleCases() {
    if (_cases.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 30),
        child: Center(child: Text("Aucune case disponible.", style: TextStyle(color: AppColors.textGrey))),
      );
    }

    final today = DateTime.now();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _cases.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) {
        final caseData = _cases[index] as Map<String, dynamic>;
        final estPayee = caseData['est_payee'] == 1 || caseData['est_payee'] == true;
        final dateCase = DateTime.parse(caseData['date_case']);
        final estAujourdhui = dateCase.year == today.year && dateCase.month == today.month && dateCase.day == today.day;

        return GestureDetector(
          onTap: estPayee ? null : () => _ouvrirModaleValidation(caseData),
          child: Container(
            decoration: BoxDecoration(
              color: estPayee ? AppColors.primaryGreen : AppColors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: estAujourdhui && !estPayee ? AppColors.primaryRed : AppColors.border,
                width: estAujourdhui && !estPayee ? 2 : 1,
              ),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "${dateCase.day}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: estPayee ? AppColors.white : AppColors.textDark,
                  ),
                ),
                if (estPayee)
                  const Icon(Icons.check, color: AppColors.white, size: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTotaux() {
    final cotise = double.tryParse((_progression?['total_cases_payees'] ?? 0).toString()) ?? 0;
    final mise = _getMiseMontant();
    final montantCotiseTotal = cotise * mise;
    final montantCredite = double.tryParse((_progression?['montant_credite_total'] ?? 0).toString()) ?? 0;

    return Card(
      color: AppColors.lightGreen,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _ligneTotal("Somme cotisée", _formatMontant(montantCotiseTotal)),
            const Divider(height: 20),
            _ligneTotal("Somme créditée au client", _formatMontant(montantCredite), accent: true),
          ],
        ),
      ),
    );
  }

  Widget _ligneTotal(String label, String value, {bool accent = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textDark, fontSize: 13.5)),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: accent ? AppColors.primaryGreen : AppColors.textDark,
          ),
        ),
      ],
    );
  }

  String _formatMontant(double montant) {
    final str = montant.toInt().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i != 0 && (str.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(str[i]);
    }
    return "${buffer.toString()} FCFA";
  }

  String _formatDateFr(DateTime date) {
    const mois = [
      "janvier", "février", "mars", "avril", "mai", "juin", "juillet",
      "août", "septembre", "octobre", "novembre", "décembre"
    ];
    return "${date.day} ${mois[date.month - 1]} ${date.year}";
  }
}
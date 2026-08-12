import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../primes/primes_liste_screen.dart';
import 'add_client_screen.dart';

enum _TriClient { nom, adresse, dateCreation }

/// Écran principal de gestion des clients/assurés.
///
/// Consomme :
///   GET    /api/clients?search=...
///   DELETE /api/clients/:id  { mot_de_passe }
class ClientsListeScreen extends StatefulWidget {
  const ClientsListeScreen({super.key});

  @override
  State<ClientsListeScreen> createState() => _ClientsListeScreenState();
}

class _ClientsListeScreenState extends State<ClientsListeScreen> {
  final ApiClient _apiClient = ApiClient();
  final _searchController = TextEditingController();

  bool _isLoading = true;
  bool _rechercheActive = false;
  String? _errorMessage;
  List<dynamic> _clients = [];
  _TriClient _triActuel = _TriClient.dateCreation;

  @override
  void initState() {
    super.initState();
    _chargerClients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _chargerClients({String? search}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final query = (search != null && search.isNotEmpty) ? '?search=${Uri.encodeQueryComponent(search)}' : '';
      final response = await _apiClient.get('/clients$query');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _clients = data;
            _isLoading = false;
          });
          _appliquerTri();
        }
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

  void _appliquerTri() {
    setState(() {
      switch (_triActuel) {
        case _TriClient.nom:
          _clients.sort((a, b) => (a['nom'] ?? '').toString().toLowerCase().compareTo((b['nom'] ?? '').toString().toLowerCase()));
          break;
        case _TriClient.adresse:
          _clients.sort((a, b) => (a['adresse'] ?? '').toString().toLowerCase().compareTo((b['adresse'] ?? '').toString().toLowerCase()));
          break;
        case _TriClient.dateCreation:
          _clients.sort((a, b) => (b['created_at'] ?? '').toString().compareTo((a['created_at'] ?? '').toString()));
          break;
      }
    });
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

  Future<void> _ouvrirCreation() async {
    final resultat = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddClientScreen()),
    );
    if (resultat == true) _chargerClients();
  }

  Future<void> _ouvrirModification(Map<String, dynamic> client) async {
    final resultat = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddClientScreen(clientData: client, isEditing: true)),
    );
    if (resultat == true) _chargerClients();
  }

  void _ouvrirPrimesDuClient(Map<String, dynamic> client) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PrimesListeScreen(clientData: {
          "id": client['id'],
          "nom": client['nom'],
          "prenom": client['prenom'],
          "telephone": client['telephone'],
          "adresse": client['adresse'],
        }),
      ),
    ).then((_) => _chargerClients());
  }

  void _confirmerSuppression(Map<String, dynamic> client) {
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
                  Text("Supprimer le client"),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("${client['nom']} ${client['prenom']} — cette action est irréversible."),
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
                        '/clients/${client['id']}',
                        body: {"mot_de_passe": passwordController.text.trim()},
                      );
                      final data = _decodeJson(response.body);

                      if (!mounted || !dialogContext.mounted) return;

                      if (response.statusCode == 200) {
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(data['message'] ?? "Client supprimé."), backgroundColor: AppColors.primaryGreen),
                        );
                        _chargerClients();
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
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        title: _rechercheActive
            ? TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(color: AppColors.white),
          decoration: const InputDecoration(
            hintText: "Rechercher nom, téléphone...",
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
          onChanged: (value) => _chargerClients(search: value),
        )
            : const Text("Clients / Assurés"),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: Icon(_rechercheActive ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _rechercheActive = !_rechercheActive;
                if (!_rechercheActive) {
                  _searchController.clear();
                  _chargerClients();
                }
              });
            },
          ),
          PopupMenuButton<_TriClient>(
            icon: const Icon(Icons.sort),
            tooltip: "Trier",
            onSelected: (tri) {
              setState(() => _triActuel = tri);
              _appliquerTri();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: _TriClient.nom, child: Text("Ordre alphabétique (nom)")),
              PopupMenuItem(value: _TriClient.adresse, child: Text("Par adresse")),
              PopupMenuItem(value: _TriClient.dateCreation, child: Text("Date de création (récent d'abord)")),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _ouvrirCreation,
        backgroundColor: AppColors.primaryGreen,
        icon: const Icon(Icons.person_add_alt_1, color: AppColors.white),
        label: const Text("Nouvel Assuré", style: TextStyle(color: AppColors.white)),
      ),
      body: _buildCorps(),
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
              ElevatedButton(onPressed: () => _chargerClients(), child: const Text("Réessayer")),
            ],
          ),
        ),
      );
    }
    if (_clients.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text("Aucun assuré enregistré pour le moment.\nUtilisez le bouton ci-dessous pour en ajouter un.",
              textAlign: TextAlign.center, style: TextStyle(color: AppColors.textGrey)),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _chargerClients(search: _searchController.text),
      color: AppColors.primaryGreen,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
        itemCount: _clients.length,
        itemBuilder: (context, index) {
          final client = _clients[index] as Map<String, dynamic>;
          return _buildClientCard(client);
        },
      ),
    );
  }

  Widget _buildClientCard(Map<String, dynamic> client) {
    final nomComplet = "${client['nom'] ?? ''} ${client['prenom'] ?? ''}".trim();
    final telephone = client['telephone']?.toString() ?? '';
    final adresse = client['adresse']?.toString() ?? '';
    final statut = client['statut']?.toString() ?? 'actif';
    final dateCreation = _formatDateCreation(client['created_at']?.toString());
    final initiales = _getInitiales(client['nom'], client['prenom']);

    final Map<String, Color> couleurStatut = {
      'actif': AppColors.primaryGreen,
      'suspendu': AppColors.warning,
      'resilie': AppColors.textGrey,
    };
    final couleur = couleurStatut[statut] ?? AppColors.textGrey;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _ouvrirPrimesDuClient(client),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.lightGreen,
                    child: Text(initiales, style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(nomComplet.isEmpty ? "Client" : nomComplet,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        if (adresse.isNotEmpty)
                          Text(adresse, style: const TextStyle(color: AppColors.textGrey, fontSize: 12.5)),
                        Text("Inscrit le $dateCreation", style: const TextStyle(color: AppColors.textGrey, fontSize: 11)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: couleur.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                    child: Text(statut, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: couleur)),
                  ),
                  if (telephone.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.phone, color: AppColors.primaryGreen, size: 22),
                      tooltip: "Appeler $telephone",
                      onPressed: () => _appelerClient(telephone),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _ouvrirModification(client),
                    icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.info),
                    label: const Text("Modifier", style: TextStyle(color: AppColors.info, fontSize: 12.5)),
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                  ),
                  TextButton.icon(
                    onPressed: () => _confirmerSuppression(client),
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

  String _getInitiales(dynamic nom, dynamic prenom) {
    final n = (nom ?? '').toString();
    final p = (prenom ?? '').toString();
    final i1 = n.isNotEmpty ? n[0].toUpperCase() : '';
    final i2 = p.isNotEmpty ? p[0].toUpperCase() : '';
    return "$i1$i2";
  }

  String _formatDateCreation(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return "date inconnue";
    final date = DateTime.tryParse(isoDate);
    if (date == null) return "date inconnue";
    const mois = [
      "janv.", "févr.", "mars", "avr.", "mai", "juin",
      "juil.", "août", "sept.", "oct.", "nov.", "déc."
    ];
    return "${date.day} ${mois[date.month - 1]} ${date.year}";
  }
}
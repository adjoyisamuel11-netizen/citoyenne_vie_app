import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import 'add_agent_screen.dart';

/// Écran de gestion des agents (liste, création, modification, activation,
/// suppression). Réservé au rôle admin — vérifié aussi côté backend.
class AgentsListeScreen extends StatefulWidget {
  const AgentsListeScreen({super.key});

  @override
  State<AgentsListeScreen> createState() => _AgentsListeScreenState();
}

class _AgentsListeScreenState extends State<AgentsListeScreen> {
  final ApiClient _apiClient = ApiClient();

  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _agents = [];

  @override
  void initState() {
    super.initState();
    _chargerAgents();
  }

  Future<void> _chargerAgents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiClient.get('/admin/agents');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (mounted) setState(() { _agents = data; _isLoading = false; });
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

  Future<void> _ouvrirCreation() async {
    final resultat = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddAgentScreen()),
    );
    if (resultat == true) _chargerAgents();
  }

  Future<void> _ouvrirModification(Map<String, dynamic> agent) async {
    final resultat = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddAgentScreen(agentData: agent, isEditing: true)),
    );
    if (resultat == true) _chargerAgents();
  }

  Future<void> _basculerStatut(Map<String, dynamic> agent) async {
    final nouveauStatut = agent['statut'] == 'actif' ? 'inactif' : 'actif';
    try {
      final response = await _apiClient.patch('/admin/agents/${agent['id']}/statut', {"statut": nouveauStatut});
      final data = _decodeJson(response.body);
      if (!mounted) return;
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? "Statut modifié."), backgroundColor: AppColors.primaryGreen),
        );
        _chargerAgents();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? "Erreur (${response.statusCode})"), backgroundColor: AppColors.danger),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Impossible de contacter le serveur."), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  void _confirmerSuppression(Map<String, dynamic> agent) {
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
                  Text("Supprimer l'agent"),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("${agent['nom']} ${agent['prenom']} — action irréversible si aucune donnée n'est rattachée."),
                  const SizedBox(height: 6),
                  const Text(
                    "Astuce : si l'agent a déjà des clients/paiements, préférez le désactiver plutôt.",
                    style: TextStyle(fontSize: 11.5, color: AppColors.textGrey, fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: passwordController,
                    obscureText: obscure,
                    decoration: InputDecoration(
                      labelText: "Votre mot de passe (admin)",
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
                              '/admin/agents/${agent['id']}',
                              body: {"mot_de_passe": passwordController.text.trim()},
                            );
                            final data = _decodeJson(response.body);

                            if (!mounted || !dialogContext.mounted) return;

                            if (response.statusCode == 200) {
                              Navigator.pop(dialogContext);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(data['message'] ?? "Agent supprimé."), backgroundColor: AppColors.primaryGreen),
                              );
                              _chargerAgents();
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
        title: const Text("Gestion des Agents"),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _isLoading ? null : _chargerAgents),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _ouvrirCreation,
        backgroundColor: AppColors.primaryGreen,
        icon: const Icon(Icons.person_add_alt_1, color: AppColors.white),
        label: const Text("Nouvel Agent", style: TextStyle(color: AppColors.white)),
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
              ElevatedButton(onPressed: _chargerAgents, child: const Text("Réessayer")),
            ],
          ),
        ),
      );
    }
    if (_agents.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text("Aucun agent enregistré pour le moment.", style: TextStyle(color: AppColors.textGrey)),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _chargerAgents,
      color: AppColors.primaryGreen,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        itemCount: _agents.length,
        itemBuilder: (context, index) {
          final agent = _agents[index] as Map<String, dynamic>;
          return _buildAgentCard(agent);
        },
      ),
    );
  }

  Widget _buildAgentCard(Map<String, dynamic> agent) {
    final nomComplet = "${agent['nom'] ?? ''} ${agent['prenom'] ?? ''}".trim();
    final email = agent['email']?.toString() ?? '';
    final role = agent['role']?.toString() ?? 'agent';
    final statut = agent['statut']?.toString() ?? 'actif';
    final actif = statut == 'actif';

    final Map<String, String> libelleRole = {
      'admin': "Administrateur",
      'agent': "Agent",
      'superviseur': "Superviseur",
    };
    final Map<String, Color> couleurRole = {
      'admin': AppColors.primaryRed,
      'agent': AppColors.primaryGreen,
      'superviseur': AppColors.info,
    };
    final couleur = couleurRole[role] ?? AppColors.textGrey;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: couleur.withValues(alpha: 0.12),
                  child: Icon(Icons.person, color: couleur),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nomComplet, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(email, style: const TextStyle(color: AppColors.textGrey, fontSize: 12.5)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: couleur.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                      child: Text(libelleRole[role] ?? role,
                          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: couleur)),
                    ),
                    const SizedBox(height: 4),
                    Switch(
                      value: actif,
                      activeTrackColor: AppColors.primaryGreen,
                      onChanged: (_) => _basculerStatut(agent),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _ouvrirModification(agent),
                  icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.info),
                  label: const Text("Modifier", style: TextStyle(color: AppColors.info, fontSize: 12.5)),
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                ),
                TextButton.icon(
                  onPressed: () => _confirmerSuppression(agent),
                  icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.danger),
                  label: const Text("Supprimer", style: TextStyle(color: AppColors.danger, fontSize: 12.5)),
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

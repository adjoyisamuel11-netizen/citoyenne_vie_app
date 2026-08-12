import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/client_model.dart';
import '../../models/grille_model.dart';
import '../../models/case_model.dart';
import '../../services/grille_service.dart';
import '../../services/paiement_service.dart';
import 'add_grille_screen.dart';
import 'recu_screen.dart';

class EtatCotisationScreen extends StatefulWidget {
  final ClientModel client;
  const EtatCotisationScreen({super.key, required this.client});

  @override
  State<EtatCotisationScreen> createState() => _EtatCotisationScreenState();
}

class _EtatCotisationScreenState extends State<EtatCotisationScreen> {
  final GrilleService _grilleService = GrilleService();
  final PaiementService _paiementService = PaiementService();

  GrilleModel? _activeGrille;
  List<CaseModel> _cases = [];
  final Set<int> _selectedCaseIds = {};
  bool _isLoading = true;
  bool _isProcessingPayment = false;

  @override
  void initState() {
    super.initState();
    _loadGrille();
  }

  Future<void> _loadGrille() async {
    setState(() => _isLoading = true);
    try {
      final grilles = await _grilleService.getGrillesParClient(widget.client.id);
      if (grilles.isNotEmpty) {
        final active = grilles.firstWhere(
              (g) => g.statut == 'en_cours',
          orElse: () => grilles.first,
        );
        final details = await _grilleService.getGrilleDetails(active.id);
        if (!mounted) return;
        setState(() {
          _activeGrille = details['grille'];
          _cases = details['cases'];
          _selectedCaseIds.clear();
        });
      } else {
        if (!mounted) return;
        setState(() {
          _activeGrille = null;
          _cases = [];
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _toggleCaseSelection(CaseModel caseItem) {
    if (caseItem.estPayee) return; // Case déjà validée

    setState(() {
      if (_selectedCaseIds.contains(caseItem.id)) {
        _selectedCaseIds.remove(caseItem.id);
      } else {
        _selectedCaseIds.add(caseItem.id);
      }
    });
  }

  void _validerPaiement() async {
    if (_selectedCaseIds.isEmpty || _activeGrille == null) return;

    final montantTotal = _selectedCaseIds.length * _activeGrille!.montantCase;

    setState(() => _isProcessingPayment = true);
    try {
      final success = await _paiementService.encaisserPaiement(
        grilleId: _activeGrille!.id,
        caseIds: _selectedCaseIds.toList(),
        montantTotal: montantTotal,
        modePaiement: 'especes',
      );

      if (mounted) {
        if (success) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RecuScreen(
                clientNom: '${widget.client.nom} ${widget.client.prenom}',
                montantPaye: montantTotal,
                nombreCases: _selectedCaseIds.length,
              ),
            ),
          );
          _loadGrille();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erreur lors de l\'encaissement')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessingPayment = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.client.nom} ${widget.client.prenom}'),
        backgroundColor: AppColors.vertPrincipal,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _activeGrille == null
          ? Center(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.vertPrincipal,
          ),
          child: const Text(
            'Créer un premier carnet',
            style: TextStyle(color: Colors.white),
          ),
          onPressed: () async {
            final res = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddGrilleScreen(clientId: widget.client.id),
              ),
            );
            if (res == true) _loadGrille();
          },
        ),
      )
          : Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade200,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Carnet : ${_activeGrille!.codeGrille}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('Prix/Case : ${_activeGrille!.montantCase} FCFA'),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _cases.length,
              itemBuilder: (context, index) {
                final caseItem = _cases[index];
                final isSelected = _selectedCaseIds.contains(caseItem.id);

                Color bgColor = Colors.grey.shade300;
                if (caseItem.estPayee) bgColor = AppColors.vertPrincipal;
                if (isSelected) bgColor = AppColors.rougeErreur;

                return InkWell(
                  onTap: () => _toggleCaseSelection(caseItem),
                  child: Container(
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${caseItem.numeroCase}',
                        style: TextStyle(
                          color: (caseItem.estPayee || isSelected)
                              ? Colors.white
                              : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_selectedCaseIds.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.vertPrincipal,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed:
                  _isProcessingPayment ? null : _validerPaiement,
                  child: _isProcessingPayment
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : Text(
                    'ENCAISSER (${_selectedCaseIds.length * _activeGrille!.montantCase} FCFA)',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
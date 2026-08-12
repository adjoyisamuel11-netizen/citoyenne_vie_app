import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';

/// Écran détaillé des statistiques : portefeuille, primes, graphiques
/// encaissements/commission, et export CSV/PDF vers le dossier Téléchargements.
class StatsDetailScreen extends StatefulWidget {
  const StatsDetailScreen({super.key});

  @override
  State<StatsDetailScreen> createState() => _StatsDetailScreenState();
}

class _StatsDetailScreenState extends State<StatsDetailScreen> {
  final ApiClient _apiClient = ApiClient();

  bool _isLoading = true;
  String? _errorMessage;
  bool _isExporting = false;

  Map<String, dynamic> _portefeuille = {};
  Map<String, dynamic> _primes = {};
  Map<String, dynamic> _encaissements = {};
  Map<String, dynamic> _commission = {};

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiClient.get('/stats/dashboard');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _portefeuille = Map<String, dynamic>.from(data['portefeuille'] ?? {});
            _primes = Map<String, dynamic>.from(data['primes'] ?? {});
            _encaissements = Map<String, dynamic>.from(data['encaissements'] ?? {});
            _commission = Map<String, dynamic>.from(data['commission'] ?? {});
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() { _errorMessage = "Erreur ${response.statusCode}"; _isLoading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _errorMessage = "Impossible de contacter le serveur."; _isLoading = false; });
    }
  }

  // ─────────────────────── Export via Storage Access Framework (SAF) ───────────────────────
  // Aucune permission de stockage requise : l'utilisateur choisit lui-même l'emplacement
  // dans la boîte de dialogue native "Enregistrer sous" (par défaut souvent Téléchargements).
  Future<void> _exporter(String format) async {
    setState(() => _isExporting = true);

    try {
      final response = await _apiClient.get('/stats/export?format=$format');

      if (response.statusCode != 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Erreur export (${response.statusCode})"), backgroundColor: AppColors.danger),
          );
        }
        return;
      }

      final nomFichier = "etat_cotisations_${DateTime.now().millisecondsSinceEpoch}.$format";

      final String? cheminEnregistre = await FilePicker.platform.saveFile(
        dialogTitle: 'Enregistrer le fichier',
        fileName: nomFichier,
        bytes: response.bodyBytes,
      );

      if (!mounted) return;

      if (cheminEnregistre == null) {
        // L'utilisateur a annulé la boîte de dialogue, rien à signaler en erreur.
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Fichier enregistré avec succès."), backgroundColor: AppColors.primaryGreen),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erreur lors de l'export."), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        title: const Text("Statistiques détaillées"),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _isLoading ? null : _charger),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
          : _errorMessage != null
          ? Center(child: Text(_errorMessage!))
          : RefreshIndicator(
        onRefresh: _charger,
        color: AppColors.primaryGreen,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCartePortefeuille(),
              const SizedBox(height: 16),
              _buildCartePrimes(),
              const SizedBox(height: 16),
              _buildGraphique(
                titre: "Encaissements (FCFA)",
                data: _encaissements,
                couleur: AppColors.primaryGreen,
              ),
              const SizedBox(height: 16),
              _buildGraphique(
                titre: "Commission générée (FCFA)",
                data: _commission,
                couleur: AppColors.info,
              ),
              const SizedBox(height: 20),
              _buildBoutonsExport(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCartePortefeuille() {
    final total = _portefeuille['total'] ?? 0;
    final actifs = _portefeuille['actifs'] ?? 0;
    final pourcentage = (_portefeuille['pourcentage_actifs'] ?? 0) as num;

    return _carte(
      titre: "Portefeuille clients",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("$actifs / $total actifs", style: const TextStyle(fontWeight: FontWeight.w600)),
              Text("${pourcentage.toInt()}%", style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: pourcentage.toDouble() / 100),
              duration: const Duration(milliseconds: 900),
              builder: (context, val, _) => LinearProgressIndicator(
                value: val.clamp(0, 1),
                minHeight: 10,
                backgroundColor: AppColors.lightGreen,
                valueColor: const AlwaysStoppedAnimation(AppColors.primaryGreen),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text("Nouveaux ce mois : ${_portefeuille['nouveaux_ce_mois'] ?? 0}",
              style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
        ],
      ),
    );
  }

  Widget _buildCartePrimes() {
    final enCours = _primes['en_cours'] ?? 0;
    final validees = _primes['validees'] ?? 0;
    final annulees = _primes['annulees'] ?? 0;

    return _carte(
      titre: "Primes",
      child: Row(
        children: [
          Expanded(child: _miniStat("En cours", enCours, AppColors.warning)),
          Expanded(child: _miniStat("Validées", validees, AppColors.primaryGreen)),
          Expanded(child: _miniStat("Annulées", annulees, AppColors.textGrey)),
        ],
      ),
    );
  }

  Widget _miniStat(String label, dynamic valeur, Color couleur) {
    return Column(
      children: [
        Text("$valeur", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: couleur)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.textGrey)),
      ],
    );
  }

  Widget _buildGraphique({required String titre, required Map<String, dynamic> data, required Color couleur}) {
    final jour = double.tryParse((data['aujourd_hui'] ?? 0).toString()) ?? 0;
    final semaine = double.tryParse((data['cette_semaine'] ?? 0).toString()) ?? 0;
    final mois = double.tryParse((data['ce_mois'] ?? 0).toString()) ?? 0;
    final annee = double.tryParse((data['cette_annee'] ?? 0).toString()) ?? 0;

    final maxY = [jour, semaine, mois, annee].reduce((a, b) => a > b ? a : b);
    final maxYAffiche = maxY <= 0 ? 10.0 : maxY * 1.2;

    return _carte(
      titre: titre,
      child: SizedBox(
        height: 180,
        child: BarChart(
          BarChartData(
            maxY: maxYAffiche,
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    const labels = ["Jour", "Semaine", "Mois", "Année"];
                    final i = value.toInt();
                    if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(labels[i], style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
                    );
                  },
                ),
              ),
            ),
            barGroups: [
              _barre(0, jour, couleur),
              _barre(1, semaine, couleur),
              _barre(2, mois, couleur),
              _barre(3, annee, couleur),
            ],
          ),
        ),
      ),
    );
  }

  BarChartGroupData _barre(int x, double valeur, Color couleur) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: valeur,
          color: couleur,
          width: 26,
          borderRadius: BorderRadius.circular(6),
        ),
      ],
    );
  }

  Widget _buildBoutonsExport() {
    return _carte(
      titre: "Exporter l'état global des cotisations",
      child: Column(
        children: [
          Text(
            "Une fenêtre native vous permettra de choisir où enregistrer le fichier.",
            style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isExporting ? null : () => _exporter('csv'),
                  icon: const Icon(Icons.table_chart_outlined),
                  label: const Text("CSV / Excel"),
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.primaryGreen, side: const BorderSide(color: AppColors.primaryGreen)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isExporting ? null : () => _exporter('pdf'),
                  icon: _isExporting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text("PDF"),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, foregroundColor: AppColors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _carte({required String titre, required Widget child}) {
    return Card(
      color: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
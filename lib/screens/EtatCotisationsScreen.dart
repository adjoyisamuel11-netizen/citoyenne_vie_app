import 'package:flutter/material.dart';

class EtatCotisationsScreen extends StatefulWidget {
  const EtatCotisationsScreen({super.key});

  @override
  State<EtatCotisationsScreen> createState() => _EtatCotisationsScreenState();
}

class _EtatCotisationsScreenState extends State<EtatCotisationsScreen> {
  // Couleurs de la charte La Citoyenne Vie
  static const Color brandBlue = Color(0xFF1E88E5);
  static const Color brandOrange = Color(0xFFFF9800);
  static const Color textDark = Color(0xFF263238);

  // Filtres
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  String _selectedStatut = "Tous";

  // Données de simulation (remplacées plus tard par la BDD)
  final List<Map<String, dynamic>> _allCotisations = [
    {"assure": "Koffi Mensah", "periode": "Juillet 2026", "montant": 5000, "statut": "Validé", "date": "2026-07-20"},
    {"assure": "Abla Lawson", "periode": "Juillet 2026", "montant": 10000, "statut": "Validé", "date": "2026-07-19"},
    {"assure": "Samba Diop", "periode": "Juin 2026", "montant": 5000, "statut": "En attente", "date": "2026-07-18"},
    {"assure": "Afi Agbeko", "periode": "Juillet 2026", "montant": 15000, "statut": "Validé", "date": "2026-07-15"},
    {"assure": "Komi Mawuli", "periode": "Mai 2026", "montant": 5000, "statut": "En attente", "date": "2026-07-10"},
  ];

  @override
  Widget build(BuildContext context) {
    // Calculs d'état dynamiques pour les KPIs
    int totalMontant = _allCotisations
        .where((c) => _selectedStatut == "Tous" || c['statut'] == _selectedStatut)
        .fold(0, (sum, item) => sum + (item['montant'] as int));

    int countTotal = _allCotisations.length;
    int countValides = _allCotisations.where((c) => c['statut'] == "Validé").length;

    return Scaffold(
      appBar: AppBar(
        title: const Text("État des Cotisations", style: TextStyle(fontWeight: FontWeight.bold, color: textDark)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: textDark),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
            tooltip: "Exporter en PDF",
            onPressed: () {
              // Action future : Appel à la fonction d'exportation PDF
              _showExportSnackBar("Exportation du PDF en cours...");
            },
          ),
          IconButton(
            icon: const Icon(Icons.table_chart, color: Colors.green),
            tooltip: "Exporter en Excel",
            onPressed: () {
              // Action future : Appel à la fonction d'exportation Excel/CSV
              _showExportSnackBar("Exportation Excel/CSV en cours...");
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- SECTION 1: FILTRES DE RECHERCHE ---
            _buildFilterCard(),

            const SizedBox(height: 20),

            // --- SECTION 2: CARTES RÉCAPITULATIVES (KPIs) ---
            Row(
              children: [
                Expanded(child: _buildKpiCard("Total Collecté", "$totalMontant FCFA", brandBlue, Icons.payments)),
                const SizedBox(width: 12),
                Expanded(child: _buildKpiCard("Validés", "$countValides / $countTotal", Colors.green, Icons.check_circle)),
              ],
            ),

            const SizedBox(height: 24),

            const Text(
              "Détail du rapport",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark),
            ),
            const SizedBox(height: 12),

            // --- SECTION 3: LISTE DU RAPPORT ---
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _allCotisations.length,
              itemBuilder: (context, index) {
                final item = _allCotisations[index];
                if (_selectedStatut != "Tous" && item['statut'] != _selectedStatut) {
                  return const SizedBox.shrink();
                }
                bool isValide = item['statut'] == "Validé";

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isValide ? Colors.green.withAlpha(30) : brandOrange.withAlpha(30),
                      child: Icon(
                        isValide ? Icons.check : Icons.hourglass_top,
                        color: isValide ? Colors.green : brandOrange,
                      ),
                    ),
                    title: Text(item['assure'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("Date: ${item['date']} • Période: ${item['periode']}"),
                    trailing: Text(
                      "${item['montant']} FCFA",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isValide ? brandBlue : textDark,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Widget pour le bloc de filtrage par date et statut
  Widget _buildFilterCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Critères du Rapport", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: brandBlue)),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.date_range, size: 18),
                  label: Text("${_startDate.day}/${_startDate.month}/${_startDate.year}"),
                  onPressed: () async {
                    DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _startDate,
                      firstDate: DateTime(2025),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) setState(() => _startDate = picked);
                  },
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Text("au"),
              ),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.date_range, size: 18),
                  label: Text("${_endDate.day}/${_endDate.month}/${_endDate.year}"),
                  onPressed: () async {
                    DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _endDate,
                      firstDate: DateTime(2025),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) setState(() => _endDate = picked);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Statut des versements :", style: TextStyle(fontWeight: FontWeight.w500)),
              DropdownButton<String>(
                value: _selectedStatut,
                items: ["Tous", "Validé", "En attente"].map((String value) {
                  return DropdownMenuItem<String>(value: value, child: Text(value));
                }).toList(),
                onChanged: (newValue) {
                  setState(() => _selectedStatut = newValue!);
                },
              ),
            ],
          )
        ],
      ),
    );
  }

  // Widget pour les cartes récapitulatives (KPIs)
  Widget _buildKpiCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  void _showExportSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: textDark, duration: const Duration(seconds: 2)),
    );
  }
}
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class RecuScreen extends StatelessWidget {
  final String clientNom;
  final double montantPaye;
  final int nombreCases;

  const RecuScreen({
    super.key,
    required this.clientNom,
    required this.montantPaye,
    required this.nombreCases,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reçu de Paiement'),
        backgroundColor: AppColors.vertPrincipal,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: AppColors.vertPrincipal,
              size: 80,
            ),
            const SizedBox(height: 16),
            const Text(
              'Paiement Enregistré avec Succès !',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    ListTile(
                      title: const Text('Client'),
                      subtitle: Text(
                        clientNom,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      title: const Text('Nombre de cases réglées'),
                      subtitle: Text('$nombreCases case(s)'),
                    ),
                    const Divider(),
                    ListTile(
                      title: const Text('Montant Total Encaissé'),
                      subtitle: Text(
                        '${montantPaye.toStringAsFixed(0)} FCFA',
                        style: const TextStyle(
                          fontSize: 18,
                          color: AppColors.vertPrincipal,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.vertPrincipal,
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'RETOURNER AU CARNET',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
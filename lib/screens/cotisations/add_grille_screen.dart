import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../services/grille_service.dart';

class AddGrilleScreen extends StatefulWidget {
  final int clientId;
  const AddGrilleScreen({super.key, required this.clientId});

  @override
  State<AddGrilleScreen> createState() => _AddGrilleScreenState();
}

class _AddGrilleScreenState extends State<AddGrilleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _typeController = TextEditingController(text: 'Cotisation Journalière');
  final _montantController = TextEditingController(text: '500');
  final _grilleService = GrilleService();
  bool _isSaving = false;

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final success = await _grilleService.creerGrille(
        clientId: widget.clientId,
        typeCotisation: _typeController.text.trim(),
        montantCase: double.parse(_montantController.text.trim()),
      );

      if (mounted) {
        if (success) {
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Impossible de créer la grille')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouveau Carnet (31 Cases)'),
        backgroundColor: AppColors.vertPrincipal,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _typeController,
                decoration: const InputDecoration(labelText: 'Type de Cotisation'),
                validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _montantController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Montant d\'une case (FCFA)'),
                validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.vertPrincipal,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _isSaving ? null : _submit,
                  child: _isSaving
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Text(
                    'CRÉER LE CARNET',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
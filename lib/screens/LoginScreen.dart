import 'package:flutter/material.dart';
import 'package:citoyenne_vie_app/screens/DashboardScreen.dart'; // ✅ Nom du fichier mis en minuscule si nécessaire

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Contrôleurs pour récupérer ce que l'agent écrit dans les champs
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  // Clé pour valider le formulaire plus tard
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Fond légèrement grisé pour faire ressortir le bloc central
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            // ─── CLÉ DU RESPONSIVE ICI ───
            // BoxConstraints permet de brider la largeur sur PC tout en restant fluide sur mobile
            child: Container(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min, // S'adapte au contenu verticalement
                    children: [
                      // 1. Logo de La Citoyenne Vie S.A. configuré depuis tes assets
                      Image.asset(
                        'assets/images/logo.jpeg',
                        height: 90,
                        errorBuilder: (context, error, stackTrace) {
                          // Icône de secours si l'image n'est pas encore détectée
                          return const Icon(
                              Icons.business,
                              size: 80,
                              color: Colors.green
                          );
                        },
                      ),
                      const SizedBox(height: 20),

                      // 2. Message textuel
                      const Text(
                        "Veuillez fournir vos identifiants",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 25),

                      // 3. Champ Nom d'utilisateur
                      TextFormField(
                        controller: _usernameController,
                        keyboardType: TextInputType.text,
                        decoration: const InputDecoration(
                          labelText: "Nom d'utilisateur",
                          hintText: "Entrez votre identifiant",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person, color: Colors.green),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 4. Champ Mot de passe
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true, // Cache les caractères saisis
                        decoration: const InputDecoration(
                          labelText: 'Mot de passe',
                          hintText: 'Entrez votre mot de passe',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.lock, color: Colors.green),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 5. Bouton de validation pour basculer vers le flux suivant
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          backgroundColor: Colors.green, // Identité d'assurance
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          // Redirection directe vers le tableau de bord initial
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const DashboardScreen()
                            ),
                          );
                        },
                        child: const Text(
                          'Se connecter',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:citoyenne_vie_app/screens/LoginScreen.dart';

void main() {
  runApp(const CitoyenneVieApp());
}

class CitoyenneVieApp extends StatelessWidget {
  const CitoyenneVieApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'La Citoyenne Vie',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}
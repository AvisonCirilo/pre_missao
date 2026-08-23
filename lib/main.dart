import 'package:flutter/material.dart';
import 'package:missao_app/telas/login_tela.dart';

void main() {
  runApp(const MissaoApp());
}

class MissaoApp extends StatelessWidget {
  const MissaoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Preparação Missionária',
      debugShowCheckedModeBanner: false, // Tira a faixa de "DEBUG"
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0D47A1)), // Azul escuro
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}
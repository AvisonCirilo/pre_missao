import 'package:flutter/material.dart';
import 'abas/aba_painel.dart';
import 'abas/aba_jovens.dart';
import 'abas/aba_perfil.dart';
import 'abas/aba_admin.dart';
import 'abas/aba_dashboard_estaca.dart'; // Certifique-se de que este arquivo existe

class HomeLider extends StatefulWidget {
  final String nivelAcesso; // Pode ser 'Ala', 'Estaca' ou 'Admin'

  const HomeLider({super.key, required this.nivelAcesso});

  @override
  State<HomeLider> createState() => _HomeLiderState();
}

class _HomeLiderState extends State<HomeLider> {
  int _indiceAtual = 0;
  
  List<Widget> _telas = [];
  List<BottomNavigationBarItem> _itensMenu = [];

  @override
  void initState() {
    super.initState();
    _configurarAcesso();
  }

  // ==========================================
  // O "CÉREBRO" DE PERMISSÕES
  // ==========================================
  void _configurarAcesso() {
    if (widget.nivelAcesso == 'Estaca') {
      // VISÃO DO PRESIDENTE DE ESTACA
      _telas = const [AbaDashboardEstaca(), AbaPerfil()];
      _itensMenu = const [
        BottomNavigationBarItem(icon: Icon(Icons.analytics_outlined), activeIcon: Icon(Icons.analytics), label: 'Minha Estaca'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Perfil'),
      ];
    } else if (widget.nivelAcesso == 'Admin') {
      // VISÃO DO ADMINISTRADOR GLOBAL
      _telas = const [AbaPainel(), AbaJovens(), AbaPerfil(), AbaAdmin()];
      _itensMenu = const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Painel'),
        BottomNavigationBarItem(icon: Icon(Icons.group_outlined), activeIcon: Icon(Icons.group), label: 'Jovens'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Perfil'),
        BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings_outlined), activeIcon: Icon(Icons.admin_panel_settings), label: 'Admin'),
      ];
    } else {
      // VISÃO PADRÃO (Bispo / Ala)
      _telas = const [AbaPainel(), AbaJovens(), AbaPerfil()];
      _itensMenu = const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Painel'),
        BottomNavigationBarItem(icon: Icon(Icons.group_outlined), activeIcon: Icon(Icons.group), label: 'Jovens'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Perfil'),
      ];
    }
  }

  void _aoTocarNaAba(int indice) {
    setState(() {
      _indiceAtual = indice;
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isEscuro = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _telas[_indiceAtual],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: isEscuro ? const Color(0xFF1E1E1E) : Colors.white,
        
        // Muda a cor do ícone principal dependendo de quem logou (Azul pra Ala, Roxo pra Estaca/Admin)
        selectedItemColor: widget.nivelAcesso == 'Ala' ? Colors.blue : Colors.purple, 
        
        unselectedItemColor: isEscuro ? Colors.grey.shade600 : Colors.grey,
        currentIndex: _indiceAtual,
        onTap: _aoTocarNaAba,
        elevation: 10,
        items: _itensMenu, // Puxa a lista inteligente gerada no initState
      ),
    );
  }
}
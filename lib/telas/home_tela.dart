import 'package:flutter/material.dart';
import 'abas/aba_painel.dart';
import 'abas/aba_perfil.dart';
import 'abas/aba_admin.dart';
import 'abas/aba_dashboard_estaca.dart'; 
import 'abas/aba_dashboard_gestor.dart';
import 'abas/admin/lista_jovens.dart';     // ABA 2 DO GESTOR
import 'abas/aba_contatos.dart';   // ABA 3 DO GESTOR

class HomeLider extends StatefulWidget {
  final String nivelAcesso; 

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

  void _configurarAcesso() {
    if (widget.nivelAcesso == 'Estaca') {
      _telas = [const AbaDashboardEstaca(), AbaPerfil(nivelAcesso: widget.nivelAcesso)];
      _itensMenu = const [
        BottomNavigationBarItem(icon: Icon(Icons.analytics_outlined), activeIcon: Icon(Icons.analytics), label: 'Minha Estaca'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Perfil'),
      ];
    } else if (widget.nivelAcesso == 'Gestor') {
      // O GESTOR AGORA TEM 4 ABAS PODEROSAS
      _telas = [
        const AbaDashboardGestor(),
        const ListaGlobalJovensTela(), // Reutiliza a lista do Admin
        const AbaContatosGestor(),
        AbaPerfil(nivelAcesso: widget.nivelAcesso)
      ];
      _itensMenu = const [
        BottomNavigationBarItem(icon: Icon(Icons.analytics_outlined), activeIcon: Icon(Icons.analytics), label: 'Painel'),
        BottomNavigationBarItem(icon: Icon(Icons.groups_outlined), activeIcon: Icon(Icons.groups), label: 'Jovens'),
        BottomNavigationBarItem(icon: Icon(Icons.contact_phone_outlined), activeIcon: Icon(Icons.contact_phone), label: 'Contatos'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Perfil'),
      ];
    } else if (widget.nivelAcesso == 'Admin') {
      _telas = [const AbaAdmin(), AbaPerfil(nivelAcesso: widget.nivelAcesso)];
      _itensMenu = const [
        BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings_outlined), activeIcon: Icon(Icons.admin_panel_settings), label: 'Administração'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Perfil'),
      ];
    } else {
      _telas = [const AbaPainel(), AbaPerfil(nivelAcesso: widget.nivelAcesso)];
      _itensMenu = const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Painel'),
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
    Color corSelecionada = Colors.blue;
    if (widget.nivelAcesso == 'Estaca') corSelecionada = Colors.purple;
    if (widget.nivelAcesso == 'Gestor') corSelecionada = Colors.teal;
    if (widget.nivelAcesso == 'Admin') corSelecionada = Colors.green;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _telas[_indiceAtual],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: isEscuro ? const Color(0xFF1E1E1E) : Colors.white,
        selectedItemColor: corSelecionada, 
        unselectedItemColor: isEscuro ? Colors.grey.shade600 : Colors.grey,
        currentIndex: _indiceAtual,
        onTap: _aoTocarNaAba,
        elevation: 10,
        items: _itensMenu, 
      ),
    );
  }
}
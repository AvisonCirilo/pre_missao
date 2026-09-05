import 'package:flutter/material.dart';
import 'abas/aba_painel.dart';
import 'abas/aba_perfil.dart';
import 'abas/aba_admin.dart';
import 'abas/aba_dashboard_estaca.dart'; 
import 'abas/aba_dashboard_gestor.dart';
import 'abas/admin/lista_jovens.dart';     
import 'abas/aba_contatos.dart';   
import 'abas/aba_contatos_ala.dart'; 

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
      _telas = [
        const AbaDashboardEstaca(),
        const ListaGlobalJovensTela(), 
        const AbaContatosGestor(),     
        AbaPerfil(nivelAcesso: widget.nivelAcesso)
      ];
      _itensMenu = const [
        BottomNavigationBarItem(icon: Icon(Icons.analytics_outlined), activeIcon: Icon(Icons.analytics), label: 'Painel'),
        BottomNavigationBarItem(icon: Icon(Icons.groups_outlined), activeIcon: Icon(Icons.groups), label: 'Jovens'),
        BottomNavigationBarItem(icon: Icon(Icons.contact_phone_outlined), activeIcon: Icon(Icons.contact_phone), label: 'Contatos'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Perfil'),
      ];
    } else if (widget.nivelAcesso == 'Gestor') {
      _telas = [
        const AbaDashboardGestor(),
        const ListaGlobalJovensTela(), 
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
      _telas = [
        const AbaPainel(), 
        const AbaContatosAla(), 
        AbaPerfil(nivelAcesso: widget.nivelAcesso)
      ];
      _itensMenu = const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Painel'),
        BottomNavigationBarItem(icon: Icon(Icons.contact_phone_outlined), activeIcon: Icon(Icons.contact_phone), label: 'Contatos'),
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
    Color corFundo = isEscuro ? const Color(0xFF1E1E1E) : Colors.white;

    // LAYOUT RESPONSIVO 
    return LayoutBuilder(
      builder: (context, constraints) {
        // VERSÃO MOBILE (Tela com menos de 600px de largura)
        if (constraints.maxWidth < 600) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: _telas[_indiceAtual],
            bottomNavigationBar: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              backgroundColor: corFundo,
              selectedItemColor: corSelecionada, 
              unselectedItemColor: isEscuro ? Colors.grey.shade600 : Colors.grey,
              currentIndex: _indiceAtual,
              onTap: _aoTocarNaAba,
              elevation: 10,
              items: _itensMenu, 
            ),
          );
        } 
        // VERSÃO DESKTOP / WEB (Telas maiores)
        else {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: Row(
              children: [
                // Menu Lateral
                NavigationRail(
                  backgroundColor: corFundo,
                  selectedIndex: _indiceAtual,
                  onDestinationSelected: _aoTocarNaAba,
                  labelType: NavigationRailLabelType.all,
                  selectedIconTheme: IconThemeData(color: corSelecionada),
                  unselectedIconTheme: IconThemeData(color: isEscuro ? Colors.grey.shade600 : Colors.grey),
                  selectedLabelTextStyle: TextStyle(color: corSelecionada, fontWeight: FontWeight.bold),
                  // Converte o seu _itensMenu dinamicamente para os destinos do Rail
                  destinations: _itensMenu.map((item) {
                    return NavigationRailDestination(
                      icon: item.icon,
                      selectedIcon: item.activeIcon,
                      label: Text(item.label ?? ''),
                    );
                  }).toList(),
                ),
                // Linha divisória
                VerticalDivider(thickness: 1, width: 1, color: isEscuro ? Colors.white12 : Colors.grey.shade200),
                // O conteúdo principal ocupa o resto do espaço
                Expanded(
                  child: _telas[_indiceAtual],
                ),
              ],
            ),
          );
        }
      },
    );
  }
}
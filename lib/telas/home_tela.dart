import 'package:flutter/material.dart';

class HomeLider extends StatefulWidget {
  const HomeLider({super.key});

  @override
  State<HomeLider> createState() => _HomeLiderState();
}

class _HomeLiderState extends State<HomeLider> {
  // Variável que guarda qual aba está selecionada no momento (começa no Painel: 0)
  int _indiceAtual = 0;

  // Lista de Telas que serão exibidas (Por enquanto, telas temporárias)
  final List<Widget> _telas = [
    const AbaPainelTemporaria(),
    const AbaJovensTemporaria(),
    const AbaPerfilTemporaria(),
  ];

  // Função disparada ao clicar em um ícone da barra inferior
  void _aoTocarNaAba(int indice) {
    setState(() {
      _indiceAtual = indice;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50, // Um fundo levemente cinza
      
      // O corpo do aplicativo muda de acordo com o índice selecionado
      body: _telas[_indiceAtual],
      
      // A Barra de Navegação Inferior
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.blue, // Cor quando selecionado
        unselectedItemColor: Colors.grey, // Cor quando inativo
        currentIndex: _indiceAtual,
        onTap: _aoTocarNaAba,
        elevation: 10,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Painel',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group_outlined),
            activeIcon: Icon(Icons.group),
            label: 'Jovens',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

// ==============================================================
// TELAS TEMPORÁRIAS (Vamos separá-las em arquivos reais depois)
// ==============================================================

class AbaPainelTemporaria extends StatelessWidget {
  const AbaPainelTemporaria({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Tira a seta de voltar
        title: const Text('Visão Geral da Ala', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: const Center(
        child: Text('Aqui faremos o Dashboard\ncom gráficos e resumos.', textAlign: TextAlign.center),
      ),
    );
  }
}

class AbaJovensTemporaria extends StatelessWidget {
  const AbaJovensTemporaria({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Lista de Jovens', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: const Center(
        child: Text('Aqui ficará a lista de jovens\ne o botão flutuante de adicionar.', textAlign: TextAlign.center),
      ),
    );
  }
}

class AbaPerfilTemporaria extends StatelessWidget {
  const AbaPerfilTemporaria({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Meu Perfil', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Center(
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
          onPressed: () {
            // Volta para a tela de login
            Navigator.pop(context);
          },
          icon: const Icon(Icons.logout),
          label: const Text('Sair da Conta'),
        ),
      ),
    );
  }
}
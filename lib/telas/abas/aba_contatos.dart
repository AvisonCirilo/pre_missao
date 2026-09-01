import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AbaContatosGestor extends StatefulWidget {
  const AbaContatosGestor({super.key});

  @override
  State<AbaContatosGestor> createState() => _AbaContatosGestorState();
}

class _AbaContatosGestorState extends State<AbaContatosGestor> {
  String _termoBusca = '';
  String _minhaEstaca = "";
  String _nivelAcesso = "Ala";
  bool _carregandoPerfil = true;

  @override
  void initState() {
    super.initState();
    _carregarPerfilLider();
  }

  Future<void> _carregarPerfilLider() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        var doc = await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).get();
        if (doc.exists && mounted) {
          var dados = doc.data() as Map<String, dynamic>? ?? {};
          setState(() {
            _minhaEstaca = dados['estaca'] ?? "";
            _nivelAcesso = dados['nivel_acesso'] ?? "Ala";
            _carregandoPerfil = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _carregandoPerfil = false);
    }
  }

  // Abre o WhatsApp direto, sem mensagem padrão
  Future<void> _abrirWhatsApp(String telefone) async {
    String numeroLimpo = telefone.replaceAll(RegExp(r'[^0-9]'), '');
    if (numeroLimpo.isEmpty) return;
    final Uri url = Uri.parse('https://wa.me/$numeroLimpo');
    try { await launchUrl(url, mode: LaunchMode.externalApplication); } catch (e) {}
  }

  Widget _construirTileLider(Map<String, dynamic> lider, Color corTexto, bool isEscuro) {
    String telefone = lider['whatsapp'] ?? '';
    return Container(
      decoration: BoxDecoration(border: Border(top: BorderSide(color: isEscuro ? Colors.white12 : Colors.grey.shade100))),
      child: ListTile(
        contentPadding: const EdgeInsets.only(left: 32, right: 16, top: 4, bottom: 4),
        leading: const Icon(Icons.person, color: Colors.grey, size: 20),
        title: Text(lider['nome'] ?? '', style: TextStyle(fontWeight: FontWeight.w600, color: corTexto)),
        subtitle: Text(lider['cargo'] ?? 'Líder', style: TextStyle(color: isEscuro ? Colors.white54 : Colors.grey, fontSize: 12)),
        trailing: telefone.isNotEmpty 
          ? IconButton(icon: const Icon(Icons.chat, color: Colors.green), onPressed: () => _abrirWhatsApp(telefone))
          : const Icon(Icons.phone_disabled, color: Colors.grey, size: 18),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isEscuro = Theme.of(context).brightness == Brightness.dark;
    Color corFundo = isEscuro ? const Color(0xFF1E1E1E) : Colors.white;
    Color corTexto = isEscuro ? Colors.white : Colors.black87;
    Color corTema = _nivelAcesso == 'Estaca' ? Colors.purple : Colors.teal;

    if (_carregandoPerfil) {
      return Scaffold(backgroundColor: Theme.of(context).scaffoldBackgroundColor, body: Center(child: CircularProgressIndicator(color: corTema)));
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false, 
        title: Text('Contatos da Liderança', style: TextStyle(fontWeight: FontWeight.bold, color: corTexto)), 
        backgroundColor: corFundo, elevation: 1
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('usuarios').orderBy('nome').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator(color: corTema));
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("Nenhum líder encontrado.", style: TextStyle(color: Colors.grey)));

          List<Map<String, dynamic>> lideres = snapshot.data!.docs.map((doc) => doc.data() as Map<String, dynamic>).where((lider) {
            String cargo = lider['cargo'] ?? '';
            String estaca = lider['estaca'] ?? '';

            if (_nivelAcesso == 'Estaca') {
              // Estaca vê a Hierarquia Geral e a sua própria Estaca
              if (cargo == 'Admin' || cargo == 'Conselho Geral') return true;
              return estaca == _minhaEstaca;
            } else {
              return true;
            }
          }).toList();

          if (_termoBusca.isNotEmpty) {
            lideres = lideres.where((l) => (l['nome'] ?? '').toLowerCase().contains(_termoBusca.toLowerCase())).toList();
          }

          // DIVISÃO DA HIERARQUIA
          List<Map<String, dynamic>> admins = [];
          List<Map<String, dynamic>> conselhoGeral = [];
          Map<String, Map<String, List<Map<String, dynamic>>>> arvoreEstacas = {};

          for (var lider in lideres) {
            String cargo = lider['cargo'] ?? '';
            String estaca = lider['estaca'] ?? 'Global';
            String unidade = lider['unidade'] ?? 'Global';

            if (cargo == 'Admin') {
              admins.add(lider);
            } else if (cargo == 'Conselho Geral') {
              conselhoGeral.add(lider);
            } else {
              arvoreEstacas.putIfAbsent(estaca, () => {});
              arvoreEstacas[estaca]!.putIfAbsent(unidade, () => []).add(lider);
            }
          }

          List<String> estacasOrdenadas = arvoreEstacas.keys.toList()..sort();

          return Column(
            children: [
              Container(
                color: corFundo, padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
                child: TextField(
                  style: TextStyle(color: corTexto), onChanged: (valor) => setState(() => _termoBusca = valor),
                  decoration: InputDecoration(hintText: "Pesquisar líder...", hintStyle: TextStyle(color: isEscuro ? Colors.white54 : Colors.grey), prefixIcon: Icon(Icons.search, color: isEscuro ? Colors.white54 : Colors.grey), filled: true, fillColor: isEscuro ? Colors.black26 : Colors.grey.shade100, contentPadding: const EdgeInsets.symmetric(vertical: 0), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // HIERARQUIA 1: ADMINISTRADORES
                    if (admins.isNotEmpty)
                      Card(
                        color: corFundo, margin: const EdgeInsets.only(bottom: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isEscuro ? Colors.white12 : Colors.grey.shade200)), elevation: 0,
                        child: Theme(
                          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            initiallyExpanded: true, iconColor: Colors.redAccent, collapsedIconColor: Colors.grey,
                            leading: CircleAvatar(backgroundColor: Colors.redAccent.withValues(alpha: 0.15), child: const Icon(Icons.security, color: Colors.redAccent)),
                            title: Text("Administração", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: corTexto)),
                            children: admins.map((lider) => _construirTileLider(lider, corTexto, isEscuro)).toList(),
                          ),
                        ),
                      ),

                    // HIERARQUIA 2: CONSELHO GERAL
                    if (conselhoGeral.isNotEmpty)
                      Card(
                        color: corFundo, margin: const EdgeInsets.only(bottom: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isEscuro ? Colors.white12 : Colors.grey.shade200)), elevation: 0,
                        child: Theme(
                          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            initiallyExpanded: true, iconColor: Colors.blue.shade700, collapsedIconColor: Colors.grey,
                            leading: CircleAvatar(backgroundColor: Colors.blue.shade700.withValues(alpha: 0.15), child: Icon(Icons.verified_user, color: Colors.blue.shade700)),
                            title: Text("Conselho Geral", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: corTexto)),
                            children: conselhoGeral.map((lider) => _construirTileLider(lider, corTexto, isEscuro)).toList(),
                          ),
                        ),
                      ),

                    // HIERARQUIA 3: ESTACAS E BISPOS LOCAIS
                    ...estacasOrdenadas.map((estaca) {
                      Map<String, List<Map<String, dynamic>>> alasDaEstaca = arvoreEstacas[estaca]!;
                      List<String> alasOrdenadas = alasDaEstaca.keys.toList()..sort();

                      return Card(
                        color: corFundo, margin: const EdgeInsets.only(bottom: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isEscuro ? Colors.white12 : Colors.grey.shade200)), elevation: 0,
                        child: Theme(
                          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            initiallyExpanded: _termoBusca.isNotEmpty, 
                            iconColor: corTema, collapsedIconColor: Colors.grey,
                            leading: CircleAvatar(backgroundColor: corTema.withValues(alpha: 0.15), child: Icon(Icons.map, color: corTema)),
                            title: Text(estaca, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: corTexto)),
                            children: alasOrdenadas.map((unidade) {
                              List<Map<String, dynamic>> lideresDaUnidade = alasDaEstaca[unidade]!;
                              return Padding(
                                padding: const EdgeInsets.only(left: 16.0),
                                child: ExpansionTile(
                                  initiallyExpanded: _termoBusca.isNotEmpty, 
                                  iconColor: Colors.orange, collapsedIconColor: Colors.grey, 
                                  leading: const Icon(Icons.church, color: Colors.orange),
                                  title: Text(unidade, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: corTexto)),
                                  children: lideresDaUnidade.map((lider) => _construirTileLider(lider, corTexto, isEscuro)).toList(),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          );
        }
      ),
    );
  }
}
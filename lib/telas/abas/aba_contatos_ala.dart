// ignore_for_file: empty_catches, unnecessary_cast

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AbaContatosAla extends StatefulWidget {
  const AbaContatosAla({super.key});

  @override
  State<AbaContatosAla> createState() => _AbaContatosAlaState();
}

class _AbaContatosAlaState extends State<AbaContatosAla> {
  String _termoBusca = '';
  String _minhaEstaca = "";
  String _minhaUnidade = "";
  String _meuUid = "";
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
        _meuUid = user.uid;
        var doc = await FirebaseFirestore.instance.collection('usuarios').doc(_meuUid).get();
        if (doc.exists && mounted) {
          var dados = doc.data() as Map<String, dynamic>? ?? {};
          setState(() {
            _minhaEstaca = dados['estaca'] ?? "";
            _minhaUnidade = dados['unidade'] ?? "";
            _carregandoPerfil = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _carregandoPerfil = false);
    }
  }

  Future<void> _abrirWhatsApp(String telefone) async {
    String numeroLimpo = telefone.replaceAll(RegExp(r'[^0-9]'), '');
    if (numeroLimpo.isEmpty) return;
    final Uri url = Uri.parse('https://wa.me/$numeroLimpo');
    try { await launchUrl(url, mode: LaunchMode.externalApplication); } catch (e) {}
  }

  Widget _construirTileContato(String nome, String subtitulo, String telefone, Color cor, IconData icone, bool isEscuro) {
    return Container(
      decoration: BoxDecoration(border: Border(top: BorderSide(color: isEscuro ? Colors.white12 : Colors.grey.shade100))),
      child: ListTile(
        contentPadding: const EdgeInsets.only(left: 20, right: 16, top: 4, bottom: 4),
        leading: CircleAvatar(backgroundColor: cor.withValues(alpha: 0.15), child: Icon(icone, color: cor, size: 20)),
        title: Text(nome, style: TextStyle(fontWeight: FontWeight.w600, color: isEscuro ? Colors.white : Colors.black87)),
        subtitle: Text(subtitulo, style: TextStyle(color: isEscuro ? Colors.white54 : Colors.grey, fontSize: 12)),
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

    if (_carregandoPerfil || _minhaEstaca.isEmpty) {
      return Scaffold(backgroundColor: Theme.of(context).scaffoldBackgroundColor, body: const Center(child: CircularProgressIndicator(color: Colors.blue)));
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false, 
        title: Text('Contatos da Rede', style: TextStyle(fontWeight: FontWeight.bold, color: corTexto)), 
        backgroundColor: corFundo, elevation: 1
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Primeira Stream: Busca os Líderes da Estaca
        stream: FirebaseFirestore.instance.collection('usuarios').where('estaca', isEqualTo: _minhaEstaca).snapshots(),
        builder: (context, snapshotLideres) {
          if (!snapshotLideres.hasData) return const Center(child: CircularProgressIndicator(color: Colors.blue));

          return StreamBuilder<QuerySnapshot>(
            // Segunda Stream: Busca os Jovens da Ala
            stream: FirebaseFirestore.instance.collection('jovens').where('unidade', isEqualTo: _minhaUnidade).snapshots(),
            builder: (context, snapshotJovens) {
              if (!snapshotJovens.hasData) return const Center(child: CircularProgressIndicator(color: Colors.blue));

              // Processa os Líderes
              List<Map<String, dynamic>> presidenciaEstaca = [];
              List<Map<String, dynamic>> outrosBispos = [];

              for (var doc in snapshotLideres.data!.docs) {
                if (doc.id == _meuUid) continue; // Remove a própria pessoa da lista
                var dados = doc.data() as Map<String, dynamic>;
                String cargo = dados['cargo'] ?? '';

                if (cargo == 'Pres. de Estaca') {
                  presidenciaEstaca.add(dados);
                } else if (cargo == 'Bispo' || cargo == 'Pres. de Ramo') {
                  outrosBispos.add(dados);
                }
              }

              // Processa os Jovens
              List<Map<String, dynamic>> jovensDaAla = snapshotJovens.data!.docs.map((d) => d.data() as Map<String, dynamic>).toList();

              // Aplica o filtro de busca
              if (_termoBusca.isNotEmpty) {
                String termo = _termoBusca.toLowerCase();
                presidenciaEstaca = presidenciaEstaca.where((l) => (l['nome'] ?? '').toLowerCase().contains(termo)).toList();
                outrosBispos = outrosBispos.where((l) => (l['nome'] ?? '').toLowerCase().contains(termo)).toList();
                jovensDaAla = jovensDaAla.where((j) => (j['nome'] ?? '').toLowerCase().contains(termo)).toList();
              }

              // Ordena os jovens por nome
              jovensDaAla.sort((a, b) => (a['nome'] ?? '').compareTo(b['nome'] ?? ''));
              outrosBispos.sort((a, b) => (a['unidade'] ?? '').compareTo(b['unidade'] ?? ''));

              return Column(
                children: [
                  Container(
                    color: corFundo, padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
                    child: TextField(
                      style: TextStyle(color: corTexto), onChanged: (valor) => setState(() => _termoBusca = valor),
                      decoration: InputDecoration(hintText: "Pesquisar nome...", hintStyle: TextStyle(color: isEscuro ? Colors.white54 : Colors.grey), prefixIcon: Icon(Icons.search, color: isEscuro ? Colors.white54 : Colors.grey), filled: true, fillColor: isEscuro ? Colors.black26 : Colors.grey.shade100, contentPadding: const EdgeInsets.symmetric(vertical: 0), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // BLOCO 1: PRESIDÊNCIA DA ESTACA (Expostos Diretamente)
                        if (presidenciaEstaca.isNotEmpty) ...[
                          Text("Presidência da Estaca", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
                          const SizedBox(height: 8),
                          Card(
                            color: corFundo, margin: const EdgeInsets.only(bottom: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isEscuro ? Colors.white12 : Colors.grey.shade200)), elevation: 0,
                            child: Column(
                              children: presidenciaEstaca.map((lider) => _construirTileContato(lider['nome'] ?? '', lider['cargo'] ?? '', lider['whatsapp'] ?? '', Colors.purple, Icons.admin_panel_settings, isEscuro)).toList(),
                            ),
                          ),
                        ],

                        // BLOCO 2: OUTROS BISPOS (Gaveta)
                        if (outrosBispos.isNotEmpty) ...[
                          Card(
                            color: corFundo, margin: const EdgeInsets.only(bottom: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isEscuro ? Colors.white12 : Colors.grey.shade200)), elevation: 0,
                            child: Theme(
                              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                              child: ExpansionTile(
                                iconColor: Colors.orange, collapsedIconColor: Colors.grey,
                                leading: CircleAvatar(backgroundColor: Colors.orange.withValues(alpha: 0.15), child: const Icon(Icons.church, color: Colors.orange)),
                                title: Text("Outros Bispos da Estaca", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: corTexto)),
                                children: outrosBispos.map((lider) => _construirTileContato(lider['nome'] ?? '', "${lider['cargo']} - ${lider['unidade']}", lider['whatsapp'] ?? '', Colors.orange, Icons.person, isEscuro)).toList(),
                              ),
                            ),
                          ),
                        ],

                        // BLOCO 3: JOVENS DA ALA (Expostos Diretamente)
                        if (jovensDaAla.isNotEmpty) ...[
                          Text("Jovens em Processo", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
                          const SizedBox(height: 8),
                          Card(
                            color: corFundo, margin: const EdgeInsets.only(bottom: 80), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isEscuro ? Colors.white12 : Colors.grey.shade200)), elevation: 0,
                            child: Column(
                              children: jovensDaAla.map((jovem) {
                                Color corStatus = Colors.blue;
                                if (jovem['status'] == 'Perspectiva') corStatus = Colors.orange;
                                if (jovem['status'] == 'Enviado') corStatus = Colors.green;
                                return _construirTileContato(jovem['nome'] ?? '', "Status: ${jovem['status']}", jovem['telefone'] ?? '', corStatus, Icons.person_outline, isEscuro);
                              }).toList(),
                            ),
                          ),
                        ] else if (_termoBusca.isEmpty) ...[
                           Padding(padding: const EdgeInsets.all(20), child: Center(child: Text("Sua ala ainda não possui jovens cadastrados.", style: TextStyle(color: Colors.grey.shade500))))
                        ],
                      ],
                    ),
                  ),
                ],
              );
            }
          );
        }
      ),
    );
  }
}
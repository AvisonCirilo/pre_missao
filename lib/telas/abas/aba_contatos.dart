import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class AbaContatosGestor extends StatefulWidget {
  const AbaContatosGestor({super.key});

  @override
  State<AbaContatosGestor> createState() => _AbaContatosGestorState();
}

class _AbaContatosGestorState extends State<AbaContatosGestor> {
  String _termoBusca = '';

  Future<void> _abrirWhatsApp(String telefone, String nomeLider) async {
    String numeroLimpo = telefone.replaceAll(RegExp(r'[^0-9]'), '');
    if (numeroLimpo.isEmpty) return;
    String mensagem = "Olá, $nomeLider! Tudo bem? Sou do conselho geral e gostaria de falar com você sobre a preparação dos nossos jovens.";
    final Uri url = Uri.parse('https://wa.me/$numeroLimpo?text=${Uri.encodeComponent(mensagem)}');
    try { await launchUrl(url, mode: LaunchMode.externalApplication); } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    bool isEscuro = Theme.of(context).brightness == Brightness.dark;
    Color corFundo = isEscuro ? const Color(0xFF1E1E1E) : Colors.white;
    Color corTexto = isEscuro ? Colors.white : Colors.black87;

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
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.teal));
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("Nenhum líder encontrado.", style: TextStyle(color: Colors.grey)));

          List<Map<String, dynamic>> lideres = snapshot.data!.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();

          // Filtro de Busca
          if (_termoBusca.isNotEmpty) {
            lideres = lideres.where((l) => (l['nome'] ?? '').toLowerCase().contains(_termoBusca.toLowerCase())).toList();
          }

          // Monta a Árvore de Contatos: Estaca > Unidade > Lider
          Map<String, Map<String, List<Map<String, dynamic>>>> arvoreContatos = {};
          for (var lider in lideres) {
            if (lider['cargo'] == 'Admin') continue; // Esconde os administradores de TI da lista
            String estaca = lider['estaca'] ?? 'Global';
            String unidade = lider['unidade'] ?? 'Global';
            arvoreContatos.putIfAbsent(estaca, () => {});
            arvoreContatos[estaca]!.putIfAbsent(unidade, () => []).add(lider);
          }
          List<String> estacasOrdenadas = arvoreContatos.keys.toList()..sort();

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
                child: arvoreContatos.isEmpty
                  ? Center(child: Text("Nenhum líder encontrado.", style: TextStyle(color: Colors.grey.shade500)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16), itemCount: estacasOrdenadas.length,
                      itemBuilder: (context, indexEstaca) {
                        String estaca = estacasOrdenadas[indexEstaca];
                        Map<String, List<Map<String, dynamic>>> alasDaEstaca = arvoreContatos[estaca]!;
                        List<String> alasOrdenadas = alasDaEstaca.keys.toList()..sort();
                        
                        return Card(
                          color: corFundo, margin: const EdgeInsets.only(bottom: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isEscuro ? Colors.white12 : Colors.grey.shade200)), elevation: 0,
                          child: Theme(
                            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                            child: ExpansionTile(
                              initiallyExpanded: _termoBusca.isNotEmpty, iconColor: Colors.teal, collapsedIconColor: Colors.grey,
                              leading: CircleAvatar(backgroundColor: Colors.teal.withValues(alpha: 0.15), child: const Icon(Icons.map, color: Colors.teal)),
                              title: Text(estaca, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: corTexto)),
                              children: alasOrdenadas.map((unidade) {
                                List<Map<String, dynamic>> lideresDaUnidade = alasDaEstaca[unidade]!;
                                return Padding(
                                  padding: const EdgeInsets.only(left: 16.0),
                                  child: ExpansionTile(
                                    initiallyExpanded: _termoBusca.isNotEmpty, iconColor: Colors.orange, collapsedIconColor: Colors.grey, leading: const Icon(Icons.church, color: Colors.orange),
                                    title: Text(unidade, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: corTexto)),
                                    children: lideresDaUnidade.map((lider) {
                                      String telefone = lider['whatsapp'] ?? '';
                                      return Container(
                                        decoration: BoxDecoration(border: Border(top: BorderSide(color: isEscuro ? Colors.white12 : Colors.grey.shade100))),
                                        child: ListTile(
                                          contentPadding: const EdgeInsets.only(left: 32, right: 16, top: 4, bottom: 4),
                                          leading: const Icon(Icons.person, color: Colors.grey, size: 20),
                                          title: Text(lider['nome'] ?? '', style: TextStyle(fontWeight: FontWeight.w600, color: corTexto)),
                                          subtitle: Text(lider['cargo'] ?? 'Líder', style: TextStyle(color: isEscuro ? Colors.white54 : Colors.grey, fontSize: 12)),
                                          trailing: telefone.isNotEmpty 
                                            ? IconButton(icon: const Icon(Icons.chat, color: Colors.green), onPressed: () => _abrirWhatsApp(telefone, lider['nome']))
                                            : const Icon(Icons.phone_disabled, color: Colors.grey, size: 18),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        );
                      },
                    ),
              ),
            ],
          );
        }
      ),
    );
  }
}
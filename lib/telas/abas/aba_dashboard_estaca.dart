import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AbaDashboardEstaca extends StatefulWidget {
  const AbaDashboardEstaca({super.key});

  @override
  State<AbaDashboardEstaca> createState() => _AbaDashboardEstacaState();
}

class _AbaDashboardEstacaState extends State<AbaDashboardEstaca> {
  final String _minhaEstaca = "Estaca Norte";
  final List<String> _alasDaEstaca = ["Ala Centro", "Ala Sul", "Ala Norte"];

  // Banco de Dados simulado unificado
  final List<Map<String, dynamic>> _todosJovens = [
    {'id': '1', 'nome': 'João Silva', 'idade': 19, 'sexo': 'Masculino', 'unidade': 'Ala Centro', 'status': 'Preparação', 'telefone': '5591900000000', 'etapas': <bool>[true, true, true, false, false, false, false, false], 'ultima_atualizacao': DateTime.now().subtract(const Duration(days: 40)), 'anotacoes': []},
    {'id': '2', 'nome': 'Ana Beatriz', 'idade': 18, 'sexo': 'Feminino', 'unidade': 'Ala Sul', 'status': 'Preparação', 'telefone': '5591900000000', 'etapas': <bool>[true, true, false, false, false, false, false], 'ultima_atualizacao': DateTime.now().subtract(const Duration(days: 5)), 'anotacoes': []},
    {'id': '3', 'nome': 'Lucas Souza', 'idade': 17, 'sexo': 'Masculino', 'unidade': 'Ala Centro', 'status': 'Perspectiva', 'telefone': '', 'etapas': <bool>[false, false, false, false, false, false, false, false], 'ultima_atualizacao': DateTime.now(), 'anotacoes': []},
    {'id': '5', 'nome': 'Julia Costa', 'idade': 19, 'sexo': 'Feminino', 'unidade': 'Ala Sul', 'status': 'Enviado', 'telefone': '5591900000000', 'etapas': <bool>[true, true, true, true, true, true, true], 'ultima_atualizacao': DateTime.now(), 'anotacoes': []},
  ];

  final List<String> _nomesEtapasRapazes = ["Aceitou o Desafio", "Ensino Médio", "Alistamento Militar", "Possui Mentor", "Metas com Bispo", "Exame Médico", "Exame Odonto", "Chamado Aberto"];
  final List<String> _nomesEtapasMocas = ["Aceitou o Desafio", "Ensino Médio", "Possui Mentor", "Metas com Bispo", "Exame Médico", "Exame Odonto", "Chamado Aberto"];

  String _termoBusca = '';

  Map<String, dynamic> _obterEstiloStatus(String status) {
    switch (status) {
      case 'Perspectiva': return {'cor': Colors.orange, 'icone': Icons.radar};
      case 'Preparação': return {'cor': Colors.blue, 'icone': Icons.assignment_ind};
      case 'Enviado': return {'cor': Colors.green, 'icone': Icons.check_circle};
      default: return {'cor': Colors.grey, 'icone': Icons.help};
    }
  }

  double _calcularProgresso(List<dynamic> etapas, String sexo) {
    if (etapas.isEmpty) return 0.0;
    int concluidas = etapas.where((etapa) => etapa == true).length;
    int total = sexo == 'Masculino' ? _nomesEtapasRapazes.length : _nomesEtapasMocas.length;
    return concluidas / total;
  }

  Widget _construirCartaoDashboard(String titulo, String valor, Color cor, IconData icone, bool isEscuro) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(color: isEscuro ? const Color(0xFF1E1E1E) : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: isEscuro ? Colors.white12 : Colors.grey.shade200), boxShadow: [BoxShadow(color: cor.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))]),
        child: Column(
          children: [
            Icon(icone, color: cor, size: 28), const SizedBox(height: 8),
            Text(valor, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isEscuro ? Colors.white : Colors.black)),
            const SizedBox(height: 4),
            Text(titulo, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // CRIAÇÃO E EDIÇÃO PELO LÍDER DA ESTACA
  // ==========================================
  void _mostrarFormularioJovem({Map<String, dynamic>? jovemAtual}) {
    bool isEdicao = jovemAtual != null;
    bool isEscuro = Theme.of(context).brightness == Brightness.dark;
    
    final nomeCtrl = TextEditingController(text: isEdicao ? jovemAtual['nome'] : "");
    final idadeCtrl = TextEditingController(text: isEdicao ? jovemAtual['idade'].toString() : "");
    final telefoneCtrl = TextEditingController(text: isEdicao ? jovemAtual['telefone'] : ""); 
    String sexoSelecionado = isEdicao ? jovemAtual['sexo'] : "Masculino";
    String unidadeSelecionada = isEdicao ? jovemAtual['unidade'] : _alasDaEstaca[0];

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateModal) {
          return Container(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 24, left: 24, right: 24, top: 24),
            decoration: BoxDecoration(color: isEscuro ? const Color(0xFF1E1E1E) : Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(25))),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: isEscuro ? Colors.white24 : Colors.grey.shade400, borderRadius: BorderRadius.circular(10))),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(isEdicao ? Icons.edit : Icons.person_add, color: Colors.purple),
                    const SizedBox(width: 10),
                    Text(isEdicao ? "Editar Jovem" : "Novo Jovem", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isEscuro ? Colors.white : Colors.black)),
                  ],
                ),
                const SizedBox(height: 25),

                // UNIDADE (A Estaca precisa escolher a qual Ala o jovem pertence)
                DropdownButtonFormField<String>(
                  value: unidadeSelecionada, dropdownColor: isEscuro ? const Color(0xFF1E1E1E) : Colors.white,
                  style: TextStyle(color: isEscuro ? Colors.white : Colors.black87),
                  decoration: InputDecoration(labelText: "Ala / Ramo", labelStyle: TextStyle(color: isEscuro ? Colors.white70 : Colors.grey.shade700), prefixIcon: Icon(Icons.church, color: isEscuro ? Colors.white70 : Colors.grey.shade600), filled: true, fillColor: isEscuro ? Colors.black26 : Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                  items: _alasDaEstaca.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (val) => setStateModal(() => unidadeSelecionada = val!),
                ),
                const SizedBox(height: 15),

                TextField(
                  controller: nomeCtrl, style: TextStyle(color: isEscuro ? Colors.white : Colors.black87),
                  decoration: InputDecoration(labelText: "Nome do Jovem", labelStyle: TextStyle(color: isEscuro ? Colors.white70 : Colors.grey.shade700), prefixIcon: Icon(Icons.person, color: isEscuro ? Colors.white70 : Colors.grey.shade600), filled: true, fillColor: isEscuro ? Colors.black26 : Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(flex: 2, child: TextField(controller: idadeCtrl, style: TextStyle(color: isEscuro ? Colors.white : Colors.black87), keyboardType: TextInputType.number, decoration: InputDecoration(labelText: "Idade", labelStyle: TextStyle(color: isEscuro ? Colors.white70 : Colors.grey.shade700), prefixIcon: Icon(Icons.cake, color: isEscuro ? Colors.white70 : Colors.grey.shade600), filled: true, fillColor: isEscuro ? Colors.black26 : Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)))),
                    const SizedBox(width: 15),
                    Expanded(flex: 3, child: DropdownButtonFormField<String>(
                      value: sexoSelecionado, dropdownColor: isEscuro ? const Color(0xFF1E1E1E) : Colors.white,
                      style: TextStyle(color: isEscuro ? Colors.white : Colors.black87),
                      decoration: InputDecoration(filled: true, fillColor: isEscuro ? Colors.black26 : Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                      items: ["Masculino", "Feminino"].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (val) => setStateModal(() => sexoSelecionado = val!),
                    )),
                  ],
                ),
                const SizedBox(height: 15),
                TextField(controller: telefoneCtrl, style: TextStyle(color: isEscuro ? Colors.white : Colors.black87), keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: "WhatsApp", labelStyle: TextStyle(color: isEscuro ? Colors.white70 : Colors.grey.shade700), prefixIcon: Icon(Icons.phone, color: isEscuro ? Colors.white70 : Colors.grey.shade600), filled: true, fillColor: isEscuro ? Colors.black26 : Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity, height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: () {
                      if (nomeCtrl.text.trim().isEmpty) return;
                      setState(() {
                        if (isEdicao) {
                          jovemAtual['nome'] = nomeCtrl.text.trim();
                          jovemAtual['idade'] = int.tryParse(idadeCtrl.text) ?? 0;
                          jovemAtual['telefone'] = telefoneCtrl.text.trim();
                          jovemAtual['unidade'] = unidadeSelecionada;
                          if (jovemAtual['sexo'] != sexoSelecionado) {
                            jovemAtual['sexo'] = sexoSelecionado;
                            int totalEtapas = sexoSelecionado == 'Masculino' ? _nomesEtapasRapazes.length : _nomesEtapasMocas.length;
                            jovemAtual['etapas'] = List.generate(totalEtapas, (index) => false);
                            jovemAtual['status'] = 'Perspectiva';
                          }
                        } else {
                          int totalEtapas = sexoSelecionado == 'Masculino' ? _nomesEtapasRapazes.length : _nomesEtapasMocas.length;
                          _todosJovens.add({'id': DateTime.now().millisecondsSinceEpoch.toString(), 'nome': nomeCtrl.text.trim(), 'idade': int.tryParse(idadeCtrl.text) ?? 0, 'sexo': sexoSelecionado, 'unidade': unidadeSelecionada, 'status': 'Perspectiva', 'telefone': telefoneCtrl.text.trim(), 'etapas': List.generate(totalEtapas, (index) => false), 'ultima_atualizacao': DateTime.now(), 'anotacoes': []});
                        }
                      });
                      Navigator.pop(context); 
                    },
                    icon: const Icon(Icons.save),
                    label: Text(isEdicao ? "Salvar" : "Criar Jovem", style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  // ==========================================
  // DETALHES E CHECKLIST (AGORA EDITÁVEL)
  // ==========================================
  void _abrirDetalhesJovem(Map<String, dynamic> jovem) {
    bool isEscuro = Theme.of(context).brightness == Brightness.dark;
    List<bool> etapasTemp = List<bool>.from(jovem['etapas']); 
    List<String> listaEtapas = jovem['sexo'] == 'Masculino' ? _nomesEtapasRapazes : _nomesEtapasMocas;
    final estilo = _obterEstiloStatus(jovem['status']);
    TextEditingController notaCtrl = TextEditingController();

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateModal) {
          double progressoModal = _calcularProgresso(etapasTemp, jovem['sexo']);
          List<dynamic> notas = jovem['anotacoes'] ?? [];

          return Container(
            height: MediaQuery.of(context).size.height * 0.9,
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 16, left: 24, right: 24, top: 16),
            decoration: BoxDecoration(color: isEscuro ? const Color(0xFF1E1E1E) : Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(25))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: isEscuro ? Colors.white24 : Colors.grey.shade400, borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 20),
                Row(
                  children: [
                    CircleAvatar(radius: 25, backgroundColor: estilo['cor'].withValues(alpha: 0.15), child: Icon(estilo['icone'], color: estilo['cor'])),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(jovem['nome'], style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isEscuro ? Colors.white : Colors.black), overflow: TextOverflow.ellipsis),
                          Text("${jovem['unidade']} • ${jovem['idade']} anos", style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.edit, color: Colors.grey), onPressed: () { Navigator.pop(context); _mostrarFormularioJovem(jovemAtual: jovem); }),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(height: 45, width: 45, child: CircularProgressIndicator(value: progressoModal, backgroundColor: isEscuro ? Colors.white12 : Colors.grey.shade200, color: estilo['cor'], strokeWidth: 4)),
                        Text("${(progressoModal * 100).toInt()}%", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isEscuro ? Colors.white : Colors.black)),
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 15),
                Expanded(
                  child: DefaultTabController(
                    length: 2,
                    child: Column(
                      children: [
                        const TabBar(
                          labelColor: Colors.purple, unselectedLabelColor: Colors.grey, indicatorColor: Colors.purple,
                          tabs: [Tab(text: "Checklist"), Tab(text: "Anotações")],
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              ListView.builder(
                                padding: const EdgeInsets.only(top: 10), itemCount: listaEtapas.length,
                                itemBuilder: (context, index) {
                                  return CheckboxListTile(
                                    title: Text(listaEtapas[index], style: TextStyle(fontWeight: etapasTemp[index] ? FontWeight.normal : FontWeight.bold, decoration: etapasTemp[index] ? TextDecoration.lineThrough : null, color: etapasTemp[index] ? Colors.grey : (isEscuro ? Colors.white : Colors.black87))),
                                    value: etapasTemp[index], activeColor: Colors.purple, checkColor: Colors.white, side: BorderSide(color: isEscuro ? Colors.grey.shade400 : Colors.grey.shade700),
                                    onChanged: (bool? valor) => setStateModal(() => etapasTemp[index] = valor ?? false),
                                  );
                                },
                              ),
                              Column(
                                children: [
                                  Expanded(
                                    child: notas.isEmpty 
                                      ? const Center(child: Text("Nenhuma anotação ainda.", style: TextStyle(color: Colors.grey)))
                                      : ListView.builder(
                                          padding: const EdgeInsets.only(top: 10), itemCount: notas.length,
                                          itemBuilder: (context, index) {
                                            var nota = notas[notas.length - 1 - index];
                                            return Card(
                                              color: isEscuro ? Colors.black26 : Colors.grey.shade50, elevation: 0, margin: const EdgeInsets.only(bottom: 8),
                                              child: Padding(
                                                padding: const EdgeInsets.all(12.0),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(nota['autor'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.purple.shade300)), Text(nota['data'], style: const TextStyle(fontSize: 10, color: Colors.grey))]),
                                                    const SizedBox(height: 4),
                                                    Text(nota['texto'], style: TextStyle(color: isEscuro ? Colors.white70 : Colors.black87, fontSize: 14)),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                  ),
                                  Row(
                                    children: [
                                      Expanded(child: TextField(controller: notaCtrl, style: TextStyle(color: isEscuro ? Colors.white : Colors.black87), decoration: InputDecoration(hintText: "Deixar uma nota...", hintStyle: const TextStyle(color: Colors.grey), filled: true, fillColor: isEscuro ? Colors.black26 : Colors.grey.shade100, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none)))),
                                      const SizedBox(width: 8),
                                      CircleAvatar(backgroundColor: Colors.purple, child: IconButton(icon: const Icon(Icons.send, color: Colors.white, size: 18), onPressed: () {
                                        if(notaCtrl.text.trim().isEmpty) return;
                                        setStateModal(() {
                                          notas.add({'data': "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}", 'autor': 'Pres. de Estaca', 'texto': notaCtrl.text.trim()});
                                          notaCtrl.clear();
                                        });
                                      }))
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(child: OutlinedButton.icon(onPressed: jovem['telefone'].toString().isEmpty ? null : () async {
                      String numero = jovem['telefone'].replaceAll(RegExp(r'[^0-9]'), '');
                      final Uri url = Uri.parse('https://wa.me/$numero?text=${Uri.encodeComponent("Olá, ${jovem['nome']}! Sou da presidência da estaca e estou acompanhando seu processo.")}');
                      try { await launchUrl(url, mode: LaunchMode.externalApplication); } catch(e){}
                    }, icon: const Icon(Icons.chat, color: Colors.green), label: const Text("WhatsApp", style: TextStyle(color: Colors.green)), style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.green), padding: const EdgeInsets.symmetric(vertical: 14)))),
                    const SizedBox(width: 10),
                    Expanded(child: ElevatedButton.icon(onPressed: () {
                      setState(() {
                        jovem['etapas'] = List<bool>.from(etapasTemp);
                        jovem['anotacoes'] = notas;
                        jovem['ultima_atualizacao'] = DateTime.now();
                        
                        double progFinal = _calcularProgresso(jovem['etapas'], jovem['sexo']);
                        if (progFinal == 1.0) {
                          jovem['status'] = 'Enviado';
                        } else if (progFinal > 0.0) {
                          jovem['status'] = 'Preparação';
                        }
                      });
                      Navigator.pop(context);
                    }, icon: const Icon(Icons.save), label: const Text("Salvar"), style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)))),
                  ],
                )
              ],
            ),
          );
        });
      }
    );
  }

  void _iniciarPreparacao(Map<String, dynamic> jovem) {
    setState(() {
      jovem['status'] = 'Preparação';
      jovem['ultima_atualizacao'] = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isEscuro = Theme.of(context).brightness == Brightness.dark;
    Color corFundo = isEscuro ? const Color(0xFF1E1E1E) : Colors.white;
    Color corTexto = isEscuro ? Colors.white : Colors.black87;

    List<Map<String, dynamic>> jovensFiltrados = _todosJovens.where((jovem) => jovem['nome'].toLowerCase().contains(_termoBusca.toLowerCase())).toList();

    int totalPerspectiva = _todosJovens.where((j) => j['status'] == 'Perspectiva').length;
    int totalPreparacao = _todosJovens.where((j) => j['status'] == 'Preparação').length;
    int totalEnviados = _todosJovens.where((j) => j['status'] == 'Enviado').length;

    Map<String, List<Map<String, dynamic>>> arvoreJovens = {};
    for (var jovem in jovensFiltrados) {
      arvoreJovens.putIfAbsent(jovem['unidade'], () => []).add(jovem);
    }
    List<String> unidadesOrdenadas = arvoreJovens.keys.toList()..sort();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(automaticallyImplyLeading: false, title: Text('Painel $_minhaEstaca', style: TextStyle(fontWeight: FontWeight.bold, color: corTexto)), backgroundColor: corFundo, elevation: 1),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarFormularioJovem(),
        backgroundColor: Colors.purple, foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add), label: const Text("Criar Jovem", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // DASHBOARD TOPO
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                _construirCartaoDashboard("Perspectiva", totalPerspectiva.toString(), Colors.orange, Icons.radar, isEscuro),
                const SizedBox(width: 10),
                _construirCartaoDashboard("Abertos", totalPreparacao.toString(), Colors.blue, Icons.assignment_ind, isEscuro),
                const SizedBox(width: 10),
                _construirCartaoDashboard("Enviados", totalEnviados.toString(), Colors.green, Icons.check_circle, isEscuro),
              ],
            ),
          ),

          Container(
            color: corFundo, padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: TextField(
              style: TextStyle(color: corTexto), onChanged: (valor) => setState(() => _termoBusca = valor),
              decoration: InputDecoration(hintText: "Pesquisar jovem na estaca...", hintStyle: TextStyle(color: isEscuro ? Colors.white54 : Colors.grey), prefixIcon: Icon(Icons.search, color: isEscuro ? Colors.white54 : Colors.grey), filled: true, fillColor: isEscuro ? Colors.black26 : Colors.grey.shade100, contentPadding: const EdgeInsets.symmetric(vertical: 0), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
            ),
          ),
          
          Expanded(
            child: arvoreJovens.isEmpty
                ? Center(child: Text("Nenhum jovem encontrado.", style: TextStyle(color: Colors.grey.shade500)))
                : ListView.builder(
                    padding: const EdgeInsets.all(16), itemCount: unidadesOrdenadas.length,
                    itemBuilder: (context, index) {
                      String unidade = unidadesOrdenadas[index];
                      List<Map<String, dynamic>> jovensDaUnidade = arvoreJovens[unidade]!;

                      return Card(
                        color: corFundo, margin: const EdgeInsets.only(bottom: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isEscuro ? Colors.white12 : Colors.grey.shade200)), elevation: 0,
                        child: Theme(
                          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            initiallyExpanded: _termoBusca.isNotEmpty, iconColor: Colors.orange, collapsedIconColor: Colors.grey, leading: const Icon(Icons.church, color: Colors.orange),
                            title: Text(unidade, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: corTexto)), subtitle: Text("${jovensDaUnidade.length} jovem(ns)", style: TextStyle(color: isEscuro ? Colors.white54 : Colors.grey, fontSize: 12)),
                            children: jovensDaUnidade.map((jovem) {
                              final estilo = _obterEstiloStatus(jovem['status']);
                              return Container(
                                decoration: BoxDecoration(border: Border(top: BorderSide(color: isEscuro ? Colors.white12 : Colors.grey.shade100))),
                                child: ListTile(
                                  onTap: () => _abrirDetalhesJovem(jovem),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                                  leading: Icon(estilo['icone'], color: estilo['cor'], size: 20),
                                  title: Text(jovem['nome'], style: TextStyle(fontWeight: FontWeight.w600, color: corTexto)),
                                  subtitle: Text("${jovem['idade']} anos", style: TextStyle(color: isEscuro ? Colors.white54 : Colors.grey, fontSize: 12)),
                                  trailing: jovem['status'] == 'Perspectiva' 
                                    ? OutlinedButton(style: OutlinedButton.styleFrom(foregroundColor: Colors.orange, side: const BorderSide(color: Colors.orange), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), onPressed: () => _iniciarPreparacao(jovem), child: const Text("Iniciar", style: TextStyle(fontSize: 10)))
                                    : Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: estilo['cor'].withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Text(jovem['status'], style: TextStyle(fontSize: 10, color: estilo['cor'], fontWeight: FontWeight.bold))),
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
      ),
    );
  }
}
import 'package:flutter/material.dart';

class ListaGlobalJovensTela extends StatefulWidget {
  const ListaGlobalJovensTela({super.key});

  @override
  State<ListaGlobalJovensTela> createState() => _ListaGlobalJovensTelaState();
}

class _ListaGlobalJovensTelaState extends State<ListaGlobalJovensTela> {
  final List<Map<String, dynamic>> _todosJovens = [
    {'id': '1', 'nome': 'João Silva', 'idade': 19, 'sexo': 'Masculino', 'estaca': 'Estaca Norte', 'unidade': 'Ala Centro', 'status': 'Preparação', 'telefone': '5591900000000', 'etapas': <bool>[true, true, true, false, false, false, false, false], 'ultima_atualizacao': DateTime.now().subtract(const Duration(days: 40)), 'anotacoes': []},
    {'id': '2', 'nome': 'Ana Beatriz', 'idade': 18, 'sexo': 'Feminino', 'estaca': 'Estaca Norte', 'unidade': 'Ala Sul', 'status': 'Preparação', 'telefone': '5591900000000', 'etapas': <bool>[true, true, false, false, false, false, false], 'ultima_atualizacao': DateTime.now().subtract(const Duration(days: 5)), 'anotacoes': []},
    {'id': '3', 'nome': 'Lucas Souza', 'idade': 17, 'sexo': 'Masculino', 'estaca': 'Estaca Norte', 'unidade': 'Ala Centro', 'status': 'Perspectiva', 'telefone': '', 'etapas': <bool>[false, false, false, false, false, false, false, false], 'ultima_atualizacao': DateTime.now(), 'anotacoes': []},
    {'id': '4', 'nome': 'Marcos Paulo', 'idade': 20, 'sexo': 'Masculino', 'estaca': 'Distrito Sul', 'unidade': 'Ramo Leste', 'status': 'Enviado', 'telefone': '5591900000000', 'etapas': <bool>[true, true, true, true, true, true, true, true], 'ultima_atualizacao': DateTime.now(), 'anotacoes': []},
    {'id': '6', 'nome': 'Pedro Henrique', 'idade': 18, 'sexo': 'Masculino', 'estaca': 'Distrito Sul', 'unidade': 'Ramo Oeste', 'status': 'Preparação', 'telefone': '5591900000000', 'etapas': <bool>[true, false, false, false, false, false, false, false], 'ultima_atualizacao': DateTime.now().subtract(const Duration(days: 60)), 'anotacoes': []},
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
    int concluidas = etapas.where((etapa) => etapa == true).length;
    int total = sexo == 'Masculino' ? _nomesEtapasRapazes.length : _nomesEtapasMocas.length;
    return concluidas / total;
  }

  Widget _construirAlertaEstagnacao(DateTime? ultimaAtualizacao) {
    if (ultimaAtualizacao == null) return const SizedBox.shrink();
    int dias = DateTime.now().difference(ultimaAtualizacao).inDays;
    if (dias > 30) {
      return Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.red.withValues(alpha: 0.5))),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 10, color: Colors.red),
            const SizedBox(width: 4),
            Text("Estagnado: $dias dias", style: const TextStyle(fontSize: 9, color: Colors.red, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  // NOVO: Cálculo dos Gargalos
  List<Map<String, dynamic>> _calcularGargalos() {
    Map<String, int> contagemEtapas = {};
    int totalPreparacao = 0;

    for (var jovem in _todosJovens) {
      if (jovem['status'] == 'Preparação') {
        totalPreparacao++;
        List<bool> etapas = jovem['etapas'];
        List<String> nomesEtapas = jovem['sexo'] == 'Masculino' ? _nomesEtapasRapazes : _nomesEtapasMocas;
        int indexPrimeiroFalso = etapas.indexOf(false);
        if (indexPrimeiroFalso != -1) {
          String etapaPendente = nomesEtapas[indexPrimeiroFalso];
          contagemEtapas[etapaPendente] = (contagemEtapas[etapaPendente] ?? 0) + 1;
        }
      }
    }

    if (totalPreparacao == 0) return [];
    
    var listaOrdenada = contagemEtapas.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value)); // Maior pro menor

    return listaOrdenada.take(3).map((e) => {
      'etapa': e.key,
      'quantidade': e.value,
      'porcentagem': e.value / totalPreparacao
    }).toList();
  }

  void _abrirDetalhesJovem(Map<String, dynamic> jovem) {
    bool isEscuro = Theme.of(context).brightness == Brightness.dark;
    List<bool> etapas = List<bool>.from(jovem['etapas']); 
    List<String> listaEtapas = jovem['sexo'] == 'Masculino' ? _nomesEtapasRapazes : _nomesEtapasMocas;
    double progressoAtual = _calcularProgresso(etapas, jovem['sexo']);
    final estilo = _obterEstiloStatus(jovem['status']);
    TextEditingController notaCtrl = TextEditingController();

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateModal) {
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
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(height: 45, width: 45, child: CircularProgressIndicator(value: progressoAtual, backgroundColor: isEscuro ? Colors.white12 : Colors.grey.shade200, color: estilo['cor'], strokeWidth: 4)),
                        Text("${(progressoAtual * 100).toInt()}%", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isEscuro ? Colors.white : Colors.black)),
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
                          labelColor: Colors.blue, unselectedLabelColor: Colors.grey, indicatorColor: Colors.blue,
                          tabs: [Tab(text: "Checklist"), Tab(text: "Anotações")],
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              ListView.builder(
                                padding: const EdgeInsets.only(top: 10), itemCount: listaEtapas.length,
                                itemBuilder: (context, index) {
                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: Icon(etapas[index] ? Icons.check_circle : Icons.radio_button_unchecked, color: etapas[index] ? Colors.green : Colors.grey.shade400),
                                    title: Text(listaEtapas[index], style: TextStyle(fontWeight: etapas[index] ? FontWeight.normal : FontWeight.w500, decoration: etapas[index] ? TextDecoration.lineThrough : null, color: etapas[index] ? Colors.grey : (isEscuro ? Colors.white : Colors.black87))),
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
                                                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(nota['autor'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blue.shade700)), Text(nota['data'], style: const TextStyle(fontSize: 10, color: Colors.grey))]),
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
                                      Expanded(child: TextField(controller: notaCtrl, style: TextStyle(color: isEscuro ? Colors.white : Colors.black87), decoration: InputDecoration(hintText: "Adicionar nota...", hintStyle: const TextStyle(color: Colors.grey), filled: true, fillColor: isEscuro ? Colors.black26 : Colors.grey.shade100, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none)))),
                                      const SizedBox(width: 8),
                                      CircleAvatar(backgroundColor: Colors.blue, child: IconButton(icon: const Icon(Icons.send, color: Colors.white, size: 18), onPressed: () {
                                        if(notaCtrl.text.trim().isEmpty) return;
                                        setState(() {
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
              ],
            ),
          );
        });
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isEscuro = Theme.of(context).brightness == Brightness.dark;
    Color corFundo = isEscuro ? const Color(0xFF1E1E1E) : Colors.white;
    Color corTexto = isEscuro ? Colors.white : Colors.black87;

    List<Map<String, dynamic>> jovensFiltrados = _todosJovens.where((jovem) {
      return jovem['nome'].toLowerCase().contains(_termoBusca.toLowerCase());
    }).toList();

    Map<String, Map<String, List<Map<String, dynamic>>>> arvoreJovens = {};
    for (var jovem in jovensFiltrados) {
      String estaca = jovem['estaca'];
      String unidade = jovem['unidade'];
      arvoreJovens.putIfAbsent(estaca, () => {});
      arvoreJovens[estaca]!.putIfAbsent(unidade, () => []).add(jovem);
    }
    List<String> estacasOrdenadas = arvoreJovens.keys.toList()..sort();
    
    // Obter dados do Dashboard
    List<Map<String, dynamic>> gargalos = _calcularGargalos();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: Text('Lista Global de Jovens', style: TextStyle(fontWeight: FontWeight.bold, color: corTexto)), backgroundColor: corFundo, elevation: 1, iconTheme: IconThemeData(color: corTexto)),
      body: Column(
        children: [
          // ==========================================
          // NOVO: DASHBOARD ANALÍTICO (GARGALOS)
          // ==========================================
          if (gargalos.isNotEmpty && _termoBusca.isEmpty)
            Container(
              padding: const EdgeInsets.all(16), margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: corFundo, borderRadius: BorderRadius.circular(16), border: Border.all(color: isEscuro ? Colors.white12 : Colors.grey.shade200)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.analytics, color: Colors.blue, size: 20), const SizedBox(width: 8),
                      Text("Gargalos na Região", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: corTexto)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...gargalos.map((g) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(g['etapa'], style: TextStyle(fontSize: 12, color: isEscuro ? Colors.white70 : Colors.black87)), Text("${(g['porcentagem'] * 100).toInt()}% (${g['quantidade']})", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey))]),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(value: g['porcentagem'], backgroundColor: isEscuro ? Colors.white12 : Colors.grey.shade200, color: Colors.redAccent, minHeight: 6, borderRadius: BorderRadius.circular(4)),
                      ],
                    ),
                  ))
                ],
              ),
            ),

          Container(
            color: corFundo, padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: TextField(
              style: TextStyle(color: corTexto), onChanged: (valor) => setState(() => _termoBusca = valor),
              decoration: InputDecoration(hintText: "Pesquisar jovem...", hintStyle: TextStyle(color: isEscuro ? Colors.white54 : Colors.grey), prefixIcon: Icon(Icons.search, color: isEscuro ? Colors.white54 : Colors.grey), filled: true, fillColor: isEscuro ? Colors.black26 : Colors.grey.shade100, contentPadding: const EdgeInsets.symmetric(vertical: 0), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
            ),
          ),
          
          Expanded(
            child: arvoreJovens.isEmpty
                ? Center(child: Text("Nenhum jovem encontrado.", style: TextStyle(color: Colors.grey.shade500)))
                : ListView.builder(
                    padding: const EdgeInsets.all(16), itemCount: estacasOrdenadas.length,
                    itemBuilder: (context, indexEstaca) {
                      String estaca = estacasOrdenadas[indexEstaca];
                      Map<String, List<Map<String, dynamic>>> alasDaEstaca = arvoreJovens[estaca]!;
                      List<String> alasOrdenadas = alasDaEstaca.keys.toList()..sort();
                      int totalEstaca = alasDaEstaca.values.fold(0, (soma, lista) => soma + lista.length);

                      return Card(
                        color: corFundo, margin: const EdgeInsets.only(bottom: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isEscuro ? Colors.white12 : Colors.grey.shade200)), elevation: 0,
                        child: Theme(
                          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            initiallyExpanded: _termoBusca.isNotEmpty, iconColor: Colors.purple, collapsedIconColor: Colors.grey,
                            leading: CircleAvatar(backgroundColor: Colors.purple.withValues(alpha: 0.15), child: const Icon(Icons.map, color: Colors.purple)),
                            title: Text(estaca, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: corTexto)), subtitle: Text("$totalEstaca jovem(ns) na região", style: TextStyle(color: isEscuro ? Colors.white54 : Colors.grey.shade600, fontSize: 13)),
                            children: alasOrdenadas.map((unidade) {
                              List<Map<String, dynamic>> jovensDaUnidade = alasDaEstaca[unidade]!;
                              return Padding(
                                padding: const EdgeInsets.only(left: 16.0),
                                child: ExpansionTile(
                                  initiallyExpanded: _termoBusca.isNotEmpty, iconColor: Colors.orange, collapsedIconColor: Colors.grey, leading: const Icon(Icons.church, color: Colors.orange),
                                  title: Text(unidade, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: corTexto)), subtitle: Text("${jovensDaUnidade.length} jovem(ns)", style: TextStyle(color: isEscuro ? Colors.white54 : Colors.grey, fontSize: 12)),
                                  children: jovensDaUnidade.map((jovem) {
                                    final estilo = _obterEstiloStatus(jovem['status']);
                                    return Container(
                                      decoration: BoxDecoration(border: Border(top: BorderSide(color: isEscuro ? Colors.white12 : Colors.grey.shade100))),
                                      child: ListTile(
                                        onTap: () => _abrirDetalhesJovem(jovem),
                                        contentPadding: const EdgeInsets.only(left: 32, right: 16, top: 4, bottom: 4),
                                        leading: Icon(estilo['icone'], color: estilo['cor'], size: 20),
                                        title: Text(jovem['nome'], style: TextStyle(fontWeight: FontWeight.w600, color: corTexto)),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text("${jovem['idade']} anos", style: TextStyle(color: isEscuro ? Colors.white54 : Colors.grey, fontSize: 12)),
                                            _construirAlertaEstagnacao(jovem['ultima_atualizacao']),
                                          ],
                                        ),
                                        trailing: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: estilo['cor'].withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Text(jovem['status'], style: TextStyle(fontSize: 10, color: estilo['cor'], fontWeight: FontWeight.bold))),
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
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AbaPainel extends StatefulWidget {
  const AbaPainel({super.key});

  @override
  State<AbaPainel> createState() => _AbaPainelState();
}

class _AbaPainelState extends State<AbaPainel> {
  int _qtdEnviados = 0;
  String _filtroAtual = 'Todos';

  final List<String> _nomesEtapasRapazes = ["Aceitou o Desafio (Entrevistado)", "Ensino Médio Concluído", "Alistamento Militar", "Possui Mentor", "Metas com o Bispo", "Exame Médico", "Exame Odontológico", "Chamado Aberto no Sistema"];
  final List<String> _nomesEtapasMocas = ["Aceitou o Desafio (Entrevistado)", "Ensino Médio Concluído", "Possui Mentor", "Metas com o Bispo", "Exame Médico", "Exame Odontológico", "Chamado Aberto no Sistema"];

  final List<Map<String, dynamic>> _jovensPreparacao = [
    {
      'id': '1', 'nome': 'João Silva', 'idade': 19, 'sexo': 'Masculino', 'telefone': '5591900000000', 
      'etapas': <bool>[true, true, true, false, true, false, false, false],
      'ultima_atualizacao': DateTime.now().subtract(const Duration(days: 45)), // Gera alerta
      'anotacoes': [{'data': '10/07/2026', 'autor': 'Bispo Centro', 'texto': 'Aguardando agendar dentista.'}]
    },
    {
      'id': '2', 'nome': 'Ana Beatriz', 'idade': 18, 'sexo': 'Feminino', 'telefone': '5591900000000', 
      'etapas': <bool>[true, false, false, false, false, false, false],
      'ultima_atualizacao': DateTime.now().subtract(const Duration(days: 5)),
      'anotacoes': []
    },
  ];

  final List<Map<String, dynamic>> _jovensPerspectiva = [
    {'id': '3', 'nome': 'Lucas Souza', 'idade': 17, 'sexo': 'Masculino', 'telefone': ''},
  ];

  double _calcularProgresso(List<dynamic> etapas, String sexo) {
    int concluidas = etapas.where((etapa) => etapa == true).length;
    int total = sexo == 'Masculino' ? _nomesEtapasRapazes.length : _nomesEtapasMocas.length;
    return concluidas / total;
  }

  Map<String, dynamic> _obterStatusAtual(List<dynamic> etapas, String sexo) {
    int concluidas = etapas.where((e) => e == true).length;
    List<String> listaEtapas = sexo == 'Masculino' ? _nomesEtapasRapazes : _nomesEtapasMocas;
    if (concluidas == listaEtapas.length) return {'texto': 'Pronto para Envio!', 'cor': Colors.green, 'icone': Icons.check_circle};
    int indexPendente = etapas.indexOf(false);
    if(indexPendente == -1) return {'texto': 'Completo', 'cor': Colors.green, 'icone': Icons.check_circle};
    String nomePendente = listaEtapas[indexPendente];
    Color cor;
    if (concluidas <= 2) { cor = Colors.blue; } else if (concluidas <= 5) { cor = Colors.orange; } else { cor = Colors.purple; }
    return {'texto': 'Pendente: $nomePendente', 'cor': cor, 'icone': Icons.pending_actions};
  }

  Widget _construirAlertaEstagnacao(DateTime? ultimaAtualizacao) {
    if (ultimaAtualizacao == null) return const SizedBox.shrink();
    int dias = DateTime.now().difference(ultimaAtualizacao).inDays;
    if (dias > 30) {
      return Container(
        margin: const EdgeInsets.only(top: 6),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.red.withValues(alpha: 0.5))),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 10, color: Colors.red),
            const SizedBox(width: 4),
            Text("Estagnado: $dias dias", style: const TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  void _mostrarFormularioJovem({Map<String, dynamic>? jovemAtual}) {
    bool isEdicao = jovemAtual != null;
    bool isEscuro = Theme.of(context).brightness == Brightness.dark;
    
    final nomeCtrl = TextEditingController(text: isEdicao ? jovemAtual['nome'] : "");
    final idadeCtrl = TextEditingController(text: isEdicao ? jovemAtual['idade'].toString() : "");
    final telefoneCtrl = TextEditingController(text: isEdicao ? jovemAtual['telefone'] : ""); 
    String sexoSelecionado = isEdicao ? jovemAtual['sexo'] : "Masculino";

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
                    Icon(isEdicao ? Icons.edit : Icons.person_add, color: Colors.blue),
                    const SizedBox(width: 10),
                    Text(isEdicao ? "Editar Jovem" : "Novo Jovem", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isEscuro ? Colors.white : Colors.black)),
                  ],
                ),
                const SizedBox(height: 25),
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
                      initialValue: sexoSelecionado, dropdownColor: isEscuro ? const Color(0xFF1E1E1E) : Colors.white,
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
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: () {
                      if (nomeCtrl.text.trim().isEmpty) return;
                      setState(() {
                        if (isEdicao) {
                          jovemAtual['nome'] = nomeCtrl.text.trim();
                          jovemAtual['idade'] = int.tryParse(idadeCtrl.text) ?? 0;
                          jovemAtual['telefone'] = telefoneCtrl.text.trim();
                          if (jovemAtual['sexo'] != sexoSelecionado) {
                            jovemAtual['sexo'] = sexoSelecionado;
                            int totalEtapas = sexoSelecionado == 'Masculino' ? _nomesEtapasRapazes.length : _nomesEtapasMocas.length;
                            jovemAtual['etapas'] = List.generate(totalEtapas, (index) => false);
                          }
                        } else {
                          _jovensPerspectiva.add({'id': DateTime.now().millisecondsSinceEpoch.toString(), 'nome': nomeCtrl.text.trim(), 'idade': int.tryParse(idadeCtrl.text) ?? 0, 'sexo': sexoSelecionado, 'telefone': telefoneCtrl.text.trim(), 'ultima_atualizacao': DateTime.now(), 'anotacoes': []});
                        }
                      });
                      Navigator.pop(context); 
                    },
                    icon: const Icon(Icons.save),
                    label: Text(isEdicao ? "Salvar" : "Adicionar Jovem", style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  void _abrirPainelDoJovem(Map<String, dynamic> jovem) {
    List<bool> etapasTemp = List<bool>.from(jovem['etapas']); 
    List<String> listaEtapas = jovem['sexo'] == 'Masculino' ? _nomesEtapasRapazes : _nomesEtapasMocas;
    bool isEscuro = Theme.of(context).brightness == Brightness.dark;
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
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: isEscuro ? Colors.white24 : Colors.grey.shade400, borderRadius: BorderRadius.circular(10))),
                const SizedBox(height: 15),
                Row(
                  children: [
                    CircleAvatar(radius: 25, backgroundColor: jovem['sexo'] == 'Masculino' ? Colors.blue.withValues(alpha: 0.2) : Colors.pink.withValues(alpha: 0.2), child: Text(jovem['nome'][0], style: TextStyle(color: jovem['sexo'] == 'Masculino' ? Colors.blue : Colors.pink, fontSize: 20, fontWeight: FontWeight.bold))),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(jovem['nome'], style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isEscuro ? Colors.white : Colors.black), overflow: TextOverflow.ellipsis),
                          Text("${jovem['idade']} anos", style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(height: 45, width: 45, child: CircularProgressIndicator(value: progressoModal, backgroundColor: isEscuro ? Colors.white12 : Colors.grey.shade200, color: Colors.blue, strokeWidth: 4)),
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
                          labelColor: Colors.blue, unselectedLabelColor: Colors.grey, indicatorColor: Colors.blue,
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
                                    value: etapasTemp[index], activeColor: Colors.blue, checkColor: Colors.white, side: BorderSide(color: isEscuro ? Colors.grey.shade400 : Colors.grey.shade700),
                                    onChanged: (bool? valor) => setStateModal(() => etapasTemp[index] = valor ?? false),
                                  );
                                },
                              ),
                              Column(
                                children: [
                                  Expanded(
                                    child: notas.isEmpty 
                                      ? const Center(child: Text("Nenhuma anotação.", style: TextStyle(color: Colors.grey)))
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
                                        setStateModal(() {
                                          notas.add({'data': "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}", 'autor': 'Bispo Atual', 'texto': notaCtrl.text.trim()});
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
                    Expanded(child: OutlinedButton.icon(onPressed: () => _chamarNoWhatsApp(jovem['nome'], jovem['telefone'], etapasTemp, listaEtapas), icon: const Icon(Icons.chat, color: Colors.green), label: const Text("WhatsApp", style: TextStyle(color: Colors.green)), style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.green), padding: const EdgeInsets.symmetric(vertical: 14)))),
                    const SizedBox(width: 10),
                    Expanded(child: ElevatedButton.icon(onPressed: () {
                      setState(() { 
                        jovem['etapas'] = List<bool>.from(etapasTemp); 
                        jovem['anotacoes'] = notas;
                        jovem['ultima_atualizacao'] = DateTime.now(); // Reseta estagnação
                      });
                      Navigator.pop(context); 
                      if (_calcularProgresso(jovem['etapas'], jovem['sexo']) == 1.0) { Future.delayed(const Duration(milliseconds: 300), () { setState(() { _jovensPreparacao.removeWhere((item) => item['id'] == jovem['id']); _qtdEnviados++; }); }); }
                    }, icon: const Icon(Icons.save), label: const Text("Salvar"), style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)))),
                  ],
                )
              ],
            ),
          );
        });
      }
    );
  }

  Future<void> _chamarNoWhatsApp(String nome, String telefone, List<dynamic> etapas, List<String> listaEtapas) async {
    String numeroLimpo = telefone.replaceAll(RegExp(r'[^0-9]'), '');
    if (numeroLimpo.isEmpty) return;
    int indexPendente = etapas.indexOf(false);
    String nomeEtapaPendente = indexPendente != -1 ? listaEtapas[indexPendente] : "Enviou tudo";
    String mensagem = "Olá, $nome! Tudo bem? Vi aqui que a sua próxima etapa é: *$nomeEtapaPendente*. Precisa de alguma ajuda com isso?";
    final Uri url = Uri.parse('https://wa.me/$numeroLimpo?text=${Uri.encodeComponent(mensagem)}');
    // ignore: empty_catches
    try { if (!await launchUrl(url, mode: LaunchMode.externalApplication)) throw Exception(); } catch (e) { }
  }

  void _iniciarPreparacao(Map<String, dynamic> jovem) {
    setState(() {
      _jovensPerspectiva.removeWhere((item) => item['id'] == jovem['id']);
      int totalEtapas = jovem['sexo'] == 'Masculino' ? _nomesEtapasRapazes.length : _nomesEtapasMocas.length;
      _jovensPreparacao.add({'id': jovem['id'], 'nome': jovem['nome'], 'idade': jovem['idade'], 'sexo': jovem['sexo'], 'telefone': jovem['telefone'] ?? '', 'etapas': List.generate(totalEtapas, (index) => false), 'ultima_atualizacao': DateTime.now(), 'anotacoes': []});
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isEscuro = Theme.of(context).brightness == Brightness.dark;
    Color corFundo = isEscuro ? const Color(0xFF1E1E1E) : Colors.white;
    Color corTexto = isEscuro ? Colors.white : Colors.black;

    List<Map<String, dynamic>> listaFiltrada = _jovensPreparacao.where((jovem) {
      if (_filtroAtual == 'Todos') return true;
      List<String> listaEtapas = jovem['sexo'] == 'Masculino' ? _nomesEtapasRapazes : _nomesEtapasMocas;
      int indexFiltro = listaEtapas.indexOf(_filtroAtual);
      if (indexFiltro == -1) return false; 
      return jovem['etapas'][indexFiltro] == false;
    }).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(automaticallyImplyLeading: false, title: Text('Visão Geral da Ala', style: TextStyle(fontWeight: FontWeight.bold, color: corTexto)), backgroundColor: corFundo, elevation: 1),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => _mostrarFormularioJovem(), backgroundColor: Colors.blue, foregroundColor: Colors.white, icon: const Icon(Icons.person_add), label: const Text("Novo Jovem", style: TextStyle(fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(padding: const EdgeInsets.all(16.0), child: Row(children: [_construirCartaoDashboard("Perspectiva", _jovensPerspectiva.length.toString(), Colors.orange, Icons.radar, isEscuro), const SizedBox(width: 10), _construirCartaoDashboard("Preparação", _jovensPreparacao.length.toString(), Colors.blue, Icons.assignment_ind, isEscuro), const SizedBox(width: 10), _construirCartaoDashboard("Enviados", _qtdEnviados.toString(), Colors.green, Icons.check_circle, isEscuro)])),
            SizedBox(height: 40, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), children: ['Todos', 'Exame Médico', 'Exame Odontológico', 'Alistamento Militar'].map((f) => _construirFiltro(f, isEscuro)).toList())),
            const SizedBox(height: 20),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0), child: Text("Processo Iniciado", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: corTexto))),
            const SizedBox(height: 10),
            if (listaFiltrada.isEmpty) Padding(padding: const EdgeInsets.all(16.0), child: Text(_filtroAtual == 'Todos' ? "Nenhum jovem em preparação." : "Nenhum jovem pendente.", style: const TextStyle(color: Colors.grey)))
            else ListView.builder(
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: listaFiltrada.length,
              itemBuilder: (context, index) {
                final jovem = listaFiltrada[index];
                double progressoAtual = _calcularProgresso(jovem['etapas'], jovem['sexo']);
                Map<String, dynamic> statusAtual = _obterStatusAtual(jovem['etapas'], jovem['sexo']);
                return Card(
                  color: corFundo, margin: const EdgeInsets.only(bottom: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isEscuro ? Colors.white12 : Colors.grey.shade200)), elevation: 0,
                  child: InkWell( 
                    onTap: () => _abrirPainelDoJovem(jovem), borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          CircleAvatar(backgroundColor: statusAtual['cor'].withValues(alpha: 0.15), child: Text(jovem['nome'][0], style: TextStyle(color: statusAtual['cor'], fontWeight: FontWeight.bold))),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(jovem['nome'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: corTexto)),
                                const SizedBox(height: 4),
                                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: statusAtual['cor'].withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(statusAtual['icone'], size: 12, color: statusAtual['cor']), const SizedBox(width: 4), Expanded(child: Text(statusAtual['texto'], style: TextStyle(fontSize: 11, color: statusAtual['cor'], fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis))])),
                                _construirAlertaEstagnacao(jovem['ultima_atualizacao'])
                              ],
                            ),
                          ),
                          Stack(alignment: Alignment.center, children: [SizedBox(height: 45, width: 45, child: CircularProgressIndicator(value: progressoAtual, backgroundColor: isEscuro ? Colors.black26 : Colors.grey.shade200, color: statusAtual['cor'], strokeWidth: 4)), Text("${(progressoAtual * 100).toInt()}%", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: corTexto))])
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 25),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0), child: Text("Missionários em Perspectiva", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: corTexto))),
            const SizedBox(height: 10),
            if (_jovensPerspectiva.isEmpty) const Padding(padding: EdgeInsets.all(16.0), child: Text("Nenhum missionário em perspectiva.", style: TextStyle(color: Colors.grey)))
            else ListView.builder(
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: _jovensPerspectiva.length,
              itemBuilder: (context, index) {
                final jovem = _jovensPerspectiva[index];
                return Card(
                  color: corFundo, margin: const EdgeInsets.only(bottom: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isEscuro ? Colors.white12 : Colors.grey.shade200)), elevation: 0,
                  child: ListTile(
                    onTap: () => _mostrarFormularioJovem(jovemAtual: jovem), 
                    leading: const Icon(Icons.person, color: Colors.orange), title: Text(jovem['nome'], style: TextStyle(fontWeight: FontWeight.w600, color: corTexto)), subtitle: Text("${jovem['idade']} anos", style: const TextStyle(color: Colors.grey)),
                    trailing: OutlinedButton(style: OutlinedButton.styleFrom(foregroundColor: Colors.orange, side: const BorderSide(color: Colors.orange), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), onPressed: () => _iniciarPreparacao(jovem), child: const Text("Iniciar", style: TextStyle(fontSize: 12))),
                  ),
                );
              },
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _construirFiltro(String titulo, bool isEscuro) {
    bool selecionado = _filtroAtual == titulo;
    return Padding(padding: const EdgeInsets.only(right: 8.0), child: FilterChip(label: Text(titulo, style: TextStyle(color: selecionado ? Colors.white : (isEscuro ? Colors.white70 : Colors.black87))), selected: selecionado, selectedColor: Colors.blue, backgroundColor: isEscuro ? const Color(0xFF1E1E1E) : Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: selecionado ? Colors.blue : (isEscuro ? Colors.white12 : Colors.grey.shade300))), onSelected: (bool value) => setState(() => _filtroAtual = titulo)));
  }

  Widget _construirCartaoDashboard(String titulo, String valor, Color cor, IconData icone, bool isEscuro) {
    return Expanded(child: Container(padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8), decoration: BoxDecoration(color: isEscuro ? const Color(0xFF1E1E1E) : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: isEscuro ? Colors.white12 : Colors.grey.shade200), boxShadow: [BoxShadow(color: cor.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))]), child: Column(children: [Icon(icone, color: cor, size: 28), const SizedBox(height: 8), Text(valor, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isEscuro ? Colors.white : Colors.black)), const SizedBox(height: 4), Text(titulo, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600))])));
  }
}
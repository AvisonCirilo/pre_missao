// ignore_for_file: empty_catches, curly_braces_in_flow_control_structures, deprecated_member_use, unnecessary_cast

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart'; 

class AbaPainel extends StatefulWidget {
  const AbaPainel({super.key});

  @override
  State<AbaPainel> createState() => _AbaPainelState();
}

class _AbaPainelState extends State<AbaPainel> {
  String _minhaEstaca = "";
  String _minhaUnidade = "";
  bool _carregandoPerfil = true;

  List<String> _nomesEtapasRapazes = ["Carregando..."];
  List<String> _nomesEtapasMocas = ["Carregando..."];
  
  StreamSubscription? _etapasSub;
  Stream<QuerySnapshot>? _streamJovens;

  @override
  void initState() {
    super.initState();
    _carregarPerfilLider(); 
    _ouvirEtapasDoBanco();
  }

  @override
  void dispose() {
    _etapasSub?.cancel();
    super.dispose();
  }

  void _ouvirEtapasDoBanco() {
    _etapasSub = FirebaseFirestore.instance.collection('sistema').doc('etapas').snapshots().listen((doc) {
      if (doc.exists && mounted) {
        setState(() {
          _nomesEtapasRapazes = List<String>.from(doc['rapazes'] ?? []);
          _nomesEtapasMocas = List<String>.from(doc['mocas'] ?? []);
        });
      }
    });
  }

  Future<void> _carregarPerfilLider() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        var doc = await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).get();
        if (doc.exists && mounted) {
          var dados = doc.data() as Map<String, dynamic>? ?? {};
          setState(() {
            _minhaEstaca = dados['estaca'] ?? "Global (Todas)";
            _minhaUnidade = dados['unidade'] ?? "Global (Todas)";
            _carregandoPerfil = false;
          });
          _iniciarConexaoBanco();
        } else {
          if (mounted) setState(() => _carregandoPerfil = false);
        }
      } else {
        if (mounted) setState(() => _carregandoPerfil = false);
      }
    } catch (e) {
      if (mounted) setState(() => _carregandoPerfil = false);
    }
  }

  void _iniciarConexaoBanco() {
    if (_minhaUnidade.isNotEmpty && _minhaUnidade != 'Global (Todas)') {
      _streamJovens = FirebaseFirestore.instance.collection('jovens')
          .where('estaca', isEqualTo: _minhaEstaca)
          .where('unidade', isEqualTo: _minhaUnidade)
          .snapshots();
    } else {
      _streamJovens = FirebaseFirestore.instance.collection('jovens').snapshots();
    }
  }

  Future<void> _atualizarAoPuxar() async {
    setState(() => _iniciarConexaoBanco());
    await Future.delayed(const Duration(seconds: 1)); 
  }

  double _calcularProgresso(List<dynamic> etapas, String sexo) {
    if (etapas.isEmpty) return 0.0;
    int concluidas = etapas.where((etapa) => etapa == true).length;
    int total = sexo == 'Masculino' ? _nomesEtapasRapazes.length : _nomesEtapasMocas.length;
    if (total == 0) return 0.0; 
    return concluidas / total;
  }

  Map<String, dynamic> _obterStatusAtual(List<dynamic> etapas, String sexo) {
    if (etapas.isEmpty) return {'texto': 'Iniciando...', 'cor': Colors.blue, 'icone': Icons.pending_actions};
    int concluidas = etapas.where((e) => e == true).length;
    List<String> listaEtapas = sexo == 'Masculino' ? _nomesEtapasRapazes : _nomesEtapasMocas;
    
    if (concluidas >= listaEtapas.length) return {'texto': 'Pronto para Envio!', 'cor': Colors.green, 'icone': Icons.check_circle};
    
    int indexPendente = etapas.indexOf(false);
    if(indexPendente == -1 || indexPendente >= listaEtapas.length) return {'texto': 'Completo', 'cor': Colors.green, 'icone': Icons.check_circle};
    
    String nomePendente = listaEtapas[indexPendente];
    Color cor;
    if (concluidas <= (listaEtapas.length / 3)) { cor = Colors.blue; } 
    else if (concluidas <= (listaEtapas.length / 1.5)) { cor = Colors.orange; } 
    else { cor = Colors.purple; }
    
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

  // ==========================================
  // WIDGETS DO PAINEL (CARDS ADAPTADOS PARA 4 NA MESMA LINHA)
  // ==========================================
  Widget _construirCartaoDashboard(String titulo, String valor, Color cor, IconData icone, bool isEscuro) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: isEscuro ? const Color(0xFF1E1E1E) : Colors.white, 
          borderRadius: BorderRadius.circular(12), 
          border: Border.all(color: isEscuro ? Colors.white12 : Colors.grey.shade200), 
          boxShadow: [BoxShadow(color: cor.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))]
        ),
        child: Column(
          children: [
            Icon(icone, color: cor, size: 24), 
            const SizedBox(height: 6),
            Text(valor, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isEscuro ? Colors.white : Colors.black)),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(titulo, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarFormularioJovem({Map<String, dynamic>? jovemAtual}) {
    if (_minhaEstaca.isEmpty || _minhaUnidade.isEmpty || _minhaEstaca == 'Global (Todas)' || _minhaUnidade == 'Global (Todas)') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Seu perfil não está vinculado a uma Ala válida. Contate o administrador!'), 
        backgroundColor: Colors.redAccent
      ));
      return;
    }

    bool isEdicao = jovemAtual != null;
    bool isEscuro = Theme.of(context).brightness == Brightness.dark;
    
    final nomeCtrl = TextEditingController(text: isEdicao ? jovemAtual['nome'] : "");
    final idadeCtrl = TextEditingController(text: isEdicao ? jovemAtual['idade'].toString() : "");
    final telefoneCtrl = TextEditingController(text: isEdicao ? jovemAtual['telefone'] : "");
    String sexoSelecionado = isEdicao ? (jovemAtual['sexo'] ?? "Masculino") : "Masculino";
    bool salvando = false;

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateModal) {
          return Container(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 24, left: 24, right: 24, top: 24),
            decoration: BoxDecoration(color: isEscuro ? const Color(0xFF1E1E1E) : Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(25))),
            child: SingleChildScrollView(
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
                  
                  TextField(controller: nomeCtrl, style: TextStyle(color: isEscuro ? Colors.white : Colors.black87), decoration: InputDecoration(labelText: "Nome do Jovem", prefixIcon: const Icon(Icons.person), filled: true, fillColor: isEscuro ? Colors.black26 : Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
                  const SizedBox(height: 15),
                  
                  Row(
                    children: [
                      Expanded(flex: 2, child: TextField(controller: idadeCtrl, style: TextStyle(color: isEscuro ? Colors.white : Colors.black87), keyboardType: TextInputType.number, decoration: InputDecoration(labelText: "Idade", prefixIcon: const Icon(Icons.cake), filled: true, fillColor: isEscuro ? Colors.black26 : Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)))),
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
                  
                  TextField(controller: telefoneCtrl, style: TextStyle(color: isEscuro ? Colors.white : Colors.black87), keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: "WhatsApp", prefixIcon: const Icon(Icons.phone), filled: true, fillColor: isEscuro ? Colors.black26 : Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
                  const SizedBox(height: 20),
                  
                  SizedBox(
                    width: double.infinity, height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: salvando ? null : () async {
                        if (nomeCtrl.text.trim().isEmpty) return;
                        setStateModal(() => salvando = true);

                        try {
                          int totalEtapas = sexoSelecionado == 'Masculino' ? _nomesEtapasRapazes.length : _nomesEtapasMocas.length;
                          String estacaFinal = _minhaEstaca;
                          String unidadeFinal = _minhaUnidade;

                          String bispoUidEncontrado = FirebaseAuth.instance.currentUser?.uid ?? "";

                          Map<String, dynamic> dados = {
                            'nome': nomeCtrl.text.trim(),
                            'idade': int.tryParse(idadeCtrl.text) ?? 0,
                            'sexo': sexoSelecionado,
                            'telefone': telefoneCtrl.text.trim(),
                            'estaca': estacaFinal,
                            'unidade': unidadeFinal,
                            'bispo_uid': bispoUidEncontrado,
                          };

                          if (isEdicao) {
                            if (jovemAtual['sexo'] != sexoSelecionado) {
                              dados['etapas'] = List.generate(totalEtapas, (index) => false);
                              dados['status'] = 'Perspectiva';
                            }
                            await FirebaseFirestore.instance.collection('jovens').doc(jovemAtual['id']).update(dados);
                          } else {
                            dados['status'] = 'Perspectiva';
                            dados['etapas'] = List.generate(totalEtapas, (index) => false);
                            dados['anotacoes'] = [];
                            dados['ultima_atualizacao'] = FieldValue.serverTimestamp();
                            await FirebaseFirestore.instance.collection('jovens').add(dados);
                          }

                          if (context.mounted) Navigator.pop(context);
                        } catch(e) {
                          setStateModal(() => salvando = false);
                          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.redAccent));
                        }
                      },
                      icon: salvando ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.save),
                      label: Text(isEdicao ? "Salvar Alterações" : "Adicionar Jovem", style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  void _abrirPainelDoJovem(Map<String, dynamic> jovem) {
    List<bool> etapasTemp = List<bool>.from(jovem['etapas'] ?? []); 
    List<String> listaEtapas = jovem['sexo'] == 'Masculino' ? _nomesEtapasRapazes : _nomesEtapasMocas;
    
    while(etapasTemp.length < listaEtapas.length) { etapasTemp.add(false); }
    if (etapasTemp.length > listaEtapas.length) { etapasTemp = etapasTemp.sublist(0, listaEtapas.length); }
    
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
                    IconButton(icon: const Icon(Icons.edit, color: Colors.grey), onPressed: () { Navigator.pop(context); _mostrarFormularioJovem(jovemAtual: jovem); }),
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
                                          notas.add({'data': "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}", 'autor': 'Líder Local', 'texto': notaCtrl.text.trim()});
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
                    Expanded(child: ElevatedButton.icon(
                      onPressed: () async {
                        double progFinal = _calcularProgresso(etapasTemp, jovem['sexo']);
                        String novoStatus = 'Perspectiva';
                        if (progFinal == 1.0) novoStatus = 'Enviado';
                        else if (progFinal > 0.0) novoStatus = 'Preparação';

                        Map<String, dynamic> dadosAtualizados = {
                          'etapas': etapasTemp,
                          'anotacoes': notas,
                          'status': novoStatus,
                          'ultima_atualizacao': FieldValue.serverTimestamp(),
                        };

                        if (novoStatus == 'Enviado' && jovem['status'] != 'Enviado') {
                          DateTime hoje = DateTime.now();
                          String dataFormatada = "${hoje.day.toString().padLeft(2, '0')}/${hoje.month.toString().padLeft(2, '0')}/${hoje.year}";
                          dadosAtualizados['data_envio'] = dataFormatada;
                        }

                        await FirebaseFirestore.instance.collection('jovens').doc(jovem['id']).update(dadosAtualizados);

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Salvo no banco de dados!'), backgroundColor: Colors.green));
                        }
                      }, 
                      icon: const Icon(Icons.save), 
                      label: const Text("Salvar Ficha"), 
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14))
                    )),
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
    String nomeEtapaPendente = indexPendente != -1 && indexPendente < listaEtapas.length ? listaEtapas[indexPendente] : "Enviou tudo";
    String mensagem = "Olá, $nome! Tudo bem? Vi aqui que a sua próxima etapa é: *$nomeEtapaPendente*. Precisa de alguma ajuda com isso?";
    final Uri url = Uri.parse('https://wa.me/$numeroLimpo?text=${Uri.encodeComponent(mensagem)}');
    try { await launchUrl(url, mode: LaunchMode.externalApplication); } catch (e) {}
  }

  void _iniciarPreparacao(Map<String, dynamic> jovem) async {
    await FirebaseFirestore.instance.collection('jovens').doc(jovem['id']).update({
      'status': 'Preparação',
      'ultima_atualizacao': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isEscuro = Theme.of(context).brightness == Brightness.dark;
    Color corFundo = isEscuro ? const Color(0xFF1E1E1E) : Colors.white;
    Color corTexto = isEscuro ? Colors.white : Colors.black;

    if (_carregandoPerfil) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(backgroundColor: corFundo, elevation: 1),
        body: const Center(child: CircularProgressIndicator(color: Colors.blue)),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false, 
        title: Text(_minhaUnidade == 'Global (Todas)' ? 'Visão Geral do Sistema' : 'Visão Geral - $_minhaUnidade', style: TextStyle(fontWeight: FontWeight.bold, color: corTexto)), 
        backgroundColor: corFundo, 
        elevation: 1
      ),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => _mostrarFormularioJovem(), backgroundColor: Colors.blue, foregroundColor: Colors.white, icon: const Icon(Icons.person_add), label: const Text("Novo Jovem", style: TextStyle(fontWeight: FontWeight.bold))),
      
      body: StreamBuilder<QuerySnapshot>(
        stream: _streamJovens,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.blue));
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("Nenhum jovem cadastrado ainda.", style: TextStyle(color: Colors.grey)));

          List<Map<String, dynamic>> todosJovens = snapshot.data!.docs.map((doc) {
            var dados = doc.data() as Map<String, dynamic>;
            dados['id'] = doc.id;
            return dados;
          }).where((jovem) {
            if (_minhaUnidade == 'Global (Todas)') return true; 
            return jovem['unidade'] == _minhaUnidade; 
          }).toList();

          List<Map<String, dynamic>> jovensPerspectiva = todosJovens.where((j) => j['status'] == 'Perspectiva').toList();
          List<Map<String, dynamic>> jovensPreparacao = todosJovens.where((j) => j['status'] == 'Preparação').toList();
          List<Map<String, dynamic>> jovensEnviados = todosJovens.where((j) => j['status'] == 'Enviado').toList();

          int totalParados = todosJovens.where((j) {
            if (j['status'] == 'Enviado' || j['ultima_atualizacao'] == null) return false;
            int dias = DateTime.now().difference((j['ultima_atualizacao'] as Timestamp).toDate()).inDays;
            return dias > 30;
          }).length;

          return RefreshIndicator(
            onRefresh: _atualizarAoPuxar,
            color: Colors.blue,
            backgroundColor: isEscuro ? const Color(0xFF1E1E1E) : Colors.white,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TODOS OS 4 INDICADORES NA MESMA LINHA
                  Padding(
                    padding: const EdgeInsets.all(16.0), 
                    child: Row(
                      children: [
                        _construirCartaoDashboard("Perspectiva", jovensPerspectiva.length.toString(), Colors.orange, Icons.radar, isEscuro), 
                        const SizedBox(width: 8), 
                        _construirCartaoDashboard("Preparação", jovensPreparacao.length.toString(), Colors.blue, Icons.assignment_ind, isEscuro),
                        const SizedBox(width: 8), 
                        _construirCartaoDashboard("Enviados", jovensEnviados.length.toString(), Colors.green, Icons.check_circle, isEscuro),
                        const SizedBox(width: 8), 
                        _construirCartaoDashboard("Estagnados", totalParados.toString(), Colors.redAccent, Icons.warning_amber_rounded, isEscuro)
                      ]
                    )
                  ),

                  const SizedBox(height: 10),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0), child: Text("Processo Iniciado", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: corTexto))),
                  const SizedBox(height: 10),
                  
                  if (jovensPreparacao.isEmpty) Padding(padding: const EdgeInsets.all(16.0), child: Text("Nenhum jovem em preparação.", style: const TextStyle(color: Colors.grey)))
                  else ListView.builder(
                    shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: jovensPreparacao.length,
                    itemBuilder: (context, index) {
                      final jovem = jovensPreparacao[index];
                      List<dynamic> etapasJov = jovem['etapas'] ?? [];
                      double progressoAtual = _calcularProgresso(etapasJov, jovem['sexo']);
                      Map<String, dynamic> statusAtual = _obterStatusAtual(etapasJov, jovem['sexo']);
                      
                      DateTime? ultimaAtt;
                      if (jovem['ultima_atualizacao'] != null) ultimaAtt = (jovem['ultima_atualizacao'] as Timestamp).toDate();

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
                                      _construirAlertaEstagnacao(ultimaAtt)
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
                  if (jovensPerspectiva.isEmpty) const Padding(padding: EdgeInsets.all(16.0), child: Text("Nenhum missionário em perspectiva.", style: TextStyle(color: Colors.grey)))
                  else ListView.builder(
                    shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: jovensPerspectiva.length,
                    itemBuilder: (context, index) {
                      final jovem = jovensPerspectiva[index];
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
      ),
    );
  }
}
// ignore_for_file: empty_catches, curly_braces_in_flow_control_structures, deprecated_member_use, unnecessary_cast
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ListaGlobalJovensTela extends StatefulWidget {
  const ListaGlobalJovensTela({super.key});

  @override
  State<ListaGlobalJovensTela> createState() => _ListaGlobalJovensTelaState();
}

class _ListaGlobalJovensTelaState extends State<ListaGlobalJovensTela> {
  String _termoBusca = "";
  List<String> _nomesEtapasRapazes = ["Carregando..."];
  List<String> _nomesEtapasMocas = ["Carregando..."];
  StreamSubscription? _etapasSub;

  String _minhaEstaca = "";
  String _nivelAcesso = "Ala";
  bool _carregandoPerfil = true;

  final List<Color> _paletaCores = [
    Colors.blue, Colors.pink.shade400, Colors.purple, Colors.teal, 
    Colors.indigo, Colors.amber.shade700, Colors.cyan.shade700, 
    Colors.deepOrange, Colors.lightGreen.shade700, Colors.brown
  ];

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

  double _calcularProgresso(List<dynamic> etapas, String sexo) {
    if (etapas.isEmpty) return 0.0;
    int concluidas = etapas.where((etapa) => etapa == true).length;
    int total = sexo == 'Masculino' ? _nomesEtapasRapazes.length : _nomesEtapasMocas.length;
    if (total == 0) return 0.0;
    return concluidas / total;
  }

  Map<String, dynamic> _obterStatusAtual(List<dynamic> etapas, String sexo, String statusBD) {
    if (statusBD == 'Indeciso') return {'texto': 'Não decidiu ainda', 'cor': Colors.redAccent, 'icone': Icons.help_outline};
    if (statusBD == 'Perspectiva') return {'texto': 'Em Perspectiva', 'cor': Colors.orange, 'icone': Icons.radar};
    if (statusBD == 'Finalizado' || statusBD == 'Enviado') return {'texto': 'Processo Finalizado', 'cor': Colors.green, 'icone': Icons.check_circle};

    List<String> listaEtapas = sexo == 'Masculino' ? _nomesEtapasRapazes : _nomesEtapasMocas;
    int indexPendente = etapas.indexOf(false);
    
    if (etapas.isEmpty || indexPendente == 0) return {'texto': listaEtapas.isNotEmpty ? listaEtapas[0] : 'Iniciando...', 'cor': _paletaCores[0], 'icone': Icons.pending_actions};
    if (indexPendente == -1 || indexPendente >= listaEtapas.length) return {'texto': 'Processo Finalizado!', 'cor': Colors.green, 'icone': Icons.check_circle};
    
    return {'texto': listaEtapas[indexPendente], 'cor': _paletaCores[indexPendente % _paletaCores.length], 'icone': Icons.pending_actions};
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

  void _mostrarOpcoesEntrevista(Map<String, dynamic> jovem) {
    bool isEscuro = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isEscuro ? const Color(0xFF1E1E1E) : Colors.white,
        title: Text("Resultado da Entrevista", style: TextStyle(color: isEscuro ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
        content: const Text("Qual foi a resposta do jovem ao convite para servir missão?", style: TextStyle(color: Colors.grey)),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseFirestore.instance.collection('jovens').doc(jovem['id']).update({
                'status': 'Indeciso',
                'ultima_atualizacao': FieldValue.serverTimestamp(),
              });
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marcado como indeciso. Movido para estagnados.'), backgroundColor: Colors.orange));
            },
            child: const Text("Não decidiu", style: TextStyle(color: Colors.redAccent)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(context);
              List<bool> etapasTemp = List<bool>.from(jovem['etapas'] ?? []);
              int totalEtapas = jovem['sexo'] == 'Masculino' ? _nomesEtapasRapazes.length : _nomesEtapasMocas.length;
              
              if (etapasTemp.isEmpty) {
                etapasTemp = List.generate(totalEtapas, (index) => index == 0);
              } else {
                etapasTemp[0] = true; 
              }
              
              jovem['status'] = 'Preparação';
              jovem['etapas'] = etapasTemp;

              await FirebaseFirestore.instance.collection('jovens').doc(jovem['id']).update({
                'status': 'Preparação',
                'etapas': etapasTemp,
                'ultima_atualizacao': FieldValue.serverTimestamp(),
              });
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Jovem em processo!'), backgroundColor: Colors.green));
                _abrirPainelDoJovem(jovem);
              }
            },
            child: const Text("Aceitou"),
          ),
        ],
      ),
    );
  }

  void _mostrarFormularioJovem({Map<String, dynamic>? jovemAtual}) {
    bool isEdicao = jovemAtual != null;
    bool isEscuro = Theme.of(context).brightness == Brightness.dark;
    
    final nomeCtrl = TextEditingController(text: isEdicao ? jovemAtual['nome'] : "");
    final idadeCtrl = TextEditingController(text: isEdicao ? jovemAtual['idade'].toString() : "");
    final telefoneCtrl = TextEditingController(text: isEdicao ? jovemAtual['telefone'] : "");
    final estacaCtrl = TextEditingController(text: isEdicao ? jovemAtual['estaca'] : (_nivelAcesso == 'Estaca' ? _minhaEstaca : ""));
    final unidadeCtrl = TextEditingController(text: isEdicao ? jovemAtual['unidade'] : "");
    
    String sexoSelecionado = isEdicao ? (jovemAtual['sexo'] ?? "Masculino") : "Masculino";

    bool temMentor = isEdicao ? (jovemAtual['tem_mentor'] ?? false) : false;
    final mentorNomeCtrl = TextEditingController(text: isEdicao ? (jovemAtual['mentor_nome'] ?? "") : "");
    final mentorTelefoneCtrl = TextEditingController(text: isEdicao ? (jovemAtual['mentor_telefone'] ?? "") : "");

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
                      Text(isEdicao ? "Editar Jovem (Global)" : "Novo Jovem (Global)", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isEscuro ? Colors.white : Colors.black)),
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

                  Row(
                    children: [
                      Expanded(child: TextField(controller: estacaCtrl, enabled: _nivelAcesso != 'Estaca', style: TextStyle(color: isEscuro ? Colors.white : Colors.black87), decoration: InputDecoration(labelText: "Estaca", prefixIcon: const Icon(Icons.map), filled: true, fillColor: isEscuro ? Colors.black26 : Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)))),
                      const SizedBox(width: 15),
                      Expanded(child: TextField(controller: unidadeCtrl, style: TextStyle(color: isEscuro ? Colors.white : Colors.black87), decoration: InputDecoration(labelText: "Ala / Ramo", prefixIcon: const Icon(Icons.church), filled: true, fillColor: isEscuro ? Colors.black26 : Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)))),
                    ],
                  ),
                  const SizedBox(height: 15),
                  
                  TextField(controller: telefoneCtrl, style: TextStyle(color: isEscuro ? Colors.white : Colors.black87), keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: "WhatsApp do Jovem", prefixIcon: const Icon(Icons.phone), filled: true, fillColor: isEscuro ? Colors.black26 : Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
                  
                  const SizedBox(height: 15),
                  const Divider(),
                  
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text("Possui Mentor?", style: TextStyle(color: isEscuro ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
                    subtitle: Text("Marque se o jovem já tem um mentor designado.", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                    value: temMentor,
                    activeColor: Colors.blue,
                    onChanged: (val) => setStateModal(() => temMentor = val),
                  ),

                  if (temMentor) ...[
                    const SizedBox(height: 10),
                    TextField(controller: mentorNomeCtrl, style: TextStyle(color: isEscuro ? Colors.white : Colors.black87), decoration: InputDecoration(labelText: "Nome do Mentor", prefixIcon: const Icon(Icons.support_agent), filled: true, fillColor: isEscuro ? Colors.black26 : Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
                    const SizedBox(height: 15),
                    TextField(controller: mentorTelefoneCtrl, style: TextStyle(color: isEscuro ? Colors.white : Colors.black87), keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: "WhatsApp do Mentor", prefixIcon: const Icon(Icons.phone_android), filled: true, fillColor: isEscuro ? Colors.black26 : Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
                  ],

                  const SizedBox(height: 25),
                  
                  SizedBox(
                    width: double.infinity, height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: salvando ? null : () async {
                        if (nomeCtrl.text.trim().isEmpty || estacaCtrl.text.trim().isEmpty || unidadeCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preencha o nome, estaca e ala.'), backgroundColor: Colors.redAccent));
                          return;
                        }
                        setStateModal(() => salvando = true);

                        try {
                          int totalEtapas = sexoSelecionado == 'Masculino' ? _nomesEtapasRapazes.length : _nomesEtapasMocas.length;
                          String bispoUidEncontrado = isEdicao ? (jovemAtual['bispo_uid'] ?? FirebaseAuth.instance.currentUser?.uid ?? "") : FirebaseAuth.instance.currentUser?.uid ?? "";

                          Map<String, dynamic> dados = {
                            'nome': nomeCtrl.text.trim(),
                            'idade': int.tryParse(idadeCtrl.text) ?? 0,
                            'sexo': sexoSelecionado,
                            'telefone': telefoneCtrl.text.trim(),
                            'estaca': estacaCtrl.text.trim(),
                            'unidade': unidadeCtrl.text.trim(),
                            'bispo_uid': bispoUidEncontrado,
                            'tem_mentor': temMentor,
                            'mentor_nome': temMentor ? mentorNomeCtrl.text.trim() : "",
                            'mentor_telefone': temMentor ? mentorTelefoneCtrl.text.trim() : "",
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

    bool temMentor = jovem['tem_mentor'] == true;
    String mentorNome = jovem['mentor_nome'] ?? '';

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
                          Text("${jovem['idade']} anos • ${jovem['unidade']}", style: const TextStyle(color: Colors.grey)),
                          if (temMentor && mentorNome.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text("Mentor(a): $mentorNome", style: const TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.w600)),
                            ),
                        ],
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.edit, color: Colors.grey), onPressed: () { Navigator.pop(context); _mostrarFormularioJovem(jovemAtual: jovem); }),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (contextDialog) => AlertDialog(
                            backgroundColor: isEscuro ? const Color(0xFF1E1E1E) : Colors.white,
                            title: Text("Excluir Jovem", style: TextStyle(color: isEscuro ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
                            content: Text("Tem certeza que deseja excluir ${jovem['nome']} permanentemente?", style: const TextStyle(color: Colors.grey)),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(contextDialog),
                                child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                                onPressed: () async {
                                  Navigator.pop(contextDialog);
                                  Navigator.pop(context);
                                  await FirebaseFirestore.instance.collection('jovens').doc(jovem['id']).delete();
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Jovem excluído com sucesso!'), backgroundColor: Colors.green));
                                  }
                                },
                                child: const Text("Excluir"),
                              ),
                            ],
                          ),
                        );
                      },
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
                                  Color corCheck = _paletaCores[index % _paletaCores.length];
                                  return CheckboxListTile(
                                    title: Text(listaEtapas[index], style: TextStyle(fontWeight: etapasTemp[index] ? FontWeight.normal : FontWeight.bold, decoration: etapasTemp[index] ? TextDecoration.lineThrough : null, color: etapasTemp[index] ? Colors.grey : (isEscuro ? Colors.white : Colors.black87))),
                                    value: etapasTemp[index], activeColor: corCheck, checkColor: Colors.white, side: BorderSide(color: isEscuro ? Colors.grey.shade400 : Colors.grey.shade700),
                                    onChanged: (bool? valor) async {
                                      setStateModal(() => etapasTemp[index] = valor ?? false);
                                      
                                      double progFinal = _calcularProgresso(etapasTemp, jovem['sexo']);
                                      String novoStatus = 'Perspectiva';
                                      if (progFinal == 1.0) novoStatus = 'Finalizado';
                                      else if (progFinal > 0.0) novoStatus = 'Preparação';

                                      Map<String, dynamic> dadosAtualizados = {
                                        'etapas': etapasTemp,
                                        'status': novoStatus,
                                        'ultima_atualizacao': FieldValue.serverTimestamp(),
                                      };

                                      if (novoStatus == 'Finalizado' && (jovem['status'] != 'Finalizado' && jovem['status'] != 'Enviado')) {
                                        DateTime hoje = DateTime.now();
                                        String dataFormatada = "${hoje.day.toString().padLeft(2, '0')}/${hoje.month.toString().padLeft(2, '0')}/${hoje.year}";
                                        dadosAtualizados['data_envio'] = dataFormatada;
                                      }

                                      await FirebaseFirestore.instance.collection('jovens').doc(jovem['id']).update(dadosAtualizados);

                                      if (novoStatus == 'Perspectiva') {
                                        if (context.mounted) {
                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Jovem retornou para Perspectiva.'), backgroundColor: Colors.orange));
                                        }
                                      } else if (novoStatus == 'Finalizado' && (jovem['status'] != 'Finalizado' && jovem['status'] != 'Enviado')) {
                                        if (context.mounted) {
                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Processo Finalizado com sucesso!'), backgroundColor: Colors.green));
                                        }
                                      }

                                      jovem['status'] = novoStatus;
                                      jovem['etapas'] = etapasTemp;
                                    },
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
                                      CircleAvatar(backgroundColor: Colors.blue, child: IconButton(icon: const Icon(Icons.send, color: Colors.white, size: 18), onPressed: () async {
                                        if(notaCtrl.text.trim().isEmpty) return;
                                        var novaNota = {'data': "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}", 'autor': 'Líder', 'texto': notaCtrl.text.trim()};
                                        setStateModal(() {
                                          notas.add(novaNota);
                                          notaCtrl.clear();
                                        });

                                        await FirebaseFirestore.instance.collection('jovens').doc(jovem['id']).update({
                                          'anotacoes': notas,
                                          'ultima_atualizacao': FieldValue.serverTimestamp(),
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

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _chamarNoWhatsApp(jovem['nome'], jovem['telefone'], etapasTemp, listaEtapas), 
                    icon: const Icon(Icons.chat, color: Colors.white), 
                    label: const Text("Chamar no WhatsApp", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), 
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 14))
                  ),
                )
              ],
            ),
          );
        });
      }
    );
  }

  Future<void> _abrirWhatsApp(String telefone) async {
    String numeroLimpo = telefone.replaceAll(RegExp(r'[^0-9]'), '');
    if (numeroLimpo.isEmpty) return;
    final Uri url = Uri.parse('https://wa.me/$numeroLimpo');
    try { await launchUrl(url, mode: LaunchMode.externalApplication); } catch (e) {}
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

  @override
  Widget build(BuildContext context) {
    bool isEscuro = Theme.of(context).brightness == Brightness.dark;
    Color corFundo = isEscuro ? const Color(0xFF1E1E1E) : Colors.white;
    Color corTexto = isEscuro ? Colors.white : Colors.black87;

    if (_carregandoPerfil) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(backgroundColor: corFundo, elevation: 1),
        body: const Center(child: CircularProgressIndicator(color: Colors.green)),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("Lista Global de Jovens", style: TextStyle(fontWeight: FontWeight.bold, color: corTexto)),
        backgroundColor: corFundo,
        elevation: 1,
        iconTheme: IconThemeData(color: corTexto),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarFormularioJovem(), 
        backgroundColor: Colors.green, 
        foregroundColor: Colors.white, 
        icon: const Icon(Icons.person_add), 
        label: const Text("Novo Jovem", style: TextStyle(fontWeight: FontWeight.bold))
      ),
      body: Column(
        children: [
          Container(
            color: corFundo, padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
            child: TextField(
              style: TextStyle(color: corTexto), onChanged: (valor) => setState(() => _termoBusca = valor),
              decoration: InputDecoration(
                hintText: "Pesquisar por nome, ala ou estaca...", 
                hintStyle: TextStyle(color: isEscuro ? Colors.white54 : Colors.grey), 
                prefixIcon: Icon(Icons.search, color: isEscuro ? Colors.white54 : Colors.grey), 
                filled: true, fillColor: isEscuro ? Colors.black26 : Colors.grey.shade100, 
                contentPadding: const EdgeInsets.symmetric(vertical: 0), 
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('jovens').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.green));
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("Nenhum jovem cadastrado ainda.", style: TextStyle(color: Colors.grey)));

                List<Map<String, dynamic>> todosJovens = snapshot.data!.docs.map((doc) {
                  var dados = doc.data() as Map<String, dynamic>;
                  dados['id'] = doc.id;
                  return dados;
                }).where((jovem) {
                  if (_nivelAcesso == 'Estaca' && jovem['estaca'] != _minhaEstaca) return false;
                  
                  if (_termoBusca.isEmpty) return true;
                  String termo = _termoBusca.toLowerCase();
                  String nome = (jovem['nome'] ?? '').toLowerCase();
                  String unidade = (jovem['unidade'] ?? '').toLowerCase();
                  String estaca = (jovem['estaca'] ?? '').toLowerCase();
                  return nome.contains(termo) || unidade.contains(termo) || estaca.contains(termo);
                }).toList();

                if (todosJovens.isEmpty) return const Center(child: Text("Nenhum resultado para a busca.", style: TextStyle(color: Colors.grey)));

                Map<String, Map<String, List<Map<String, dynamic>>>> arvore = {};
                for (var jovem in todosJovens) {
                  String estaca = jovem['estaca'] ?? 'Estaca Desconhecida';
                  String unidade = jovem['unidade'] ?? 'Ala Desconhecida';

                  arvore.putIfAbsent(estaca, () => {});
                  arvore[estaca]!.putIfAbsent(unidade, () => []).add(jovem);
                }

                List<String> estacasOrdenadas = arvore.keys.toList()..sort();

                return ListView(
                  padding: const EdgeInsets.all(16),
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: estacasOrdenadas.map((estaca) {
                    Map<String, List<Map<String, dynamic>>> alasMap = arvore[estaca]!;
                    List<String> alasOrdenadas = alasMap.keys.toList()..sort();

                    return Card(
                      color: corFundo, margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isEscuro ? Colors.white12 : Colors.grey.shade200)),
                      elevation: 0,
                      child: Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          initiallyExpanded: estacasOrdenadas.length == 1 || _termoBusca.isNotEmpty,
                          iconColor: Colors.purple, collapsedIconColor: Colors.grey,
                          leading: CircleAvatar(backgroundColor: Colors.purple.withValues(alpha: 0.15), child: const Icon(Icons.map, color: Colors.purple)),
                          title: Text(estaca, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: corTexto)),
                          children: alasOrdenadas.map((ala) {
                            List<Map<String, dynamic>> jovensAla = alasMap[ala]!;
                            
                            List<Map<String, dynamic>> finalizados = jovensAla.where((j) => j['status'] == 'Finalizado' || j['status'] == 'Enviado').toList();
                            List<Map<String, dynamic>> preparacao = jovensAla.where((j) => j['status'] == 'Preparação').toList();
                            List<Map<String, dynamic>> perspectiva = jovensAla.where((j) => j['status'] == 'Perspectiva' || j['status'] == 'Indeciso').toList();

                            finalizados.sort((a, b) => (a['nome'] ?? '').toString().toLowerCase().compareTo((b['nome'] ?? '').toString().toLowerCase()));
                            perspectiva.sort((a, b) => (a['nome'] ?? '').toString().toLowerCase().compareTo((b['nome'] ?? '').toString().toLowerCase()));

                            Map<String, List<Map<String, dynamic>>> agrupamentoEtapas = {};
                            for (var j in preparacao) {
                              Map<String, dynamic> statusGeral = _obterStatusAtual(j['etapas'] ?? [], j['sexo'], j['status'] ?? '');
                              String pendencia = statusGeral['texto'];
                              agrupamentoEtapas.putIfAbsent(pendencia, () => []).add(j);
                            }
                            List<String> etapasOrdenadas = agrupamentoEtapas.keys.toList()..sort();
                            for (var key in etapasOrdenadas) {
                              agrupamentoEtapas[key]!.sort((a, b) => (a['nome'] ?? '').toString().toLowerCase().compareTo((b['nome'] ?? '').toString().toLowerCase()));
                            }

                            Widget construirTileJovem(Map<String, dynamic> j, Color corStatus, IconData iconeStatus) {
                              bool isIndeciso = j['status'] == 'Indeciso';
                              bool isPerspectiva = j['status'] == 'Perspectiva' || isIndeciso;
                              String telefone = j['telefone'] ?? '';
                              
                              int dias = 0;
                              if (j['ultima_atualizacao'] != null) {
                                dias = DateTime.now().difference((j['ultima_atualizacao'] as Timestamp).toDate()).inDays;
                              }
                              bool isEstagnado = dias > 30 && j['status'] != 'Finalizado' && j['status'] != 'Enviado' && !isIndeciso;

                              String subtitulo = "${j['idade']} anos";
                              if (isEstagnado) subtitulo = "Sem atualização há >30 dias";
                              if (isIndeciso) subtitulo = "Não decidiu ainda";
                              if (j['status'] == 'Finalizado' || j['status'] == 'Enviado') subtitulo = "100% Concluído";

                              return Container(
                                decoration: BoxDecoration(border: Border(top: BorderSide(color: isEscuro ? Colors.white12 : Colors.grey.shade100))),
                                child: ListTile(
                                  onTap: () {
                                    if (isPerspectiva) _mostrarOpcoesEntrevista(j);
                                    else _abrirPainelDoJovem(j);
                                  },
                                  contentPadding: const EdgeInsets.only(left: 32, right: 16),
                                  leading: CircleAvatar(backgroundColor: corStatus.withValues(alpha: 0.15), child: Icon(iconeStatus, color: corStatus, size: 20)),
                                  title: Text(j['nome'] ?? '', style: TextStyle(fontWeight: FontWeight.w500, color: corTexto, fontSize: 14)),
                                  subtitle: Text(subtitulo, style: TextStyle(color: (isEstagnado || isIndeciso) ? Colors.redAccent : Colors.grey, fontSize: 12)),
                                  trailing: isPerspectiva
                                      ? OutlinedButton(
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: isIndeciso ? Colors.redAccent : Colors.orange, 
                                            side: BorderSide(color: isIndeciso ? Colors.redAccent : Colors.orange), 
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            padding: const EdgeInsets.symmetric(horizontal: 12),
                                          ), 
                                          onPressed: () => _mostrarOpcoesEntrevista(j), 
                                          child: const Text("Entrevistado", style: TextStyle(fontSize: 12))
                                        )
                                      : (telefone.isNotEmpty
                                          ? IconButton(icon: const Icon(Icons.chat, color: Colors.green, size: 20), onPressed: () => _abrirWhatsApp(telefone))
                                          : const Icon(Icons.phone_disabled, color: Colors.grey, size: 18)),
                                ),
                              );
                            }

                            List<Widget> conteudosAla = [];

                            if (finalizados.isNotEmpty) {
                              conteudosAla.add(ExpansionTile(
                                initiallyExpanded: _termoBusca.isNotEmpty,
                                iconColor: Colors.green, collapsedIconColor: Colors.grey,
                                title: Text("Processos Finalizados (${finalizados.length})", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green)),
                                children: finalizados.map((j) => construirTileJovem(j, Colors.green, Icons.check_circle)).toList(),
                              ));
                            }

                            if (etapasOrdenadas.isNotEmpty) {
                              conteudosAla.add(ExpansionTile(
                                initiallyExpanded: _termoBusca.isNotEmpty,
                                iconColor: Colors.blue, collapsedIconColor: Colors.grey,
                                title: Text("Em processo (${preparacao.length})", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blue)),
                                children: etapasOrdenadas.map((etapa) {
                                  List<Map<String, dynamic>> lista = agrupamentoEtapas[etapa]!;
                                  Map<String, dynamic> statusGrupo = _obterStatusAtual(lista.first['etapas'] ?? [], lista.first['sexo'], lista.first['status']);
                                  Color corGrupo = statusGrupo['cor'];
                                  IconData iconeGrupo = statusGrupo['icone'];

                                  return Padding(
                                    padding: const EdgeInsets.only(left: 16),
                                    child: ExpansionTile(
                                      initiallyExpanded: _termoBusca.isNotEmpty,
                                      iconColor: corGrupo, collapsedIconColor: Colors.grey,
                                      leading: CircleAvatar(backgroundColor: corGrupo.withValues(alpha: 0.15), child: Icon(iconeGrupo, color: corGrupo, size: 20)),
                                      title: Text("$etapa (${lista.length})", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: corTexto)),
                                      children: lista.map((j) => construirTileJovem(j, corGrupo, iconeGrupo)).toList(),
                                    ),
                                  );
                                }).toList(),
                              ));
                            }

                            if (perspectiva.isNotEmpty) {
                              conteudosAla.add(ExpansionTile(
                                initiallyExpanded: _termoBusca.isNotEmpty,
                                iconColor: Colors.orange, collapsedIconColor: Colors.grey,
                                title: Text("Perspectiva (${perspectiva.length})", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.orange)),
                                children: perspectiva.map((j) => construirTileJovem(j, j['status'] == 'Indeciso' ? Colors.redAccent : Colors.orange, Icons.person)).toList(),
                              ));
                            }

                            return Padding(
                              padding: const EdgeInsets.only(left: 16),
                              child: ExpansionTile(
                                initiallyExpanded: alasOrdenadas.length == 1 || _termoBusca.isNotEmpty,
                                iconColor: Colors.orange, collapsedIconColor: Colors.grey,
                                leading: const Icon(Icons.church, color: Colors.orange),
                                title: Text("$ala (${jovensAla.length})", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: corTexto)),
                                children: conteudosAla,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  }).toList(),
                );
              }
            ),
          ),
        ],
      ),
    );
  }
}
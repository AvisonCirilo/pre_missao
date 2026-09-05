import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class DashboardList extends StatefulWidget {
  final String titulo;
  final String statusFiltro;
  final String etapaFiltro;
  final bool isEstagnado;
  final String minhaEstaca;
  final String minhaUnidade;

  const DashboardList({
    super.key,
    required this.titulo,
    this.statusFiltro = '',
    this.etapaFiltro = '',
    this.isEstagnado = false,
    this.minhaEstaca = '',
    this.minhaUnidade = '',
  });

  @override
  State<DashboardList> createState() => _DashboardListState();
}

class _DashboardListState extends State<DashboardList> {
  List<String> _nomesEtapasRapazes = [];
  List<String> _nomesEtapasMocas = [];

  final List<Color> _paletaCores = [
    Colors.blue, Colors.pink.shade400, Colors.purple, Colors.teal, 
    Colors.indigo, Colors.amber.shade700, Colors.cyan.shade700, 
    Colors.deepOrange, Colors.lightGreen.shade700, Colors.brown
  ];

  @override
  void initState() {
    super.initState();
    _buscarEtapasDoBanco();
  }

  void _buscarEtapasDoBanco() {
    FirebaseFirestore.instance.collection('sistema').doc('etapas').get().then((doc) {
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

  Map<String, dynamic> _obterStatusAtual(List<dynamic> etapas, String sexo, String statusBD, bool isEstag) {
    if (statusBD == 'Indeciso') return {'texto': 'Não decidiu ainda', 'cor': Colors.redAccent, 'icone': Icons.help_outline};
    if (isEstag) return {'texto': 'Sem atualização há mais de 30 dias', 'cor': Colors.redAccent, 'icone': Icons.warning_amber_rounded};
    if (statusBD == 'Perspectiva') return {'texto': 'Em Perspectiva', 'cor': Colors.orange, 'icone': Icons.radar};
    if (statusBD == 'Finalizado' || statusBD == 'Enviado') return {'texto': 'Processo Finalizado', 'cor': Colors.green, 'icone': Icons.check_circle};

    List<String> listaEtapas = sexo == 'Masculino' ? _nomesEtapasRapazes : _nomesEtapasMocas;
    int indexPendente = etapas.indexOf(false);
    
    if (etapas.isEmpty || indexPendente == 0) return {'texto': listaEtapas.isNotEmpty ? listaEtapas[0] : 'Iniciando...', 'cor': _paletaCores[0], 'icone': Icons.pending_actions};
    if (indexPendente == -1 || indexPendente >= listaEtapas.length) return {'texto': 'Processo Finalizado!', 'cor': Colors.green, 'icone': Icons.check_circle};
    
    return {'texto': listaEtapas[indexPendente], 'cor': _paletaCores[indexPendente % _paletaCores.length], 'icone': Icons.pending_actions};
  }

  Future<void> _abrirWhatsApp(String telefone) async {
    String numeroLimpo = telefone.replaceAll(RegExp(r'[^0-9]'), '');
    if (numeroLimpo.isEmpty) return;
    final Uri url = Uri.parse('https://wa.me/$numeroLimpo');
    try { await launchUrl(url, mode: LaunchMode.externalApplication); } catch (e) {}
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
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marcado como indeciso.'), backgroundColor: Colors.orange));
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
                              TextButton(onPressed: () => Navigator.pop(contextDialog), child: const Text("Cancelar", style: TextStyle(color: Colors.grey))),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                                onPressed: () async {
                                  Navigator.pop(contextDialog);
                                  Navigator.pop(context);
                                  await FirebaseFirestore.instance.collection('jovens').doc(jovem['id']).delete();
                                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Jovem excluído!'), backgroundColor: Colors.green));
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
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Processo Finalizado!'), backgroundColor: Colors.green));
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
                                        var novaNota = {'data': "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}", 'autor': 'Anotação Dashboard', 'texto': notaCtrl.text.trim()};
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
                    onPressed: () {
                      String numeroLimpo = (jovem['telefone'] ?? '').replaceAll(RegExp(r'[^0-9]'), '');
                      if (numeroLimpo.isEmpty) return;
                      int indexPendente = etapasTemp.indexOf(false);
                      String nomeEtapaPendente = indexPendente != -1 && indexPendente < listaEtapas.length ? listaEtapas[indexPendente] : "Enviou tudo";
                      String mensagem = "Olá, ${jovem['nome']}! Tudo bem? Vi aqui que a sua próxima etapa é: *$nomeEtapaPendente*. Precisa de alguma ajuda com isso?";
                      launchUrl(Uri.parse('https://wa.me/$numeroLimpo?text=${Uri.encodeComponent(mensagem)}'), mode: LaunchMode.externalApplication);
                    },
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

  @override
  Widget build(BuildContext context) {
    bool isEscuro = Theme.of(context).brightness == Brightness.dark;
    Color corFundo = isEscuro ? const Color(0xFF1E1E1E) : Colors.white;
    Color corTexto = isEscuro ? Colors.white : Colors.black87;

    bool isVisaoBispo = widget.minhaUnidade.isNotEmpty && 
                        widget.minhaUnidade != 'Global (Todas)' && 
                        widget.minhaUnidade != 'Todas as Alas';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.titulo, style: TextStyle(fontWeight: FontWeight.bold, color: corTexto, fontSize: 18)),
        backgroundColor: corFundo,
        elevation: 1,
        iconTheme: IconThemeData(color: corTexto),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('jovens').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.blue));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Nenhum jovem encontrado.", style: TextStyle(color: Colors.grey)));
          }

          List<Map<String, dynamic>> jovensFiltrados = snapshot.data!.docs.map((doc) {
            var dados = doc.data() as Map<String, dynamic>;
            dados['id'] = doc.id;
            return dados;
          }).where((jovem) {
            if (widget.minhaEstaca.isNotEmpty && widget.minhaEstaca != 'Global (Todas)') {
              if (jovem['estaca'] != widget.minhaEstaca) return false;
            }
            if (widget.minhaUnidade.isNotEmpty && widget.minhaUnidade != 'Global (Todas)' && widget.minhaUnidade != 'Todas as Alas') {
              if (jovem['unidade'] != widget.minhaUnidade) return false;
            }
            if (widget.isEstagnado) {
              if (jovem['status'] == 'Finalizado' || jovem['status'] == 'Enviado') return false;
              if (jovem['status'] == 'Indeciso') return true;
              if (jovem['ultima_atualizacao'] == null) return false;
              int dias = DateTime.now().difference((jovem['ultima_atualizacao'] as Timestamp).toDate()).inDays;
              return dias > 30;
            }
            
            // NOVO: Filtrar por uma Etapa específica do Gráfico
            if (widget.etapaFiltro.isNotEmpty) {
              if (jovem['status'] != 'Preparação') return false;
              Map<String, dynamic> statusGeral = _obterStatusAtual(jovem['etapas'] ?? [], jovem['sexo'], jovem['status'] ?? '', widget.isEstagnado);
              if (statusGeral['texto'] != widget.etapaFiltro) return false;
            } else {
              // Comportamentos Padrões
              if (widget.statusFiltro == 'Perspectiva') {
                return jovem['status'] == 'Perspectiva' || jovem['status'] == 'Indeciso';
              }
              if (widget.statusFiltro == 'Finalizado') {
                return jovem['status'] == 'Finalizado' || jovem['status'] == 'Enviado';
              }
              if (widget.statusFiltro.isNotEmpty) {
                return jovem['status'] == widget.statusFiltro;
              }
            }
            return true;
          }).toList();

          jovensFiltrados.sort((a, b) => (a['nome'] ?? '').toString().toLowerCase().compareTo((b['nome'] ?? '').toString().toLowerCase()));

          if (jovensFiltrados.isEmpty) {
            return const Center(child: Text("Nenhum jovem nesta situação.", style: TextStyle(color: Colors.grey)));
          }

          Widget construirTileJovem(Map<String, dynamic> jovem, Color corStatus, IconData iconeStatus) {
            String telefone = jovem['telefone'] ?? '';
            bool isIndeciso = jovem['status'] == 'Indeciso';
            bool isPerspectiva = jovem['status'] == 'Perspectiva' || isIndeciso;

            String subtitulo = isVisaoBispo ? "${jovem['idade']} anos" : "${jovem['unidade']} • ${jovem['estaca']}";
            if (widget.isEstagnado && !isIndeciso) subtitulo = "Sem atualização há >30 dias • $subtitulo";
            if (isIndeciso) subtitulo = "Não decidiu ainda • $subtitulo";

            return Container(
              decoration: BoxDecoration(border: Border(top: BorderSide(color: isEscuro ? Colors.white12 : Colors.grey.shade100))),
              child: ListTile(
                onTap: () {
                  if (isPerspectiva) _mostrarOpcoesEntrevista(jovem);
                  else _abrirPainelDoJovem(jovem);
                },
                contentPadding: const EdgeInsets.only(left: 32, right: 16),
                leading: CircleAvatar(
                  backgroundColor: corStatus.withValues(alpha: 0.15),
                  child: Icon(iconeStatus, color: corStatus, size: 20),
                ),
                title: Text(jovem['nome'] ?? '', style: TextStyle(fontWeight: FontWeight.w500, color: corTexto, fontSize: 14)),
                subtitle: Text(subtitulo, style: TextStyle(color: (widget.isEstagnado || isIndeciso) ? Colors.redAccent : Colors.grey, fontSize: 12)),
                trailing: isPerspectiva
                    ? OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isIndeciso ? Colors.redAccent : Colors.orange, 
                          side: BorderSide(color: isIndeciso ? Colors.redAccent : Colors.orange), 
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ), 
                        onPressed: () => _mostrarOpcoesEntrevista(jovem), 
                        child: const Text("Entrevistado", style: TextStyle(fontSize: 12))
                      )
                    : (telefone.isNotEmpty
                        ? IconButton(icon: const Icon(Icons.chat, color: Colors.green, size: 20), onPressed: () => _abrirWhatsApp(telefone))
                        : const Icon(Icons.phone_disabled, color: Colors.grey, size: 18)),
              ),
            );
          }

          // Se for "Preparação" GLOBAL (Sem filtro específico de etapa clicada no gráfico) -> Monta Kanban
          if (widget.statusFiltro == 'Preparação' && widget.etapaFiltro.isEmpty) {
            Map<String, List<Map<String, dynamic>>> agrupamentoEtapas = {};
            for (var j in jovensFiltrados) {
              Map<String, dynamic> statusGeral = _obterStatusAtual(j['etapas'] ?? [], j['sexo'], j['status'], widget.isEstagnado);
              String etapa = statusGeral['texto'];
              agrupamentoEtapas.putIfAbsent(etapa, () => []).add(j);
            }

            List<String> etapasOrdenadas = agrupamentoEtapas.keys.toList()..sort();

            return ListView(
              padding: const EdgeInsets.all(16),
              children: etapasOrdenadas.map((etapa) {
                List<Map<String, dynamic>> lista = agrupamentoEtapas[etapa]!;
                Map<String, dynamic> statusGrupo = _obterStatusAtual(lista.first['etapas'] ?? [], lista.first['sexo'], lista.first['status'], false);
                Color corGrupo = statusGrupo['cor'];
                IconData iconeGrupo = statusGrupo['icone'];

                return Card(
                  color: corFundo, margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isEscuro ? Colors.white12 : Colors.grey.shade200)),
                  elevation: 0,
                  child: Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      initiallyExpanded: true,
                      iconColor: corGrupo, collapsedIconColor: Colors.grey,
                      leading: CircleAvatar(backgroundColor: corGrupo.withValues(alpha: 0.15), child: Icon(iconeGrupo, color: corGrupo)),
                      title: Text("$etapa (${lista.length})", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: corTexto)),
                      children: lista.map((jovem) => construirTileJovem(jovem, corGrupo, iconeGrupo)).toList(),
                    ),
                  ),
                );
              }).toList(),
            );
          } 
          else {
            // Outras situações (Perspectiva, Finalizado, ou Uma Etapa Específica Clicada no Gráfico)
            if (isVisaoBispo) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: jovensFiltrados.map((jovem) {
                  Map<String, dynamic> status = _obterStatusAtual(jovem['etapas'] ?? [], jovem['sexo'], jovem['status'], widget.isEstagnado);
                  return Card(
                    color: corFundo, margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isEscuro ? Colors.white12 : Colors.grey.shade200)),
                    elevation: 0,
                    child: construirTileJovem(jovem, status['cor'], status['icone']),
                  );
                }).toList(),
              );
            } else {
              // Estaca/Gestor: Árvore Estaca -> Ala
              Map<String, Map<String, List<Map<String, dynamic>>>> arvore = {};
              for (var jovem in jovensFiltrados) {
                String estaca = jovem['estaca'] ?? 'Estaca Desconhecida';
                String unidade = jovem['unidade'] ?? 'Ala Desconhecida';
                arvore.putIfAbsent(estaca, () => {});
                arvore[estaca]!.putIfAbsent(unidade, () => []).add(jovem);
              }
              List<String> estacasOrdenadas = arvore.keys.toList()..sort();

              return ListView(
                padding: const EdgeInsets.all(16),
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
                        initiallyExpanded: true,
                        iconColor: Colors.purple, collapsedIconColor: Colors.grey,
                        leading: CircleAvatar(backgroundColor: Colors.purple.withValues(alpha: 0.15), child: const Icon(Icons.map, color: Colors.purple)),
                        title: Text(estaca, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: corTexto)),
                        children: alasOrdenadas.map((ala) {
                          List<Map<String, dynamic>> listaJovens = alasMap[ala]!;
                          return Padding(
                            padding: const EdgeInsets.only(left: 16),
                            child: ExpansionTile(
                              initiallyExpanded: alasOrdenadas.length == 1,
                              iconColor: Colors.orange, collapsedIconColor: Colors.grey,
                              leading: const Icon(Icons.church, color: Colors.orange),
                              title: Text("$ala (${listaJovens.length})", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: corTexto)),
                              children: listaJovens.map((jovem) {
                                Map<String, dynamic> status = _obterStatusAtual(jovem['etapas'] ?? [], jovem['sexo'], jovem['status'], widget.isEstagnado);
                                return construirTileJovem(jovem, status['cor'], status['icone']);
                              }).toList(),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  );
                }).toList(),
              );
            }
          }
        },
      ),
    );
  }
}
// ignore_for_file: unnecessary_cast
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dashboard_list.dart';

class AbaDashboardEstaca extends StatefulWidget {
  const AbaDashboardEstaca({super.key});

  @override
  State<AbaDashboardEstaca> createState() => _AbaDashboardEstacaState();
}

class _AbaDashboardEstacaState extends State<AbaDashboardEstaca> {
  String _minhaEstaca = "";
  int _metaAnual = 50;
  bool _carregandoPerfil = true;
  Stream<QuerySnapshot>? _streamJovens;

  List<String> _nomesEtapasRapazes = [];
  List<String> _nomesEtapasMocas = [];
  StreamSubscription? _etapasSub;

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

  Map<String, dynamic> _obterStatusAtual(List<dynamic> etapas, String sexo, String statusBD) {
    if (statusBD == 'Indeciso') return {'texto': 'Não decidiu ainda', 'cor': Colors.redAccent};
    if (statusBD == 'Perspectiva') return {'texto': 'Em Perspectiva', 'cor': Colors.orange};
    if (statusBD == 'Finalizado' || statusBD == 'Enviado') return {'texto': 'Processo Finalizado', 'cor': Colors.green};

    List<String> listaEtapas = sexo == 'Masculino' ? _nomesEtapasRapazes : _nomesEtapasMocas;
    int indexPendente = etapas.indexOf(false);
    
    if (etapas.isEmpty || indexPendente == 0) return {'texto': listaEtapas.isNotEmpty ? listaEtapas[0] : 'Iniciando...', 'cor': _paletaCores[0]};
    if (indexPendente == -1 || indexPendente >= listaEtapas.length) return {'texto': 'Processo Finalizado!', 'cor': Colors.green};
    
    return {'texto': listaEtapas[indexPendente], 'cor': _paletaCores[indexPendente % _paletaCores.length]};
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
            _metaAnual = dados['meta_anual'] ?? 50;
            _carregandoPerfil = false;
          });
          _iniciarConexaoBanco();
        } else {
          if (mounted) setState(() => _carregandoPerfil = false);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _carregandoPerfil = false);
    }
  }

  void _iniciarConexaoBanco() {
    if (_minhaEstaca.isNotEmpty && _minhaEstaca != 'Global (Todas)') {
      _streamJovens = FirebaseFirestore.instance.collection('jovens').where('estaca', isEqualTo: _minhaEstaca).snapshots();
    }
  }

  Future<void> _atualizarAoPuxar() async {
    setState(() => _iniciarConexaoBanco());
    await Future.delayed(const Duration(seconds: 1));
  }

  void _editarMeta() {
    bool isEscuro = Theme.of(context).brightness == Brightness.dark;
    TextEditingController metaCtrl = TextEditingController(text: _metaAnual.toString());
    
    showDialog(
      context: context,
      builder: (contextDialog) => AlertDialog(
        backgroundColor: isEscuro ? const Color(0xFF1E1E1E) : Colors.white,
        title: Text("Definir Meta Anual", style: TextStyle(color: isEscuro ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: metaCtrl,
          keyboardType: TextInputType.number,
          style: TextStyle(color: isEscuro ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            labelText: "Quantidade de Envios",
            filled: true, fillColor: isEscuro ? Colors.black26 : Colors.grey.shade100,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(contextDialog), child: const Text("Cancelar", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
            onPressed: () async {
              int novaMeta = int.tryParse(metaCtrl.text.trim()) ?? 50;
              User? user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).update({'meta_anual': novaMeta});
                setState(() => _metaAnual = novaMeta);
              }
              if (context.mounted) Navigator.pop(contextDialog);
            },
            child: const Text("Salvar"),
          ),
        ],
      ),
    );
  }

  Widget _construirCartaoDashboard(String titulo, String valor, Color cor, IconData icone, bool isEscuro, VoidCallback onTap) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: isEscuro ? const Color(0xFF1E1E1E) : Colors.white, 
          borderRadius: BorderRadius.circular(16), 
          border: Border.all(color: isEscuro ? Colors.white12 : Colors.grey.shade200), 
          boxShadow: [BoxShadow(color: cor.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))]
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              child: Column(
                children: [
                  Icon(icone, color: cor, size: 28), const SizedBox(height: 8),
                  Text(valor, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isEscuro ? Colors.white : Colors.black)),
                  const SizedBox(height: 4),
                  FittedBox(fit: BoxFit.scaleDown, child: Text(titulo, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _construirGraficoProgresso(List<Map<String, dynamic>> finalizados, bool isEscuro) {
    int anoAtual = DateTime.now().year;
    int mesAtual = DateTime.now().month;

    List<int> contagemMensal = List.filled(12, 0);
    for (var j in finalizados) {
      String data = j['data_envio'] ?? '';
      if (data.length == 10) {
        int? ano = int.tryParse(data.substring(6, 10));
        int? mes = int.tryParse(data.substring(3, 5));
        if (ano == anoAtual && mes != null && mes >= 1 && mes <= 12) {
          contagemMensal[mes - 1]++;
        }
      }
    }

    List<int> acumuladoMensal = List.filled(12, 0);
    int soma = 0;
    for (int i = 0; i < mesAtual; i++) {
      soma += contagemMensal[i];
      acumuladoMensal[i] = soma;
    }

    List<FlSpot> spots = [];
    for (int i = 0; i < mesAtual; i++) {
      spots.add(FlSpot((i + 1).toDouble(), acumuladoMensal[i].toDouble()));
    }

    double maxY = (_metaAnual > soma ? _metaAnual : soma) + 5.0;

    return Container(
      width: double.infinity,
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: isEscuro ? const Color(0xFF1E1E1E) : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: isEscuro ? Colors.white12 : Colors.grey.shade200), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Progresso Anual ($anoAtual)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isEscuro ? Colors.white : Colors.black87)),
              IconButton(icon: const Icon(Icons.edit, size: 18, color: Colors.blue), onPressed: _editarMeta, constraints: const BoxConstraints(), padding: EdgeInsets.zero),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (value) => FlLine(color: isEscuro ? Colors.white12 : Colors.grey.shade200, strokeWidth: 1)),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 35, // ESPAÇO ADICIONADO PARA CORRIGIR O CORTE
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        const style = TextStyle(color: Colors.grey, fontSize: 10);
                        List<String> meses = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
                        if (value.toInt() >= 1 && value.toInt() <= 12 && value.toInt() % 2 != 0) {
                          return SideTitleWidget(
                            meta: meta,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 8.0), 
                              child: Text(meses[value.toInt() - 1], style: style)
                            )
                          );
                        }
                        return SideTitleWidget(meta: meta, child: const SizedBox.shrink());
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, getTitlesWidget: (value, meta) => SideTitleWidget(meta: meta, child: Text(value.toInt().toString(), style: const TextStyle(color: Colors.grey, fontSize: 10))))),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minX: 1, maxX: 12, minY: 0, maxY: maxY,
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: _metaAnual.toDouble(),
                      color: Colors.orange,
                      strokeWidth: 2,
                      dashArray: [5, 5],
                      label: HorizontalLineLabel(show: true, alignment: Alignment.topRight, padding: const EdgeInsets.only(right: 5, bottom: 5), style: const TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold), labelResolver: (line) => 'Meta ($_metaAnual)'),
                    )
                  ]
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: true, getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(radius: 4, color: Colors.white, strokeWidth: 2, strokeColor: Colors.blue)),
                    belowBarData: BarAreaData(show: true, color: Colors.blue.withValues(alpha: 0.15)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirGraficoGargalos(List<Map<String, dynamic>> emProcesso, bool isEscuro) {
    if (emProcesso.isEmpty) return const SizedBox.shrink();

    Map<String, int> contagem = {};
    Map<String, Color> cores = {};

    for (var j in emProcesso) {
      Map<String, dynamic> status = _obterStatusAtual(j['etapas'] ?? [], j['sexo'] ?? 'Masculino', j['status'] ?? '');
      String etapa = status['texto'];
      contagem[etapa] = (contagem[etapa] ?? 0) + 1;
      cores[etapa] = status['cor'];
    }

    List<String> etapasOrdenadas = contagem.keys.toList();
    etapasOrdenadas.sort((a, b) {
      int indexA = _nomesEtapasRapazes.indexOf(a);
      int indexB = _nomesEtapasRapazes.indexOf(b);
      if (indexA == -1) indexA = 999;
      if (indexB == -1) indexB = 999;
      return indexA.compareTo(indexB);
    });

    List<BarChartGroupData> barGroups = [];
    double maxY = 0;

    for (int i = 0; i < etapasOrdenadas.length; i++) {
      String etapa = etapasOrdenadas[i];
      int valor = contagem[etapa]!;
      if (valor > maxY) maxY = valor.toDouble();

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: valor.toDouble(),
              color: cores[etapa],
              width: 25,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: 320,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: isEscuro ? const Color(0xFF1E1E1E) : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: isEscuro ? Colors.white12 : Colors.grey.shade200), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart, color: Colors.blue, size: 20), const SizedBox(width: 8),
              Text("Distribuição no Checklist", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isEscuro ? Colors.white : Colors.black87)),
            ],
          ),
          const SizedBox(height: 5),
          const Text("Toque em uma barra para ver os jovens nesta etapa", style: TextStyle(color: Colors.grey, fontSize: 11)),
          const SizedBox(height: 25),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: (etapasOrdenadas.length * 80.0).clamp(MediaQuery.of(context).size.width - 64, double.infinity),
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxY + 2,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchCallback: (FlTouchEvent event, barTouchResponse) {
                        if (event is FlTapUpEvent && barTouchResponse != null && barTouchResponse.spot != null) {
                          int index = barTouchResponse.spot!.touchedBarGroupIndex;
                          String etapaClicada = etapasOrdenadas[index];
                          Navigator.push(context, MaterialPageRoute(builder: (_) => DashboardList(
                            titulo: etapaClicada,
                            statusFiltro: "Preparação",
                            etapaFiltro: etapaClicada,
                            minhaEstaca: _minhaEstaca
                          )));
                        }
                      },
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          String nomeEtapa = etapasOrdenadas[group.x];
                          return BarTooltipItem(
                            '$nomeEtapa\n',
                            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            children: <TextSpan>[
                              TextSpan(text: '${rod.toY.toInt()} jovens', style: TextStyle(color: cores[nomeEtapa], fontSize: 12, fontWeight: FontWeight.w500)),
                            ],
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 45,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            int index = value.toInt();
                            if (index >= 0 && index < etapasOrdenadas.length) {
                              String titulo = etapasOrdenadas[index];
                              if (titulo.length > 12) titulo = "${titulo.substring(0, 10)}...";
                              return SideTitleWidget(
                                meta: meta,
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(titulo, style: const TextStyle(fontSize: 10, color: Colors.grey), textAlign: TextAlign.center),
                                ),
                              );
                            }
                            return SideTitleWidget(meta: meta, child: const SizedBox.shrink());
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 35,
                          getTitlesWidget: (value, meta) {
                            if (value == value.toInt().toDouble()) {
                              return SideTitleWidget(meta: meta, child: Text(value.toInt().toString(), style: const TextStyle(fontSize: 10, color: Colors.grey)));
                            }
                            return SideTitleWidget(meta: meta, child: const SizedBox.shrink());
                          },
                        )
                      ),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: FlGridData(
                      show: true, 
                      drawVerticalLine: false, 
                      horizontalInterval: 1,
                      getDrawingHorizontalLine: (value) => FlLine(color: isEscuro ? Colors.white12 : Colors.grey.shade300, strokeWidth: 1, dashArray: [4, 4]),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: barGroups,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isEscuro = Theme.of(context).brightness == Brightness.dark;
    Color corFundo = isEscuro ? const Color(0xFF1E1E1E) : Colors.white;
    Color corTexto = isEscuro ? Colors.white : Colors.black87;

    if (_carregandoPerfil || _minhaEstaca.isEmpty) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(backgroundColor: corFundo, elevation: 1),
        body: const Center(child: CircularProgressIndicator(color: Colors.purple)),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(automaticallyImplyLeading: false, title: Text('Painel da Estaca - $_minhaEstaca', style: TextStyle(fontWeight: FontWeight.bold, color: corTexto)), backgroundColor: corFundo, elevation: 1),
      
      body: StreamBuilder<QuerySnapshot>(
        stream: _streamJovens,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.purple));
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("Nenhum jovem cadastrado na Estaca ainda.", style: TextStyle(color: Colors.grey)));

          List<Map<String, dynamic>> todosJovens = snapshot.data!.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();

          List<Map<String, dynamic>> listaFinalizados = todosJovens.where((j) => j['status'] == 'Finalizado' || j['status'] == 'Enviado').toList();
          List<Map<String, dynamic>> listaEmProcesso = todosJovens.where((j) => j['status'] == 'Preparação').toList();
          
          int totalPerspectiva = todosJovens.where((j) => j['status'] == 'Perspectiva' || j['status'] == 'Indeciso').length;
          int totalPreparacao = listaEmProcesso.length;
          int totalFinalizadosCount = listaFinalizados.length;

          int totalParados = todosJovens.where((j) {
            if (j['status'] == 'Finalizado' || j['status'] == 'Enviado') return false;
            if (j['status'] == 'Indeciso') return true;
            if (j['ultima_atualizacao'] == null) return false;
            int dias = DateTime.now().difference((j['ultima_atualizacao'] as Timestamp).toDate()).inDays;
            return dias > 30;
          }).length;

          return RefreshIndicator(
            onRefresh: _atualizarAoPuxar,
            color: Colors.purple,
            backgroundColor: isEscuro ? const Color(0xFF1E1E1E) : Colors.white,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _construirCartaoDashboard("Perspectiva", totalPerspectiva.toString(), Colors.orange, Icons.radar, isEscuro, () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => DashboardList(titulo: "Jovens em Perspectiva", statusFiltro: "Perspectiva", minhaEstaca: _minhaEstaca)));
                      }),
                      const SizedBox(width: 10),
                      _construirCartaoDashboard("Em processo", totalPreparacao.toString(), Colors.blue, Icons.assignment_ind, isEscuro, () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => DashboardList(titulo: "Jovens em processo", statusFiltro: "Preparação", minhaEstaca: _minhaEstaca)));
                      }),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _construirCartaoDashboard("Finalizados", totalFinalizadosCount.toString(), Colors.green, Icons.check_circle, isEscuro, () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => DashboardList(titulo: "Jovens Finalizados", statusFiltro: "Finalizado", minhaEstaca: _minhaEstaca)));
                      }),
                      const SizedBox(width: 10),
                      _construirCartaoDashboard("Estagnados", totalParados.toString(), Colors.redAccent, Icons.warning_amber_rounded, isEscuro, () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => DashboardList(titulo: "Fichas Estagnadas", isEstagnado: true, minhaEstaca: _minhaEstaca)));
                      }),
                    ],
                  ),
                  
                  const SizedBox(height: 25),
                  _construirGraficoProgresso(listaFinalizados, isEscuro),
                  
                  if (listaEmProcesso.isNotEmpty) ...[
                    const SizedBox(height: 25),
                    _construirGraficoGargalos(listaEmProcesso, isEscuro),
                  ],

                  const SizedBox(height: 25),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: corFundo, borderRadius: BorderRadius.circular(16), border: Border.all(color: isEscuro ? Colors.white12 : Colors.grey.shade200)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.lightbulb_outline, color: Colors.purple, size: 20), const SizedBox(width: 8),
                            Text("Ação Recomendada", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: corTexto)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          totalParados > 0 
                            ? "Existem $totalParados jovens na estaca há mais de 30 dias sem atualização. Clique no quadro vermelho acima e contate os responsáveis."
                            : "Excelente! Nenhum jovem da sua estaca está com a ficha estagnada.", 
                          style: TextStyle(color: isEscuro ? Colors.white70 : Colors.black87, fontSize: 14)
                        ),
                      ],
                    ),
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
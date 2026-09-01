import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';

class AbaDashboardEstaca extends StatefulWidget {
  const AbaDashboardEstaca({super.key});

  @override
  State<AbaDashboardEstaca> createState() => _AbaDashboardEstacaState();
}

class _AbaDashboardEstacaState extends State<AbaDashboardEstaca> {
  String _minhaEstaca = "";
  bool _carregandoPerfil = true;
  
  Stream<QuerySnapshot>? _streamJovens;

  int _indiceTocadoStatus = -1;
  int _indiceTocadoGenero = -1;

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

  Widget _construirGraficoPizza(String titulo, List<PieChartSectionData> secoes, List<Widget> legendas, bool isEscuro) {
    return Expanded(
      child: Container(
        height: 220,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: isEscuro ? const Color(0xFF1E1E1E) : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: isEscuro ? Colors.white12 : Colors.grey.shade200), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))]),
        child: Column(
          children: [
            Text(titulo, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isEscuro ? Colors.white : Colors.black87)),
            const SizedBox(height: 10),
            Expanded(
              child: secoes.isEmpty 
                ? const Center(child: Text("Sem dados", style: TextStyle(color: Colors.grey)))
                : PieChart(
                    PieChartData(
                      sectionsSpace: 2, centerSpaceRadius: 25, sections: secoes,
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          setState(() {
                            if (!event.isInterestedForInteractions || pieTouchResponse == null || pieTouchResponse.touchedSection == null) {
                              if (titulo.contains("Status")) _indiceTocadoStatus = -1;
                              if (titulo.contains("Gênero")) _indiceTocadoGenero = -1;
                              return;
                            }
                            if (titulo.contains("Status")) _indiceTocadoStatus = pieTouchResponse.touchedSection!.touchedSectionIndex;
                            if (titulo.contains("Gênero")) _indiceTocadoGenero = pieTouchResponse.touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                    ),
                  ),
            ),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: legendas),
          ],
        ),
      ),
    );
  }

  Widget _indicadorLegenda(Color cor, String texto, bool isEscuro) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: cor)),
        const SizedBox(width: 4),
        Text(texto, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isEscuro ? Colors.white70 : Colors.black54)),
      ],
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
      appBar: AppBar(automaticallyImplyLeading: false, title: Text('Painel Analítico - $_minhaEstaca', style: TextStyle(fontWeight: FontWeight.bold, color: corTexto)), backgroundColor: corFundo, elevation: 1),
      
      body: StreamBuilder<QuerySnapshot>(
        stream: _streamJovens,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.purple));
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("Nenhum jovem cadastrado na Estaca ainda.", style: TextStyle(color: Colors.grey)));

          List<Map<String, dynamic>> todosJovens = snapshot.data!.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();

          int totalPerspectiva = todosJovens.where((j) => j['status'] == 'Perspectiva').length;
          int totalPreparacao = todosJovens.where((j) => j['status'] == 'Preparação').length;
          int totalEnviados = todosJovens.where((j) => j['status'] == 'Enviado').length;

          // Calcula Jovens Parados (> 30 dias sem atualização)
          int totalParados = todosJovens.where((j) {
            if (j['status'] == 'Enviado' || j['ultima_atualizacao'] == null) return false;
            int dias = DateTime.now().difference((j['ultima_atualizacao'] as Timestamp).toDate()).inDays;
            return dias > 30;
          }).length;

          int totalRapazes = todosJovens.where((j) => j['sexo'] == 'Masculino').length;
          int totalMocas = todosJovens.where((j) => j['sexo'] == 'Feminino').length;

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
                      _construirCartaoDashboard("Perspectiva", totalPerspectiva.toString(), Colors.orange, Icons.radar, isEscuro),
                      const SizedBox(width: 10),
                      _construirCartaoDashboard("Preparação", totalPreparacao.toString(), Colors.blue, Icons.assignment_ind, isEscuro),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _construirCartaoDashboard("Enviados", totalEnviados.toString(), Colors.green, Icons.flight_takeoff, isEscuro),
                      const SizedBox(width: 10),
                      _construirCartaoDashboard("Estagnados", totalParados.toString(), Colors.redAccent, Icons.warning_amber_rounded, isEscuro),
                    ],
                  ),
                  const SizedBox(height: 25),
                  Text("Proporção da Estaca", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _construirGraficoPizza(
                        "Status do Processo", 
                        [
                          if (totalPerspectiva > 0) PieChartSectionData(value: totalPerspectiva.toDouble(), color: Colors.orange, title: '$totalPerspectiva', radius: _indiceTocadoStatus == 0 ? 35 : 30, titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                          if (totalPreparacao > 0) PieChartSectionData(value: totalPreparacao.toDouble(), color: Colors.blue, title: '$totalPreparacao', radius: _indiceTocadoStatus == 1 ? 35 : 30, titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                          if (totalEnviados > 0) PieChartSectionData(value: totalEnviados.toDouble(), color: Colors.green, title: '$totalEnviados', radius: _indiceTocadoStatus == 2 ? 35 : 30, titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                        ], 
                        [
                          _indicadorLegenda(Colors.orange, "Persp.", isEscuro),
                          _indicadorLegenda(Colors.blue, "Prep.", isEscuro),
                          _indicadorLegenda(Colors.green, "Env.", isEscuro),
                        ],
                        isEscuro
                      ),
                      const SizedBox(width: 10),
                      _construirGraficoPizza(
                        "Gênero", 
                        [
                          if (totalRapazes > 0) PieChartSectionData(value: totalRapazes.toDouble(), color: Colors.blue.shade700, title: '$totalRapazes', radius: _indiceTocadoGenero == 0 ? 35 : 30, titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                          if (totalMocas > 0) PieChartSectionData(value: totalMocas.toDouble(), color: Colors.pink.shade400, title: '$totalMocas', radius: _indiceTocadoGenero == 1 ? 35 : 30, titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                        ], 
                        [
                          _indicadorLegenda(Colors.blue.shade700, "Rapazes", isEscuro),
                          _indicadorLegenda(Colors.pink.shade400, "Moças", isEscuro),
                        ],
                        isEscuro
                      ),
                    ],
                  ),
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
                            ? "Existem $totalParados jovens na estaca há mais de 30 dias sem nenhuma atualização. Utilize a aba 'Contatos' para incentivar os Bispos responsáveis."
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
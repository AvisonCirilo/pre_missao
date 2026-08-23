import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AbaPainel extends StatefulWidget {
  const AbaPainel({super.key});

  @override
  State<AbaPainel> createState() => _AbaPainelState();
}

class _AbaPainelState extends State<AbaPainel> {
  int _qtdEnviados = 2;

  final List<Map<String, dynamic>> _jovensPreparacao = [
    {'id': '1', 'nome': 'João Silva', 'idade': 19, 'etapaAtual': 2, 'telefone': '5591900000000'},
    {'id': '2', 'nome': 'Mateus Oliveira', 'idade': 20, 'etapaAtual': 1, 'telefone': '5591900000000'},
    {'id': '3', 'nome': 'Carlos Eduardo', 'idade': 18, 'etapaAtual': 3, 'telefone': '5591900000000'},
  ];

  final List<Map<String, dynamic>> _jovensPerspectiva = [
    {'id': '4', 'nome': 'Lucas Souza', 'idade': 17, 'telefone': ''},
  ];

  // ==========================================
  // O CÉREBRO DA AUTOMAÇÃO DAS 4 ETAPAS
  // ==========================================
  Map<String, dynamic> _obterDadosDaEtapa(int etapa) {
    switch (etapa) {
      case 1:
        return {'titulo': 'Prep. Pessoal & Decisão', 'cor': Colors.blue, 'progresso': 0.25, 'icone': Icons.menu_book};
      case 2:
        return {'titulo': 'Exames & Entrevista', 'cor': Colors.orange, 'progresso': 0.50, 'icone': Icons.medical_services};
      case 3:
        return {'titulo': 'Portal Missionário', 'cor': Colors.purple, 'progresso': 0.75, 'icone': Icons.computer};
      case 4:
        return {'titulo': 'Entrevista Pres. Estaca', 'cor': Colors.green, 'progresso': 1.0, 'icone': Icons.verified};
      default:
        return {'titulo': 'Desconhecido', 'cor': Colors.grey, 'progresso': 0.0, 'icone': Icons.help};
    }
  }

  // ==========================================
  // FORMULÁRIO PARA ADICIONAR / EDITAR JOVEM (VOLTOU!)
  // ==========================================
  void _mostrarFormularioJovem({Map<String, dynamic>? jovemAtual, bool isPerspectiva = false}) {
    bool isEdicao = jovemAtual != null;
    
    final nomeCtrl = TextEditingController(text: isEdicao ? jovemAtual['nome'] : "");
    final idadeCtrl = TextEditingController(text: isEdicao ? jovemAtual['idade'].toString() : "");
    // Novo campo para o WhatsApp
    final telefoneCtrl = TextEditingController(text: isEdicao ? jovemAtual['telefone'] : ""); 

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24, 
            left: 24, right: 24, top: 24
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 20),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(isEdicao ? Icons.edit : Icons.person_add, color: Colors.blue),
                  const SizedBox(width: 10),
                  Text(isEdicao ? "Editar Jovem" : "Novo Jovem", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 25),

              TextField(
                controller: nomeCtrl,
                decoration: InputDecoration(
                  labelText: "Nome do Jovem", prefixIcon: const Icon(Icons.person),
                  filled: true, fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: idadeCtrl, keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Idade", prefixIcon: const Icon(Icons.cake),
                        filled: true, fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    flex: 4,
                    child: TextField(
                      controller: telefoneCtrl, keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: "Telefone (WhatsApp)", prefixIcon: const Icon(Icons.phone),
                        filled: true, fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue, foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                  ),
                  onPressed: () {
                    if (nomeCtrl.text.isEmpty || idadeCtrl.text.isEmpty) return;
                    
                    setState(() {
                      if (isEdicao) {
                        jovemAtual['nome'] = nomeCtrl.text;
                        jovemAtual['idade'] = int.tryParse(idadeCtrl.text) ?? 0;
                        jovemAtual['telefone'] = telefoneCtrl.text;
                      } else {
                        _jovensPerspectiva.add({
                          'id': DateTime.now().toString(),
                          'nome': nomeCtrl.text,
                          'idade': int.tryParse(idadeCtrl.text) ?? 0,
                          'telefone': telefoneCtrl.text,
                        });
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
      },
    );
  }

  Future<void> _chamarNoWhatsApp(String nome, String telefone, int etapa) async {
    // Se o líder não cadastrou o telefone, usa um número genérico só para não quebrar no teste
    String numeroLimpo = telefone.replaceAll(RegExp(r'[^0-9]'), '');
    if (numeroLimpo.isEmpty) numeroLimpo = '5591900000000';

    String mensagem = "Olá, $nome! Tudo bem? ";
    if (etapa == 1) mensagem += "Como estão os seus estudos e a sua preparação pessoal para a missão?";
    else if (etapa == 2) mensagem += "Como está o andamento dos seus exames médicos e odontológicos? Precisa de alguma ajuda?";
    else if (etapa == 3) mensagem += "Falta pouco! Conseguiu preencher os dados e anexar os laudos no Portal Missionário?";
    else if (etapa == 4) mensagem += "Excelente notícia! Sua entrevista com o Presidente da Estaca já está marcada?";

    final Uri url = Uri.parse('https://wa.me/$numeroLimpo?text=${Uri.encodeComponent(mensagem)}');
    
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Erro ao abrir WhatsApp');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao tentar abrir o WhatsApp.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _avancarEtapa(Map<String, dynamic> jovem) {
    setState(() {
      if (jovem['etapaAtual'] < 4) {
        jovem['etapaAtual']++;
      } else {
        _jovensPreparacao.remove(jovem);
        _qtdEnviados++;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Papéis de ${jovem['nome']} enviados com sucesso! 🎉'), backgroundColor: Colors.green),
        );
      }
    });
  }

  void _iniciarPreparacao(Map<String, dynamic> jovem) {
    setState(() {
      _jovensPerspectiva.remove(jovem);
      _jovensPreparacao.add({
        'id': jovem['id'],
        'nome': jovem['nome'],
        'idade': jovem['idade'],
        'etapaAtual': 1, 
        'telefone': jovem['telefone'] ?? ''
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Visão Geral da Ala', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      // O BOTÃO FLUTUANTE VOLTOU AQUI!
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarFormularioJovem(),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text("Novo Jovem", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. DASHBOARD
            Row(
              children: [
                _construirCartaoDashboard("Perspectiva", _jovensPerspectiva.length.toString(), Colors.orange, Icons.radar),
                const SizedBox(width: 10),
                _construirCartaoDashboard("Preparação", _jovensPreparacao.length.toString(), Colors.blue, Icons.assignment_ind),
                const SizedBox(width: 10),
                _construirCartaoDashboard("Enviados", _qtdEnviados.toString(), Colors.green, Icons.check_circle),
              ],
            ),
            const SizedBox(height: 30),

            // 2. LISTA: EM PREPARAÇÃO
            const Text("Processo Iniciado", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            
            if (_jovensPreparacao.isEmpty)
              const Text("Nenhum jovem em preparação.", style: TextStyle(color: Colors.grey))
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _jovensPreparacao.length,
                itemBuilder: (context, index) {
                  final jovem = _jovensPreparacao[index];
                  final dadosEtapa = _obterDadosDaEtapa(jovem['etapaAtual']);
                  
                  return Card(
                    color: Colors.white,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          // Envolvermos a Row principal em um GestureDetector ou InkWell permite edição
                          GestureDetector(
                            onTap: () => _mostrarFormularioJovem(jovemAtual: jovem, isPerspectiva: false),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: dadosEtapa['cor'].withValues(alpha: 0.15),
                                  child: Text(jovem['nome'][0], style: TextStyle(color: dadosEtapa['cor'], fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(jovem['nome'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: dadosEtapa['cor'].withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: dadosEtapa['cor'].withValues(alpha: 0.5)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(dadosEtapa['icone'], size: 12, color: dadosEtapa['cor']),
                                            const SizedBox(width: 4),
                                            Text(dadosEtapa['titulo'], style: TextStyle(fontSize: 11, color: dadosEtapa['cor'], fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    SizedBox(
                                      height: 40, width: 40,
                                      child: CircularProgressIndicator(
                                        value: dadosEtapa['progresso'],
                                        backgroundColor: Colors.grey.shade200,
                                        color: dadosEtapa['cor'],
                                        strokeWidth: 4,
                                      ),
                                    ),
                                    Text("${(dadosEtapa['progresso'] * 100).toInt()}%", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                  ],
                                )
                              ],
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Divider(),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton.icon(
                                onPressed: () => _chamarNoWhatsApp(jovem['nome'], jovem['telefone'], jovem['etapaAtual']),
                                icon: const Icon(Icons.chat, color: Colors.green, size: 18),
                                label: const Text("WhatsApp", style: TextStyle(color: Colors.green)),
                                style: TextButton.styleFrom(backgroundColor: Colors.green.withValues(alpha: 0.1)),
                              ),
                              ElevatedButton(
                                onPressed: () => _avancarEtapa(jovem),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: dadosEtapa['cor'],
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                                ),
                                child: Text(jovem['etapaAtual'] == 4 ? "Finalizar Envio" : "Avançar Etapa", style: const TextStyle(fontSize: 12)),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),

            const SizedBox(height: 25),

            // 3. LISTA: JOVENS EM PERSPECTIVA
            const Text("Missionários em Perspectiva", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            if (_jovensPerspectiva.isEmpty)
              const Text("Nenhum missionário em perspectiva.", style: TextStyle(color: Colors.grey))
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _jovensPerspectiva.length,
                itemBuilder: (context, index) {
                  final jovem = _jovensPerspectiva[index];
                  return Card(
                    color: Colors.white,
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                    elevation: 0,
                    child: ListTile(
                      onTap: () => _mostrarFormularioJovem(jovemAtual: jovem, isPerspectiva: true),
                      leading: const Icon(Icons.person, color: Colors.orange),
                      title: Text(jovem['nome'], style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text("${jovem['idade']} anos"),
                      trailing: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.orange, side: const BorderSide(color: Colors.orange),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                        ),
                        onPressed: () => _iniciarPreparacao(jovem),
                        child: const Text("Iniciar", style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  );
                },
              ),
            
            const SizedBox(height: 80), // Espaço para não cobrir itens com o botão flutuante
          ],
        ),
      ),
    );
  }

  Widget _construirCartaoDashboard(String titulo, String valor, Color cor, IconData icone) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [BoxShadow(color: cor.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Icon(icone, color: cor, size: 28),
            const SizedBox(height: 8),
            Text(valor, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(titulo, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
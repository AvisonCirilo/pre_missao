import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AbaPainel extends StatefulWidget {
  const AbaPainel({super.key});

  @override
  State<AbaPainel> createState() => _AbaPainelState();
}

class _AbaPainelState extends State<AbaPainel> {
  int _qtdEnviados = 2;

  final List<String> _nomesEtapas = [
    "Entrevista com o Bispo",
    "Abertura no Sistema",
    "Exame Médico",
    "Exame Dentário",
    "Acordo Financeiro",
    "Entrevista Pres. Estaca",
    "Envio do Chamado"
  ];

  final List<Map<String, dynamic>> _jovensPreparacao = [
    {
      'id': '1', 'nome': 'João Silva', 'idade': 19, 'telefone': '5591900000000',
      'etapas': <bool>[true, true, false, true, false, false, false] // Tipagem explícita adicionada
    },
    {
      'id': '2', 'nome': 'Mateus Oliveira', 'idade': 20, 'telefone': '5591900000000',
      'etapas': <bool>[true, false, false, false, false, false, false]
    },
  ];

  final List<Map<String, dynamic>> _jovensPerspectiva = [
    {'id': '3', 'nome': 'Lucas Souza', 'idade': 17, 'telefone': ''},
  ];

  // ==========================================
  // AUTOMAÇÃO E CÁLCULOS (CORRIGIDOS PARA DYNAMIC)
  // ==========================================
  // Mudamos de List<bool> para List<dynamic> para aceitar os dados do Firebase/Map
  double _calcularProgresso(List<dynamic> etapas) {
    int concluidas = etapas.where((etapa) => etapa == true).length;
    return concluidas / 7.0;
  }

  Map<String, dynamic> _obterStatusAtual(List<dynamic> etapas) {
    int concluidas = etapas.where((e) => e == true).length;
    
    if (concluidas == 7) {
      return {'texto': 'Pronto e Enviado!', 'cor': Colors.green, 'icone': Icons.check_circle};
    }
    
    int indexPendente = etapas.indexOf(false);
    String nomePendente = _nomesEtapas[indexPendente];

    Color cor;
    if (concluidas <= 2) cor = Colors.blue;
    else if (concluidas <= 5) cor = Colors.orange;
    else cor = Colors.purple;

    return {'texto': 'Pendente: $nomePendente', 'cor': cor, 'icone': Icons.pending_actions};
  }

  // ==========================================
  // FORMULÁRIO DE CADASTRO E EDIÇÃO
  // ==========================================
  void _mostrarFormularioJovem({Map<String, dynamic>? jovemAtual}) {
    bool isEdicao = jovemAtual != null;
    
    final nomeCtrl = TextEditingController(text: isEdicao ? jovemAtual['nome'] : "");
    final idadeCtrl = TextEditingController(text: isEdicao ? jovemAtual['idade'].toString() : "");
    final telefoneCtrl = TextEditingController(text: isEdicao ? jovemAtual['telefone'] : ""); 

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 24, left: 24, right: 24, top: 24),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
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
                decoration: InputDecoration(labelText: "Nome do Jovem", prefixIcon: const Icon(Icons.person), filled: true, fillColor: Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
              ),
              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(flex: 2, child: TextField(controller: idadeCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: "Idade", prefixIcon: const Icon(Icons.cake), filled: true, fillColor: Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)))),
                  const SizedBox(width: 15),
                  Expanded(flex: 4, child: TextField(controller: telefoneCtrl, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: "WhatsApp", prefixIcon: const Icon(Icons.phone), filled: true, fillColor: Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)))),
                ],
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: () {
                    if (nomeCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('O nome é obrigatório!'), backgroundColor: Colors.redAccent));
                      return;
                    }
                    
                    setState(() {
                      if (isEdicao) {
                        jovemAtual['nome'] = nomeCtrl.text.trim();
                        jovemAtual['idade'] = int.tryParse(idadeCtrl.text) ?? 0;
                        jovemAtual['telefone'] = telefoneCtrl.text.trim();
                      } else {
                        _jovensPerspectiva.add({
                          'id': DateTime.now().millisecondsSinceEpoch.toString(),
                          'nome': nomeCtrl.text.trim(),
                          'idade': int.tryParse(idadeCtrl.text) ?? 0,
                          'telefone': telefoneCtrl.text.trim(),
                        });
                      }
                    });
                    Navigator.pop(context); 
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEdicao ? 'Dados atualizados!' : 'Jovem adicionado!'), backgroundColor: Colors.green));
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

  // ==========================================
  // PAINEL DE CHECKLIST E GESTÃO DO JOVEM
  // ==========================================
  void _abrirPainelDoJovem(Map<String, dynamic> jovem) {
    // CORREÇÃO: Forçamos a cópia a ser estritamente List<bool> para o modal interno
    List<bool> etapasTemp = List<bool>.from(jovem['etapas']); 

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            double progressoModal = _calcularProgresso(etapasTemp);
            
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
              child: Column(
                children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(10))),
                  const SizedBox(height: 20),
                  
                  Row(
                    children: [
                      CircleAvatar(radius: 25, backgroundColor: Colors.blue.shade100, child: Text(jovem['nome'][0], style: const TextStyle(color: Colors.blue, fontSize: 20, fontWeight: FontWeight.bold))),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(jovem['nome'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                            Text("${jovem['idade']} anos", style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.grey),
                        onPressed: () {
                          Navigator.pop(context); 
                          _mostrarFormularioJovem(jovemAtual: jovem); 
                        },
                      ),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(height: 45, width: 45, child: CircularProgressIndicator(value: progressoModal, backgroundColor: Colors.grey.shade200, color: Colors.blue, strokeWidth: 4)),
                          Text("${(progressoModal * 100).toInt()}%", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      )
                    ],
                  ),
                  const Divider(height: 30),

                  Expanded(
                    child: ListView.builder(
                      itemCount: _nomesEtapas.length,
                      itemBuilder: (context, index) {
                        return CheckboxListTile(
                          title: Text(
                            _nomesEtapas[index],
                            style: TextStyle(
                              fontWeight: etapasTemp[index] ? FontWeight.normal : FontWeight.bold,
                              decoration: etapasTemp[index] ? TextDecoration.lineThrough : null,
                              color: etapasTemp[index] ? Colors.grey : Colors.black87,
                            ),
                          ),
                          value: etapasTemp[index],
                          activeColor: Colors.blue,
                          onChanged: (bool? valor) {
                            setStateModal(() => etapasTemp[index] = valor ?? false);
                          },
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 15),
                  
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _chamarNoWhatsApp(jovem['nome'], jovem['telefone'], etapasTemp),
                          icon: const Icon(Icons.chat, color: Colors.green), label: const Text("WhatsApp", style: TextStyle(color: Colors.green)),
                          style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.green), padding: const EdgeInsets.symmetric(vertical: 14)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              jovem['etapas'] = List<bool>.from(etapasTemp); // Salva novamente garantindo a tipagem
                            });
                            
                            Navigator.pop(context); 

                            if (_calcularProgresso(jovem['etapas']) == 1.0) {
                              Future.delayed(const Duration(milliseconds: 300), () {
                                setState(() {
                                  _jovensPreparacao.removeWhere((item) => item['id'] == jovem['id']);
                                  _qtdEnviados++;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chamado enviado com sucesso! 🎉'), backgroundColor: Colors.green));
                              });
                            }
                          },
                          icon: const Icon(Icons.save), label: const Text("Salvar"),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            );
          }
        );
      }
    );
  }

  // ==========================================
  // FUNÇÕES AUXILIARES
  // ==========================================
  Future<void> _chamarNoWhatsApp(String nome, String telefone, List<dynamic> etapas) async {
    String numeroLimpo = telefone.replaceAll(RegExp(r'[^0-9]'), '');
    if (numeroLimpo.isEmpty) numeroLimpo = '5591900000000';

    int indexPendente = etapas.indexOf(false);
    String nomeEtapaPendente = indexPendente != -1 ? _nomesEtapas[indexPendente] : "Enviou tudo";

    String mensagem = "Olá, $nome! Tudo bem? Vi aqui no sistema que a sua próxima etapa é: *$nomeEtapaPendente*. Precisa de alguma ajuda com isso?";
    final Uri url = Uri.parse('https://wa.me/$numeroLimpo?text=${Uri.encodeComponent(mensagem)}');
    
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) throw Exception();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao tentar abrir o WhatsApp.'), backgroundColor: Colors.red));
    }
  }

  void _iniciarPreparacao(Map<String, dynamic> jovem) {
    setState(() {
      _jovensPerspectiva.removeWhere((item) => item['id'] == jovem['id']);
      _jovensPreparacao.add({
        'id': jovem['id'],
        'nome': jovem['nome'],
        'idade': jovem['idade'],
        'telefone': jovem['telefone'] ?? '',
        // CORREÇÃO: Informando explicitamente o tipo List<bool> na hora de criar
        'etapas': <bool>[false, false, false, false, false, false, false]
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
        backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 1,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarFormularioJovem(), 
        backgroundColor: Colors.blue, foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add), label: const Text("Novo Jovem", style: TextStyle(fontWeight: FontWeight.bold)),
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
                shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                itemCount: _jovensPreparacao.length,
                itemBuilder: (context, index) {
                  final jovem = _jovensPreparacao[index];
                  double progressoAtual = _calcularProgresso(jovem['etapas']);
                  Map<String, dynamic> statusAtual = _obterStatusAtual(jovem['etapas']);
                  
                  return Card(
                    color: Colors.white, margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)), elevation: 0,
                    child: InkWell( 
                      onTap: () => _abrirPainelDoJovem(jovem), 
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: statusAtual['cor'].withValues(alpha: 0.15),
                              child: Text(jovem['nome'][0], style: TextStyle(color: statusAtual['cor'], fontWeight: FontWeight.bold)),
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
                                    decoration: BoxDecoration(color: statusAtual['cor'].withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(statusAtual['icone'], size: 12, color: statusAtual['cor']),
                                        const SizedBox(width: 4),
                                        Expanded(child: Text(statusAtual['texto'], style: TextStyle(fontSize: 11, color: statusAtual['cor'], fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(height: 45, width: 45, child: CircularProgressIndicator(value: progressoAtual, backgroundColor: Colors.grey.shade200, color: statusAtual['cor'], strokeWidth: 4)),
                                Text("${(progressoAtual * 100).toInt()}%", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              ],
                            )
                          ],
                        ),
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
                shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                itemCount: _jovensPerspectiva.length,
                itemBuilder: (context, index) {
                  final jovem = _jovensPerspectiva[index];
                  return Card(
                    color: Colors.white, margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)), elevation: 0,
                    child: ListTile(
                      onTap: () => _mostrarFormularioJovem(jovemAtual: jovem), 
                      leading: const Icon(Icons.person, color: Colors.orange),
                      title: Text(jovem['nome'], style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text("${jovem['idade']} anos"),
                      trailing: OutlinedButton(
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.orange, side: const BorderSide(color: Colors.orange), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                        onPressed: () => _iniciarPreparacao(jovem),
                        child: const Text("Iniciar", style: TextStyle(fontSize: 12)),
                      ),
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
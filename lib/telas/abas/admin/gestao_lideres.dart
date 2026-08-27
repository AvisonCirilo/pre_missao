import 'package:flutter/material.dart';

class GestaoLideresTela extends StatefulWidget {
  const GestaoLideresTela({super.key});

  @override
  State<GestaoLideresTela> createState() => _GestaoLideresTelaState();
}

class _GestaoLideresTelaState extends State<GestaoLideresTela> {
  // Banco de Dados Falso (Mock) para os líderes
  final List<Map<String, dynamic>> _lideres = [
    {'id': '1', 'nome': 'Irmão Silva', 'cargo': 'Bispo', 'unidade': 'Ala Centro', 'email': 'bispo.centro@email.com'},
    {'id': '2', 'nome': 'Irmão Costa', 'cargo': 'Pres. de Estaca', 'unidade': 'Estaca Norte', 'email': 'estaca.norte@email.com'},
  ];

  // Listas de opções para os Dropdowns
  final List<String> _opcoesCargo = ['Bispo', 'Pres. de Ramo', 'Líder da Missão da Ala', 'Pres. de Estaca', 'Sumo Conselheiro'];
  final List<String> _opcoesUnidade = ['Ala Centro', 'Ala Sul', 'Ramo Leste', 'Estaca Norte'];

  void _mostrarFormularioLider({Map<String, dynamic>? liderAtual}) {
    bool isEdicao = liderAtual != null;
    bool isEscuro = Theme.of(context).brightness == Brightness.dark;

    final nomeCtrl = TextEditingController(text: isEdicao ? liderAtual['nome'] : "");
    final emailCtrl = TextEditingController(text: isEdicao ? liderAtual['email'] : "");
    final senhaCtrl = TextEditingController(); 
    
    String cargoSelecionado = isEdicao ? liderAtual['cargo'] : _opcoesCargo[0];
    String unidadeSelecionada = isEdicao ? liderAtual['unidade'] : _opcoesUnidade[0];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return Container(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 24, left: 24, right: 24, top: 24),
              decoration: BoxDecoration(
                color: isEscuro ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(25))
              ),
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
                      Text(isEdicao ? "Editar Acesso" : "Novo Líder", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isEscuro ? Colors.white : Colors.black)),
                    ],
                  ),
                  const SizedBox(height: 25),

                  _construirCampoTexto("Nome Completo", nomeCtrl, Icons.person, isEscuro),
                  const SizedBox(height: 15),
                  
                  _construirCampoTexto("E-mail de Login", emailCtrl, Icons.email, isEscuro, isEmail: true),
                  const SizedBox(height: 15),

                  if (!isEdicao)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 15),
                      child: _construirCampoTexto("Senha Temporária", senhaCtrl, Icons.lock, isEscuro),
                    ),

                  Row(
                    children: [
                      Expanded(
                        child: _construirDropdown("Cargo", cargoSelecionado, _opcoesCargo, Icons.badge, isEscuro, (val) => setStateModal(() => cargoSelecionado = val!)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  Row(
                    children: [
                      Expanded(
                        child: _construirDropdown("Visão de Unidade", unidadeSelecionada, _opcoesUnidade, Icons.church, isEscuro, (val) => setStateModal(() => unidadeSelecionada = val!)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity, height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: () {
                        if (nomeCtrl.text.trim().isEmpty || emailCtrl.text.trim().isEmpty) return;
                        
                        setState(() {
                          if (isEdicao) {
                            liderAtual['nome'] = nomeCtrl.text.trim();
                            liderAtual['email'] = emailCtrl.text.trim();
                            liderAtual['cargo'] = cargoSelecionado;
                            liderAtual['unidade'] = unidadeSelecionada;
                          } else {
                            _lideres.add({
                              'id': DateTime.now().millisecondsSinceEpoch.toString(),
                              'nome': nomeCtrl.text.trim(),
                              'email': emailCtrl.text.trim(),
                              'cargo': cargoSelecionado,
                              'unidade': unidadeSelecionada,
                            });
                          }
                        });
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.save),
                      label: Text(isEdicao ? "Salvar Alterações" : "Criar Acesso", style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          }
        );
      },
    );
  }

  Widget _construirCampoTexto(String label, TextEditingController controller, IconData icon, bool isEscuro, {bool isEmail = false}) {
    return TextField(
      controller: controller,
      keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
      style: TextStyle(color: isEscuro ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        labelText: label, labelStyle: TextStyle(color: isEscuro ? Colors.white70 : Colors.grey.shade700),
        prefixIcon: Icon(icon, color: isEscuro ? Colors.white70 : Colors.grey.shade600),
        filled: true, fillColor: isEscuro ? Colors.black26 : Colors.grey.shade100,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
      ),
    );
  }

  Widget _construirDropdown(String label, String valorAtual, List<String> itens, IconData icon, bool isEscuro, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      initialValue: valorAtual,
      dropdownColor: isEscuro ? const Color(0xFF1E1E1E) : Colors.white,
      style: TextStyle(color: isEscuro ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        labelText: label, labelStyle: TextStyle(color: isEscuro ? Colors.white70 : Colors.grey.shade700),
        prefixIcon: Icon(icon, color: isEscuro ? Colors.white70 : Colors.grey.shade600),
        filled: true, fillColor: isEscuro ? Colors.black26 : Colors.grey.shade100,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
      ),
      items: itens.map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis))).toList(),
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isEscuro = Theme.of(context).brightness == Brightness.dark;
    Color corFundo = isEscuro ? const Color(0xFF1E1E1E) : Colors.white;
    Color corTexto = isEscuro ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Gestão de Líderes', style: TextStyle(fontWeight: FontWeight.bold, color: corTexto)),
        backgroundColor: corFundo,
        elevation: 1,
        iconTheme: IconThemeData(color: corTexto),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarFormularioLider(),
        backgroundColor: Colors.blue, foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add), label: const Text("Novo Líder", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _lideres.length,
        itemBuilder: (context, index) {
          final lider = _lideres[index];
          bool isEstaca = lider['cargo'].contains('Estaca') || lider['cargo'].contains('Sumo');

          // ==========================================
          // NOVO: DISMISSIBLE (DESLIZAR PARA APAGAR)
          // ==========================================
          return Dismissible(
            key: Key(lider['id']), // A chave única que o Flutter precisa para saber quem apagar
            direction: DismissDirection.endToStart, // Só permite deslizar da direita para a esquerda
            
            // Fundo vermelho com lixeira que aparece ao deslizar
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.delete, color: Colors.white, size: 30),
            ),
            
            // Caixa de confirmação antes de apagar de vez
            confirmDismiss: (direction) async {
              return await showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    backgroundColor: corFundo,
                    title: Text("Confirmar Exclusão", style: TextStyle(color: corTexto)),
                    content: Text("Tem certeza que deseja remover o acesso de ${lider['nome']}?", style: TextStyle(color: corTexto)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text("Apagar"),
                      ),
                    ],
                  );
                },
              );
            },
            
            // Ação que ocorre se o usuário confirmar a exclusão
            onDismissed: (direction) {
              setState(() {
                _lideres.removeAt(index);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${lider['nome']} foi removido.'), backgroundColor: Colors.redAccent)
              );
            },
            
            // O Cartão original do Líder fica dentro do child do Dismissible
            child: Card(
              color: corFundo, margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isEscuro ? Colors.white12 : Colors.grey.shade200)),
              elevation: 0,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                leading: CircleAvatar(
                  backgroundColor: isEstaca ? Colors.purple.withValues(alpha: 0.15) : Colors.blue.withValues(alpha: 0.15),
                  child: Icon(isEstaca ? Icons.admin_panel_settings : Icons.person, color: isEstaca ? Colors.purple : Colors.blue),
                ),
                title: Text(lider['nome'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: corTexto)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text("${lider['cargo']} • ${lider['unidade']}", style: TextStyle(color: isEscuro ? Colors.white70 : Colors.black87, fontWeight: FontWeight.w500)),
                    Text(lider['email'], style: TextStyle(color: isEscuro ? Colors.white54 : Colors.grey, fontSize: 12)),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.edit, color: Colors.grey),
                  onPressed: () => _mostrarFormularioLider(liderAtual: lider),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
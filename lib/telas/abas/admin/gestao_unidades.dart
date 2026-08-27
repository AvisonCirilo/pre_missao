import 'package:flutter/material.dart';

class GestaoUnidadesTela extends StatefulWidget {
  const GestaoUnidadesTela({super.key});

  @override
  State<GestaoUnidadesTela> createState() => _GestaoUnidadesTelaState();
}

class _GestaoUnidadesTelaState extends State<GestaoUnidadesTela> {
  // Banco de Dados Falso (Mock) para as unidades
  final List<Map<String, dynamic>> _unidades = [
    {'id': '1', 'nome': 'Centro', 'tipo': 'Ala', 'estaca': 'Estaca Norte'},
    {'id': '2', 'nome': 'Sul', 'tipo': 'Ala', 'estaca': 'Estaca Norte'},
    {'id': '3', 'nome': 'Leste', 'tipo': 'Ramo', 'estaca': 'Distrito Sul'},
  ];

  // Formulário para Adicionar ou Editar Unidade
  void _mostrarFormularioUnidade({Map<String, dynamic>? unidadeAtual}) {
    bool isEdicao = unidadeAtual != null;
    bool isEscuro = Theme.of(context).brightness == Brightness.dark;

    final nomeCtrl = TextEditingController(text: isEdicao ? unidadeAtual['nome'] : "");
    final estacaCtrl = TextEditingController(text: isEdicao ? unidadeAtual['estaca'] : "");
    String tipoSelecionado = isEdicao ? unidadeAtual['tipo'] : "Ala";

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
                      Icon(isEdicao ? Icons.edit : Icons.add_business, color: Colors.orange),
                      const SizedBox(width: 10),
                      Text(isEdicao ? "Editar Unidade" : "Nova Unidade", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isEscuro ? Colors.white : Colors.black)),
                    ],
                  ),
                  const SizedBox(height: 25),

                  // TIPO: Ala ou Ramo
                  DropdownButtonFormField<String>(
                    initialValue: tipoSelecionado,
                    dropdownColor: isEscuro ? const Color(0xFF1E1E1E) : Colors.white,
                    style: TextStyle(color: isEscuro ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      labelText: "Tipo de Unidade", labelStyle: TextStyle(color: isEscuro ? Colors.white70 : Colors.grey.shade700),
                      prefixIcon: Icon(Icons.apartment, color: isEscuro ? Colors.white70 : Colors.grey.shade600),
                      filled: true, fillColor: isEscuro ? Colors.black26 : Colors.grey.shade100,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
                    ),
                    items: ["Ala", "Ramo"].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (val) => setStateModal(() => tipoSelecionado = val!),
                  ),
                  const SizedBox(height: 15),

                  // NOME DA UNIDADE
                  TextField(
                    controller: nomeCtrl, style: TextStyle(color: isEscuro ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      labelText: "Nome (Ex: Centro)", labelStyle: TextStyle(color: isEscuro ? Colors.white70 : Colors.grey.shade700),
                      prefixIcon: Icon(Icons.church, color: isEscuro ? Colors.white70 : Colors.grey.shade600),
                      filled: true, fillColor: isEscuro ? Colors.black26 : Colors.grey.shade100,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
                    ),
                  ),
                  const SizedBox(height: 15),

                  // NOME DA ESTACA/DISTRITO
                  TextField(
                    controller: estacaCtrl, style: TextStyle(color: isEscuro ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      labelText: "Pertence à (Ex: Estaca Norte)", labelStyle: TextStyle(color: isEscuro ? Colors.white70 : Colors.grey.shade700),
                      prefixIcon: Icon(Icons.map, color: isEscuro ? Colors.white70 : Colors.grey.shade600),
                      filled: true, fillColor: isEscuro ? Colors.black26 : Colors.grey.shade100,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
                    ),
                  ),
                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity, height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: () {
                        if (nomeCtrl.text.trim().isEmpty || estacaCtrl.text.trim().isEmpty) return;
                        
                        setState(() {
                          if (isEdicao) {
                            unidadeAtual['nome'] = nomeCtrl.text.trim();
                            unidadeAtual['tipo'] = tipoSelecionado;
                            unidadeAtual['estaca'] = estacaCtrl.text.trim();
                          } else {
                            _unidades.add({
                              'id': DateTime.now().millisecondsSinceEpoch.toString(),
                              'nome': nomeCtrl.text.trim(),
                              'tipo': tipoSelecionado,
                              'estaca': estacaCtrl.text.trim(),
                            });
                          }
                        });
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.save),
                      label: Text(isEdicao ? "Salvar" : "Criar Unidade", style: const TextStyle(fontWeight: FontWeight.bold)),
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

  @override
  Widget build(BuildContext context) {
    bool isEscuro = Theme.of(context).brightness == Brightness.dark;
    Color corFundo = isEscuro ? const Color(0xFF1E1E1E) : Colors.white;
    Color corTexto = isEscuro ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Gestão de Unidades', style: TextStyle(fontWeight: FontWeight.bold, color: corTexto)),
        backgroundColor: corFundo,
        elevation: 1,
        iconTheme: IconThemeData(color: corTexto), // Seta de voltar
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarFormularioUnidade(),
        backgroundColor: Colors.orange, foregroundColor: Colors.white,
        icon: const Icon(Icons.add), label: const Text("Nova Unidade", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _unidades.length,
        itemBuilder: (context, index) {
          final und = _unidades[index];
          return Card(
            color: corFundo, margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isEscuro ? Colors.white12 : Colors.grey.shade200)),
            elevation: 0,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: Colors.orange.withValues(alpha: 0.15),
                child: const Icon(Icons.church, color: Colors.orange),
              ),
              title: Text("${und['tipo']} ${und['nome']}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: corTexto)),
              subtitle: Text(und['estaca'], style: TextStyle(color: isEscuro ? Colors.white54 : Colors.grey)),
              trailing: IconButton(
                icon: const Icon(Icons.edit, color: Colors.grey),
                onPressed: () => _mostrarFormularioUnidade(unidadeAtual: und),
              ),
            ),
          );
        },
      ),
    );
  }
}
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GestaoUnidadesTela extends StatefulWidget {
  const GestaoUnidadesTela({super.key});

  @override
  State<GestaoUnidadesTela> createState() => _GestaoUnidadesTelaState();
}

class _GestaoUnidadesTelaState extends State<GestaoUnidadesTela> {
  List<String> _estacasCadastradas = ['Nenhuma Estaca Criada'];

  @override
  void initState() {
    super.initState();
    _escutarEstacasDoBanco();
  }

  // Escuta o Firebase em tempo real buscando apenas as Estacas/Distritos
  void _escutarEstacasDoBanco() {
    FirebaseFirestore.instance
        .collection('unidades')
        .where('tipo', whereIn: ['Estaca', 'Distrito', 'Missão'])
        .snapshots()
        .listen((snapshot) {
          List<String> estacas = [];
          for (var doc in snapshot.docs) {
            estacas.add("${doc['tipo']} ${doc['nome']}");
          }
          if (mounted) {
            setState(() {
              _estacasCadastradas = estacas.isNotEmpty ? estacas : ['Nenhuma Estaca Criada'];
            });
          }
        });
  }

  void _mostrarFormularioUnidade({DocumentSnapshot? unidadeAtual}) {
    bool isEdicao = unidadeAtual != null;
    bool isEscuro = Theme.of(context).brightness == Brightness.dark;

    Map<String, dynamic>? dados = isEdicao ? unidadeAtual.data() as Map<String, dynamic> : null;

    final nomeCtrl = TextEditingController(text: isEdicao ? dados!['nome'] : "");
    String tipoSelecionado = isEdicao ? (dados!['tipo'] ?? "Ala") : "Ala";
    
    String estacaSelecionada = isEdicao ? (dados!['estaca'] ?? _estacasCadastradas.first) : _estacasCadastradas.first;
    if (!_estacasCadastradas.contains(estacaSelecionada)) estacaSelecionada = _estacasCadastradas.first;

    bool salvando = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            bool precisaDeEstaca = (tipoSelecionado == 'Ala' || tipoSelecionado == 'Ramo');

            return Container(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 24, left: 24, right: 24, top: 24),
              decoration: BoxDecoration(
                color: isEscuro ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: SingleChildScrollView(
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
                        Text(
                          isEdicao ? "Editar Unidade" : "Nova Unidade",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isEscuro ? Colors.white : Colors.black),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),

                    DropdownButtonFormField<String>(
                      initialValue: tipoSelecionado,
                      dropdownColor: isEscuro ? const Color(0xFF1E1E1E) : Colors.white,
                      style: TextStyle(color: isEscuro ? Colors.white : Colors.black87),
                      decoration: InputDecoration(
                        labelText: "Tipo de Unidade",
                        labelStyle: TextStyle(color: isEscuro ? Colors.white70 : Colors.grey.shade700),
                        prefixIcon: Icon(Icons.apartment, color: isEscuro ? Colors.white70 : Colors.grey.shade600),
                        filled: true,
                        fillColor: isEscuro ? Colors.black26 : Colors.grey.shade100,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      items: ["Ala", "Ramo", "Estaca", "Distrito", "Missão"].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (val) {
                        setStateModal(() => tipoSelecionado = val!);
                      },
                    ),
                    const SizedBox(height: 15),

                    TextField(
                      controller: nomeCtrl,
                      style: TextStyle(color: isEscuro ? Colors.white : Colors.black87),
                      decoration: InputDecoration(
                        labelText: "Nome da Ala",
                        labelStyle: TextStyle(color: isEscuro ? Colors.white70 : Colors.grey.shade700),
                        prefixIcon: Icon(Icons.church, color: isEscuro ? Colors.white70 : Colors.grey.shade600),
                        filled: true,
                        fillColor: isEscuro ? Colors.black26 : Colors.grey.shade100,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 15),

                    if (precisaDeEstaca)
                      DropdownButtonFormField<String>(
                        value: estacaSelecionada,
                        dropdownColor: isEscuro ? const Color(0xFF1E1E1E) : Colors.white,
                        style: TextStyle(color: isEscuro ? Colors.white : Colors.black87),
                        decoration: InputDecoration(
                          labelText: "Pertence à qual Estaca?",
                          labelStyle: TextStyle(color: isEscuro ? Colors.white70 : Colors.grey.shade700),
                          prefixIcon: Icon(Icons.map, color: isEscuro ? Colors.white70 : Colors.grey.shade600),
                          filled: true,
                          fillColor: isEscuro ? Colors.black26 : Colors.grey.shade100,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        items: _estacasCadastradas.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (val) => setStateModal(() => estacaSelecionada = val!),
                      ),
                    
                    const SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity, height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: salvando ? null : () async {
                          if (nomeCtrl.text.trim().isEmpty) return;
                          if (precisaDeEstaca && estacaSelecionada == 'Nenhuma Estaca Criada') {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Crie uma Estaca primeiro!'), backgroundColor: Colors.red));
                            return;
                          }
                          
                          setStateModal(() => salvando = true);
                          String estacaFinal = precisaDeEstaca ? estacaSelecionada : 'Global (Todas)';

                          try {
                            if (isEdicao) {
                              await FirebaseFirestore.instance.collection('unidades').doc(unidadeAtual.id).update({
                                'nome': nomeCtrl.text.trim(),
                                'tipo': tipoSelecionado,
                                'estaca': estacaFinal,
                              });
                            } else {
                              await FirebaseFirestore.instance.collection('unidades').add({
                                'nome': nomeCtrl.text.trim(),
                                'tipo': tipoSelecionado,
                                'estaca': estacaFinal,
                                'criado_em': FieldValue.serverTimestamp(),
                              });
                            }
                            if (context.mounted) Navigator.pop(context);
                          } catch(e) {
                            setStateModal(() => salvando = false);
                            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.redAccent));
                          }
                        },
                        icon: salvando ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.save),
                        label: Text(isEdicao ? "Salvar" : "Criar Unidade", style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        );
      },
    );
  }

  // ==========================================
  // WIDGET CONSTRUTOR DE SEÇÕES (DIVISÕES)
  // ==========================================
  Widget _construirSessaoUnidades(
    String titulo,
    List<DocumentSnapshot> unidades,
    Color corTema,
    IconData icone,
    bool isEscuro,
    Color corFundo,
    Color corTexto
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 15, bottom: 10, left: 5),
          child: Row(
            children: [
              Icon(icone, color: corTema, size: 22),
              const SizedBox(width: 8),
              Text(titulo, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: corTema)),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(), // Desativa rolagem interna para rolar com a tela inteira
          itemCount: unidades.length,
          itemBuilder: (context, index) {
            var doc = unidades[index];
            Map<String, dynamic> und = doc.data() as Map<String, dynamic>;

            bool isEstaca = (und['tipo'] == 'Estaca' || und['tipo'] == 'Distrito' || und['tipo'] == 'Missão');

            return Dismissible(
              key: Key(doc.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.delete, color: Colors.white, size: 30),
              ),
              confirmDismiss: (direction) async {
                return await showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: corFundo,
                    title: Text("Confirmar Exclusão", style: TextStyle(color: corTexto)),
                    content: Text("Tem certeza que deseja excluir a unidade ${und['tipo']} ${und['nome']}?", style: TextStyle(color: corTexto)),
                    actions: [
                      TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text("Cancelar", style: TextStyle(color: Colors.grey))),
                      ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white), onPressed: () => Navigator.of(context).pop(true), child: const Text("Excluir")),
                    ],
                  ),
                );
              },
              onDismissed: (direction) async {
                await FirebaseFirestore.instance.collection('unidades').doc(doc.id).delete();
              },
              child: Card(
                color: corFundo,
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: isEscuro ? Colors.white12 : Colors.grey.shade200),
                ),
                elevation: 0,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: corTema.withValues(alpha: 0.15),
                    child: Icon(icone, color: corTema),
                  ),
                  title: Text(
                    "${und['tipo']} ${und['nome']}",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: corTexto),
                  ),
                  subtitle: Text(
                    isEstaca ? 'Região Administrativa' : 'Pertence à: ${und['estaca']}',
                    style: TextStyle(
                      color: isEscuro ? Colors.white54 : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.grey),
                    onPressed: () => _mostrarFormularioUnidade(unidadeAtual: doc),
                  ),
                ),
              ),
            );
          },
        ),
      ],
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
        iconTheme: IconThemeData(color: corTexto),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarFormularioUnidade(),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text("Nova Unidade", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('unidades').orderBy('nome').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.orange));
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("Nenhuma unidade cadastrada.", style: TextStyle(color: Colors.grey)));

          // Filtra e divide a lista em 3 categorias
          var estacas = snapshot.data!.docs.where((d) => ['Estaca', 'Distrito', 'Missão'].contains(d['tipo'])).toList();
          var alas = snapshot.data!.docs.where((d) => d['tipo'] == 'Ala').toList();
          var ramos = snapshot.data!.docs.where((d) => d['tipo'] == 'Ramo').toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (estacas.isNotEmpty) 
                  _construirSessaoUnidades("Estacas e Distritos", estacas, Colors.purple, Icons.map, isEscuro, corFundo, corTexto),
                
                if (alas.isNotEmpty) 
                  _construirSessaoUnidades("Alas", alas, Colors.orange, Icons.church, isEscuro, corFundo, corTexto),
                
                if (ramos.isNotEmpty) 
                  _construirSessaoUnidades("Ramos", ramos, Colors.teal, Icons.other_houses, isEscuro, corFundo, corTexto),
                  
                const SizedBox(height: 80), // Espaço para não cobrir com o botão flutuante
              ],
            ),
          );
        }
      ),
    );
  }
}
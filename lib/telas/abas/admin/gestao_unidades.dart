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
        .where('tipo', whereIn: ['Estaca', 'Distrito'])
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
                      items: ["Ala", "Ramo", "Estaca", "Distrito"].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (val) {
                        setStateModal(() => tipoSelecionado = val!);
                      },
                    ),
                    const SizedBox(height: 15),

                    TextField(
                      controller: nomeCtrl,
                      style: TextStyle(color: isEscuro ? Colors.white : Colors.black87),
                      decoration: InputDecoration(
                        labelText: "Nome da Unidade",
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
  // WIDGET CONSTRUTOR EM CASCATA
  // ==========================================
  Widget _construirTileUnidade(DocumentSnapshot filha, bool isEscuro, Color corFundo, Color corTexto) {
    Map<String, dynamic> fData = filha.data() as Map<String, dynamic>;
    Color corTema = fData['tipo'] == 'Ala' ? Colors.orange : Colors.teal;
    IconData icone = fData['tipo'] == 'Ala' ? Icons.church : Icons.other_houses;
    
    return Dismissible(
      key: Key(filha.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.redAccent,
        child: const Icon(Icons.delete, color: Colors.white, size: 24),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: corFundo,
            title: Text("Confirmar Exclusão", style: TextStyle(color: corTexto)),
            content: Text("Tem certeza que deseja excluir a unidade ${fData['tipo']} ${fData['nome']}?", style: TextStyle(color: corTexto)),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text("Cancelar", style: TextStyle(color: Colors.grey))),
              ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white), onPressed: () => Navigator.of(context).pop(true), child: const Text("Excluir")),
            ],
          ),
        );
      },
      onDismissed: (direction) async {
        await FirebaseFirestore.instance.collection('unidades').doc(filha.id).delete();
      },
      child: Container(
        decoration: BoxDecoration(border: Border(top: BorderSide(color: isEscuro ? Colors.white12 : Colors.grey.shade100))),
        child: ListTile(
          contentPadding: const EdgeInsets.only(left: 32, right: 16, top: 0, bottom: 0),
          leading: Icon(icone, color: corTema, size: 20),
          title: Text("${fData['tipo']} ${fData['nome']}", style: TextStyle(fontWeight: FontWeight.w600, color: corTexto)),
          trailing: IconButton(
            icon: const Icon(Icons.edit, color: Colors.grey, size: 18),
            onPressed: () => _mostrarFormularioUnidade(unidadeAtual: filha),
          ),
        ),
      ),
    );
  }

  Widget _construirCardEstaca(DocumentSnapshot estacaDoc, List<DocumentSnapshot> filhas, bool isEscuro, Color corFundo, Color corTexto) {
    Map<String, dynamic> und = estacaDoc.data() as Map<String, dynamic>;
    String nomeEstaca = "${und['tipo']} ${und['nome']}";

    return Dismissible(
      key: Key(estacaDoc.id),
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
            content: Text("Tem certeza que deseja excluir a unidade $nomeEstaca?\n\nAtenção: Todas as Alas e Ramos vinculadas ficarão sem referência.", style: TextStyle(color: corTexto)),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text("Cancelar", style: TextStyle(color: Colors.grey))),
              ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white), onPressed: () => Navigator.of(context).pop(true), child: const Text("Excluir")),
            ],
          ),
        );
      },
      onDismissed: (direction) async {
        await FirebaseFirestore.instance.collection('unidades').doc(estacaDoc.id).delete();
      },
      child: Card(
        color: corFundo,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isEscuro ? Colors.white12 : Colors.grey.shade200)),
        elevation: 0,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            iconColor: Colors.purple, collapsedIconColor: Colors.grey,
            leading: CircleAvatar(backgroundColor: Colors.purple.withValues(alpha: 0.15), child: const Icon(Icons.map, color: Colors.purple)),
            title: Row(
              children: [
                Expanded(
                  child: Text(nomeEstaca, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: corTexto)),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.grey, size: 20),
                  onPressed: () => _mostrarFormularioUnidade(unidadeAtual: estacaDoc),
                ),
              ],
            ),
            children: filhas.map((filha) => _construirTileUnidade(filha, isEscuro, corFundo, corTexto)).toList(),
          ),
        ),
      ),
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

          var todasUnidades = snapshot.data!.docs;
          var estacas = todasUnidades.where((d) => ['Estaca', 'Distrito'].contains(d['tipo'])).toList();
          var alasRamos = todasUnidades.where((d) => ['Ala', 'Ramo'].contains(d['tipo'])).toList();

          // Encontrar unidades órfãs (cujo pai foi excluído ou não existe)
          List<DocumentSnapshot> orfas = [];
          for (var ala in alasRamos) {
             Map<String, dynamic> data = ala.data() as Map<String, dynamic>;
             String estacaPai = data['estaca'] ?? '';
             bool temPai = estacas.any((e) {
                var eData = e.data() as Map<String, dynamic>;
                return "${eData['tipo']} ${eData['nome']}" == estacaPai;
             });
             if (!temPai) orfas.add(ala);
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
               ...estacas.map((estaca) {
                  Map<String, dynamic> eData = estaca.data() as Map<String, dynamic>;
                  String nomeEstaca = "${eData['tipo']} ${eData['nome']}";
                  
                  var filhas = alasRamos.where((d) {
                     var dData = d.data() as Map<String, dynamic>;
                     return dData['estaca'] == nomeEstaca;
                  }).toList();

                  return _construirCardEstaca(estaca, filhas, isEscuro, corFundo, corTexto);
               }),

               if (orfas.isNotEmpty) ...[
                 const Padding(
                   padding: EdgeInsets.only(top: 20, bottom: 10, left: 5),
                   child: Text("Alas / Ramos Sem Vínculo (Órfãs)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                 ),
                 Card(
                   color: corFundo,
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isEscuro ? Colors.white12 : Colors.grey.shade200)),
                   elevation: 0,
                   child: Column(
                     children: orfas.map((orfa) {
                        Map<String, dynamic> fData = orfa.data() as Map<String, dynamic>;
                        return ListTile(
                          leading: const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                          title: Text("${fData['tipo']} ${fData['nome']}", style: TextStyle(color: corTexto, fontWeight: FontWeight.bold)),
                          subtitle: Text("Estaca: ${fData['estaca']} (Não encontrada)", style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                          trailing: IconButton(
                             icon: const Icon(Icons.edit, color: Colors.grey),
                             onPressed: () => _mostrarFormularioUnidade(unidadeAtual: orfa),
                          ),
                        );
                     }).toList(),
                   ),
                 )
               ],

               const SizedBox(height: 80),
            ],
          );
        }
      ),
    );
  }
}
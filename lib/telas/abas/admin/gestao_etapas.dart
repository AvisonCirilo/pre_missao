import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GestaoEtapasTela extends StatefulWidget {
  const GestaoEtapasTela({super.key});

  @override
  State<GestaoEtapasTela> createState() => _GestaoEtapasTelaState();
}

class _GestaoEtapasTelaState extends State<GestaoEtapasTela> {
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _inicializarBanco();
  }

  // Cria o documento base no Firebase se for a primeira vez que abrimos essa tela
  Future<void> _inicializarBanco() async {
    var doc = await FirebaseFirestore.instance.collection('sistema').doc('etapas').get();
    if (!doc.exists) {
      await FirebaseFirestore.instance.collection('sistema').doc('etapas').set({
        'rapazes': [
          "Aceitou o Desafio (Entrevistado)", "Ensino Médio Concluído", 
          "Alistamento Militar", "Possui Mentor", "Metas com o Bispo", 
          "Exame Médico", "Exame Odontológico", "Chamado Aberto no Sistema"
        ],
        'mocas': [
          "Aceitou o Desafio (Entrevistado)", "Ensino Médio Concluído", 
          "Possui Mentor", "Metas com o Bispo", "Exame Médico", 
          "Exame Odontológico", "Chamado Aberto no Sistema"
        ]
      });
    }
    if (mounted) setState(() => _carregando = false);
  }

  void _adicionarEtapa(String categoria, List<dynamic> etapasAtuais) {
    TextEditingController novaEtapaCtrl = TextEditingController();
    bool isEscuro = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isEscuro ? const Color(0xFF1E1E1E) : Colors.white,
        title: Text("Nova Etapa", style: TextStyle(color: isEscuro ? Colors.white : Colors.black)),
        content: TextField(
          controller: novaEtapaCtrl,
          autofocus: true,
          style: TextStyle(color: isEscuro ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            hintText: "Ex: Entrevista com a Estaca",
            hintStyle: TextStyle(color: isEscuro ? Colors.white54 : Colors.grey),
            filled: true, fillColor: isEscuro ? Colors.black26 : Colors.grey.shade100,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
            onPressed: () async {
              if (novaEtapaCtrl.text.trim().isEmpty) return;
              etapasAtuais.add(novaEtapaCtrl.text.trim());
              await FirebaseFirestore.instance.collection('sistema').doc('etapas').update({categoria: etapasAtuais});
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("Adicionar"),
          ),
        ],
      ),
    );
  }

  Widget _construirListaReordenavel(String categoria, List<dynamic> etapas, bool isEscuro) {
    return Column(
      children: [
        ListTile(
          title: Text(categoria == 'rapazes' ? "Checklist dos Rapazes" : "Checklist das Moças", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
          trailing: IconButton(
            icon: const Icon(Icons.add_circle, color: Colors.indigo, size: 28),
            onPressed: () => _adicionarEtapa(categoria, etapas),
          ),
        ),
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: etapas.length,
            onReorder: (antigoIndex, novoIndex) async {
              if (novoIndex > antigoIndex) novoIndex -= 1;
              final item = etapas.removeAt(antigoIndex);
              etapas.insert(novoIndex, item);
              
              // Salva a nova ordem no banco imediatamente
              await FirebaseFirestore.instance.collection('sistema').doc('etapas').update({categoria: etapas});
            },
            itemBuilder: (context, index) {
              return Card(
                key: ValueKey(etapas[index] + index.toString()),
                color: isEscuro ? Colors.black26 : Colors.grey.shade50,
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: isEscuro ? Colors.white12 : Colors.grey.shade300)),
                child: ListTile(
                  leading: const Icon(Icons.drag_handle, color: Colors.grey),
                  title: Text(etapas[index], style: TextStyle(fontWeight: FontWeight.w500, color: isEscuro ? Colors.white : Colors.black87)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () async {
                      etapas.removeAt(index);
                      await FirebaseFirestore.instance.collection('sistema').doc('etapas').update({categoria: etapas});
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isEscuro = Theme.of(context).brightness == Brightness.dark;
    Color corFundo = isEscuro ? const Color(0xFF1E1E1E) : Colors.white;
    Color corTexto = isEscuro ? Colors.white : Colors.black87;

    if (_carregando) {
      return Scaffold(backgroundColor: Theme.of(context).scaffoldBackgroundColor, body: const Center(child: CircularProgressIndicator(color: Colors.indigo)));
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text('Checklist Dinâmico', style: TextStyle(fontWeight: FontWeight.bold, color: corTexto)),
          backgroundColor: corFundo,
          elevation: 1,
          iconTheme: IconThemeData(color: corTexto),
          bottom: const TabBar(
            indicatorColor: Colors.indigo, labelColor: Colors.indigo, unselectedLabelColor: Colors.grey,
            tabs: [Tab(text: "Rapazes", icon: Icon(Icons.man)), Tab(text: "Moças", icon: Icon(Icons.woman))],
          ),
        ),
        body: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('sistema').doc('etapas').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.indigo));
            if (!snapshot.hasData || !snapshot.data!.exists) return const Center(child: Text("Configurando banco...", style: TextStyle(color: Colors.grey)));

            var dados = snapshot.data!.data() as Map<String, dynamic>;
            List<dynamic> etapasRapazes = List.from(dados['rapazes'] ?? []);
            List<dynamic> etapasMocas = List.from(dados['mocas'] ?? []);

            return TabBarView(
              children: [
                _construirListaReordenavel('rapazes', etapasRapazes, isEscuro),
                _construirListaReordenavel('mocas', etapasMocas, isEscuro),
              ],
            );
          },
        ),
      ),
    );
  }
}
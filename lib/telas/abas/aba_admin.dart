import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'admin/lista_jovens.dart';
import 'admin/gestao_lideres.dart';
import './admin/gestao_unidades.dart';
import 'admin/gestao_etapas.dart'; 

class AbaAdmin extends StatefulWidget {
  const AbaAdmin({super.key});

  @override
  State<AbaAdmin> createState() => _AbaAdminState();
}

class _AbaAdminState extends State<AbaAdmin> {
  // ==========================================
  // LÓGICA DE LIMPEZA DE REGISTROS ANTIGOS
  // ==========================================
  Future<void> _limparRegistrosAntigos() async {
    showDialog(
      context: context, 
      barrierDismissible: false, 
      builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.redAccent))
    );

    try {
      var enviados = await FirebaseFirestore.instance.collection('jovens').where('status', isEqualTo: 'Enviado').get();
      List<DocumentSnapshot> paraDeletar = [];
      
      DateTime umAnoAtras = DateTime.now().subtract(const Duration(days: 365));
      
      for (var doc in enviados.docs) {
        var dados = doc.data() as Map<String, dynamic>;
        String dataEnvio = dados['data_envio'] ?? '';
        bool adicionado = false;

        if (dataEnvio.isNotEmpty && dataEnvio.contains('/')) {
          var partes = dataEnvio.split('/');
          if (partes.length == 3) {
            int dia = int.tryParse(partes[0]) ?? 1;
            int mes = int.tryParse(partes[1]) ?? 1;
            int ano = int.tryParse(partes[2]) ?? 2000;
            DateTime dataDoEnvio = DateTime(ano, mes, dia);
            
            if (dataDoEnvio.isBefore(umAnoAtras)) {
              paraDeletar.add(doc);
              adicionado = true;
            }
          }
        }
        
        if (!adicionado && dados['ultima_atualizacao'] != null) {
          DateTime att = (dados['ultima_atualizacao'] as Timestamp).toDate();
          if (att.isBefore(umAnoAtras)) {
            paraDeletar.add(doc);
          }
        }
      }
      
      if (mounted) Navigator.pop(context);
      
      if (paraDeletar.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('O sistema está limpo. Nenhum jovem foi enviado há mais de 1 ano.'), backgroundColor: Colors.green));
        return;
      }
      
      if (mounted) {
        bool confirmar = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.white,
            title: const Row(children: [Icon(Icons.warning, color: Colors.redAccent), SizedBox(width: 8), Text("Atenção!")]),
            content: Text("Encontramos ${paraDeletar.length} jovem(ns) enviados para a missão há mais de 1 ano.\n\nDeseja excluir permanentemente essas fichas do sistema para liberar espaço?"),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancelar", style: TextStyle(color: Colors.grey))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                onPressed: () => Navigator.pop(context, true), 
                child: const Text("Sim, Excluir", style: TextStyle(color: Colors.white))
              ),
            ]
          )
        ) ?? false;
        
        if (confirmar) {
          if (mounted) showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.redAccent)));
          
          int deletados = 0;
          for (var doc in paraDeletar) {
            await FirebaseFirestore.instance.collection('jovens').doc(doc.id).delete();
            deletados++;
          }
          
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$deletados registros antigos foram apagados com sucesso!'), backgroundColor: Colors.green));
          }
        }
      }
      
    } catch(e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro na varredura: $e'), backgroundColor: Colors.redAccent));
      }
    }
  }

  // ==========================================
  // WIDGET AUXILIAR: ESTATÍSTICAS EM TEMPO REAL 
  // ==========================================
  Widget _construirCardEstatistica(
    String titulo,
    Color cor,
    IconData icone,
    bool isEscuro,
    Stream<QuerySnapshot> streamBuscador, 
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: isEscuro ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isEscuro ? Colors.white12 : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: cor.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: streamBuscador,
          builder: (context, snapshot) {
            String valor = "..."; 
            if (snapshot.hasData) {
              valor = snapshot.data!.docs.length.toString();
            }
            return Column(
              children: [
                Icon(icone, color: cor, size: 28),
                const SizedBox(height: 8),
                Text(
                  valor,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isEscuro ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  titulo,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            );
          }
        ),
      ),
    );
  }

  // ==========================================
  // WIDGET AUXILIAR: BOTÕES DE MENU
  // ==========================================
  Widget _construirBotaoAcao(
    String titulo,
    String subtitulo,
    IconData icone,
    Color cor,
    bool isEscuro,
    VoidCallback acao,
  ) {
    return Card(
      color: isEscuro ? const Color(0xFF1E1E1E) : Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isEscuro ? Colors.white12 : Colors.grey.shade200,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: cor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icone, color: cor),
        ),
        title: Text(
          titulo,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isEscuro ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitulo,
          style: TextStyle(
            fontSize: 12,
            color: isEscuro ? Colors.white54 : Colors.black54,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 14,
          color: Colors.grey,
        ),
        onTap: acao,
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
        automaticallyImplyLeading: false,
        title: Text(
          'Painel de Administração',
          style: TextStyle(fontWeight: FontWeight.bold, color: corTexto),
        ),
        backgroundColor: corFundo,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Visão Global do Sistema", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
            const SizedBox(height: 10),
            
            Row(
              children: [
                _construirCardEstatistica("Líderes", Colors.blue, Icons.admin_panel_settings, isEscuro, FirebaseFirestore.instance.collection('usuarios').snapshots()),
                const SizedBox(width: 10),
                _construirCardEstatistica("Total Jovens", Colors.green, Icons.groups, isEscuro, FirebaseFirestore.instance.collection('jovens').snapshots()),
              ],
            ),
            const SizedBox(height: 10),
            
            Row(
              children: [
                _construirCardEstatistica("Alas / Ramos", Colors.orange, Icons.church, isEscuro, FirebaseFirestore.instance.collection('unidades').where('tipo', whereIn: ['Ala', 'Ramo']).snapshots()),
                const SizedBox(width: 10),
                _construirCardEstatistica("Estacas", Colors.purple, Icons.map, isEscuro, FirebaseFirestore.instance.collection('unidades').where('tipo', whereIn: ['Estaca', 'Distrito', 'Missão']).snapshots()),
              ],
            ),

            const SizedBox(height: 35),
            Text("Gestão de Acessos", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
            const SizedBox(height: 10),
            _construirBotaoAcao("Gerenciar Líderes", "Criar contas, alterar senhas e remover acessos de bispos e líderes da missão.", Icons.manage_accounts, Colors.blue, isEscuro, () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const GestaoLideresTela()));
            }),

            const SizedBox(height: 25),
            Text("Estrutura da Igreja", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
            const SizedBox(height: 10),
            _construirBotaoAcao("Gerenciar Alas e Ramos", "Adicionar ou renomear as unidades que aparecerão no aplicativo.", Icons.church, Colors.orange, isEscuro, () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const GestaoUnidadesTela()));
            }),
            _construirBotaoAcao("Lista Global de Jovens", "Acessar e pesquisar todos os jovens cadastrados em todas as unidades.", Icons.format_list_bulleted, Colors.green, isEscuro, () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ListaGlobalJovensTela()));
            }),

            const SizedBox(height: 25),
            Text("Sistema", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
            const SizedBox(height: 10),
            
            _construirBotaoAcao(
              "Checklist Dinâmico",
              "Personalizar as etapas, adicionar ou remover tarefas para os missionários.",
              Icons.checklist,
              Colors.indigo,
              isEscuro,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const GestaoEtapasTela()),
                );
              },
            ),
            
            _construirBotaoAcao("Limpar Registros Antigos", "Excluir jovens que já viajaram para a missão há mais de 1 ano.", Icons.delete_sweep, Colors.redAccent, isEscuro, _limparRegistrosAntigos),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
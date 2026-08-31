import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChamadosEnviadosTela extends StatefulWidget {
  const ChamadosEnviadosTela({super.key});

  @override
  State<ChamadosEnviadosTela> createState() => _ChamadosEnviadosTelaState();
}

class _ChamadosEnviadosTelaState extends State<ChamadosEnviadosTela> {
  String _minhaEstaca = "";
  String _minhaUnidade = "";
  String _nivelAcesso = "Ala";
  bool _carregandoPerfil = true;

  @override
  void initState() {
    super.initState();
    _carregarPerfilLider();
  }

  // Descobre quem está logado para filtrar a lista corretamente
  Future<void> _carregarPerfilLider() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        var doc = await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).get();
        if (doc.exists && mounted) {
          var dados = doc.data() as Map<String, dynamic>? ?? {};
          setState(() {
            _minhaEstaca = dados['estaca'] ?? "Global (Todas)";
            _minhaUnidade = dados['unidade'] ?? "Global (Todas)";
            _nivelAcesso = dados['nivel_acesso'] ?? "Ala";
            _carregandoPerfil = false;
          });
        } else {
          if (mounted) setState(() => _carregandoPerfil = false);
        }
      } else {
        if (mounted) setState(() => _carregandoPerfil = false);
      }
    } catch (e) {
      if (mounted) setState(() => _carregandoPerfil = false);
    }
  }

  // Formulário rápido para atualizar a data e o local da missão
  void _atualizarDestinoJovem(Map<String, dynamic> jovem) {
    bool isEscuro = Theme.of(context).brightness == Brightness.dark;
    
    final destinoCtrl = TextEditingController(text: jovem['destino'] ?? "");
    final dataCtrl = TextEditingController(text: jovem['data_envio'] ?? "");
    
    bool salvando = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateModal) {
          return Container(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 24, left: 24, right: 24, top: 24),
            decoration: BoxDecoration(color: isEscuro ? const Color(0xFF1E1E1E) : Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(25))),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: isEscuro ? Colors.white24 : Colors.grey.shade400, borderRadius: BorderRadius.circular(10))),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.flight_takeoff, color: Colors.green),
                      const SizedBox(width: 10),
                      Text("Atualizar Chamado", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isEscuro ? Colors.white : Colors.black)),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(jovem['nome'], style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 25),
                  
                  TextField(
                    controller: destinoCtrl, 
                    style: TextStyle(color: isEscuro ? Colors.white : Colors.black87),
                    decoration: InputDecoration(labelText: "Destino da Missão", hintText: "Ex: Brasil São Paulo Sul", labelStyle: TextStyle(color: isEscuro ? Colors.white70 : Colors.grey.shade700), prefixIcon: Icon(Icons.public, color: isEscuro ? Colors.white70 : Colors.grey.shade600), filled: true, fillColor: isEscuro ? Colors.black26 : Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                  ),
                  const SizedBox(height: 15),
                  
                  TextField(
                    controller: dataCtrl, 
                    style: TextStyle(color: isEscuro ? Colors.white : Colors.black87),
                    decoration: InputDecoration(labelText: "Data de Envio/Abertura", hintText: "Ex: 15/08/2026", labelStyle: TextStyle(color: isEscuro ? Colors.white70 : Colors.grey.shade700), prefixIcon: Icon(Icons.calendar_today, color: isEscuro ? Colors.white70 : Colors.grey.shade600), filled: true, fillColor: isEscuro ? Colors.black26 : Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  SizedBox(
                    width: double.infinity, height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: salvando ? null : () async {
                        setStateModal(() => salvando = true);
                        try {
                          await FirebaseFirestore.instance.collection('jovens').doc(jovem['id']).update({
                            'destino': destinoCtrl.text.trim(),
                            'data_envio': dataCtrl.text.trim(),
                          });
                          if (context.mounted) Navigator.pop(context);
                        } catch(e) {
                          setStateModal(() => salvando = false);
                          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.redAccent));
                        }
                      },
                      icon: salvando ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.save),
                      label: const Text("Salvar Destino", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isEscuro = Theme.of(context).brightness == Brightness.dark;
    Color corFundo = isEscuro ? const Color(0xFF1E1E1E) : Colors.white;
    Color corTexto = isEscuro ? Colors.white : Colors.black87;

    if (_carregandoPerfil) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(backgroundColor: corFundo, elevation: 1),
        body: const Center(child: CircularProgressIndicator(color: Colors.green)),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Chamados Enviados', style: TextStyle(fontWeight: FontWeight.bold, color: corTexto)),
        backgroundColor: corFundo,
        elevation: 1,
        iconTheme: IconThemeData(color: corTexto),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Busca todos os jovens que estão com o status de Enviado
        stream: FirebaseFirestore.instance.collection('jovens').where('status', isEqualTo: 'Enviado').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.green));
          
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.send, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text("Nenhum chamado concluído ainda.", style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                ],
              ),
            );
          }

          // Filtra a lista inteligentemente pelo Nível de Acesso
          List<Map<String, dynamic>> jovensEnviados = snapshot.data!.docs.map((doc) {
            var dados = doc.data() as Map<String, dynamic>;
            dados['id'] = doc.id;
            return dados;
          }).where((jovem) {
            if (_nivelAcesso == 'Admin' || _nivelAcesso == 'Gestor') return true;
            if (_nivelAcesso == 'Estaca') return jovem['estaca'] == _minhaEstaca;
            return jovem['unidade'] == _minhaUnidade;
          }).toList();

          if (jovensEnviados.isEmpty) {
            return Center(
              child: Text("Nenhum jovem enviado na sua unidade.", style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: jovensEnviados.length,
            itemBuilder: (context, index) {
              final jovem = jovensEnviados[index];
              
              String destino = jovem['destino'] ?? '';
              String dataEnvio = jovem['data_envio'] ?? '';
              
              bool aguardando = destino.isEmpty || destino.toLowerCase().contains('aguardando');
              
              return Card(
                color: corFundo,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isEscuro ? Colors.white12 : Colors.grey.shade200)),
                elevation: 0,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _atualizarDestinoJovem(jovem),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    leading: CircleAvatar(
                      backgroundColor: aguardando ? Colors.orange.withValues(alpha: 0.15) : Colors.green.withValues(alpha: 0.15),
                      child: Icon(aguardando ? Icons.hourglass_empty : Icons.flight_takeoff, color: aguardando ? Colors.orange : Colors.green),
                    ),
                    title: Text(jovem['nome'] ?? 'Sem nome', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: corTexto)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text("Enviado/Aberto em: ${dataEnvio.isEmpty ? 'Pendente' : dataEnvio}", style: TextStyle(color: isEscuro ? Colors.white70 : Colors.black87, fontSize: 12)),
                        const SizedBox(height: 2),
                        Text(aguardando ? 'Aguardando Carta...' : destino, style: TextStyle(color: aguardando ? Colors.orange : Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                    trailing: const Icon(Icons.edit, color: Colors.grey, size: 20),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
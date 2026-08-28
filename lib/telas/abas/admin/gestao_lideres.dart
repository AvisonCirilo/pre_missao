import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class GestaoLideresTela extends StatefulWidget {
  const GestaoLideresTela({super.key});

  @override
  State<GestaoLideresTela> createState() => _GestaoLideresTelaState();
}

class _GestaoLideresTelaState extends State<GestaoLideresTela> {
  final List<String> _opcoesCargo = ['Bispo', 'Pres. de Ramo', 'Pres. de Estaca', 'Conselho Geral'];
  final List<String> _opcoesUnidade = ['Ala Centro', 'Ala Sul', 'Ramo Leste', 'Estaca Norte', 'Distrito Sul', 'Global (Todas)'];

  // Traduz o cargo escolhido para o nível de acesso que o sistema entende
  String _obterNivelAcesso(String cargo) {
    if (cargo == 'Conselho Geral') return 'Gestor';
    if (cargo == 'Pres. de Estaca') return 'Estaca';
    if (cargo == 'Admin') return 'Admin';
    return 'Ala'; 
  }

  void _mostrarFormularioLider({DocumentSnapshot? liderAtual}) {
    bool isEdicao = liderAtual != null;
    bool isEscuro = Theme.of(context).brightness == Brightness.dark;

    Map<String, dynamic>? dados = isEdicao ? liderAtual.data() as Map<String, dynamic> : null;

    final nomeCtrl = TextEditingController(text: isEdicao ? dados!['nome'] : "");
    final emailCtrl = TextEditingController(text: isEdicao ? dados!['email'] : "");
    final senhaCtrl = TextEditingController(); 
    
    String cargoSelecionado = isEdicao ? (dados!['cargo'] ?? _opcoesCargo[0]) : _opcoesCargo[0];
    String unidadeSelecionada = isEdicao ? (dados!['unidade'] ?? _opcoesUnidade[0]) : _opcoesUnidade[0];

    bool salvando = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return Container(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 24, left: 24, right: 24, top: 24),
              decoration: BoxDecoration(color: isEscuro ? const Color(0xFF1E1E1E) : Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(25))),
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
                        child: _construirDropdown("Cargo", cargoSelecionado, _opcoesCargo, Icons.badge, isEscuro, (val) {
                          setStateModal(() {
                            cargoSelecionado = val!;
                            if (cargoSelecionado == 'Conselho Geral') {
                              unidadeSelecionada = 'Global (Todas)';
                            }
                          });
                        }),
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
                      onPressed: salvando ? null : () async {
                        if (nomeCtrl.text.trim().isEmpty || emailCtrl.text.trim().isEmpty) return;
                        if (!isEdicao && senhaCtrl.text.trim().isEmpty) return;
                        
                        setStateModal(() => salvando = true);

                        try {
                          String nivelAcessoCalc = _obterNivelAcesso(cargoSelecionado);

                          if (isEdicao) {
                            await FirebaseFirestore.instance.collection('usuarios').doc(liderAtual!.id).update({
                              'nome': nomeCtrl.text.trim(),
                              'email': emailCtrl.text.trim(),
                              'cargo': cargoSelecionado,
                              'nivel_acesso': nivelAcessoCalc,
                              'unidade': unidadeSelecionada,
                            });
                          } else {
                            // Inicia app invisível para não deslogar o Admin
                            FirebaseApp appSecundario = await Firebase.initializeApp(
                              name: 'AppSecundario',
                              options: Firebase.app().options,
                            );

                            UserCredential credencial = await FirebaseAuth.instanceFor(app: appSecundario)
                                .createUserWithEmailAndPassword(
                              email: emailCtrl.text.trim(),
                              password: senhaCtrl.text.trim(),
                            );

                            String novoUid = credencial.user!.uid;
                            await appSecundario.delete(); // Fecha o app invisível

                            await FirebaseFirestore.instance.collection('usuarios').doc(novoUid).set({
                              'nome': nomeCtrl.text.trim(),
                              'email': emailCtrl.text.trim(),
                              'cargo': cargoSelecionado,
                              'nivel_acesso': nivelAcessoCalc,
                              'unidade': unidadeSelecionada,
                              'data_criacao': FieldValue.serverTimestamp(),
                            });
                          }
                          if (context.mounted) Navigator.pop(context);
                        } catch (e) {
                          setStateModal(() => salvando = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.redAccent));
                          }
                        }
                      },
                      icon: salvando ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.save),
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
      decoration: InputDecoration(labelText: label, labelStyle: TextStyle(color: isEscuro ? Colors.white70 : Colors.grey.shade700), prefixIcon: Icon(icon, color: isEscuro ? Colors.white70 : Colors.grey.shade600), filled: true, fillColor: isEscuro ? Colors.black26 : Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
    );
  }

  Widget _construirDropdown(String label, String valorAtual, List<String> itens, IconData icon, bool isEscuro, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: valorAtual,
      dropdownColor: isEscuro ? const Color(0xFF1E1E1E) : Colors.white,
      style: TextStyle(color: isEscuro ? Colors.white : Colors.black87),
      decoration: InputDecoration(labelText: label, labelStyle: TextStyle(color: isEscuro ? Colors.white70 : Colors.grey.shade700), prefixIcon: Icon(icon, color: isEscuro ? Colors.white70 : Colors.grey.shade600), filled: true, fillColor: isEscuro ? Colors.black26 : Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
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
      appBar: AppBar(title: Text('Gestão de Líderes', style: TextStyle(fontWeight: FontWeight.bold, color: corTexto)), backgroundColor: corFundo, elevation: 1, iconTheme: IconThemeData(color: corTexto)),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => _mostrarFormularioLider(), backgroundColor: Colors.blue, foregroundColor: Colors.white, icon: const Icon(Icons.person_add), label: const Text("Novo Líder", style: TextStyle(fontWeight: FontWeight.bold))),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('usuarios').orderBy('nome').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("Nenhum líder cadastrado.", style: TextStyle(color: Colors.grey)));

          var documentos = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: documentos.length,
            itemBuilder: (context, index) {
              var doc = documentos[index];
              Map<String, dynamic> lider = doc.data() as Map<String, dynamic>;
              
              String nome = lider['nome'] ?? 'Sem Nome';
              String cargo = lider['cargo'] ?? 'Desconhecido';
              String unidade = lider['unidade'] ?? 'Desconhecida';
              String email = lider['email'] ?? 'Sem E-mail';
              
              bool isConselho = cargo.contains('Conselho');
              bool isEstaca = cargo.contains('Estaca');
              
              Color corAvatar = isConselho ? Colors.teal : (isEstaca ? Colors.purple : Colors.blue);
              IconData iconeAvatar = isConselho ? Icons.domain : (isEstaca ? Icons.admin_panel_settings : Icons.person);

              return Dismissible(
                key: Key(doc.id), 
                direction: DismissDirection.endToStart, 
                background: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.delete, color: Colors.white, size: 30)),
                confirmDismiss: (direction) async {
                  return await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: corFundo, title: Text("Confirmar Exclusão", style: TextStyle(color: corTexto)), content: Text("Tem certeza que deseja remover o acesso de $nome?", style: TextStyle(color: corTexto)),
                      actions: [
                        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text("Cancelar", style: TextStyle(color: Colors.grey))),
                        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white), onPressed: () => Navigator.of(context).pop(true), child: const Text("Apagar")),
                      ],
                    ),
                  );
                },
                onDismissed: (direction) async {
                  await FirebaseFirestore.instance.collection('usuarios').doc(doc.id).delete();
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$nome foi removido.'), backgroundColor: Colors.redAccent));
                },
                child: Card(
                  color: corFundo, margin: const EdgeInsets.only(bottom: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isEscuro ? Colors.white12 : Colors.grey.shade200)), elevation: 0,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    leading: CircleAvatar(backgroundColor: corAvatar.withValues(alpha: 0.15), child: Icon(iconeAvatar, color: corAvatar)),
                    title: Text(nome, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: corTexto)),
                    subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const SizedBox(height: 4), Text("$cargo • $unidade", style: TextStyle(color: isEscuro ? Colors.white70 : Colors.black87, fontWeight: FontWeight.w500)), Text(email, style: TextStyle(color: isEscuro ? Colors.white54 : Colors.grey, fontSize: 12))]),
                    trailing: IconButton(icon: const Icon(Icons.edit, color: Colors.grey), onPressed: () => _mostrarFormularioLider(liderAtual: doc)),
                  ),
                ),
              );
            },
          );
        }
      ),
    );
  }
}
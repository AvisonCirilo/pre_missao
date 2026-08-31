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
  final List<String> _opcoesCargo = ['Bispo', 'Pres. de Ramo', 'Pres. de Estaca', 'Conselho Geral', 'Admin'];
  
  // Dicionário invisível que organiza as Alas dentro das Estacas
  Map<String, List<String>> _arvoreUnidades = {'Global (Todas)': ['Global (Todas)']};

  @override
  void initState() {
    super.initState();
    _construirArvoreDoBanco();
  }

  // Monta a estrutura em cascata lendo as Alas e Estacas criadas na tela de Unidades
  void _construirArvoreDoBanco() {
    FirebaseFirestore.instance.collection('unidades').snapshots().listen((snapshot) {
      Map<String, List<String>> arvore = {'Global (Todas)': ['Global (Todas)']};
      
      for (var doc in snapshot.docs) {
        String tipo = doc['tipo'] ?? '';
        String nomeDaUnidade = "$tipo ${doc['nome']}";
        String estacaPai = doc['estaca'] ?? 'Global (Todas)';

        if (tipo == 'Estaca' || tipo == 'Distrito') {
          arvore.putIfAbsent(nomeDaUnidade, () => [nomeDaUnidade]); 
        } else if (tipo == 'Ala' || tipo == 'Ramo') {
          arvore.putIfAbsent(estacaPai, () => [estacaPai]).add(nomeDaUnidade);
        }
      }
      if (mounted) setState(() => _arvoreUnidades = arvore);
    });
  }

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
    final usuarioCtrl = TextEditingController(text: isEdicao ? dados!['usuario'] : "");
    final senhaCtrl = TextEditingController(); 
    final emailContatoCtrl = TextEditingController(text: isEdicao ? (dados!['email_contato'] ?? "") : "");
    final whatsappCtrl = TextEditingController(text: isEdicao ? (dados!['whatsapp'] ?? "") : "");
    
    String cargoSelecionado = isEdicao ? (dados!['cargo'] ?? _opcoesCargo[0]) : _opcoesCargo[0];
    if (!_opcoesCargo.contains(cargoSelecionado)) cargoSelecionado = _opcoesCargo[0]; 

    // Lógica em Cascata Inicial
    String estacaSelecionada = isEdicao ? (dados!['estaca'] ?? _arvoreUnidades.keys.first) : _arvoreUnidades.keys.first;
    if (!_arvoreUnidades.containsKey(estacaSelecionada)) estacaSelecionada = _arvoreUnidades.keys.first;

    List<String> listaAlas = _arvoreUnidades[estacaSelecionada]!;
    String unidadeSelecionada = isEdicao ? (dados!['unidade'] ?? listaAlas.first) : listaAlas.first;
    if (!listaAlas.contains(unidadeSelecionada)) unidadeSelecionada = listaAlas.first;

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
              child: SingleChildScrollView(
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

                    _construirCampoTexto("Usuário de Login (Ex: bispo.centro)", usuarioCtrl, Icons.account_circle, isEscuro, enabled: !isEdicao),
                    const SizedBox(height: 15),

                    _construirCampoTexto(isEdicao ? "Nova Senha (Deixe em branco para manter)" : "Senha Temporária (Mín. 6 letras)", senhaCtrl, Icons.lock, isEscuro),
                    const SizedBox(height: 15),

                    DropdownButtonFormField<String>(
                      value: cargoSelecionado, dropdownColor: isEscuro ? const Color(0xFF1E1E1E) : Colors.white, style: TextStyle(color: isEscuro ? Colors.white : Colors.black87),
                      decoration: InputDecoration(labelText: "Cargo", labelStyle: TextStyle(color: isEscuro ? Colors.white70 : Colors.grey.shade700), prefixIcon: Icon(Icons.badge, color: isEscuro ? Colors.white70 : Colors.grey.shade600), filled: true, fillColor: isEscuro ? Colors.black26 : Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                      items: _opcoesCargo.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (val) {
                        setStateModal(() {
                          cargoSelecionado = val!;
                          if (cargoSelecionado == 'Conselho Geral' || cargoSelecionado == 'Admin') {
                            estacaSelecionada = 'Global (Todas)';
                            listaAlas = _arvoreUnidades[estacaSelecionada]!;
                            unidadeSelecionada = 'Global (Todas)';
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 15),

                    // DROPDOWN 1: ESCOLHER A ESTACA
                    DropdownButtonFormField<String>(
                      value: estacaSelecionada, dropdownColor: isEscuro ? const Color(0xFF1E1E1E) : Colors.white, style: TextStyle(color: isEscuro ? Colors.white : Colors.black87),
                      decoration: InputDecoration(labelText: "Estaca da Liderança", labelStyle: TextStyle(color: isEscuro ? Colors.white70 : Colors.grey.shade700), prefixIcon: Icon(Icons.map, color: isEscuro ? Colors.white70 : Colors.grey.shade600), filled: true, fillColor: isEscuro ? Colors.black26 : Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                      items: _arvoreUnidades.keys.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (val) {
                        setStateModal(() {
                          estacaSelecionada = val!;
                          listaAlas = _arvoreUnidades[estacaSelecionada]!;
                          unidadeSelecionada = listaAlas.first; // Reseta a Ala para a primeira da nova Estaca
                        });
                      },
                    ),
                    const SizedBox(height: 15),

                    // DROPDOWN 2: ESCOLHER A ALA (Adapta-se à Estaca escolhida)
                    DropdownButtonFormField<String>(
                      value: unidadeSelecionada, dropdownColor: isEscuro ? const Color(0xFF1E1E1E) : Colors.white, style: TextStyle(color: isEscuro ? Colors.white : Colors.black87),
                      decoration: InputDecoration(labelText: "Unidade Específica", labelStyle: TextStyle(color: isEscuro ? Colors.white70 : Colors.grey.shade700), prefixIcon: Icon(Icons.church, color: isEscuro ? Colors.white70 : Colors.grey.shade600), filled: true, fillColor: isEscuro ? Colors.black26 : Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                      items: listaAlas.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (val) => setStateModal(() => unidadeSelecionada = val!),
                    ),
                    
                    const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider()),
                    Text("Informações de Contato (Públicas)", style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 15),

                    _construirCampoTexto("E-mail de Contato", emailContatoCtrl, Icons.email, isEscuro, tipo: TextInputType.emailAddress),
                    const SizedBox(height: 15),
                    _construirCampoTexto("WhatsApp do Líder", whatsappCtrl, Icons.phone, isEscuro, tipo: TextInputType.phone),
                    
                    const SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity, height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        onPressed: salvando ? null : () async {
                          if (nomeCtrl.text.trim().isEmpty || usuarioCtrl.text.trim().isEmpty) return;
                          if (!isEdicao && senhaCtrl.text.trim().length < 6) return;
                          
                          setStateModal(() => salvando = true);

                          try {
                            String nivelAcessoCalc = _obterNivelAcesso(cargoSelecionado);
                            String usuarioLimpo = usuarioCtrl.text.trim().replaceAll(' ', '').toLowerCase();
                            String emailAuthFantasma = "$usuarioLimpo@sistema.local";

                            Map<String, dynamic> dadosFinais = {
                              'nome': nomeCtrl.text.trim(),
                              'usuario': usuarioLimpo,
                              'email_contato': emailContatoCtrl.text.trim(),
                              'whatsapp': whatsappCtrl.text.trim(),
                              'cargo': cargoSelecionado,
                              'nivel_acesso': nivelAcessoCalc,
                              'estaca': estacaSelecionada, // SALVA A ESTACA NO PERFIL
                              'unidade': unidadeSelecionada, // SALVA A ALA NO PERFIL
                            };

                            if (isEdicao) {
                              if (senhaCtrl.text.trim().isNotEmpty) {
                                if (senhaCtrl.text.trim().length < 6) throw Exception("Mínimo de 6 caracteres.");
                                String? senhaAntigaSistema = dados!['senha_sistema'];
                                String emailDoLider = dados['email'] ?? emailAuthFantasma;

                                if (senhaAntigaSistema != null) {
                                  FirebaseApp appSecundario = await Firebase.initializeApp(name: 'AppSecundario', options: Firebase.app().options);
                                  try {
                                    UserCredential credencial = await FirebaseAuth.instanceFor(app: appSecundario).signInWithEmailAndPassword(email: emailDoLider, password: senhaAntigaSistema);
                                    await credencial.user!.updatePassword(senhaCtrl.text.trim());
                                    dadosFinais['senha_sistema'] = senhaCtrl.text.trim();
                                  } finally {
                                    await appSecundario.delete();
                                  }
                                } else {
                                  throw Exception("Usuário criado antes da atualização. Recrie o acesso dele.");
                                }
                              }
                              await FirebaseFirestore.instance.collection('usuarios').doc(liderAtual!.id).update(dadosFinais);
                            } else {
                              FirebaseApp appSecundario = await Firebase.initializeApp(name: 'AppSecundario', options: Firebase.app().options);
                              UserCredential credencial = await FirebaseAuth.instanceFor(app: appSecundario).createUserWithEmailAndPassword(email: emailAuthFantasma, password: senhaCtrl.text.trim());
                              String novoUid = credencial.user!.uid;
                              await appSecundario.delete();

                              dadosFinais['email'] = emailAuthFantasma;
                              dadosFinais['senha_sistema'] = senhaCtrl.text.trim();
                              dadosFinais['data_criacao'] = FieldValue.serverTimestamp();
                              
                              await FirebaseFirestore.instance.collection('usuarios').doc(novoUid).set(dadosFinais);
                            }
                            if (context.mounted) Navigator.pop(context);
                          } catch (e) {
                            setStateModal(() => salvando = false);
                            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.redAccent));
                          }
                        },
                        icon: salvando ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.save),
                        label: Text(isEdicao ? "Salvar Alterações" : "Criar Acesso", style: const TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _construirCampoTexto(String label, TextEditingController controller, IconData icon, bool isEscuro, {TextInputType tipo = TextInputType.text, bool enabled = true}) {
    return TextField(
      controller: controller, keyboardType: tipo, enabled: enabled,
      style: TextStyle(color: isEscuro ? Colors.white : Colors.black87),
      decoration: InputDecoration(labelText: label, labelStyle: TextStyle(color: isEscuro ? Colors.white70 : Colors.grey.shade700), prefixIcon: Icon(icon, color: isEscuro ? Colors.white70 : Colors.grey.shade600), filled: true, fillColor: isEscuro ? Colors.black26 : Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
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

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              Map<String, dynamic> lider = doc.data() as Map<String, dynamic>;
              
              String nome = lider['nome'] ?? 'Sem Nome';
              String cargo = lider['cargo'] ?? 'Desconhecido';
              String estaca = lider['estaca'] ?? 'Global';
              String unidade = lider['unidade'] ?? 'Desconhecida';
              String usuarioLogin = lider['usuario'] ?? 'Sem Usuário';
              
              bool isConselho = cargo.contains('Conselho');
              bool isEstaca = cargo.contains('Estaca');
              bool isAdmin = cargo.contains('Admin');
              
              Color corAvatar = isConselho ? Colors.teal : (isEstaca ? Colors.purple : (isAdmin ? Colors.green : Colors.blue));
              IconData iconeAvatar = isConselho ? Icons.domain : (isEstaca ? Icons.admin_panel_settings : (isAdmin ? Icons.security : Icons.person));

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
                },
                child: Card(
                  color: corFundo, margin: const EdgeInsets.only(bottom: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isEscuro ? Colors.white12 : Colors.grey.shade200)), elevation: 0,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    leading: CircleAvatar(backgroundColor: corAvatar.withValues(alpha: 0.15), child: Icon(iconeAvatar, color: corAvatar)),
                    title: Text(nome, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: corTexto)),
                    subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const SizedBox(height: 4), 
                      Text("$cargo • $unidade", style: TextStyle(color: isEscuro ? Colors.white70 : Colors.black87, fontWeight: FontWeight.w500)), 
                      const SizedBox(height: 4), 
                      Row(children: [const Icon(Icons.account_circle, size: 14, color: Colors.grey), const SizedBox(width: 4), Text(usuarioLogin, style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold))])
                    ]),
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
// ignore_for_file: deprecated_member_use, unnecessary_non_null_assertion, unused_local_variable

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
  Map<String, List<String>> _arvoreUnidades = {'Global (Todas)': []};

  @override
  void initState() {
    super.initState();
    _construirArvoreDoBanco();
  }

  // Monta a estrutura em cascata ignorando a "Global" para líderes locais
  void _construirArvoreDoBanco() {
    FirebaseFirestore.instance.collection('unidades').snapshots().listen((snapshot) {
      Map<String, List<String>> arvore = {'Global (Todas)': []};
      
      for (var doc in snapshot.docs) {
        String tipo = doc['tipo'] ?? '';
        String nomeDaUnidade = "$tipo ${doc['nome']}";
        String estacaPai = doc['estaca'] ?? '';

        if (tipo == 'Estaca' || tipo == 'Distrito' || tipo == 'Missão') {
          arvore.putIfAbsent(nomeDaUnidade, () => []); 
        } else if (tipo == 'Ala' || tipo == 'Ramo') {
          if (estacaPai.isNotEmpty && estacaPai != 'Global (Todas)') {
            arvore.putIfAbsent(estacaPai, () => []).add(nomeDaUnidade);
          }
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
    
    String estacaSelecionada = isEdicao ? (dados!['estaca'] ?? '') : '';
    String unidadeSelecionada = isEdicao ? (dados!['unidade'] ?? '') : '';

    bool salvando = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            
            // Lógica de Visibilidade Inteligente
            bool isGlobal = cargoSelecionado == 'Conselho Geral' || cargoSelecionado == 'Admin';
            bool isEstacaNivel = cargoSelecionado == 'Pres. de Estaca';
            bool isAlaNivel = cargoSelecionado == 'Bispo' || cargoSelecionado == 'Pres. de Ramo';

            // Puxa apenas as estacas reais (esconde a opção "Global")
            List<String> estacasReais = _arvoreUnidades.keys.where((k) => k != 'Global (Todas)').toList();
            if (estacasReais.isEmpty) estacasReais = ['Nenhuma Estaca Cadastrada'];
            if (!estacasReais.contains(estacaSelecionada)) estacaSelecionada = estacasReais.first;

            // Puxa as alas apenas da estaca selecionada
            List<String> alasReais = [];
            if (estacaSelecionada != 'Nenhuma Estaca Cadastrada' && _arvoreUnidades.containsKey(estacaSelecionada)) {
              alasReais = _arvoreUnidades[estacaSelecionada]!;
            }
            if (alasReais.isEmpty) alasReais = ['Nenhuma Ala Cadastrada'];
            if (!alasReais.contains(unidadeSelecionada)) unidadeSelecionada = alasReais.first;

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

                    _construirCampoTexto("Usuário de Login", usuarioCtrl, Icons.account_circle, isEscuro, enabled: !isEdicao),
                    const SizedBox(height: 15),

                    _construirCampoTexto(isEdicao ? "Nova Senha" : "Senha Temporária", senhaCtrl, Icons.lock, isEscuro),
                    const SizedBox(height: 15),

                    DropdownButtonFormField<String>(
                      value: cargoSelecionado, dropdownColor: isEscuro ? const Color(0xFF1E1E1E) : Colors.white, style: TextStyle(color: isEscuro ? Colors.white : Colors.black87),
                      decoration: InputDecoration(labelText: "Cargo", labelStyle: TextStyle(color: isEscuro ? Colors.white70 : Colors.grey.shade700), prefixIcon: Icon(Icons.badge, color: isEscuro ? Colors.white70 : Colors.grey.shade600), filled: true, fillColor: isEscuro ? Colors.black26 : Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                      items: _opcoesCargo.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (val) {
                        setStateModal(() {
                          cargoSelecionado = val!;
                        });
                      },
                    ),

                    // SÓ MOSTRA O CAMPO DE ESTACA SE NÃO FOR GLOBAL
                    if (!isGlobal) ...[
                      const SizedBox(height: 15),
                      DropdownButtonFormField<String>(
                        value: estacaSelecionada, dropdownColor: isEscuro ? const Color(0xFF1E1E1E) : Colors.white, style: TextStyle(color: isEscuro ? Colors.white : Colors.black87),
                        decoration: InputDecoration(labelText: "Estaca da Liderança", labelStyle: TextStyle(color: isEscuro ? Colors.white70 : Colors.grey.shade700), prefixIcon: Icon(Icons.map, color: isEscuro ? Colors.white70 : Colors.grey.shade600), filled: true, fillColor: isEscuro ? Colors.black26 : Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                        items: estacasReais.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (val) {
                          setStateModal(() {
                            estacaSelecionada = val!;
                            var novasAlas = _arvoreUnidades[estacaSelecionada] ?? [];
                            unidadeSelecionada = novasAlas.isNotEmpty ? novasAlas.first : 'Nenhuma Ala Cadastrada';
                          });
                        },
                      ),
                    ],

                    // SÓ MOSTRA O CAMPO DE ALA SE FOR BISPO OU PRES DE RAMO
                    if (isAlaNivel) ...[
                      const SizedBox(height: 15),
                      DropdownButtonFormField<String>(
                        value: unidadeSelecionada, dropdownColor: isEscuro ? const Color(0xFF1E1E1E) : Colors.white, style: TextStyle(color: isEscuro ? Colors.white : Colors.black87),
                        decoration: InputDecoration(labelText: "Unidade Específica", labelStyle: TextStyle(color: isEscuro ? Colors.white70 : Colors.grey.shade700), prefixIcon: Icon(Icons.church, color: isEscuro ? Colors.white70 : Colors.grey.shade600), filled: true, fillColor: isEscuro ? Colors.black26 : Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                        items: alasReais.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (val) => setStateModal(() => unidadeSelecionada = val!),
                      ),
                    ],
                    
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

                          String estacaFinal = 'Global (Todas)';
                          String unidadeFinal = 'Global (Todas)';

                          // TRAVAS DE SEGURANÇA: Impede criar líder de ala/estaca se o local físico não existir
                          if (!isGlobal) {
                            if (estacaSelecionada == 'Nenhuma Estaca Cadastrada') {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Crie uma Estaca primeiro na Gestão de Unidades!'), backgroundColor: Colors.redAccent));
                              return;
                            }
                            estacaFinal = estacaSelecionada;
                            unidadeFinal = 'Todas as Alas'; // Visão do Pres. de Estaca

                            if (isAlaNivel) {
                              if (unidadeSelecionada == 'Nenhuma Ala Cadastrada') {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Crie uma Ala/Ramo primeiro na Gestão de Unidades!'), backgroundColor: Colors.redAccent));
                                return;
                              }
                              unidadeFinal = unidadeSelecionada; // Visão do Bispo
                            }
                          }
                          
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
                              'estaca': estacaFinal,
                               'unidade': unidadeFinal, 
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

  // ==========================================
  // WIDGET CONSTRUTOR DE ITENS INDIVIDUAIS
  // ==========================================
  Widget _construirItemLider(DocumentSnapshot doc, bool isEscuro, Color corFundo, Color corTexto) {
    Map<String, dynamic> lider = doc.data() as Map<String, dynamic>;
    String nome = lider['nome'] ?? 'Sem Nome';
    String cargo = lider['cargo'] ?? 'Desconhecido';
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
            content: Text("Tem certeza que deseja remover o acesso de $nome?", style: TextStyle(color: corTexto)),
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
      child: Container(
        decoration: BoxDecoration(border: Border(top: BorderSide(color: isEscuro ? Colors.white12 : Colors.grey.shade100))),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

          // Organizando a árvore de hierarquia
          List<DocumentSnapshot> admins = [];
          List<DocumentSnapshot> conselhoGeral = [];
          Map<String, Map<String, List<DocumentSnapshot>>> arvoreEstacas = {};

          for (var doc in snapshot.data!.docs) {
             var lider = doc.data() as Map<String, dynamic>;
             String cargo = lider['cargo'] ?? '';
             String estaca = lider['estaca'] ?? 'Global';
             String unidade = lider['unidade'] ?? 'Global';

             if (cargo == 'Admin') {
               admins.add(doc);
             } else if (cargo == 'Conselho Geral') {
               conselhoGeral.add(doc);
             } else {
               arvoreEstacas.putIfAbsent(estaca, () => {});
               arvoreEstacas[estaca]!.putIfAbsent(unidade, () => []).add(doc);
             }
          }

          List<String> estacasOrdenadas = arvoreEstacas.keys.toList()..sort();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
               
               // 1. ADMINS
               if (admins.isNotEmpty)
                 Card(
                    color: corFundo, margin: const EdgeInsets.only(bottom: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isEscuro ? Colors.white12 : Colors.grey.shade200)), elevation: 0,
                    child: Theme(
                       data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                       child: ExpansionTile(
                          initiallyExpanded: true, iconColor: Colors.redAccent, collapsedIconColor: Colors.grey,
                          leading: CircleAvatar(backgroundColor: Colors.redAccent.withValues(alpha: 0.15), child: const Icon(Icons.security, color: Colors.redAccent)),
                          title: Text("Administração", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: corTexto)),
                          children: admins.map((doc) => _construirItemLider(doc, isEscuro, corFundo, corTexto)).toList(),
                       )
                    )
                 ),
               
               // 2. CONSELHO GERAL
               if (conselhoGeral.isNotEmpty)
                 Card(
                    color: corFundo, margin: const EdgeInsets.only(bottom: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isEscuro ? Colors.white12 : Colors.grey.shade200)), elevation: 0,
                    child: Theme(
                       data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                       child: ExpansionTile(
                          initiallyExpanded: true, iconColor: Colors.blue.shade700, collapsedIconColor: Colors.grey,
                          leading: CircleAvatar(backgroundColor: Colors.blue.shade700.withValues(alpha: 0.15), child: Icon(Icons.verified_user, color: Colors.blue.shade700)),
                          title: Text("Conselho Geral", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: corTexto)),
                          children: conselhoGeral.map((doc) => _construirItemLider(doc, isEscuro, corFundo, corTexto)).toList(),
                       )
                    )
                 ),
               
               // 3. ESTACAS > ALAS
               ...estacasOrdenadas.map((estaca) {
                  var alasMap = arvoreEstacas[estaca]!;
                  List<DocumentSnapshot> lideresEstaca = alasMap['Todas as Alas'] ?? alasMap['Global (Todas)'] ?? alasMap['Nenhuma Ala Cadastrada'] ?? [];
                  
                  // Colecionar alas agrupadas para hierarquia de Bispos e Ramos
                  List<String> nomesAlas = alasMap.keys.where((k) => k != 'Todas as Alas' && k != 'Global (Todas)' && k != 'Nenhuma Ala Cadastrada').toList()..sort();

                  if (lideresEstaca.isEmpty && nomesAlas.isEmpty) return const SizedBox.shrink();

                  return Card(
                     color: corFundo, margin: const EdgeInsets.only(bottom: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isEscuro ? Colors.white12 : Colors.grey.shade200)), elevation: 0,
                     child: Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                           iconColor: Colors.purple, collapsedIconColor: Colors.grey,
                           leading: CircleAvatar(backgroundColor: Colors.purple.withValues(alpha: 0.15), child: const Icon(Icons.map, color: Colors.purple)),
                           title: Text(estaca, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: corTexto)),
                           children: [
                              // Presidência da Estaca
                              if (lideresEstaca.isNotEmpty)
                                 ...lideresEstaca.map((doc) => _construirItemLider(doc, isEscuro, corFundo, corTexto)),
                              
                              // Alas aninhadas dentro da Estaca
                              ...nomesAlas.map((ala) {
                                 return Padding(
                                    padding: const EdgeInsets.only(left: 16),
                                    child: ExpansionTile(
                                       iconColor: Colors.orange, collapsedIconColor: Colors.grey,
                                       leading: const Icon(Icons.church, color: Colors.orange),
                                       title: Text(ala, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: corTexto)),
                                       children: alasMap[ala]!.map((doc) => _construirItemLider(doc, isEscuro, corFundo, corTexto)).toList(),
                                    )
                                 );
                              })
                           ]
                        )
                     )
                  );
               }),

               const SizedBox(height: 80),
            ]
          );
        }
      ),
    );
  }
}
// ignore_for_file: duplicate_ignore, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'home_tela.dart';
// ignore: unused_import
import 'recuperar_senha.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usuarioController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  bool _ocultarSenha = true;
  bool _carregando = false;

  Future<void> _fazerLoginFirebase() async {
    String inputUsuario = _usuarioController.text.trim().toLowerCase();
    String senha = _senhaController.text.trim();

    if (inputUsuario.isEmpty || senha.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha usuário e senha.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _carregando = true);

    // O truque: Transforma o usuário em um e-mail fantasma para o Firebase
    String emailFormatado = "$inputUsuario@sistema.local";

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: emailFormatado, password: senha);

      DocumentSnapshot docUsuario = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userCredential.user!.uid)
          .get();

      if (docUsuario.exists) {
        String nivelAcesso = docUsuario['nivel_acesso'] ?? 'Ala';
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeLider(nivelAcesso: nivelAcesso),
          ),
        );
      } else {
        // Se a ficha foi apagada do Firestore, mas o login existe no Authentication
        if (inputUsuario == 'admin' && senha == 'missao2026') {
          await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(userCredential.user!.uid)
              .set({
                'nome': 'Admin Principal',
                'usuario': 'admin',
                'cargo': 'Admin',
                'nivel_acesso': 'Admin',
                'unidade': 'Global',
              });
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Ficha restaurada! Clique em ENTRAR novamente."),
              backgroundColor: Colors.green,
            ),
          );
          await FirebaseAuth.instance.signOut();
        } else {
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Ficha não encontrada."),
              backgroundColor: Colors.redAccent,
            ),
          );
          await FirebaseAuth.instance.signOut();
        }
      }

      // ignore: unused_catch_clause
    } on FirebaseAuthException catch (e) {
      if (inputUsuario == 'admin' && senha == 'missao2026') {
        await _criarPrimeiroAdmin(emailFormatado, senha);
      } else {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuário ou senha incorretos.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _criarPrimeiroAdmin(String email, String senha) async {
    try {
      UserCredential credencial;
      try {
        credencial = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: senha,
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          // Se já existe no Auth, faz login para forçar a restauração do documento
          credencial = await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: email,
            password: senha,
          );
        } else {
          rethrow;
        }
      }

      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(credencial.user!.uid)
          .set({
            'nome': 'Admin Principal',
            'usuario': 'admin',
            'cargo': 'Admin',
            'nivel_acesso': 'Admin',
            'unidade': 'Global',
          });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Conta Mestre restaurada! Clique em ENTRAR novamente."),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erro ao restaurar Admin: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // ==========================================
  // WIDGET: LADO ESQUERDO (Apenas para PC)
  // ==========================================
  Widget _construirPainelApresentacao(BuildContext context) {
    bool isEscuro = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isEscuro ? const Color(0xFF151515) : const Color(0xFF0F2027),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isEscuro 
            ? [const Color(0xFF111111), const Color(0xFF1A1A1A)] 
            : [const Color(0xFF0F2027), const Color(0xFF203A43), const Color(0xFF2C5364)],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Image.asset(
                  'assets/images/image.png',
                  height: 160,
                  width: 160,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'Meu Chamado',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Sistema integrado para líderes.\nAcompanhe o progresso e ajude\nos jovens a alcançarem a missão.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.8),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // WIDGET: FORMULÁRIO (Usado no Celular e no PC)
  // ==========================================
  Widget _construirFormularioLogin(BuildContext context, {required bool isDesktop}) {
    bool isEscuro = Theme.of(context).brightness == Brightness.dark;
    Color corTexto = isEscuro ? Colors.white : Colors.black87;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400), // Mantém o formulário elegante no PC
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!isDesktop) ...[
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Image.asset(
                      'assets/images/image.png',
                      height: 140,
                      width: 140,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ] else ...[
                Text(
                  'Bem-vindo de volta',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: corTexto),
                ),
                const SizedBox(height: 8),
                Text(
                  'Faça login com suas credenciais de liderança.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 40),
              ],

              TextField(
                controller: _usuarioController,
                style: TextStyle(
                  color: isEscuro ? Colors.white : Colors.black87,
                ),
                decoration: InputDecoration(
                  hintText: 'Usuário',
                  hintStyle: TextStyle(
                    color: isEscuro ? Colors.white54 : Colors.grey,
                  ),
                  prefixIcon: Icon(
                    Icons.person_outline,
                    color: isEscuro ? Colors.white70 : Colors.grey,
                  ),
                  filled: true,
                  fillColor: isEscuro ? Colors.black26 : Colors.white,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isEscuro ? Colors.white24 : Colors.grey.shade400,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Colors.blue,
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15),

              TextField(
                controller: _senhaController,
                obscureText: _ocultarSenha,
                style: TextStyle(
                  color: isEscuro ? Colors.white : Colors.black87,
                ),
                decoration: InputDecoration(
                  hintText: 'Senha',
                  hintStyle: TextStyle(
                    color: isEscuro ? Colors.white54 : Colors.grey,
                  ),
                  prefixIcon: Icon(
                    Icons.key,
                    color: isEscuro ? Colors.white70 : Colors.grey,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _ocultarSenha ? Icons.visibility_off : Icons.visibility,
                      color: isEscuro ? Colors.white70 : Colors.grey,
                    ),
                    onPressed: () => setState(() => _ocultarSenha = !_ocultarSenha),
                  ),
                  filled: true,
                  fillColor: isEscuro ? Colors.black26 : Colors.white,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isEscuro ? Colors.white24 : Colors.grey.shade400,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Colors.blue,
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 35),

              SizedBox(
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  onPressed: _carregando ? null : _fazerLoginFirebase,
                  child: _carregando
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'ENTRAR',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 1.5,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isEscuro = Theme.of(context).brightness == Brightness.dark;
    
    // RESPONSIVIDADE: Detecta se a tela é larga (PC) ou estreita (Mobile)
    double larguraTela = MediaQuery.of(context).size.width;
    bool isDesktop = larguraTela > 800;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // No celular, o rodapé fica fixo embaixo. No PC, ele fica dentro do Stack na área direita.
      bottomNavigationBar: isDesktop ? null : Padding(
        padding: const EdgeInsets.only(bottom: 25.0, top: 10.0),
        child: Text(
          "Desenvolvido por Avison Cirilo",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isEscuro ? Colors.white54 : Colors.grey,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: isDesktop
          // ==========================================
          // LAYOUT PARA PC (Duas colunas)
          // ==========================================
          ? Row(
              children: [
                Expanded(flex: 4, child: _construirPainelApresentacao(context)),
                Expanded(
                  flex: 6, 
                  child: Stack(
                    children: [
                      _construirFormularioLogin(context, isDesktop: true),
                      // Rodapé na versão PC
                      Positioned(
                        bottom: 20,
                        left: 0,
                        right: 0,
                        child: Text(
                          "Desenvolvido por Avison Cirilo",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isEscuro ? Colors.white54 : Colors.grey,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  )
                ),
              ],
            )
          // ==========================================
          // LAYOUT PARA CELULAR (Formulário centralizado)
          // ==========================================
          : SafeArea(child: _construirFormularioLogin(context, isDesktop: false)),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_tela.dart';
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preencha usuário e senha.'), backgroundColor: Colors.orange));
      return;
    }

    setState(() => _carregando = true);
    
    // O truque: Transforma o usuário em um e-mail fantasma para o Firebase
    String emailFormatado = "$inputUsuario@sistema.local"; 

    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailFormatado,
        password: senha,
      );

      DocumentSnapshot docUsuario = await FirebaseFirestore.instance.collection('usuarios').doc(userCredential.user!.uid).get();

      if (docUsuario.exists) {
        String nivelAcesso = docUsuario['nivel_acesso'] ?? 'Ala';
        if (!mounted) return;
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeLider(nivelAcesso: nivelAcesso)));
      } else {
        // Se a ficha foi apagada do Firestore, mas o login existe no Authentication
        if (inputUsuario == 'admin' && senha == 'missao2026') {
          await FirebaseFirestore.instance.collection('usuarios').doc(userCredential.user!.uid).set({
            'nome': 'Admin Principal', 'usuario': 'admin', 'cargo': 'Admin', 'nivel_acesso': 'Admin', 'unidade': 'Global',
          });
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ficha restaurada! Clique em ENTRAR novamente."), backgroundColor: Colors.green));
          await FirebaseAuth.instance.signOut();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ficha não encontrada."), backgroundColor: Colors.redAccent));
          await FirebaseAuth.instance.signOut();
        }
      }

    } on FirebaseAuthException catch (e) {
      if (inputUsuario == 'admin' && senha == 'missao2026') {
         await _criarPrimeiroAdmin(emailFormatado, senha);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuário ou senha incorretos.'), backgroundColor: Colors.redAccent));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _criarPrimeiroAdmin(String email, String senha) async {
    try {
      UserCredential credencial;
      try {
        credencial = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: senha);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          // Se já existe no Auth, faz login para forçar a restauração do documento
          credencial = await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: senha);
        } else {
          rethrow;
        }
      }
      
      await FirebaseFirestore.instance.collection('usuarios').doc(credencial.user!.uid).set({
        'nome': 'Admin Principal', 'usuario': 'admin', 'cargo': 'Admin', 'nivel_acesso': 'Admin', 'unidade': 'Global',
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Conta Mestre restaurada! Clique em ENTRAR novamente."), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro ao restaurar Admin: $e"), backgroundColor: Colors.redAccent));
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isEscuro = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: SizedBox(
                width: 400,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.menu_book_rounded, size: 120, color: Colors.blue),
                    const SizedBox(height: 30),
                    
                    TextField(
                      controller: _usuarioController,
                      style: TextStyle(color: isEscuro ? Colors.white : Colors.black87),
                      decoration: InputDecoration(
                        hintText: 'Usuário (Ex: bispo.centro)',
                        hintStyle: TextStyle(color: isEscuro ? Colors.white54 : Colors.grey),
                        prefixIcon: Icon(Icons.person_outline, color: isEscuro ? Colors.white70 : Colors.grey),
                        filled: true, fillColor: isEscuro ? Colors.black26 : Colors.white,
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isEscuro ? Colors.white24 : Colors.grey.shade400)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blue, width: 2)),
                      ),
                    ),
                    const SizedBox(height: 15),
                    
                    TextField(
                      controller: _senhaController,
                      obscureText: _ocultarSenha,
                      style: TextStyle(color: isEscuro ? Colors.white : Colors.black87),
                      decoration: InputDecoration(
                        hintText: 'Senha',
                        hintStyle: TextStyle(color: isEscuro ? Colors.white54 : Colors.grey),
                        prefixIcon: Icon(Icons.key, color: isEscuro ? Colors.white70 : Colors.grey),
                        suffixIcon: IconButton(
                          icon: Icon(_ocultarSenha ? Icons.visibility_off : Icons.visibility, color: isEscuro ? Colors.white70 : Colors.grey),
                          onPressed: () => setState(() => _ocultarSenha = !_ocultarSenha),
                        ),
                        filled: true, fillColor: isEscuro ? Colors.black26 : Colors.white,
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isEscuro ? Colors.white24 : Colors.grey.shade400)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blue, width: 2)),
                      ),
                    ),
                    const SizedBox(height: 35),
                    
                    SizedBox(
                      width: double.infinity, height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        onPressed: _carregando ? null : _fazerLoginFirebase,
                        child: _carregando 
                          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('ENTRAR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
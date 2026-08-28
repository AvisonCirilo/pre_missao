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
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  bool _ocultarSenha = true;
  bool _carregando = false;

  // Função para realizar o login real com o Firebase
  Future<void> _fazerLoginFirebase() async {
    String email = _emailController.text.trim();
    String senha = _senhaController.text.trim();

    if (email.isEmpty || senha.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, preencha o e-mail e a senha.'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() {
      _carregando = true;
    });

    try {
      // 1. Autentica no Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: senha,
      );

      // 2. Busca o cargo do usuário na coleção 'usuarios' do Firestore
      // ignore: unused_local_variable
      String uid = userCredential.user!.uid;
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('email', isEqualTo: email)
          .get();

      String nivelAcesso = 'Ala'; // Padrão caso não encontre

      if (querySnapshot.docs.isNotEmpty) {
        var dadosUsuario = querySnapshot.docs.first.data() as Map<String, dynamic>;
        nivelAcesso = dadosUsuario['nivel_acesso'] ?? dadosUsuario['cargo'] ?? 'Ala';
      }

      if (!mounted) return;

      // 3. Redireciona para a Home dinâmica passando o nível de acesso encontrado
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeLider(nivelAcesso: nivelAcesso)),
      );

    } on FirebaseAuthException catch (e) {
      // ignore: avoid_print
      print("❌ ERRO DO FIREBASE AUTH: ${e.code}");

      String mensagemErro = 'Erro ao fazer login.';
      if (e.code == 'invalid-credential' || e.code == 'user-not-found' || e.code == 'wrong-password') {
        mensagemErro = 'E-mail ou senha incorretos.';
      } else if (e.code == 'invalid-email') {
        mensagemErro = 'Formato de e-mail inválido.';
      } else {
        mensagemErro = 'Erro Auth: ${e.code}'; // Mostra o erro na tela do celular
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensagemErro), backgroundColor: Colors.redAccent),
        );
      }
    }catch (e) {
      // ignore: avoid_print
      print("❌ ERRO GERAL/FIRESTORE: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro no banco de dados: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
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
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(color: isEscuro ? Colors.white : Colors.black87),
                      decoration: InputDecoration(
                        hintText: 'E-mail',
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
                    const SizedBox(height: 10),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RecuperarSenhaTela())),
                          child: Text('Esqueceu a senha?', style: TextStyle(color: isEscuro ? Colors.white70 : Colors.grey[700], fontWeight: FontWeight.bold)),
                        ),
                      ],
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
                    const SizedBox(height: 15),
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
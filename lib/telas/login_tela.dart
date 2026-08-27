/*import 'package:flutter/material.dart';
import 'home_tela.dart';
import 'recuperar_senha.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _ocultarSenha = true;

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
                    const Icon(Icons.menu_book_rounded, size: 140, color: Colors.blue),
                    const SizedBox(height: 30),
                    
                    TextField(
                      style: TextStyle(color: isEscuro ? Colors.white : Colors.black87),
                      decoration: InputDecoration(
                        hintText: 'Usuário',
                        hintStyle: TextStyle(color: isEscuro ? Colors.white54 : Colors.grey),
                        prefixIcon: Icon(Icons.person_outline, color: isEscuro ? Colors.white70 : Colors.grey),
                        filled: true, fillColor: isEscuro ? Colors.black26 : Colors.white,
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isEscuro ? Colors.white24 : Colors.grey.shade400)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blue, width: 2)),
                      ),
                    ),
                    const SizedBox(height: 15),
                    
                    TextField(
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
                    const SizedBox(height: 25),
                    
                    SizedBox(
                      width: double.infinity, height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HomeLider())),
                        child: const Text('LOGIN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
}*/

import 'package:flutter/material.dart';
import 'home_tela.dart';
import 'recuperar_senha.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _ocultarSenha = true;

  // Função centralizada para fazer login e enviar o cargo
  void _fazerLogin(String cargo) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => HomeLider(nivelAcesso: cargo)),
    );
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
                      style: TextStyle(color: isEscuro ? Colors.white : Colors.black87),
                      decoration: InputDecoration(
                        hintText: 'Usuário',
                        hintStyle: TextStyle(color: isEscuro ? Colors.white54 : Colors.grey),
                        prefixIcon: Icon(Icons.person_outline, color: isEscuro ? Colors.white70 : Colors.grey),
                        filled: true, fillColor: isEscuro ? Colors.black26 : Colors.white,
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isEscuro ? Colors.white24 : Colors.grey.shade400)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blue, width: 2)),
                      ),
                    ),
                    const SizedBox(height: 15),
                    
                    TextField(
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
                    
                    // ==========================================
                    // PAINEL DE TESTES RÁPIDOS DE LOGIN
                    // ==========================================
                    Text("ESCOLHA SEU PERFIL PARA TESTAR", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
                    const SizedBox(height: 10),

                    SizedBox(
                      width: double.infinity, height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        onPressed: () => _fazerLogin('Ala'),
                        child: const Text('Entrar como Bispo (Ala)', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    
                    SizedBox(
                      width: double.infinity, height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        onPressed: () => _fazerLogin('Estaca'),
                        child: const Text('Entrar como Estaca', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 10),

                    SizedBox(
                      width: double.infinity, height: 50,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.blueGrey, side: const BorderSide(color: Colors.blueGrey), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        onPressed: () => _fazerLogin('Admin'),
                        child: const Text('Entrar como Admin Global', style: TextStyle(fontWeight: FontWeight.bold)),
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
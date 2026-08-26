import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class RecuperarSenhaTela extends StatelessWidget {
  const RecuperarSenhaTela({super.key});

  Future<void> _abrirWhatsApp(BuildContext context) async {
    const numeroTelefone = '5591991021704';
    const mensagem = 'Olá, sou líder local e preciso de ajuda para recuperar minha senha de acesso no app de Preparação Missionária.';
    final Uri url = Uri.parse('https://wa.me/$numeroTelefone?text=${Uri.encodeComponent(mensagem)}');
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) throw Exception();
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao abrir o WhatsApp.'), backgroundColor: Colors.redAccent));
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isEscuro = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, foregroundColor: isEscuro ? Colors.white : Colors.black),
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
                    const Icon(Icons.support_agent, size: 100, color: Colors.blue),
                    const SizedBox(height: 30),
                    Text('Precisa de Ajuda?', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: isEscuro ? Colors.white : Colors.black)),
                    const SizedBox(height: 15),
                    const Text('Para recuperar o seu acesso ou tirar dúvidas, entre em contato direto com o administrador via WhatsApp.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey)),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity, height: 55,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        icon: const Icon(Icons.chat), label: const Text('CHAMAR NO WHATSAPP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        onPressed: () => _abrirWhatsApp(context),
                      ),
                    ),
                    const SizedBox(height: 20),
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
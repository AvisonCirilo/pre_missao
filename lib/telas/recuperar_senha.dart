import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class RecuperarSenhaTela extends StatelessWidget {
  const RecuperarSenhaTela({super.key});

  // Função que faz a mágica de abrir o WhatsApp
  Future<void> _abrirWhatsApp(BuildContext context) async {
    // Código do País (55) + DDD (91) + Número[cite: 2]
    const numeroTelefone = '5591991021704'; 
    
    // A mensagem padrão que já vai aparecer digitada para a pessoa
    const mensagem = 'Olá, sou líder local e preciso de ajuda para recuperar minha senha de acesso no app de Preparação Missionária.';
    
    // Monta o link oficial do WhatsApp[cite: 2]
    final Uri url = Uri.parse('https://wa.me/$numeroTelefone?text=${Uri.encodeComponent(mensagem)}');

    try {
      // Tenta abrir o link no aplicativo do WhatsApp[cite: 2]
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Não foi possível abrir o WhatsApp');
      }
    } catch (e) {
      // Se der erro (ex: não tem WhatsApp instalado), mostra um aviso[cite: 2]
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao tentar abrir o WhatsApp. Verifique se o app está instalado.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Deixa a barra invisível[cite: 2]
        elevation: 0, // Tira a sombra[cite: 2]
        foregroundColor: Colors.black, // Cor da setinha de voltar[cite: 2]
      ),
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
                    // Ícone de Suporte
                    const Icon(
                      Icons.support_agent,
                      size: 100,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 30),
                    
                    // Títulos
                    const Text(
                      'Precisa de Ajuda?',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'Para recuperar o seu acesso ou tirar dúvidas, entre em contato direto com o administrador via WhatsApp.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 40),

                    // Botão Chamar no WhatsApp
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.chat), // Ícone de chat no botão
                        label: const Text(
                          'CHAMAR NO WHATSAPP',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
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
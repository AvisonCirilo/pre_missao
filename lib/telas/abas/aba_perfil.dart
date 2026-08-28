import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../main.dart'; 
import '../chamados_enviados.dart';
import '../../services/gerador_pdf.dart';

class AbaPerfil extends StatefulWidget {
  const AbaPerfil({super.key});

  @override
  State<AbaPerfil> createState() => _AbaPerfilState();
}

class _AbaPerfilState extends State<AbaPerfil> {
  // Variáveis do Líder
  final String _nomeLider = "Irmão Silva";
  final String _cargoLider = "Bispo"; 
  final String _unidadeLider = "Ala Centro - Estaca Norte";

  Future<void> _abrirLink(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Não foi possível abrir o link');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao abrir a página oficial.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isEscuro = Theme.of(context).brightness == Brightness.dark;
    Color corFundo = isEscuro ? const Color(0xFF1E1E1E) : Colors.white;
    Color corTexto = isEscuro ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Meu Perfil', style: TextStyle(fontWeight: FontWeight.bold, color: corTexto)),
        backgroundColor: corFundo,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.blue.withValues(alpha: 0.2),
                    child: Text(_nomeLider[0], style: const TextStyle(fontSize: 40, color: Colors.blue, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 15),
                  Text(_nomeLider, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: corTexto)),
                  Text(_cargoLider, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                    ),
                    child: Text(_unidadeLider, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            
            Align(
              alignment: Alignment.centerLeft,
              child: Text("Ferramentas", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade400)),
            ),
            const SizedBox(height: 10),
            Card(
              color: corFundo,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isEscuro ? Colors.white12 : Colors.grey.shade200)),
              child: Column(
                children: [
                  ListTile(
                    leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.send, color: Colors.blue)),
                    title: Text("Chamados Enviados", style: TextStyle(color: corTexto)),
                    subtitle: Text("Jovens que já finalizaram o processo", style: TextStyle(color: Colors.grey.shade500)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ChamadosEnviadosTela()),
                      );
                    },
                  ),
                  Divider(height: 1, color: isEscuro ? Colors.white12 : Colors.grey.shade200),
                  ListTile(
                    leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.picture_as_pdf, color: Colors.green)),
                    title: Text("Exportar Relatório (PDF)", style: TextStyle(color: corTexto)),
                    subtitle: Text("Gera um resumo da ala para a Estaca", style: TextStyle(color: Colors.grey.shade500)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                    onTap: () async {
                      List<Map<String, dynamic>> jovensParaRelatorio = [
                        {'nome': 'João Silva', 'idade': 19, 'status': 'Aguardando Exames', 'telefone': '(91) 90000-0000'},
                        {'nome': 'Lucas Souza', 'idade': 17, 'status': 'Perspectiva', 'telefone': '(91) 91111-1111'},
                        {'nome': 'Ana Beatriz', 'idade': 18, 'status': 'Enviado', 'data_envio': '15/07/2026', 'destino': 'Missão Brasil São Paulo Sul'},
                        {'nome': 'Marcos Paulo', 'idade': 20, 'status': 'Enviado', 'data_envio': '12/08/2026', 'destino': 'Aguardando Carta'},
                      ];

                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gerando PDF...')));
                      await GeradorPdf.gerarRelatorio(_unidadeLider.split(" - ")[0], jovensParaRelatorio);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
            
            Align(
              alignment: Alignment.centerLeft,
              child: Text("Recursos Oficiais", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade400)),
            ),
            const SizedBox(height: 10),
            Card(
              color: corFundo,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isEscuro ? Colors.white12 : Colors.grey.shade200)),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.public, color: Colors.blue),
                    title: Text("Recursos de Líderes e Secretários", style: TextStyle(color: corTexto)),
                    trailing: const Icon(Icons.open_in_new, size: 16, color: Colors.grey),
                    onTap: () => _abrirLink('https://lcr.churchofjesuschrist.org/'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
            
            Align(
              alignment: Alignment.centerLeft,
              child: Text("Configurações", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade400)),
            ),
            const SizedBox(height: 10),
            Card(
              color: corFundo,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isEscuro ? Colors.white12 : Colors.grey.shade200)),
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.dark_mode, color: Colors.grey),
                    title: Text("Modo Escuro (Dark Mode)", style: TextStyle(color: corTexto)),
                    activeColor: Colors.blue,
                    value: isEscuro, 
                    onChanged: (bool valor) {
                      temaGlobalNotifier.value = valor ? ThemeMode.dark : ThemeMode.light;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 35),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: corFundo,
                      title: Text("Sair da Conta", style: TextStyle(color: corTexto)),
                      content: Text("Tem certeza que deseja sair do aplicativo?", style: TextStyle(color: corTexto)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.of(context).popUntil((route) => route.isFirst);
                          },
                          child: const Text("Sair"),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.logout),
                label: const Text("Sair da Conta", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
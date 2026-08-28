import 'package:flutter/material.dart';

class ChamadosEnviadosTela extends StatelessWidget {
  const ChamadosEnviadosTela({super.key});

  @override
  Widget build(BuildContext context) {
    bool isEscuro = Theme.of(context).brightness == Brightness.dark;
    Color corFundo = isEscuro ? const Color(0xFF1E1E1E) : Colors.white;
    Color corTexto = isEscuro ? Colors.white : Colors.black87;

    // Banco de dados simulado apenas para os jovens "Enviados"
    final List<Map<String, dynamic>> jovensEnviados = [
      {'nome': 'Marcos Paulo', 'idade': 20, 'data_envio': '12/08/2026', 'destino': 'Aguardando Carta...'},
      {'nome': 'Julia Costa', 'idade': 19, 'data_envio': '05/07/2026', 'destino': 'Missão Brasil São Paulo Sul'},
      {'nome': 'Felipe Almeida', 'idade': 18, 'data_envio': '20/05/2026', 'destino': 'Missão Portugal Lisboa'},
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Chamados Enviados', style: TextStyle(fontWeight: FontWeight.bold, color: corTexto)),
        backgroundColor: corFundo,
        elevation: 1,
        iconTheme: IconThemeData(color: corTexto), // Cor da setinha de voltar
      ),
      body: jovensEnviados.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.send, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text("Nenhum chamado enviado ainda.", style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: jovensEnviados.length,
              itemBuilder: (context, index) {
                final jovem = jovensEnviados[index];
                bool aguardando = jovem['destino'].contains('Aguardando');

                return Card(
                  color: corFundo,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isEscuro ? Colors.white12 : Colors.grey.shade200)),
                  elevation: 0,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    leading: CircleAvatar(
                      backgroundColor: aguardando ? Colors.orange.withValues(alpha: 0.15) : Colors.green.withValues(alpha: 0.15),
                      child: Icon(aguardando ? Icons.hourglass_empty : Icons.flight_takeoff, color: aguardando ? Colors.orange : Colors.green),
                    ),
                    title: Text(jovem['nome'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: corTexto)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text("Enviado em: ${jovem['data_envio']}", style: TextStyle(color: isEscuro ? Colors.white70 : Colors.black87, fontSize: 12)),
                        const SizedBox(height: 2),
                        Text(jovem['destino'], style: TextStyle(color: aguardando ? Colors.orange : Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                    trailing: const Icon(Icons.star, color: Colors.amber),
                  ),
                );
              },
            ),
    );
  }
}
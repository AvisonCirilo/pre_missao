import 'package:flutter/material.dart';

import 'admin/lista_jovens.dart';
import 'admin/gestao_lideres.dart';
import './admin/gestao_unidades.dart';

class AbaAdmin extends StatefulWidget {
  const AbaAdmin({super.key});

  @override
  State<AbaAdmin> createState() => _AbaAdminState();
}

class _AbaAdminState extends State<AbaAdmin> {
  // WIDGET AUXILIAR: Cartões de Estatísticas Globais
  Widget _construirCardEstatistica(
    String titulo,
    String valor,
    Color cor,
    IconData icone,
    bool isEscuro,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: isEscuro ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isEscuro ? Colors.white12 : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: cor.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icone, color: cor, size: 28),
            const SizedBox(height: 8),
            Text(
              valor,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isEscuro ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // WIDGET AUXILIAR: Botões de Ação do Menu
  Widget _construirBotaoAcao(
    String titulo,
    String subtitulo,
    IconData icone,
    Color cor,
    bool isEscuro,
    VoidCallback acao,
  ) {
    return Card(
      color: isEscuro ? const Color(0xFF1E1E1E) : Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isEscuro ? Colors.white12 : Colors.grey.shade200,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: cor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icone, color: cor),
        ),
        title: Text(
          titulo,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isEscuro ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitulo,
          style: TextStyle(
            fontSize: 12,
            color: isEscuro ? Colors.white54 : Colors.black54,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 14,
          color: Colors.grey,
        ),
        onTap: acao,
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
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Painel de Administração',
          style: TextStyle(fontWeight: FontWeight.bold, color: corTexto),
        ),
        backgroundColor: corFundo,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==========================================
            // 1. ESTATÍSTICAS GLOBAIS DA ESTACA/DISTRITO
            // ==========================================
            Text(
              "Visão Global do Sistema",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _construirCardEstatistica(
                  "Líderes",
                  "8",
                  Colors.blue,
                  Icons.admin_panel_settings,
                  isEscuro,
                ),
                const SizedBox(width: 10),
                _construirCardEstatistica(
                  "Total Jovens",
                  "32",
                  Colors.green,
                  Icons.groups,
                  isEscuro,
                ),
                const SizedBox(width: 10),
                _construirCardEstatistica(
                  "Alas/Ramos",
                  "5",
                  Colors.orange,
                  Icons.church,
                  isEscuro,
                ),
              ],
            ),
            const SizedBox(height: 35),

            // ==========================================
            // 2. GESTÃO DE ACESSOS (LÍDERES)
            // ==========================================
            Text(
              "Gestão de Acessos",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 10),
            _construirBotaoAcao(
              "Gerenciar Líderes",
              "Criar contas, alterar senhas e remover acessos de bispos e líderes da missão.",
              Icons.manage_accounts,
              Colors.blue,
              isEscuro,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GestaoLideresTela(),
                  ),
                );
              },
            ),

            const SizedBox(height: 25),

            // ==========================================
            // 3. ESTRUTURA DA ESTACA / DISTRITO
            // ==========================================
            Text(
              "Estrutura da Igreja",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 10),
            _construirBotaoAcao(
              "Gerenciar Alas e Ramos",
              "Adicionar ou renomear as unidades que aparecerão no aplicativo.",
              Icons.church,
              Colors.orange,
              isEscuro,
              () {
                // Essa é a navegação que abre a nova tela!
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GestaoUnidadesTela(),
                  ),
                );
              },
            ),
            _construirBotaoAcao(
              "Lista Global de Jovens",
              "Acessar e pesquisar todos os jovens cadastrados em todas as unidades.",
              Icons.format_list_bulleted,
              Colors.green,
              isEscuro,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ListaGlobalJovensTela(),
                  ),
                );
              },
            ),

            const SizedBox(height: 25),

            // ==========================================
            // 4. CONFIGURAÇÕES DO SISTEMA
            // ==========================================
            Text(
              "Sistema",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 10),
            _construirBotaoAcao(
              "Exportar Banco de Dados",
              "Baixar uma cópia completa de segurança (Backup) de todas as informações.",
              Icons.cloud_download,
              Colors.purple,
              isEscuro,
              () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Iniciando Backup...')),
              ),
            ),
            _construirBotaoAcao(
              "Limpar Registros Antigos",
              "Excluir jovens que já viajaram para a missão há mais de 1 ano.",
              Icons.delete_sweep,
              Colors.redAccent,
              isEscuro,
              () => ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Acesso Restrito!'))),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

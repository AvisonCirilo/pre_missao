import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class GeradorPdf {
  static Future<void> gerarRelatorio(String tituloRelatorio, List<Map<String, dynamic>> jovens) async {
    final pdf = pw.Document();

    // ==========================================
    // MÁGICA: HIERARQUIA DE ESTACA > ALA
    // ==========================================
    Map<String, Map<String, List<Map<String, dynamic>>>> arvorePDF = {};
    
    for (var j in jovens) {
      // Tratamento para evitar campos vazios quebrando o layout
      String estaca = (j['estaca'] == null || j['estaca'].toString().trim().isEmpty) ? 'Sem Estaca' : j['estaca'];
      String unidade = (j['unidade'] == null || j['unidade'].toString().trim().isEmpty) ? 'Sem Ala' : j['unidade'];

      arvorePDF.putIfAbsent(estaca, () => {});
      arvorePDF[estaca]!.putIfAbsent(unidade, () => []).add(j);
    }

    List<String> estacasOrdenadas = arvorePDF.keys.toList()..sort();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          List<pw.Widget> conteudos = [
            // CABEÇALHO DO RELATÓRIO
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Relatório de Preparação Missionária', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),
                    pw.Text(tituloRelatorio, style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
                  ],
                ),
                pw.Text('Data: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}', style: const pw.TextStyle(color: PdfColors.grey700)),
              ],
            ),
            pw.Divider(thickness: 1, color: PdfColors.grey400),
            pw.SizedBox(height: 10),
          ];

          if (jovens.isEmpty) {
            conteudos.add(pw.Text('Nenhum dado encontrado para gerar o relatório.', style: const pw.TextStyle(color: PdfColors.grey600)));
            return conteudos;
          }

          // ==========================================
          // CONSTRUÇÃO DOS BLOCOS VISUAIS
          // ==========================================
          for (String estaca in estacasOrdenadas) {
            
            // CABEÇALHO DA ESTACA (Destaque principal)
            conteudos.add(
              pw.Container(
                width: double.infinity,
                margin: const pw.EdgeInsets.only(top: 20, bottom: 10),
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue800,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(estaca.toUpperCase(), style: pw.TextStyle(color: PdfColors.white, fontSize: 14, fontWeight: pw.FontWeight.bold)),
              ),
            );

            Map<String, List<Map<String, dynamic>>> alasDaEstaca = arvorePDF[estaca]!;
            List<String> alasOrdenadas = alasDaEstaca.keys.toList()..sort();

            for (String ala in alasOrdenadas) {
              
              // CABEÇALHO DA ALA (Subtítulo cinza claro)
              conteudos.add(
                pw.Container(
                  width: double.infinity,
                  margin: const pw.EdgeInsets.only(top: 10, bottom: 8),
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(left: pw.BorderSide(color: PdfColors.blue800, width: 4)),
                    color: PdfColors.grey200,
                  ),
                  child: pw.Text(ala, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                ),
              );

              var listaJovens = alasDaEstaca[ala]!;
              
              // Ajustado para englobar os status atuais corretamente
              var prep = listaJovens.where((j) => j['status'] != 'Enviado' && j['status'] != 'Finalizado').toList();
              var env = listaJovens.where((j) => j['status'] == 'Enviado' || j['status'] == 'Finalizado').toList();

              // Função para exibir o texto correto na coluna de status da tabela
              String traduzirStatus(String? statusBD) {
                if (statusBD == 'Preparação') return 'Em processo';
                if (statusBD == 'Finalizado' || statusBD == 'Enviado') return 'Finalizado';
                return statusBD ?? '';
              }

              // TABELA: JOVENS EM PROCESSO
              if (prep.isNotEmpty) {
                conteudos.add(pw.Text('Em processo / Perspectiva', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)));
                conteudos.add(pw.SizedBox(height: 4));
                conteudos.add(
                  pw.TableHelper.fromTextArray(
                    headers: ['Nome', 'Idade', 'Status', 'Telefone'],
                    headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.black, fontSize: 9),
                    headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
                    rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5))),
                    cellStyle: const pw.TextStyle(fontSize: 9),
                    cellPadding: const pw.EdgeInsets.all(6),
                    data: prep.map((j) => [
                      j['nome'], 
                      j['idade'].toString(), 
                      traduzirStatus(j['status']), 
                      j['telefone'] ?? ''
                    ]).toList(),
                  ),
                );
                conteudos.add(pw.SizedBox(height: 10));
              }

              // TABELA: PROCESSOS FINALIZADOS
              if (env.isNotEmpty) {
                conteudos.add(pw.Text('Processos Finalizados', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)));
                conteudos.add(pw.SizedBox(height: 4));
                conteudos.add(
                  pw.TableHelper.fromTextArray(
                    headers: ['Nome', 'Idade', 'Data de Envio', 'Destino'],
                    headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.black, fontSize: 9),
                    headerDecoration: const pw.BoxDecoration(color: PdfColors.green100),
                    rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5))),
                    cellStyle: const pw.TextStyle(fontSize: 9),
                    cellPadding: const pw.EdgeInsets.all(6),
                    data: env.map((j) => [
                      j['nome'], 
                      j['idade'].toString(), 
                      j['data_envio'] ?? '', 
                      j['destino'] ?? ''
                    ]).toList(),
                  ),
                );
                conteudos.add(pw.SizedBox(height: 15));
              }
            }
          }

          return conteudos;
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Relatorio_Missoes.pdf',
    );
  }
}
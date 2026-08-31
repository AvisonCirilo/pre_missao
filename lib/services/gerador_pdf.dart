import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class GeradorPdf {
  static Future<void> gerarRelatorio(String tituloRelatorio, List<Map<String, dynamic>> jovens) async {
    final pdf = pw.Document();

    // MÁGICA: Agrupa os jovens por Estaca e Ala
    Map<String, List<Map<String, dynamic>>> jovensPorUnidade = {};
    for (var j in jovens) {
      String estaca = j['estaca'] ?? 'Sem Estaca';
      String unidade = j['unidade'] ?? 'Sem Ala';
      String chave = "$estaca - $unidade";
      jovensPorUnidade.putIfAbsent(chave, () => []).add(j);
    }

    List<String> chavesOrdenadas = jovensPorUnidade.keys.toList()..sort();

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

          // GERA UM BLOCO PARA CADA ALA/UNIDADE ENCONTRADA NO FILTRO
          for (String chave in chavesOrdenadas) {
            var listaJovens = jovensPorUnidade[chave]!;
            var prep = listaJovens.where((j) => j['status'] != 'Enviado').toList();
            var env = listaJovens.where((j) => j['status'] == 'Enviado').toList();

            conteudos.add(
              pw.Container(
                width: double.infinity,
                margin: const pw.EdgeInsets.only(top: 15, bottom: 10),
                padding: const pw.EdgeInsets.all(6),
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                child: pw.Text(chave, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              ),
            );

            if (prep.isNotEmpty) {
              conteudos.add(pw.Text('Em Preparação / Perspectiva', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)));
              conteudos.add(pw.SizedBox(height: 5));
              conteudos.add(
                pw.TableHelper.fromTextArray(
                  headers: ['Nome', 'Idade', 'Status', 'Telefone'],
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
                  rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5))),
                  cellStyle: const pw.TextStyle(fontSize: 10),
                  cellPadding: const pw.EdgeInsets.all(6),
                  data: prep.map((j) => [j['nome'], j['idade'].toString(), j['status'] ?? '', j['telefone'] ?? '']).toList(),
                ),
              );
              conteudos.add(pw.SizedBox(height: 10));
            }

            if (env.isNotEmpty) {
              conteudos.add(pw.Text('Chamados Enviados', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)));
              conteudos.add(pw.SizedBox(height: 5));
              conteudos.add(
                pw.TableHelper.fromTextArray(
                  headers: ['Nome', 'Idade', 'Data Envio', 'Destino'],
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.green800),
                  rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5))),
                  cellStyle: const pw.TextStyle(fontSize: 10),
                  cellPadding: const pw.EdgeInsets.all(6),
                  data: env.map((j) => [j['nome'], j['idade'].toString(), j['data_envio'] ?? '', j['destino'] ?? '']).toList(),
                ),
              );
              conteudos.add(pw.SizedBox(height: 15));
            }
          }

          if (jovens.isEmpty) {
            conteudos.add(pw.Text('Nenhum dado encontrado para gerar o relatório.', style: const pw.TextStyle(color: PdfColors.grey600)));
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
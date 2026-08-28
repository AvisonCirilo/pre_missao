import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class GeradorPdf {
  static Future<void> gerarRelatorio(String nomeUnidade, List<Map<String, dynamic>> jovens) async {
    final pdf = pw.Document();

    // Filtra a lista separando quem já foi enviado de quem ainda está se preparando
    final jovensPreparacao = jovens.where((j) => j['status'] != 'Enviado').toList();
    final jovensEnviados = jovens.where((j) => j['status'] == 'Enviado').toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // CABEÇALHO DO RELATÓRIO
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Relatório de Preparação Missionária', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),
                    pw.Text('Unidade: $nomeUnidade', style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
                  ],
                ),
                pw.Text('Data: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}', style: const pw.TextStyle(color: PdfColors.grey700)),
              ],
            ),
            pw.Divider(thickness: 1, color: PdfColors.grey400),
            pw.SizedBox(height: 20),

            // SEÇÃO 1: PREPARAÇÃO E PERSPECTIVA (TABELA AZUL)
            pw.Text('Jovens em Preparação / Perspectiva', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
            pw.SizedBox(height: 10),
            if (jovensPreparacao.isEmpty)
              pw.Text('Nenhum jovem em preparação no momento.', style: const pw.TextStyle(color: PdfColors.grey600))
            else
              pw.TableHelper.fromTextArray(
                headers: ['Nome do Jovem', 'Idade', 'Status', 'Telefone'],
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
                rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5))),
                cellPadding: const pw.EdgeInsets.all(8),
                data: jovensPreparacao.map((jovem) {
                  return [
                    jovem['nome'],
                    jovem['idade'].toString(),
                    jovem['status'] ?? 'Em Preparação',
                    jovem['telefone'] ?? 'Não informado',
                  ];
                }).toList(),
              ),
            
            pw.SizedBox(height: 30),

            // SEÇÃO 2: CHAMADOS ENVIADOS (TABELA VERDE)
            pw.Text('Chamados Enviados (Últimos 12 meses)', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
            pw.SizedBox(height: 10),
            if (jovensEnviados.isEmpty)
              pw.Text('Nenhum chamado enviado recentemente.', style: const pw.TextStyle(color: PdfColors.grey600))
            else
              pw.TableHelper.fromTextArray(
                headers: ['Nome do Jovem', 'Idade', 'Data de Envio', 'Destino'],
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.green800),
                rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5))),
                cellPadding: const pw.EdgeInsets.all(8),
                data: jovensEnviados.map((jovem) {
                  return [
                    jovem['nome'],
                    jovem['idade'].toString(),
                    jovem['data_envio'] ?? 'Não registrada',
                    jovem['destino'] ?? 'Aguardando Carta',
                  ];
                }).toList(),
              ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Relatorio_$nomeUnidade.pdf',
    );
  }
}
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class FichaPdfService {
  static Future<void> exportarFichaPdf({
    required String nomeAluno,
    required String objetivo,
    required String nomePersonal,
    required String crefPersonal,
    required List<dynamic> fichas,
  }) async {
    final doc = pw.Document();

    final corPrimaria = PdfColor.fromHex('#00C853');
    final corEscura = PdfColor.fromHex('#121212');
    final corCard = PdfColor.fromHex('#F4F6F8');

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) => [
          // Cabeçalho PersonalPro
          pw.Container(
            padding: const pw.EdgeInsets.all(18),
            decoration: pw.BoxDecoration(
              color: corEscura,
              borderRadius: pw.BorderRadius.circular(10),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'COACH CENTER — FICHA DE TREINO OFICIAL',
                      style: pw.TextStyle(
                        color: corPrimaria,
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Aluno(a): $nomeAluno  |  Objetivo: $objetivo',
                      style: const pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      nomePersonal,
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    if (crefPersonal.isNotEmpty)
                      pw.Text(
                        crefPersonal,
                        style: const pw.TextStyle(
                          color: PdfColors.grey300,
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // Lista de Divisões (Treino A, B, C...)
          ...fichas.map((ficha) {
            final nomeDivisao = ficha['nomeDivisao']?.toString() ?? 'Treino';
            final descricao = ficha['descricao']?.toString() ?? '';
            final exercicios = (ficha['exercicios'] as List<dynamic>?) ?? [];

            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 18),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: pw.BoxDecoration(
                      color: corPrimaria,
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          nomeDivisao.toUpperCase(),
                          style: pw.TextStyle(
                            color: PdfColors.black,
                            fontSize: 13,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        if (descricao.isNotEmpty)
                          pw.Text(
                            descricao,
                            style: const pw.TextStyle(
                              color: PdfColors.black,
                              fontSize: 9,
                            ),
                          ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Table(
                    border: pw.TableBorder.all(
                      color: PdfColors.grey300,
                      width: 0.6,
                    ),
                    columnWidths: {
                      0: const pw.FlexColumnWidth(3.0),
                      1: const pw.FlexColumnWidth(1.3),
                      2: const pw.FlexColumnWidth(1.2),
                      3: const pw.FlexColumnWidth(1.0),
                      4: const pw.FlexColumnWidth(1.0),
                      5: const pw.FlexColumnWidth(2.5),
                    },
                    children: [
                      pw.TableRow(
                        decoration: pw.BoxDecoration(color: corCard),
                        children: [
                          _cellHeader('Exercício'),
                          _cellHeader('Grupo'),
                          _cellHeader('Séries x Reps'),
                          _cellHeader('Carga'),
                          _cellHeader('Descanso'),
                          _cellHeader('Observação / Técnica'),
                        ],
                      ),
                      ...exercicios.map((ex) {
                        final series = ex['series']?.toString() ?? '4';
                        final reps = ex['repeticoes']?.toString() ?? '10-12';
                        final carga = ex['cargaKg']?.toString() ?? '0';
                        final descanso =
                            ex['descansoSegundos']?.toString() ?? '60';
                        final obs = ex['observacaoTecnica']?.toString() ?? '-';

                        return pw.TableRow(
                          children: [
                            _cellBody(
                              ex['nomeExercicio']?.toString() ?? '',
                              bold: true,
                            ),
                            _cellBody(ex['grupoMuscular']?.toString() ?? ''),
                            _cellBody('${series}x $reps'),
                            _cellBody('${carga}kg'),
                            _cellBody('${descanso}s'),
                            _cellBody(obs),
                          ],
                        );
                      }),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => doc.save(),
      name: 'Ficha_Treino_${nomeAluno.replaceAll(' ', '_')}.pdf',
    );
  }

  static pw.Widget _cellHeader(String text) => pw.Padding(
    padding: const pw.EdgeInsets.all(6),
    child: pw.Text(
      text,
      style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
    ),
  );

  static pw.Widget _cellBody(String text, {bool bold = false}) => pw.Padding(
    padding: const pw.EdgeInsets.all(6),
    child: pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: 8.5,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      ),
    ),
  );
}

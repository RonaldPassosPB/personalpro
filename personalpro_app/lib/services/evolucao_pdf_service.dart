import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class EvolucaoPdfService {
  static Future<void> exportarEvolucaoPdf({
    required String nomeAluno,
    required String nomePersonal,
    required List<dynamic> avaliacoes,
    required List<dynamic> progressaoCargas,
    required List<dynamic> historicoTreinos,
  }) async {
    final doc = pw.Document();

    final corPrimaria = PdfColor.fromHex('#00C853');
    final corEscura = PdfColor.fromHex('#121212');
    final corCard = PdfColor.fromHex('#F4F6F8');
    final dataEmissao = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) => [
          // Cabeçalho Oficial
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
                      'PERSONALPRO — RELATÓRIO DE EVOLUÇÃO FÍSICA',
                      style: pw.TextStyle(
                        color: corPrimaria,
                        fontSize: 15,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Aluno: $nomeAluno  |  Personal: $nomePersonal',
                      style: const pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Emissão: $dataEmissao',
                      style: const pw.TextStyle(
                        color: PdfColors.grey400,
                        fontSize: 10,
                      ),
                    ),
                    pw.Text(
                      'Gestão de Performance',
                      style: pw.TextStyle(
                        color: corPrimaria,
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 18),

          // Seção 1: Histórico de Avaliações Físicas & Composição Corporal
          pw.Text(
            '1. HISTÓRICO DE COMPOSIÇÃO CORPORAL & ANTROPOMETRIA',
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: corEscura,
            ),
          ),
          pw.SizedBox(height: 8),

          if (avaliacoes.isEmpty)
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: corCard,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Text(
                'Nenhuma avaliação física cadastrada no período.',
                style: const pw.TextStyle(
                  fontSize: 11,
                  color: PdfColors.grey700,
                ),
              ),
            )
          else ...[
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _cellHeader('Data'),
                    _cellHeader('Peso (kg)'),
                    _cellHeader('Altura (m)'),
                    _cellHeader('IMC'),
                    _cellHeader('% Gordura (BF)'),
                    _cellHeader('Massa Magra'),
                  ],
                ),
                ...avaliacoes.map((av) {
                  final peso = (av['peso'] ?? 0).toDouble();
                  final alt = (av['altura'] ?? 0).toDouble();
                  final imc = alt > 0
                      ? (peso / (alt * alt)).toStringAsFixed(1)
                      : '-';
                  final bf = av['percentualGordura'] != null
                      ? '${av['percentualGordura']}%'
                      : '-';
                  final mm = av['massaMagraKg'] != null
                      ? '${av['massaMagraKg']} kg'
                      : '-';
                  final dt = av['dataAvaliacao'] != null
                      ? DateFormat(
                          'dd/MM/yyyy',
                        ).format(DateTime.parse(av['dataAvaliacao'].toString()))
                      : '-';

                  return pw.TableRow(
                    children: [
                      _cellData(dt),
                      _cellData('${peso.toStringAsFixed(1)} kg'),
                      _cellData('${alt.toStringAsFixed(2)} m'),
                      _cellData(imc),
                      _cellData(bf),
                      _cellData(mm),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 12),

            // Últimas Medidas Circunferenciais
            _buildUltimasMedidasPdf(avaliacoes, corCard),
          ],
          pw.SizedBox(height: 20),

          // Seção 2: Progressão de Carga por Exercício
          pw.Text(
            '2. PROGRESSÃO DE CARGA EM EXERCÍCIOS BÁSICOS (KG)',
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: corEscura,
            ),
          ),
          pw.SizedBox(height: 8),

          if (progressaoCargas.isEmpty)
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: corCard,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Text(
                'Ainda não há registros de progressão de carga arquivados.',
                style: const pw.TextStyle(
                  fontSize: 11,
                  color: PdfColors.grey700,
                ),
              ),
            )
          else
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _cellHeader('Exercício'),
                    _cellHeader('Carga Máx (kg)'),
                    _cellHeader('Séries x Reps'),
                    _cellHeader('RPE / Esforço'),
                    _cellHeader('Data'),
                  ],
                ),
                ...progressaoCargas.map((p) {
                  final dt = p['dataRegistro'] != null
                      ? DateFormat(
                          'dd/MM/yyyy',
                        ).format(DateTime.parse(p['dataRegistro'].toString()))
                      : '-';
                  return pw.TableRow(
                    children: [
                      _cellData(p['nomeExercicio']?.toString() ?? '-'),
                      _cellData('${p['cargaKg']} kg'),
                      _cellData('${p['series']}x ${p['repeticoes']}'),
                      _cellData(p['rpe']?.toString() ?? '8/10'),
                      _cellData(dt),
                    ],
                  );
                }),
              ],
            ),
          pw.SizedBox(height: 20),

          // Seção 3: Histórico Recente de Treinos Concluídos
          pw.Text(
            '3. HISTÓRICO DE TREINOS CONCLUÍDOS NA ACADEMIA',
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: corEscura,
            ),
          ),
          pw.SizedBox(height: 8),

          if (historicoTreinos.isEmpty)
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: corCard,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Text(
                'Nenhum treino finalizado registrado até o momento.',
                style: const pw.TextStyle(
                  fontSize: 11,
                  color: PdfColors.grey700,
                ),
              ),
            )
          else
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _cellHeader('Data'),
                    _cellHeader('Treino / Divisão'),
                    _cellHeader('Duração'),
                    _cellHeader('Observação do Atleta'),
                  ],
                ),
                ...historicoTreinos.take(8).map((h) {
                  final dt = h['dataHora'] != null
                      ? DateFormat(
                          'dd/MM/yyyy HH:mm',
                        ).format(DateTime.parse(h['dataHora'].toString()))
                      : '-';
                  return pw.TableRow(
                    children: [
                      _cellData(dt),
                      _cellData(h['nomeTreino']?.toString() ?? 'Treino'),
                      _cellData('${h['duracaoMinutos'] ?? 60} min'),
                      _cellData(
                        h['observacaoAluno']?.toString() ??
                            'Concluído com sucesso',
                      ),
                    ],
                  );
                }),
              ],
            ),

          pw.SizedBox(height: 24),
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'PersonalPro — Plataforma de Gestão de Treinos & Performance',
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey600,
                ),
              ),
              pw.Text(
                'Documento gerado para fins de acompanhamento físico',
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Evolucao_${nomeAluno.replaceAll(' ', '_')}.pdf',
    );
  }

  static pw.Widget _cellHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.5),
      ),
    );
  }

  static pw.Widget _cellData(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 9.5)),
    );
  }

  static pw.Widget _buildUltimasMedidasPdf(
    List<dynamic> avaliacoes,
    PdfColor corCard,
  ) {
    if (avaliacoes.isEmpty) return pw.SizedBox();
    final ultima = avaliacoes.first;
    Map<String, dynamic> medidas = {};
    if (ultima['medidasJson'] != null) {
      try {
        medidas = Map<String, dynamic>.from(
          jsonDecode(ultima['medidasJson'].toString()),
        );
      } catch (_) {}
    }
    if (medidas.isEmpty) return pw.SizedBox();

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: corCard,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Últimas Circunferências Registradas (cm):',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
          ),
          pw.SizedBox(height: 6),
          pw.Wrap(
            spacing: 12,
            runSpacing: 4,
            children: medidas.entries
                .map(
                  (e) => pw.Text(
                    '• ${e.key}: ${e.value} cm',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

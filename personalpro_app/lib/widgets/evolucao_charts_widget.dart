import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme.dart';

class ImageHelper {
  static final ImagePicker _picker = ImagePicker();

  /// Seleciona imagem da galeria/computador ou câmera e retorna Data URI Base64
  static Future<String?> selecionarImagemBase64() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 78,
      );
      if (file == null) return null;
      final bytes = await file.readAsBytes();
      return 'data:image/jpeg;base64,${base64Encode(bytes)}';
    } catch (_) {
      return null;
    }
  }

  static Widget renderAvatarOrImage(
    String? source, {
    double radius = 24,
    String fallbackText = 'P',
    IconData? fallbackIcon,
  }) {
    if (source != null && source.trim().isNotEmpty) {
      try {
        if (source.startsWith('data:image')) {
          final b64 = source.split(',').last;
          final bytes = base64Decode(b64);
          return CircleAvatar(
            radius: radius,
            backgroundImage: MemoryImage(bytes),
          );
        } else if (source.startsWith('http')) {
          return CircleAvatar(
            radius: radius,
            backgroundImage: NetworkImage(source),
          );
        }
      } catch (_) {}
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppTheme.neonGreen.withValues(alpha: 0.16),
      child: fallbackIcon != null
          ? Icon(fallbackIcon, color: AppTheme.neonGreen, size: radius)
          : Text(
              fallbackText.isNotEmpty ? fallbackText[0].toUpperCase() : 'P',
              style: TextStyle(
                color: AppTheme.neonGreen,
                fontWeight: FontWeight.bold,
                fontSize: radius * 0.75,
              ),
            ),
    );
  }

  static Widget renderBoxPhoto(
    String? source, {
    double height = 210,
    String label = 'Foto',
  }) {
    Widget content;
    if (source != null && source.trim().isNotEmpty) {
      try {
        if (source.startsWith('data:image')) {
          final bytes = base64Decode(source.split(',').last);
          content = Image.memory(
            bytes,
            fit: BoxFit.cover,
            width: double.infinity,
            height: height,
          );
        } else {
          content = Image.network(
            source,
            fit: BoxFit.cover,
            width: double.infinity,
            height: height,
          );
        }
      } catch (_) {
        content = _placeholder(height, label);
      }
    } else {
      content = _placeholder(height, label);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        children: [
          content,
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.neonGreen.withValues(alpha: 0.5),
                ),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.neonGreen,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _placeholder(double height, String label) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.bgDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.camera_alt_outlined,
            color: AppTheme.textSecondary,
            size: 36,
          ),
          SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// Painel Completo de Gráficos de Evolução Física (Peso, % Gordura),
/// Progressão de Carga por Exercício e Comparativo Antes x Depois
class EvolucaoCompletaPanel extends StatefulWidget {
  final List<dynamic> avaliacoes;
  final List<dynamic> progressaoCargas;

  const EvolucaoCompletaPanel({
    super.key,
    required this.avaliacoes,
    required this.progressaoCargas,
  });

  @override
  State<EvolucaoCompletaPanel> createState() => _EvolucaoCompletaPanelState();
}

class _EvolucaoCompletaPanelState extends State<EvolucaoCompletaPanel> {
  String? _exercicioSelecionado;

  @override
  Widget build(BuildContext context) {
    // Ordena avaliações da mais antiga para a mais recente para o gráfico
    final avalCronologica = List<dynamic>.from(widget.avaliacoes.reversed);

    // Agrupa exercícios disponíveis em progressaoCargas
    final nomesExercicios = widget.progressaoCargas
        .map((e) => e['nomeExercicio']?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();

    final exAtual =
        (_exercicioSelecionado != null &&
            nomesExercicios.contains(_exercicioSelecionado))
        ? _exercicioSelecionado
        : (nomesExercicios.isNotEmpty ? nomesExercicios.first : null);

    final pontosCarga = widget.progressaoCargas
        .where((e) => e['nomeExercicio']?.toString() == exAtual)
        .toList();

    // Avaliações para Comparativo Antes x Depois
    final avalAntes = avalCronologica.isNotEmpty ? avalCronologica.first : null;
    final avalDepois = avalCronologica.length > 1
        ? avalCronologica.last
        : avalAntes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. GRÁFICO DE EVOLUÇÃO DE PESO (KG) E % DE GORDURA
        if (avalCronologica.isNotEmpty) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.show_chart, color: AppTheme.neonGreen),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'GRÁFICO DE EVOLUÇÃO CORPORAL (PESO kg & % GORDURA)',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (avalCronologica.length >= 2)
                        _buildDeltaBadge(
                          avalCronologica.first,
                          avalCronologica.last,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 190,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _DualEvolutionChartPainter(
                        avaliacoes: avalCronologica,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.circle, size: 10, color: AppTheme.neonGreen),
                      SizedBox(width: 6),
                      Text(
                        'Peso Corporal (kg)',
                        style: TextStyle(fontSize: 12),
                      ),
                      SizedBox(width: 24),
                      Icon(
                        Icons.circle,
                        size: 10,
                        color: AppTheme.warningAmber,
                      ),
                      SizedBox(width: 6),
                      Text('% de Gordura (BF)', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // 2. GRÁFICO DE PROGRESSÃO DE CARGA POR EXERCÍCIO
        if (nomesExercicios.isNotEmpty) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.trending_up, color: AppTheme.electricBlue),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'HISTÓRICO DE PROGRESSÃO DE CARGA POR EXERCÍCIO (KG)',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: nomesExercicios.map((nome) {
                        final sel = nome == exAtual;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(nome),
                            selected: sel,
                            selectedColor: AppTheme.electricBlue,
                            labelStyle: TextStyle(
                              color: sel ? Colors.black : AppTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            onSelected: (_) =>
                                setState(() => _exercicioSelecionado = nome),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (pontosCarga.isNotEmpty)
                    SizedBox(
                      height: 170,
                      width: double.infinity,
                      child: CustomPaint(
                        painter: _LoadProgressionChartPainter(
                          pontos: pontosCarga,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // 3. COMPARATIVO VISUAL ANTES x DEPOIS (FOTOS DE AVALIAÇÃO FÍSICA)
        if (avalAntes != null && avalDepois != null) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.compare, color: AppTheme.neonGreen),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'COMPARATIVO ANTES x DEPOIS (AVALIAÇÃO FÍSICA & FOTOS)',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            ImageHelper.renderBoxPhoto(
                              avalAntes['fotoFrenteUrl']?.toString(),
                              height: 185,
                              label:
                                  'ANTES (${avalAntes['dataAvaliacao'].toString().split('T').first})\n${avalAntes['peso']}kg • BF ${avalAntes['percentualGordura'] ?? '-'}%',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          children: [
                            ImageHelper.renderBoxPhoto(
                              avalDepois['fotoFrenteUrl']?.toString(),
                              height: 185,
                              label:
                                  'DEPOIS (${avalDepois['dataAvaliacao'].toString().split('T').first})\n${avalDepois['peso']}kg • BF ${avalDepois['percentualGordura'] ?? '-'}%',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDeltaBadge(dynamic primeira, dynamic ultima) {
    final p1 = ((primeira['peso'] ?? 0) as num).toDouble();
    final p2 = ((ultima['peso'] ?? 0) as num).toDouble();
    final diffPeso = p2 - p1;
    final sinal = diffPeso >= 0 ? '+' : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.neonGreen.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.neonGreen.withValues(alpha: 0.5)),
      ),
      child: Text(
        'Evolução Peso: $sinal${diffPeso.toStringAsFixed(1)} kg',
        style: const TextStyle(
          color: AppTheme.neonGreen,
          fontWeight: FontWeight.bold,
          fontSize: 11.5,
        ),
      ),
    );
  }
}

class _DualEvolutionChartPainter extends CustomPainter {
  final List<dynamic> avaliacoes;
  _DualEvolutionChartPainter({required this.avaliacoes});

  @override
  void paint(Canvas canvas, Size size) {
    if (avaliacoes.isEmpty) return;

    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1;

    for (int i = 0; i <= 3; i++) {
      final y = 20 + (size.height - 50) * (i / 3);
      canvas.drawLine(Offset(16, y), Offset(size.width - 16, y), gridPaint);
    }

    final pesos = avaliacoes
        .map((a) => ((a['peso'] ?? 0) as num).toDouble())
        .toList();
    final bfs = avaliacoes
        .map((a) => ((a['percentualGordura'] ?? 15) as num).toDouble())
        .toList();

    final minPeso = pesos.reduce(math.min) - 2;
    final maxPeso = pesos.reduce(math.max) + 2;

    final minBf = bfs.reduce(math.min) - 2;
    final maxBf = bfs.reduce(math.max) + 2;

    _desenharLinha(
      canvas,
      size,
      valores: pesos,
      minVal: minPeso,
      maxVal: maxPeso,
      cor: AppTheme.neonGreen,
      sufixo: 'kg',
      offsetYTexto: -18,
    );

    _desenharLinha(
      canvas,
      size,
      valores: bfs,
      minVal: minBf,
      maxVal: maxBf,
      cor: AppTheme.warningAmber,
      sufixo: '%',
      offsetYTexto: 10,
    );

    // Datas no rodapé
    final n = avaliacoes.length;
    for (int i = 0; i < n; i++) {
      final x = n == 1
          ? size.width / 2
          : 32 + (size.width - 64) * (i / (n - 1));
      final dataStr = avaliacoes[i]['dataAvaliacao']
          .toString()
          .split('T')
          .first;
      final tp = TextPainter(
        text: TextSpan(
          text: dataStr.length >= 10 ? dataStr.substring(5, 10) : dataStr,
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, size.height - 18));
    }
  }

  void _desenharLinha(
    Canvas canvas,
    Size size, {
    required List<double> valores,
    required double minVal,
    required double maxVal,
    required Color cor,
    required String sufixo,
    required double offsetYTexto,
  }) {
    final n = valores.length;
    final linePaint = Paint()
      ..color = cor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()..color = cor;
    final path = Path();

    for (int i = 0; i < n; i++) {
      final x = n == 1
          ? size.width / 2
          : 32 + (size.width - 64) * (i / (n - 1));
      final norm = (maxVal - minVal).abs() < 0.01
          ? 0.5
          : (valores[i] - minVal) / (maxVal - minVal);
      final y = (size.height - 35) - norm * (size.height - 65);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }

      canvas.drawCircle(Offset(x, y), 5, dotPaint);

      final tp = TextPainter(
        text: TextSpan(
          text: '${valores[i].toStringAsFixed(1)}$sufixo',
          style: TextStyle(
            color: cor,
            fontSize: 10.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, y + offsetYTexto));
    }

    if (n > 1) {
      canvas.drawPath(path, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _LoadProgressionChartPainter extends CustomPainter {
  final List<dynamic> pontos;
  _LoadProgressionChartPainter({required this.pontos});

  @override
  void paint(Canvas canvas, Size size) {
    if (pontos.isEmpty) return;

    final cargas = pontos
        .map((p) => ((p['cargaKg'] ?? 0) as num).toDouble())
        .toList();
    final maxCarga = (cargas.reduce(math.max) * 1.15).clamp(10.0, 9999.0);
    final n = pontos.length;
    final barWidth = math.min(42.0, (size.width - 40) / (n * 1.8));

    for (int i = 0; i < n; i++) {
      final x = n == 1
          ? size.width / 2
          : 36 + (size.width - 72) * (i / (n - 1));
      final h = (cargas[i] / maxCarga) * (size.height - 50);
      final top = (size.height - 24) - h;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x - barWidth / 2, top, barWidth, h),
        const Radius.circular(6),
      );

      final barPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.electricBlue,
            AppTheme.neonGreen.withValues(alpha: 0.7),
          ],
        ).createShader(rect.outerRect);

      canvas.drawRRect(rect, barPaint);

      final tpVal = TextPainter(
        text: TextSpan(
          text: '${cargas[i].toStringAsFixed(0)}kg',
          style: const TextStyle(
            color: AppTheme.neonGreen,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tpVal.paint(canvas, Offset(x - tpVal.width / 2, top - 16));

      final dataRaw = pontos[i]['dataRegistro'].toString().split('T').first;
      final tpDate = TextPainter(
        text: TextSpan(
          text: dataRaw.length >= 10 ? dataRaw.substring(5, 10) : dataRaw,
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 9.5),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tpDate.paint(canvas, Offset(x - tpDate.width / 2, size.height - 18));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

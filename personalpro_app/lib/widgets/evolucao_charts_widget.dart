import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme.dart';

class ImageHelper {
  static final ImagePicker _picker = ImagePicker();

  /// Seleciona imagem da galeria/computador ou câmera e retorna Data URI Base64
  static Future<String?> selecionarImagemBase64() async {
    try {
      // Sem passar maxWidth/maxHeight/imageQuality para evitar travamentos de canvas.toBlob no Web
      final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
      if (file == null) return null;
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) return null;

      // Se a imagem for maior que 300KB, redimensionamos para tamanho ideal de perfil (maxDim: 400)
      if (bytes.lengthInBytes > 300 * 1024) {
        final comprimida = await _redimensionarBytes(bytes, maxDim: 400);
        if (comprimida != null) return comprimida;
      }

      final mime = (file.mimeType != null && file.mimeType!.isNotEmpty)
          ? file.mimeType!
          : 'image/jpeg';
      return 'data:$mime;base64,${base64Encode(bytes)}';
    } catch (e) {
      debugPrint('Erro ao selecionar imagem: $e');
      return null;
    }
  }

  static Future<String?> _redimensionarBytes(
    Uint8List bytes, {
    int maxDim = 400,
  }) async {
    try {
      final codec = await ui.instantiateImageCodec(bytes, targetWidth: maxDim);
      final frame = await codec.getNextFrame();
      final byteData = await frame.image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (byteData != null) {
        final outBytes = byteData.buffer.asUint8List();
        return 'data:image/png;base64,${base64Encode(outBytes)}';
      }
    } catch (e) {
      debugPrint('Falha ao redimensionar bytes de imagem: $e');
    }
    return null;
  }

  static Widget renderAvatarOrImage(
    String? source, {
    double radius = 24,
    String fallbackText = 'P',
    IconData? fallbackIcon,
  }) {
    if (source != null && source.trim().isNotEmpty) {
      try {
        final cleanSource = source.trim();
        if (cleanSource.startsWith('data:image')) {
          final b64 = cleanSource
              .split(',')
              .last
              .replaceAll(RegExp(r'\s+'), '');
          final bytes = base64Decode(b64);
          return CircleAvatar(
            radius: radius,
            backgroundImage: MemoryImage(bytes),
          );
        } else if (cleanSource.startsWith('http')) {
          return CircleAvatar(
            radius: radius,
            backgroundImage: NetworkImage(cleanSource),
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
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.neonGreen.withValues(alpha: 0.5),
                ),
              ),
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10.5,
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
          const SizedBox(height: 16),
        ],

        // 4. QUADRO COMPLETO DE PERIMETRIA & MEDIDAS (PADRÃO MFIT)
        if (widget.avaliacoes.isNotEmpty)
          _buildCardPerimetriaCompleta(widget.avaliacoes),
      ],
    );
  }

  Widget _buildCardPerimetriaCompleta(List<dynamic> avals) {
    final recente = avals.first;
    final anterior = avals.length > 1 ? avals[1] : null;

    final medRecente = _extrairMedidasMap(recente);
    final medAnterior = anterior != null ? _extrairMedidasMap(anterior) : <String, double>{};

    final grupos = [
      {
        'titulo': 'TRONCO & CIRCUNFERÊNCIAS',
        'icone': Icons.straighten,
        'cor': AppTheme.electricBlue,
        'itens': [
          {'k': 'pescoco', 'label': 'Pescoço'},
          {'k': 'ombros', 'label': 'Ombros'},
          {'k': 'peitoral', 'label': 'Peitoral/Tórax'},
          {'k': 'cintura', 'label': 'Cintura'},
          {'k': 'abdomen', 'label': 'Abdômen'},
          {'k': 'quadril', 'label': 'Quadril'},
        ]
      },
      {
        'titulo': 'MEMBROS SUPERIORES (BRAÇOS)',
        'icone': Icons.fitness_center,
        'cor': AppTheme.neonGreen,
        'itens': [
          {'k': 'bracoDireito', 'label': 'Braço D. (Relax)'},
          {'k': 'bracoDireitoContraido', 'label': 'Braço D. (Contr)'},
          {'k': 'bracoEsquerdo', 'label': 'Braço E. (Relax)'},
          {'k': 'bracoEsquerdoContraido', 'label': 'Braço E. (Contr)'},
          {'k': 'antebracoDireito', 'label': 'Antebraço D.'},
          {'k': 'antebracoEsquerdo', 'label': 'Antebraço E.'},
        ]
      },
      {
        'titulo': 'MEMBROS INFERIORES (PERNAS)',
        'icone': Icons.directions_run,
        'cor': const Color(0xFFE040FB),
        'itens': [
          {'k': 'coxaDireita', 'label': 'Coxa D. (Alta)'},
          {'k': 'coxaEsquerda', 'label': 'Coxa E. (Alta)'},
          {'k': 'panturrilhaDireita', 'label': 'Panturrilha D.'},
          {'k': 'panturrilhaEsquerda', 'label': 'Panturrilha E.'},
        ]
      },
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.straighten, color: AppTheme.neonGreen, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'MEDIDAS & PERIMETRIA',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.neonGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Última: ${recente['dataAvaliacao'].toString().split('T').first}',
                    style: const TextStyle(color: AppTheme.neonGreen, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...grupos.map((grp) {
              final itens = (grp['itens'] as List<Map<String, String>>)
                  .where((item) => medRecente.containsKey(item['k']))
                  .toList();
              if (itens.isEmpty) return const SizedBox.shrink();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 8),
                    child: Row(
                      children: [
                        Icon(grp['icone'] as IconData, size: 15, color: grp['cor'] as Color),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            grp['titulo'] as String,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: grp['cor'] as Color,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: itens.map((item) {
                      final valAtual = medRecente[item['k']]!;
                      final valAnt = medAnterior[item['k']];
                      final diff = valAnt != null ? valAtual - valAnt : null;

                      return Container(
                        constraints: const BoxConstraints(minWidth: 105),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: AppTheme.bgDark,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['label']!,
                              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${valAtual.toStringAsFixed(1)} cm',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                if (diff != null && diff != 0) ...[
                                  const SizedBox(width: 6),
                                  Text(
                                    diff > 0 ? '+${diff.toStringAsFixed(1)}' : diff.toStringAsFixed(1),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: diff > 0 ? AppTheme.neonGreen : AppTheme.performanceRed,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 6),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Map<String, double> _extrairMedidasMap(dynamic aval) {
    final map = <String, double>{};
    if (aval == null) return map;
    try {
      final raw = aval['medidasJson'];
      if (raw != null) {
        final parsed = raw is Map ? raw : jsonDecode(raw.toString());
        if (parsed is Map) {
          parsed.forEach((k, v) {
            final numVal = double.tryParse(v.toString());
            if (numVal != null) map[k.toString()] = numVal;
          });
        }
      }
    } catch (_) {}
    return map;
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

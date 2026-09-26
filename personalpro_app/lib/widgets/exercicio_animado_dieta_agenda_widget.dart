import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../services/whatsapp_service.dart';
import '../theme.dart';
import 'video_embed_stub.dart' if (dart.library.js_interop) 'video_embed_web.dart';

// ============================================================================
// HELPER DE VÍDEOS REAIS DE EXERCÍCIOS (YOUTUBE / MP4 / GIF)
// ============================================================================

class ExercicioVideoCatalogo {
  static String resolverUrlVideoPadrao(String nomeExercicio, String grupoMuscular, String? customUrl) {
    final c = (customUrl ?? '').trim();
    if (c.isNotEmpty && c.startsWith('http')) return c;

    final n = nomeExercicio.toLowerCase();
    final g = grupoMuscular.toLowerCase();

    if (n.contains('supino inclinado')) return 'https://www.youtube.com/watch?v=8iPEnn-ltC8';
    if (n.contains('supino')) return 'https://www.youtube.com/watch?v=rT7DgCr-3pg';
    if (n.contains('crucifixo') || n.contains('peck')) return 'https://www.youtube.com/watch?v=eozdVDA78K0';
    if (n.contains('crossover')) return 'https://www.youtube.com/watch?v=taI4XduLpTk';
    if (n.contains('puxada') || n.contains('barra fixa')) return 'https://www.youtube.com/watch?v=CAwf7n6Luuc';
    if (n.contains('remada curvada')) return 'https://www.youtube.com/watch?v=FWJR5Ve8bnQ';
    if (n.contains('remada')) return 'https://www.youtube.com/watch?v=GZbfZ033f74';
    if (n.contains('agachamento')) return 'https://www.youtube.com/watch?v=ultWZbUMPL8';
    if (n.contains('leg press') || n.contains('leg')) return 'https://www.youtube.com/watch?v=IZxyjW7MPJQ';
    if (n.contains('extensora')) return 'https://www.youtube.com/watch?v=YyvSfVjQeL0';
    if (n.contains('flexora')) return 'https://www.youtube.com/watch?v=1Tq3QdYUuHs';
    if (n.contains('stiff') || n.contains('terra')) return 'https://www.youtube.com/watch?v=1oed-UmAxFs';
    if (n.contains('pélvica') || n.contains('pelvica')) return 'https://www.youtube.com/watch?v=SEdqd1n0cvg';
    if (n.contains('panturrilha')) return 'https://www.youtube.com/watch?v=gwLzBJYoWlI';
    if (n.contains('desenvolvimento')) return 'https://www.youtube.com/watch?v=qEwKCR5JCog';
    if (n.contains('elevação lateral') || n.contains('elevacao lateral')) {
      return 'https://www.youtube.com/watch?v=3VcKaXpzqRo';
    }
    if (n.contains('rosca martelo')) return 'https://www.youtube.com/watch?v=zC3nLlEvin4';
    if (n.contains('rosca')) return 'https://www.youtube.com/watch?v=kwG2ipFRgfo';
    if (n.contains('tríceps testa') || n.contains('triceps testa')) {
      return 'https://www.youtube.com/watch?v=d_KZxkY_0cM';
    }
    if (n.contains('tríceps') || n.contains('triceps')) return 'https://www.youtube.com/watch?v=2-LAMcpzODU';
    if (g.contains('peito')) return 'https://www.youtube.com/watch?v=rT7DgCr-3pg';
    if (g.contains('costa')) return 'https://www.youtube.com/watch?v=CAwf7n6Luuc';
    if (g.contains('perna')) return 'https://www.youtube.com/watch?v=ultWZbUMPL8';
    if (g.contains('ombro')) return 'https://www.youtube.com/watch?v=3VcKaXpzqRo';
    if (g.contains('bíceps') || g.contains('biceps')) return 'https://www.youtube.com/watch?v=kwG2ipFRgfo';
    if (g.contains('tríceps') || g.contains('triceps')) return 'https://www.youtube.com/watch?v=2-LAMcpzODU';
    return 'https://www.youtube.com/watch?v=pSHjTRCQxIw';
  }

  static String? extrairYoutubeId(String url) {
    final u = url.trim();
    final reg = RegExp(
      r'(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?|shorts)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})',
      caseSensitive: false,
    );
    final match = reg.firstMatch(u);
    return match?.group(1);
  }
}

// ============================================================================
// 1. MINIATURA DE VÍDEO REAL DO EXERCÍCIO + PLAYER EMBUTIDO (IFRAME / VIDEO)
// ============================================================================

class ExercicioAnimadoThumbnail extends StatelessWidget {
  final String nomeExercicio;
  final String grupoMuscular;
  final String? videoUrl;
  final double width;
  final double height;
  final VoidCallback? onTap;

  const ExercicioAnimadoThumbnail({
    super.key,
    required this.nomeExercicio,
    required this.grupoMuscular,
    this.videoUrl,
    this.width = 112,
    this.height = 76,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = ExercicioVideoCatalogo.resolverUrlVideoPadrao(
      nomeExercicio,
      grupoMuscular,
      videoUrl,
    );
    final ytId = ExercicioVideoCatalogo.extrairYoutubeId(resolvedUrl);
    final thumbUrl = ytId != null
        ? 'https://img.youtube.com/vi/$ytId/hqdefault.jpg'
        : resolvedUrl;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFF0E131A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.neonGreen.withValues(alpha: 0.55),
            width: 1.4,
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10.5),
                child: Image.network(
                  thumbUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    color: const Color(0xFF121822),
                    child: const Center(
                      child: Icon(Icons.fitness_center, color: AppTheme.neonGreen, size: 28),
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.5),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.35),
                      Colors.black.withValues(alpha: 0.55),
                    ],
                  ),
                ),
              ),
            ),
            Center(
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppTheme.neonGreen.withValues(alpha: 0.92),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.neonGreen.withValues(alpha: 0.45),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(Icons.play_arrow_rounded, size: 20, color: Colors.black),
              ),
            ),
            Positioned(
              left: 5,
              top: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.videocam, color: AppTheme.neonGreen, size: 10),
                    SizedBox(width: 3),
                    Text(
                      'VÍDEO HD',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.neonGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PlayerVideoExercicioInline extends StatelessWidget {
  final String nomeExercicio;
  final String grupoMuscular;
  final String? videoUrl;
  final int exercicioId;
  final VoidCallback? onFechar;
  final VoidCallback? onAbrirModalCompleto;

  const PlayerVideoExercicioInline({
    super.key,
    required this.nomeExercicio,
    required this.grupoMuscular,
    this.videoUrl,
    required this.exercicioId,
    this.onFechar,
    this.onAbrirModalCompleto,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = ExercicioVideoCatalogo.resolverUrlVideoPadrao(
      nomeExercicio,
      grupoMuscular,
      videoUrl,
    );
    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.neonGreen.withValues(alpha: 0.55), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF141820),
              borderRadius: BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.ondemand_video, color: AppTheme.neonGreen, size: 18),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'VÍDEO DE EXECUÇÃO: $nomeExercicio',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.neonGreen,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onAbrirModalCompleto != null)
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                        onPressed: onAbrirModalCompleto,
                        icon: const Icon(Icons.open_in_full, size: 14, color: Colors.cyanAccent),
                        label: const Text(
                          'Guia Técnico / Editar Vídeo',
                          style: TextStyle(fontSize: 11, color: Colors.cyanAccent),
                        ),
                      ),
                    if (onFechar != null)
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Fechar Player',
                        onPressed: onFechar,
                        icon: const Icon(Icons.keyboard_arrow_up, color: Colors.white70),
                      ),
                  ],
                ),
              ],
            ),
          ),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(13)),
              child: kIsWeb
                  ? buildNativeWebVideoEmbed(
                      resolvedUrl,
                      ExercicioVideoCatalogo.extrairYoutubeId(resolvedUrl),
                    )
                  : Center(
                      child: ElevatedButton.icon(
                        onPressed: () => launchUrl(
                          Uri.parse(resolvedUrl),
                          mode: LaunchMode.externalApplication,
                        ),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('ASSISTIR VÍDEO'),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class ExercicioExecucaoModal {
  static void abrir(BuildContext context, Map<String, dynamic> exercicio) {
    showDialog(
      context: context,
      builder: (ctx) => _ExercicioExecucaoDialog(exercicio: exercicio),
    );
  }
}

class _ExercicioExecucaoDialog extends StatefulWidget {
  final Map<String, dynamic> exercicio;

  const _ExercicioExecucaoDialog({required this.exercicio});

  @override
  State<_ExercicioExecucaoDialog> createState() => _ExercicioExecucaoDialogState();
}

class _ExercicioExecucaoDialogState extends State<_ExercicioExecucaoDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final TextEditingController _urlCtrl;
  bool _modoSimuladorBiomecanico = false;
  bool _salvandoUrl = false;
  late String _videoUrlAtual;

  @override
  void initState() {
    super.initState();
    final nome = (widget.exercicio['nomeExercicio'] ?? widget.exercicio['nome'] ?? 'Exercício').toString();
    final grupo = (widget.exercicio['grupoMuscular'] ?? 'Musculação').toString();
    _videoUrlAtual = ExercicioVideoCatalogo.resolverUrlVideoPadrao(
      nome,
      grupo,
      widget.exercicio['videoUrl']?.toString(),
    );
    _urlCtrl = TextEditingController(text: _videoUrlAtual);
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  String _obterDicaBiomecanica(String grupo, String nome) {
    final g = grupo.toLowerCase();
    final n = nome.toLowerCase();
    if (n.contains('supino') || g.contains('peito')) {
      return '1. Retraia as escápulas e mantenha os pés firmes no chão.\n'
          '2. Desça a carga de forma controlada (2 segundos) até a linha média do peitoral.\n'
          '3. Empurre explosivamente soltando o ar sem desencostar os ombros do banco.';
    }
    if (n.contains('agachamento') || n.contains('leg') || g.contains('perna')) {
      return '1. Mantenha o abdômen travado (bracing) e a coluna neutra.\n'
          '2. Desça flexionando quadril e joelhos alinhados com a ponta dos pés até 90° ou mais.\n'
          '3. Empurre o solo pelos calcanhares contraindo quadríceps e glúteos no topo.';
    }
    if (n.contains('puxada') || n.contains('remada') || g.contains('costa')) {
      return '1. Inicie o movimento deprimindo as escápulas antes de puxar com os braços.\n'
          '2. Traga os cotovelos em direção ao tronco e segure 1 segundo na contração máxima.\n'
          '3. Retorne devagar alongando totalmente a dorsal sem soltar o peso de vez.';
    }
    if (n.contains('rosca') || g.contains('bíceps') || g.contains('biceps')) {
      return '1. Trave os cotovelos fixos ao lado das costelas (sem gangorrar o tronco).\n'
          '2. Suba contraindo o bíceps até o topo e segure 1s apertando a musculatura.\n'
          '3. Desça controlando em 2 a 3 segundos até alongar quase totalmente o braço.';
    }
    return '1. Estabilize o core (abdômen e lombar) antes de iniciar a primeira repetição.\n'
        '2. Controle a fase excêntrica (descida) em 2 segundos e solte o ar na fase de força.\n'
        '3. Evite usar impulso articular; mantenha tensão contínua no músculo alvo.';
  }

  Future<void> _salvarNovoVideo() async {
    final exId = widget.exercicio['id'];
    final novaUrl = _urlCtrl.text.trim();
    if (novaUrl.isEmpty) return;
    setState(() {
      _salvandoUrl = true;
      _videoUrlAtual = novaUrl;
      widget.exercicio['videoUrl'] = novaUrl;
    });
    if (exId != null) {
      try {
        await ApiService().dio.patch(
          '/api/treinos/exercicios/$exId/video',
          data: {'videoUrl': novaUrl},
        );
      } catch (_) {}
    }
    if (mounted) {
      setState(() => _salvandoUrl = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎬 Vídeo de execução atualizado com sucesso!'),
          backgroundColor: AppTheme.neonGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;
    final isMobile = screenW < 600;
    final nome = (widget.exercicio['nomeExercicio'] ?? widget.exercicio['nome'] ?? 'Exercício').toString();
    final grupo = (widget.exercicio['grupoMuscular'] ?? 'Musculação').toString();
    final series = widget.exercicio['series'] ?? 4;
    final reps = (widget.exercicio['repeticoes'] ?? '10 a 12').toString();
    final carga = widget.exercicio['cargaKg'] ?? 20;
    final descanso = widget.exercicio['descansoSegundos'] ?? 60;
    final obs = (widget.exercicio['observacaoTecnica'] ?? '').toString();
    final ytId = ExercicioVideoCatalogo.extrairYoutubeId(_videoUrlAtual);

    return Dialog(
      backgroundColor: AppTheme.surfaceCard,
      insetPadding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 24, vertical: isMobile ? 12 : 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: math.min(screenW - 20, 660)),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 14 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // CABEÇALHO DO EXERCÍCIO
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: AppTheme.neonGreen.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.play_circle_fill, color: AppTheme.neonGreen, size: 24),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nome,
                          style: TextStyle(
                            fontSize: isMobile ? 15.5 : 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          '$grupo • $series séries x $reps ($carga kg) • Descanso: ${descanso}s',
                          style: const TextStyle(fontSize: 12, color: AppTheme.neonGreen),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // SELETOR DE MODO: VÍDEO REAL EMBUTIDO vs SIMULADOR BIOMECÂNICO
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('🎬 Vídeo Real da Execução (Player HD)'),
                    selected: !_modoSimuladorBiomecanico,
                    selectedColor: AppTheme.neonGreen.withValues(alpha: 0.25),
                    onSelected: (_) => setState(() => _modoSimuladorBiomecanico = false),
                  ),
                  ChoiceChip(
                    label: const Text('🦾 Mapa de Ativação Muscular (2D)'),
                    selected: _modoSimuladorBiomecanico,
                    selectedColor: AppTheme.neonGreen.withValues(alpha: 0.25),
                    onSelected: (_) => setState(() => _modoSimuladorBiomecanico = true),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // PLAYER DE VÍDEO REAL EMBUTIDO (IFRAME YOUTUBE / HTML5 VIDEO) OU MAPA 2D
              Container(
                height: isMobile ? 225 : 330,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.neonGreen.withValues(alpha: 0.45), width: 1.5),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14.5),
                  child: !_modoSimuladorBiomecanico && kIsWeb
                      ? buildNativeWebVideoEmbed(_videoUrlAtual, ytId)
                      : AnimatedBuilder(
                          animation: _ctrl,
                          builder: (_, _) => CustomPaint(
                            painter: _BiomecanicaExercicioPainter(
                              progress: _ctrl.value,
                              nomeExercicio: nome,
                              grupoMuscular: grupo,
                              compact: false,
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 14),

              // CAMPO PARA O PERSONAL PERSONALIZAR O LINK DO VÍDEO (YOUTUBE / MP4)
              if (widget.exercicio['id'] != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF131820),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '🔗 LINK DO VÍDEO DO EXERCÍCIO (YOUTUBE / SHORTS / MP4)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _urlCtrl,
                              style: const TextStyle(fontSize: 12.5),
                              decoration: const InputDecoration(
                                isDense: true,
                                hintText: 'Cole aqui o link do YouTube ou MP4...',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: _salvandoUrl ? null : _salvarNovoVideo,
                            icon: const Icon(Icons.save, size: 16),
                            label: Text(_salvandoUrl ? '...' : 'Trocar Vídeo'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // GUIA TÉCNICO DE BIOMECÂNICA E POSTURA
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF141820),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.verified_outlined, color: AppTheme.neonGreen, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'DICAS DE EXECUÇÃO CORRETA & POSTURA',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.neonGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _obterDicaBiomecanica(grupo, nome),
                      style: const TextStyle(fontSize: 12.5, height: 1.45, color: Colors.white),
                    ),
                    if (obs.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.tips_and_updates, color: Colors.amberAccent, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Orientação do Personal: $obs',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.amberAccent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // BOTÕES DE AÇÃO RESPONSIVOS
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 10,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () async {
                      final uri = Uri.parse(_videoUrlAtual);
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    },
                    icon: const Icon(Icons.open_in_new, color: AppTheme.neonGreen, size: 16),
                    label: const Text('Abrir no App YouTube'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('FECHAR PLAYER'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BiomecanicaExercicioPainter extends CustomPainter {
  final double progress;
  final String nomeExercicio;
  final String grupoMuscular;
  final bool compact;

  _BiomecanicaExercicioPainter({
    required this.progress,
    required this.nomeExercicio,
    required this.grupoMuscular,
    required this.compact,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 1;
    final step = compact ? 16.0 : 26.0;
    for (double x = 0; x < w; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), gridPaint);
    }
    for (double y = 0; y < h; y += step) {
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    final bodyPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.88)
      ..strokeWidth = compact ? 3.2 : 5.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final equipPaint = Paint()
      ..color = const Color(0xFF90A4AE)
      ..strokeWidth = compact ? 2.5 : 4.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final neonMusclePaint = Paint()
      ..color = Color.lerp(const Color(0xFF00E676), const Color(0xFFFF5252), progress)!
      ..strokeWidth = compact ? 5.0 : 9.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final glowPaint = Paint()
      ..color = AppTheme.neonGreen.withValues(alpha: 0.25 + 0.25 * progress)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final n = nomeExercicio.toLowerCase();
    final g = grupoMuscular.toLowerCase();

    final cx = w * 0.5;
    final cy = h * 0.54;

    if (n.contains('supino') || n.contains('crucifixo') || g.contains('peito')) {
      final benchY = cy + (compact ? 12 : 26);
      canvas.drawLine(Offset(w * 0.20, benchY), Offset(w * 0.78, benchY), equipPaint);
      canvas.drawLine(Offset(w * 0.30, benchY), Offset(w * 0.30, h * 0.88), equipPaint);
      canvas.drawLine(Offset(w * 0.68, benchY), Offset(w * 0.68, h * 0.88), equipPaint);

      final shoulder = Offset(w * 0.36, benchY - (compact ? 6 : 12));
      final hip = Offset(w * 0.60, benchY - (compact ? 6 : 12));
      final knee = Offset(w * 0.74, benchY - (compact ? 4 : 8));
      final foot = Offset(w * 0.78, h * 0.86);
      canvas.drawCircle(Offset(w * 0.28, benchY - (compact ? 8 : 14)), compact ? 5 : 9, bodyPaint);
      canvas.drawLine(shoulder, hip, bodyPaint);
      canvas.drawLine(hip, knee, bodyPaint);
      canvas.drawLine(knee, foot, bodyPaint);

      canvas.drawLine(shoulder, Offset(w * 0.46, benchY - (compact ? 8 : 15)), glowPaint);
      canvas.drawLine(shoulder, Offset(w * 0.46, benchY - (compact ? 8 : 15)), neonMusclePaint);

      final barY = (benchY - (compact ? 12 : 24)) - progress * (compact ? 22 : 48);
      final elbowY = (benchY - (compact ? 2 : 4)) - progress * (compact ? 14 : 30);
      final elbow = Offset(w * 0.38, elbowY);
      final hand = Offset(w * 0.38, barY);

      canvas.drawLine(shoulder, elbow, bodyPaint);
      canvas.drawLine(elbow, hand, bodyPaint);

      final platePaint = Paint()..color = AppTheme.neonGreen;
      canvas.drawLine(Offset(w * 0.26, barY), Offset(w * 0.50, barY), equipPaint);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(w * 0.38, barY),
            width: compact ? 8 : 14,
            height: compact ? 14 : 26,
          ),
          const Radius.circular(3),
        ),
        platePaint,
      );
    } else if (n.contains('agachamento') ||
        n.contains('leg') ||
        n.contains('extensora') ||
        n.contains('stiff') ||
        g.contains('perna')) {
      final drop = (1.0 - progress) * (compact ? 15.0 : 34.0);
      final ankle = Offset(cx + (compact ? 4 : 8), h * 0.84);
      final knee = Offset(cx + (compact ? 12 : 24) * (1.1 - 0.5 * progress), h * 0.64 + drop * 0.35);
      final hip = Offset(cx - (compact ? 10 : 22) * (1.1 - 0.4 * progress), h * 0.46 + drop);
      final shoulder = Offset(cx - (compact ? 2 : 5), h * 0.24 + drop);
      final head = Offset(shoulder.dx + 2, shoulder.dy - (compact ? 9 : 16));

      canvas.drawLine(hip, knee, glowPaint);
      canvas.drawLine(hip, knee, neonMusclePaint);
      canvas.drawLine(knee, ankle, bodyPaint);
      canvas.drawLine(hip, shoulder, bodyPaint);
      canvas.drawCircle(head, compact ? 5 : 9, bodyPaint);

      canvas.drawLine(
        Offset(shoulder.dx - (compact ? 14 : 26), shoulder.dy + 2),
        Offset(shoulder.dx + (compact ? 14 : 26), shoulder.dy + 2),
        equipPaint,
      );
      canvas.drawCircle(
        Offset(shoulder.dx, shoulder.dy + 2),
        compact ? 6 : 11,
        Paint()..color = AppTheme.neonGreen,
      );
    } else {
      final hip = Offset(cx, h * 0.62);
      final footL = Offset(cx - (compact ? 8 : 16), h * 0.86);
      final footR = Offset(cx + (compact ? 8 : 16), h * 0.86);
      final shoulder = Offset(cx, h * 0.34);
      final head = Offset(cx, h * 0.22);

      canvas.drawLine(hip, footL, bodyPaint);
      canvas.drawLine(hip, footR, bodyPaint);
      canvas.drawLine(hip, shoulder, bodyPaint);
      canvas.drawCircle(head, compact ? 5 : 9, bodyPaint);

      final elbow = Offset(cx + (compact ? 8 : 16), h * 0.48);
      canvas.drawLine(shoulder, elbow, glowPaint);
      canvas.drawLine(shoulder, elbow, neonMusclePaint);

      final angle = (math.pi * 0.42) - progress * (math.pi * 0.72);
      final forearmLen = compact ? 16.0 : 32.0;
      final hand = Offset(
        elbow.dx + math.cos(angle) * forearmLen,
        elbow.dy + math.sin(angle) * forearmLen,
      );
      canvas.drawLine(elbow, hand, bodyPaint);
      canvas.drawCircle(hand, compact ? 5 : 9, Paint()..color = AppTheme.neonGreen);
    }
  }

  @override
  bool shouldRepaint(covariant _BiomecanicaExercicioPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ============================================================================
// 2. EXPORTADOR DE DIETA E MACROS EM PDF ESTILIZADO (DietaPdfService)
// ============================================================================

class DietaPdfService {
  static Future<void> exportarPlanoAlimentarPdf({
    required String nomeAluno,
    required String nomePersonal,
    required Map<String, dynamic> plano,
    required List<dynamic> refeicoes,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) => [
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#121212'),
              borderRadius: pw.BorderRadius.circular(10),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'PERSONALPRO - PLANO ALIMENTAR & MACROS',
                      style: pw.TextStyle(
                        color: PdfColor.fromHex('#00E676'),
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Aluno(a): $nomeAluno  |  Consultoria: $nomePersonal',
                      style: const pw.TextStyle(color: PdfColors.white, fontSize: 11),
                    ),
                    pw.Text(
                      'Protocolo: ${plano['titulo'] ?? 'Dieta Personalizada'} (${plano['objetivo'] ?? 'Hipertrofia'})',
                      style: const pw.TextStyle(color: PdfColors.grey300, fontSize: 10),
                    ),
                  ],
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#00E676'),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Text(
                    '${plano['metaKcal'] ?? 2500} kcal/dia',
                    style: pw.TextStyle(
                      color: PdfColors.black,
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 14),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#F4F6F8'),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _macroPdfBox('TMB Basal', '${plano['tmbKcal'] ?? 1800} kcal'),
                _macroPdfBox('Gasto Total (GET)', '${plano['getKcal'] ?? 2400} kcal'),
                _macroPdfBox('Proteínas', '${plano['proteinaG'] ?? 180} g'),
                _macroPdfBox('Carboidratos', '${plano['carboidratoG'] ?? 300} g'),
                _macroPdfBox('Gorduras Boas', '${plano['gorduraG'] ?? 70} g'),
                _macroPdfBox('Meta de Água', '${plano['aguaLitros'] ?? 3.5} Litros'),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          ...refeicoes.map((r) {
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 10),
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColor.fromHex('#DCE1E7')),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        '${r['horario'] ?? '08:00'} - ${r['nomeRefeicao'] ?? 'Refeição'}',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
                      ),
                      pw.Text(
                        '~${r['kcalEstimada'] ?? 500} kcal  (P: ${r['proteinaG']}g | C: ${r['carboG']}g | G: ${r['gorduraG']}g)',
                        style: pw.TextStyle(fontSize: 9.5, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    (r['alimentosDescricao'] ?? '').toString(),
                    style: const pw.TextStyle(fontSize: 10.5),
                  ),
                  if ((r['substituicoes'] ?? '').toString().trim().isNotEmpty) ...[
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Opções de Substituição: ${r['substituicoes']}',
                      style: pw.TextStyle(
                        fontSize: 9.5,
                        color: PdfColors.teal800,
                        fontStyle: pw.FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (_) async => pdf.save(),
      name: 'Plano_Alimentar_${nomeAluno.replaceAll(' ', '_')}.pdf',
    );
  }

  static pw.Widget _macroPdfBox(String label, String val) {
    return pw.Column(
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700)),
        pw.SizedBox(height: 2),
        pw.Text(val, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }
}

// ============================================================================
// 3. PAINEL DO PERSONAL: PRESCRIÇÃO DE DIETA & CALCULADORA DE MACROS (100% RESPONSIVO)
// ============================================================================

class PainelDietaPersonalWidget extends StatefulWidget {
  final List<dynamic> alunos;
  final String nomePersonal;

  const PainelDietaPersonalWidget({
    super.key,
    required this.alunos,
    required this.nomePersonal,
  });

  @override
  State<PainelDietaPersonalWidget> createState() => _PainelDietaPersonalWidgetState();
}

class _PainelDietaPersonalWidgetState extends State<PainelDietaPersonalWidget> {
  int? _alunoIdSelecionado;
  bool _carregando = false;

  final _tituloCtrl = TextEditingController(text: 'Protocolo Hipertrofia Limpa & Definição');
  String _objetivo = 'Hipertrofia';
  final _pesoCtrl = TextEditingController(text: '81.4');
  final _alturaCtrl = TextEditingController(text: '178');
  final _idadeCtrl = TextEditingController(text: '26');
  String _sexo = 'M';
  double _fatorAtividade = 1.55;

  int _tmb = 1825;
  int _get = 2450;
  int _metaKcal = 2750;
  int _protG = 185;
  int _carbG = 320;
  int _gordG = 72;
  double _aguaLitros = 3.6;
  final _obsCtrl = TextEditingController(
    text: 'Beber 3.6L de água por dia (45ml/kg). Creatina 5g todos os dias.',
  );

  List<Map<String, dynamic>> _refeicoes = [];

  @override
  void initState() {
    super.initState();
    if (widget.alunos.isNotEmpty) {
      _alunoIdSelecionado = widget.alunos.first['id'];
      _carregarDietaDoAluno(_alunoIdSelecionado!);
    }
  }

  Future<void> _carregarDietaDoAluno(int alunoId) async {
    setState(() {
      _alunoIdSelecionado = alunoId;
      _carregando = true;
    });
    try {
      final resp = await ApiService().dio.get('/api/dieta/aluno/$alunoId');
      final plano = resp.data['plano'];
      final refs = resp.data['refeicoes'] as List<dynamic>? ?? [];
      if (plano != null) {
        _tituloCtrl.text = (plano['titulo'] ?? '').toString();
        _objetivo = (plano['objetivo'] ?? 'Hipertrofia').toString();
        _pesoCtrl.text = (plano['pesoBaseKg'] ?? 80).toString();
        _alturaCtrl.text = (plano['alturaCm'] ?? 175).toString();
        _idadeCtrl.text = (plano['idade'] ?? 25).toString();
        _sexo = (plano['sexo'] ?? 'M').toString();
        _fatorAtividade = double.tryParse((plano['fatorAtividade'] ?? 1.55).toString()) ?? 1.55;
        _tmb = int.tryParse((plano['tmbKcal'] ?? 1800).toString()) ?? 1800;
        _get = int.tryParse((plano['getKcal'] ?? 2400).toString()) ?? 2400;
        _metaKcal = int.tryParse((plano['metaKcal'] ?? 2600).toString()) ?? 2600;
        _protG = int.tryParse((plano['proteinaG'] ?? 180).toString()) ?? 180;
        _carbG = int.tryParse((plano['carboidratoG'] ?? 300).toString()) ?? 300;
        _gordG = int.tryParse((plano['gorduraG'] ?? 70).toString()) ?? 70;
        _aguaLitros = double.tryParse((plano['aguaLitros'] ?? 3.5).toString()) ?? 3.5;
        _obsCtrl.text = (plano['observacoes'] ?? '').toString();
        _refeicoes = refs.map((r) => Map<String, dynamic>.from(r as Map)).toList();
      } else {
        _calcularMifflinStJeorGerarCardapio();
      }
    } catch (_) {}
    if (mounted) setState(() => _carregando = false);
  }

  void _calcularMifflinStJeorGerarCardapio() {
    final peso = double.tryParse(_pesoCtrl.text.replaceAll(',', '.')) ?? 80;
    final altura = double.tryParse(_alturaCtrl.text.replaceAll(',', '.')) ?? 175;
    final idade = int.tryParse(_idadeCtrl.text) ?? 25;

    final tmbCalc = _sexo == 'M'
        ? (10 * peso) + (6.25 * altura) - (5 * idade) + 5
        : (10 * peso) + (6.25 * altura) - (5 * idade) - 161;
    final getCalc = tmbCalc * _fatorAtividade;

    int meta = getCalc.round();
    if (_objetivo == 'Hipertrofia') meta += 350;
    if (_objetivo == 'Emagrecimento') meta -= 450;

    final prot = (peso * 2.2).round();
    final gord = (peso * 0.9).round();
    final kcalRestante = math.max(400, meta - (prot * 4) - (gord * 9));
    final carb = (kcalRestante / 4).round();
    final agua = double.parse(((peso * 0.045)).toStringAsFixed(1));

    setState(() {
      _tmb = tmbCalc.round();
      _get = getCalc.round();
      _metaKcal = meta;
      _protG = prot;
      _carbG = carb;
      _gordG = gord;
      _aguaLitros = agua;
      if (_refeicoes.isEmpty) {
        _refeicoes = [
          {
            'horario': '07:30',
            'nomeRefeicao': 'Refeição 1 — Café da Manhã Proteico',
            'alimentosDescricao': '• 3 Ovos mexidos + 2 fatias de pão integral\n• 1 Banana com aveia (40g)\n• Café sem açúcar',
            'substituicoes': 'Crepioca (2 ovos + 40g goma de tapioca + queijo minas)',
            'kcalEstimada': (meta * 0.22).round(),
            'proteinaG': (prot * 0.22).round(),
            'carboG': (carb * 0.22).round(),
            'gorduraG': (gord * 0.25).round(),
          },
          {
            'horario': '12:30',
            'nomeRefeicao': 'Refeição 2 — Almoço Base',
            'alimentosDescricao': '• 180g Filé de Frango Grelhado\n• 200g Arroz Branco/Integral + 100g Feijão\n• Salada verde + 1 col. sopa de Azeite Extra Virgem',
            'substituicoes': '180g Patinho moído + 220g Batata inglesa ou doce',
            'kcalEstimada': (meta * 0.30).round(),
            'proteinaG': (prot * 0.30).round(),
            'carboG': (carb * 0.30).round(),
            'gorduraG': (gord * 0.28).round(),
          },
          {
            'horario': '16:30',
            'nomeRefeicao': 'Refeição 3 — Pré-Treino Energético',
            'alimentosDescricao': '• 40g Whey Protein + 50g Aveia\n• 1 Banana prata + 15g Pasta de Amendoim\n• 5g Creatina Monohidratada',
            'substituicoes': '150g Frango desfiado + 150g Batata doce cozida',
            'kcalEstimada': (meta * 0.20).round(),
            'proteinaG': (prot * 0.22).round(),
            'carboG': (carb * 0.22).round(),
            'gorduraG': (gord * 0.22).round(),
          },
          {
            'horario': '20:30',
            'nomeRefeicao': 'Refeição 4 — Pós-Treino / Jantar',
            'alimentosDescricao': '• 180g Carne Magra (Patinho/Alcatra) ou Tilápia\n• 180g Arroz ou Macarrão\n• Legumes no vapor à vontade',
            'substituicoes': '180g Peito de Frango + 200g Mandioca ou Abóbora',
            'kcalEstimada': (meta * 0.28).round(),
            'proteinaG': (prot * 0.26).round(),
            'carboG': (carb * 0.26).round(),
            'gorduraG': (gord * 0.25).round(),
          },
        ];
      }
    });
  }

  Future<void> _salvarPlanoNoServidor() async {
    if (_alunoIdSelecionado == null) return;
    await ApiService().dio.post(
      '/api/dieta/salvar',
      data: {
        'alunoId': _alunoIdSelecionado,
        'titulo': _tituloCtrl.text,
        'objetivo': _objetivo,
        'pesoBaseKg': double.tryParse(_pesoCtrl.text.replaceAll(',', '.')) ?? 80,
        'alturaCm': double.tryParse(_alturaCtrl.text.replaceAll(',', '.')) ?? 175,
        'idade': int.tryParse(_idadeCtrl.text) ?? 25,
        'sexo': _sexo,
        'fatorAtividade': _fatorAtividade,
        'tmbKcal': _tmb,
        'getKcal': _get,
        'metaKcal': _metaKcal,
        'proteinaG': _protG,
        'carboidratoG': _carbG,
        'gorduraG': _gordG,
        'aguaLitros': _aguaLitros,
        'observacoes': _obsCtrl.text,
        'refeicoes': _refeicoes,
      },
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🥗 Plano Alimentar & Macros salvo e liberado no App do Aluno!'),
        backgroundColor: AppTheme.neonGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;
    final isMobile = screenW < 640;
    final alunoAtual = widget.alunos.firstWhere(
      (a) => a['id'] == _alunoIdSelecionado,
      orElse: () => widget.alunos.isNotEmpty ? widget.alunos.first : null,
    );

    return ListView(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🥗 PRESCRIÇÃO DE DIETA & CALCULADORA DE MACROS (TMB / GET)',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                ),
                Text(
                  'Calcule automaticamente o Gasto Energético (Mifflin-St Jeor), prescreva refeições e exporte em PDF',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    if (alunoAtual == null) return;
                    DietaPdfService.exportarPlanoAlimentarPdf(
                      nomeAluno: alunoAtual['nome']?.toString() ?? 'Aluno',
                      nomePersonal: widget.nomePersonal,
                      plano: {
                        'titulo': _tituloCtrl.text,
                        'objetivo': _objetivo,
                        'tmbKcal': _tmb,
                        'getKcal': _get,
                        'metaKcal': _metaKcal,
                        'proteinaG': _protG,
                        'carboidratoG': _carbG,
                        'gorduraG': _gordG,
                        'aguaLitros': _aguaLitros,
                        'observacoes': _obsCtrl.text,
                      },
                      refeicoes: _refeicoes,
                    );
                  },
                  icon: const Icon(Icons.picture_as_pdf, color: AppTheme.neonGreen, size: 18),
                  label: const Text('Exportar PDF'),
                ),
                ElevatedButton.icon(
                  onPressed: _salvarPlanoNoServidor,
                  icon: const Icon(Icons.save, size: 18),
                  label: const Text('SALVAR DIETA'),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.alunos.map((a) {
            final sel = a['id'] == _alunoIdSelecionado;
            return ChoiceChip(
              label: Text(a['nome']?.toString() ?? 'Aluno'),
              selected: sel,
              selectedColor: AppTheme.neonGreen.withValues(alpha: 0.25),
              onSelected: (_) => _carregarDietaDoAluno(a['id']),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        if (_carregando)
          const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
        else ...[
          Container(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.neonGreen.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    const Text(
                      '⚡ CALCULADORA AUTOMÁTICA DE MACROS & METABOLISMO (MIFFLIN-ST JEOR)',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: AppTheme.neonGreen,
                        fontSize: 13,
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00B0FF),
                        foregroundColor: Colors.black,
                      ),
                      onPressed: _calcularMifflinStJeorGerarCardapio,
                      icon: const Icon(Icons.bolt, size: 16),
                      label: const Text('Recalcular TMB & Macros'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (isMobile) ...[
                  TextField(
                    controller: _tituloCtrl,
                    decoration: const InputDecoration(labelText: 'Título do Protocolo Alimentar'),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: ['Hipertrofia', 'Emagrecimento', 'Manutenção'].contains(_objetivo)
                        ? _objetivo
                        : 'Hipertrofia',
                    decoration: const InputDecoration(labelText: 'Objetivo'),
                    items: const [
                      DropdownMenuItem(value: 'Hipertrofia', child: Text('💪 Hipertrofia (+350 kcal)')),
                      DropdownMenuItem(value: 'Emagrecimento', child: Text('🔥 Cutting (-450 kcal)')),
                      DropdownMenuItem(value: 'Manutenção', child: Text('⚖️ Recomposição (Normocalórica)')),
                    ],
                    onChanged: (v) {
                      setState(() => _objetivo = v ?? 'Hipertrofia');
                      _calcularMifflinStJeorGerarCardapio();
                    },
                  ),
                ] else
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _tituloCtrl,
                          decoration: const InputDecoration(labelText: 'Título do Protocolo Alimentar'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: ['Hipertrofia', 'Emagrecimento', 'Manutenção'].contains(_objetivo)
                              ? _objetivo
                              : 'Hipertrofia',
                          decoration: const InputDecoration(labelText: 'Objetivo'),
                          items: const [
                            DropdownMenuItem(value: 'Hipertrofia', child: Text('💪 Hipertrofia (+350 kcal)')),
                            DropdownMenuItem(value: 'Emagrecimento', child: Text('🔥 Cutting (-450 kcal)')),
                            DropdownMenuItem(value: 'Manutenção', child: Text('⚖️ Recomposição (Normocalórica)')),
                          ],
                          onChanged: (v) {
                            setState(() => _objetivo = v ?? 'Hipertrofia');
                            _calcularMifflinStJeorGerarCardapio();
                          },
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _pesoCtrl,
                        decoration: const InputDecoration(labelText: 'Peso (kg)'),
                        onChanged: (_) => _calcularMifflinStJeorGerarCardapio(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _alturaCtrl,
                        decoration: const InputDecoration(labelText: 'Altura (cm)'),
                        onChanged: (_) => _calcularMifflinStJeorGerarCardapio(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _idadeCtrl,
                        decoration: const InputDecoration(labelText: 'Idade'),
                        onChanged: (_) => _calcularMifflinStJeorGerarCardapio(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _macroBadge('TMB Basal', '$_tmb kcal', Colors.grey),
                    _macroBadge('Gasto Diário (GET)', '$_get kcal', Colors.cyanAccent),
                    _macroBadge('META CALÓRICA', '$_metaKcal kcal', AppTheme.neonGreen),
                    _macroBadge('PROTEÍNAS (2.2g/kg)', '${_protG}g', const Color(0xFFFF5252)),
                    _macroBadge('CARBOIDRATOS', '${_carbG}g', Colors.amberAccent),
                    _macroBadge('GORDURAS BOAS', '${_gordG}g', Colors.orangeAccent),
                    _macroBadge('HIDRATAÇÃO', '${_aguaLitros}L Água', const Color(0xFF29B6F6)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              Text(
                '🍽️ REFEIÇÕES DO DIA (${_refeicoes.length})',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _refeicoes.add({
                      'horario': '15:00',
                      'nomeRefeicao': 'Nova Refeição / Lanche Proteico',
                      'alimentosDescricao': '• 170g Iogurte Natural + 30g Whey + 1 Fruta',
                      'substituicoes': '2 Ovos cozidos + 1 fatia de pão integral',
                      'kcalEstimada': 320,
                      'proteinaG': 28,
                      'carboG': 32,
                      'gorduraG': 8,
                    });
                  });
                },
                icon: const Icon(Icons.add, size: 16, color: AppTheme.neonGreen),
                label: const Text('+ Adicionar Refeição'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._refeicoes.asMap().entries.map((entry) {
            final idx = entry.key;
            final r = entry.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.neonGreen.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                r['horario']?.toString() ?? '08:00',
                                style: const TextStyle(
                                  color: AppTheme.neonGreen,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                r['nomeRefeicao']?.toString() ?? 'Refeição',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${r['kcalEstimada']} kcal • P:${r['proteinaG']}g C:${r['carboG']}g G:${r['gorduraG']}g',
                              style: const TextStyle(fontSize: 11.5, color: Colors.cyanAccent),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: AppTheme.performanceRed, size: 18),
                              onPressed: () => setState(() => _refeicoes.removeAt(idx)),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      r['alimentosDescricao']?.toString() ?? '',
                      style: const TextStyle(fontSize: 13, height: 1.4),
                    ),
                    if ((r['substituicoes'] ?? '').toString().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        '🔄 Substituições: ${r['substituicoes']}',
                        style: const TextStyle(fontSize: 12, color: AppTheme.neonGreen),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _macroBadge(String label, String val, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
          const SizedBox(height: 2),
          Text(
            val,
            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: color),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 4. PAINEL DO PERSONAL: AGENDA DE HORÁRIOS & CHECK-IN (100% RESPONSIVO)
// ============================================================================

class PainelAgendaPersonalWidget extends StatefulWidget {
  final List<dynamic> alunos;

  const PainelAgendaPersonalWidget({super.key, required this.alunos});

  @override
  State<PainelAgendaPersonalWidget> createState() => _PainelAgendaPersonalWidgetState();
}

class _PainelAgendaPersonalWidgetState extends State<PainelAgendaPersonalWidget> {
  bool _carregando = true;
  Map<String, dynamic> _resumo = {};
  List<dynamic> _aulas = [];

  @override
  void initState() {
    super.initState();
    _carregarAgenda();
  }

  Future<void> _carregarAgenda() async {
    setState(() => _carregando = true);
    try {
      final resp = await ApiService().dio.get('/api/agenda/personal');
      if (mounted) {
        setState(() {
          _resumo = Map<String, dynamic>.from(resp.data['resumo'] ?? {});
          _aulas = resp.data['aulas'] ?? [];
          _carregando = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _carregando = false);
    }
  }

  void _abrirModalNovoAgendamento() {
    int? alunoId = widget.alunos.isNotEmpty ? widget.alunos.first['id'] : null;
    final tituloCtrl = TextEditingController(text: 'Treino Presencial — Acompanhamento Biomecânico');
    final localCtrl = TextEditingController(text: 'Unidade Principal — Sala de Musculação');
    final horaCtrl = TextEditingController(text: '18:00');
    String tipo = 'PRESENCIAL';

    showDialog(
      context: context,
      builder: (ctx) {
        final w = MediaQuery.sizeOf(ctx).width;
        return StatefulBuilder(
          builder: (ctx, setModalState) => AlertDialog(
            backgroundColor: AppTheme.surfaceCard,
            insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            title: const Text('📅 Agendar Aula / Consultoria'),
            content: SizedBox(
              width: math.min(w - 32, 440),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      initialValue: alunoId,
                      decoration: const InputDecoration(labelText: 'Aluno'),
                      items: widget.alunos
                          .map((a) => DropdownMenuItem<int>(
                                value: a['id'],
                                child: Text(a['nome']?.toString() ?? 'Aluno'),
                              ))
                          .toList(),
                      onChanged: (v) => setModalState(() => alunoId = v),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: tipo,
                      decoration: const InputDecoration(labelText: 'Tipo de Atendimento'),
                      items: const [
                        DropdownMenuItem(value: 'PRESENCIAL', child: Text('🏋️ Aula Presencial na Academia')),
                        DropdownMenuItem(value: 'AVALIACAO_FISICA', child: Text('📏 Avaliação Física & Fotos')),
                        DropdownMenuItem(value: 'CONSULTORIA_ONLINE', child: Text('💻 Consultoria Online')),
                      ],
                      onChanged: (v) => setModalState(() => tipo = v ?? 'PRESENCIAL'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: tituloCtrl,
                      decoration: const InputDecoration(labelText: 'Foco do Treino / Aula'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: horaCtrl,
                      decoration: const InputDecoration(labelText: 'Horário de Hoje (HH:mm)'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: localCtrl,
                      decoration: const InputDecoration(labelText: 'Local / Academia'),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: () async {
                  if (alunoId == null) return;
                  final parts = horaCtrl.text.split(':');
                  final h = int.tryParse(parts.first) ?? 18;
                  final m = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
                  final now = DateTime.now();
                  final dt = DateTime(now.year, now.month, now.day, h, m);
                  await ApiService().dio.post('/api/agenda', data: {
                    'alunoId': alunoId,
                    'dataHoraInicio': dt.toIso8601String(),
                    'duracaoMinutos': 60,
                    'tipoAula': tipo,
                    'tituloTreino': tituloCtrl.text,
                    'localAcademia': localCtrl.text,
                  });
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  _carregarAgenda();
                },
                child: const Text('CONFIRMAR'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;
    final isMobile = screenW < 640;

    return ListView(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📅 AGENDA DE HORÁRIOS & CHECK-IN DE AULAS PRESENCIAIS',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                ),
                Text(
                  'Controle seus horários de atendimento, envie lembrete no WhatsApp e faça Check-in de presença',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: _abrirModalNovoAgendamento,
              icon: const Icon(Icons.add_alarm),
              label: const Text('+ AGENDAR AULA'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _kpiCard('Aulas Hoje', '${_resumo['aulasHoje'] ?? 0}', AppTheme.neonGreen, isMobile),
            _kpiCard('Horários Agendados', '${_resumo['agendadasPendentes'] ?? 0}', Colors.cyanAccent, isMobile),
            _kpiCard('Aulas Concluídas', '${_resumo['concluidasTotal'] ?? 0}', Colors.amberAccent, isMobile),
          ],
        ),
        const SizedBox(height: 20),
        if (_carregando)
          const Center(child: CircularProgressIndicator())
        else
          ..._aulas.map((ag) {
            final status = (ag['status'] ?? 'AGENDADA').toString();
            final concluida = status == 'CONCLUIDA';
            final dt = DateTime.tryParse((ag['dataHoraInicio'] ?? '').toString()) ?? DateTime.now();
            final dataFmt =
                '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} às ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 12 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: concluida
                                ? AppTheme.neonGreen.withValues(alpha: 0.16)
                                : Colors.cyanAccent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                concluida ? Icons.verified : Icons.schedule,
                                color: concluida ? AppTheme.neonGreen : Colors.cyanAccent,
                                size: 20,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                dataFmt,
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    ag['nomeAluno']?.toString() ?? 'Aluno',
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: concluida
                                          ? AppTheme.neonGreen.withValues(alpha: 0.18)
                                          : Colors.amber.withValues(alpha: 0.18),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      status,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: concluida ? AppTheme.neonGreen : Colors.amberAccent,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${ag['tituloTreino']} • 📍 ${ag['localAcademia'] ?? 'Academia'}',
                                style: const TextStyle(fontSize: 12.5, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (!concluida)
                          ElevatedButton.icon(
                            onPressed: () async {
                              await ApiService().dio.patch(
                                '/api/agenda/${ag['id']}/status',
                                data: {'status': 'CONCLUIDA'},
                              );
                              _carregarAgenda();
                            },
                            icon: const Icon(Icons.check_circle, size: 16),
                            label: const Text('Check-in Aula'),
                          ),
                        OutlinedButton.icon(
                          onPressed: () => WhatsAppService.abrirMensagem(
                            ag['telefoneAluno']?.toString(),
                            'Olá ${ag['nomeAluno']}! Confirmando nosso horário agendado ($dataFmt) para *${ag['tituloTreino']}* em ${ag['localAcademia']}. Bora pra cima! 💪🔥',
                          ),
                          icon: const Icon(Icons.chat, size: 16, color: AppTheme.neonGreen),
                          label: const Text('Lembrete WhatsApp'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _kpiCard(String label, String val, Color color, bool isMobile) {
    return Container(
      width: isMobile ? 155 : 210,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11.5, color: AppTheme.textSecondary)),
          const SizedBox(height: 4),
          Text(val, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }
}

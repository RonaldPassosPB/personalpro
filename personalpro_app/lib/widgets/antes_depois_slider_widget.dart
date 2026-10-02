import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../theme.dart';

class ComparadorFotosAntesDepoisWidget extends StatefulWidget {
  final List<dynamic> avaliacoes;

  const ComparadorFotosAntesDepoisWidget({
    super.key,
    required this.avaliacoes,
  });

  @override
  State<ComparadorFotosAntesDepoisWidget> createState() =>
      _ComparadorFotosAntesDepoisWidgetState();
}

class _ComparadorFotosAntesDepoisWidgetState
    extends State<ComparadorFotosAntesDepoisWidget> {
  double _splitPercent = 0.50;
  String _tipoVisualizacao = 'frente'; // 'frente', 'lado', 'costas'
  int _idxAntes = -1;
  int _idxDepois = -1;

  @override
  void initState() {
    super.initState();
    _inicializarIndices();
  }

  @override
  void didUpdateWidget(covariant ComparadorFotosAntesDepoisWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.avaliacoes != widget.avaliacoes) {
      _inicializarIndices();
    }
  }

  void _inicializarIndices() {
    if (widget.avaliacoes.length >= 2) {
      // Ordenadas: mais recente primeiro (índice 0 = depois), mais antiga última (antes)
      _idxDepois = 0;
      _idxAntes = widget.avaliacoes.length - 1;
    } else if (widget.avaliacoes.length == 1) {
      _idxDepois = 0;
      _idxAntes = 0;
    } else {
      _idxDepois = -1;
      _idxAntes = -1;
    }
  }

  Map<String, dynamic>? _extrairFotos(dynamic avaliacao) {
    if (avaliacao == null) return null;
    final raw = avaliacao['fotosJson'];
    if (raw == null || raw.toString().isEmpty) return null;
    try {
      if (raw is Map) return Map<String, dynamic>.from(raw);
      return Map<String, dynamic>.from(jsonDecode(raw.toString()));
    } catch (_) {
      return null;
    }
  }

  String? _obterUrlFoto(dynamic avaliacao, String tipo) {
    final fotos = _extrairFotos(avaliacao);
    if (fotos == null) return null;
    return fotos[tipo]?.toString();
  }

  String _formatarData(dynamic dataRaw) {
    if (dataRaw == null) return '-';
    try {
      final dt = DateTime.parse(dataRaw.toString());
      return DateFormat('dd/MM/yyyy').format(dt);
    } catch (_) {
      return dataRaw.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLight = AppTheme.isLight;
    final accentGreen = AppTheme.primaryAccent;
    final borderSubtle = isLight
        ? const Color(0xFFE2E8F0)
        : const Color(0xFF1E293B);

    final temAvaliacoes = widget.avaliacoes.isNotEmpty;
    final avalAntes = (_idxAntes >= 0 && _idxAntes < widget.avaliacoes.length)
        ? widget.avaliacoes[_idxAntes]
        : null;
    final avalDepois = (_idxDepois >= 0 && _idxDepois < widget.avaliacoes.length)
        ? widget.avaliacoes[_idxDepois]
        : null;

    final urlAntes = _obterUrlFoto(avalAntes, _tipoVisualizacao);
    final urlDepois = _obterUrlFoto(avalDepois, _tipoVisualizacao);

    final pesoAntes = avalAntes != null ? (avalAntes['peso']?.toString() ?? '-') : '-';
    final pesoDepois = avalDepois != null ? (avalDepois['peso']?.toString() ?? '-') : '-';
    final dataAntes = _formatarData(avalAntes?['dataAvaliacao']);
    final dataDepois = _formatarData(avalDepois?['dataAvaliacao']);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderSubtle),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accentGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.compare_rounded,
                      color: accentGreen,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Comparador Antes & Depois',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        'Arraste o divisor para ver a transformação visual',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Seletor de ângulo (Frente / Lado / Costas)
              Container(
                decoration: BoxDecoration(
                  color: isLight ? const Color(0xFFF1F5F9) : const Color(0xFF141C2E),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderSubtle),
                ),
                padding: const EdgeInsets.all(3),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _botaoAngulo('frente', 'Frente'),
                    _botaoAngulo('lado', 'Lado'),
                    _botaoAngulo('costas', 'Costas'),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Seletor de Avaliações se houver mais de 2
          if (widget.avaliacoes.length > 2) ...[
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Antes: ', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    DropdownButton<int>(
                      value: _idxAntes,
                      isDense: true,
                      underline: const SizedBox(),
                      items: List.generate(
                        widget.avaliacoes.length,
                        (i) => DropdownMenuItem(
                          value: i,
                          child: Text(
                            '${_formatarData(widget.avaliacoes[i]['dataAvaliacao'])} (${widget.avaliacoes[i]['peso']} kg)',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                      onChanged: (v) {
                        if (v != null) setState(() => _idxAntes = v);
                      },
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Depois: ', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    DropdownButton<int>(
                      value: _idxDepois,
                      isDense: true,
                      underline: const SizedBox(),
                      items: List.generate(
                        widget.avaliacoes.length,
                        (i) => DropdownMenuItem(
                          value: i,
                          child: Text(
                            '${_formatarData(widget.avaliacoes[i]['dataAvaliacao'])} (${widget.avaliacoes[i]['peso']} kg)',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                      onChanged: (v) {
                        if (v != null) setState(() => _idxDepois = v);
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
          ],

          // Área Interativa do Slider Antes / Depois
          LayoutBuilder(
            builder: (context, constraints) {
              final boxWidth = constraints.maxWidth;
              final boxHeight = (boxWidth * 0.72).clamp(240.0, 420.0);

              final temFotosReais = urlAntes != null &&
                  urlDepois != null &&
                  urlAntes.isNotEmpty &&
                  urlDepois.isNotEmpty;

              return ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: boxWidth,
                  height: boxHeight,
                  decoration: BoxDecoration(
                    color: isLight ? const Color(0xFFF1F5F9) : const Color(0xFF090D16),
                    border: Border.all(color: borderSubtle),
                  ),
                  child: temFotosReais
                      ? _buildSplitFotos(
                          boxWidth: boxWidth,
                          boxHeight: boxHeight,
                          urlAntes: urlAntes,
                          urlDepois: urlDepois,
                          dataAntes: dataAntes,
                          pesoAntes: pesoAntes,
                          dataDepois: dataDepois,
                          pesoDepois: pesoDepois,
                        )
                      : _buildPlaceholderOuDemonstrativo(
                          boxWidth: boxWidth,
                          boxHeight: boxHeight,
                          isLight: isLight,
                          accentGreen: accentGreen,
                          dataAntes: dataAntes,
                          pesoAntes: pesoAntes,
                          dataDepois: dataDepois,
                          pesoDepois: pesoDepois,
                          temAvaliacoes: temAvaliacoes,
                        ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _botaoAngulo(String tipo, String rotulo) {
    final selecionado = _tipoVisualizacao == tipo;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _tipoVisualizacao = tipo);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selecionado ? AppTheme.primaryAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          rotulo,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: selecionado ? FontWeight.w800 : FontWeight.w600,
            color: selecionado ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildSplitFotos({
    required double boxWidth,
    required double boxHeight,
    required String urlAntes,
    required String urlDepois,
    required String dataAntes,
    required String pesoAntes,
    required String dataDepois,
    required String pesoDepois,
  }) {
    final splitX = boxWidth * _splitPercent;

    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        setState(() {
          _splitPercent =
              (details.localPosition.dx / boxWidth).clamp(0.05, 0.95);
        });
      },
      child: Stack(
        children: [
          // Foto DEPOIS (Fundo Total)
          Positioned.fill(
            child: Image.network(
              urlDepois,
              fit: BoxFit.cover,
              errorBuilder: (ctx, err, st) => _errorImage('Depois'),
            ),
          ),

          // Foto ANTES (Recortada à esquerda)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: splitX,
            child: ClipRect(
              child: Align(
                alignment: Alignment.centerLeft,
                widthFactor: 1.0,
                child: SizedBox(
                  width: boxWidth,
                  height: boxHeight,
                  child: Image.network(
                    urlAntes,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, st) => _errorImage('Antes'),
                  ),
                ),
              ),
            ),
          ),

          // Linha divisória e Handle interativo
          Positioned(
            left: splitX - 1.5,
            top: 0,
            bottom: 0,
            child: Container(
              width: 3,
              color: AppTheme.primaryAccent,
            ),
          ),

          // Círculo com ícone ↔
          Positioned(
            left: splitX - 18,
            top: (boxHeight / 2) - 18,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryAccent,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.swap_horiz_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),

          // Badge ANTES (inferior esquerdo)
          Positioned(
            left: 12,
            bottom: 12,
            child: _badgeLegenda(
              titulo: 'ANTES',
              detalhe: '$dataAntes • $pesoAntes kg',
              cor: Colors.black87,
            ),
          ),

          // Badge DEPOIS (inferior direito)
          Positioned(
            right: 12,
            bottom: 12,
            child: _badgeLegenda(
              titulo: 'DEPOIS',
              detalhe: '$dataDepois • $pesoDepois kg',
              cor: AppTheme.primaryAccent.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderOuDemonstrativo({
    required double boxWidth,
    required double boxHeight,
    required bool isLight,
    required Color accentGreen,
    required String dataAntes,
    required String pesoAntes,
    required String dataDepois,
    required String pesoDepois,
    required bool temAvaliacoes,
  }) {
    final splitX = boxWidth * _splitPercent;

    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        setState(() {
          _splitPercent =
              (details.localPosition.dx / boxWidth).clamp(0.05, 0.95);
        });
      },
      child: Stack(
        children: [
          // Lado Direito (Depois - Ilustrativo / Silhouette)
          Positioned.fill(
            child: Container(
              color: isLight
                  ? const Color(0xFFE2E8F0)
                  : const Color(0xFF0F172A),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.fitness_center_rounded,
                      size: 48,
                      color: accentGreen.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Foto Depois (Evolução)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Lado Esquerdo (Antes - Ilustrativo)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: splitX,
            child: ClipRect(
              child: Container(
                width: boxWidth,
                height: boxHeight,
                color: isLight
                    ? const Color(0xFFCBD5E1)
                    : const Color(0xFF1E293B),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.person_outline_rounded,
                        size: 48,
                        color: AppTheme.textSecondary.withValues(alpha: 0.6),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Foto Antes (Início)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Linha divisória e Handle interativo
          Positioned(
            left: splitX - 1.5,
            top: 0,
            bottom: 0,
            child: Container(
              width: 3,
              color: accentGreen,
            ),
          ),

          // Handle ↔
          Positioned(
            left: splitX - 18,
            top: (boxHeight / 2) - 18,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentGreen,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.swap_horiz_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),

          // Legendas informativas
          Positioned(
            left: 12,
            bottom: 12,
            child: _badgeLegenda(
              titulo: 'ANTES',
              detalhe: temAvaliacoes ? '$dataAntes • $pesoAntes kg' : 'Sem foto cadastrada',
              cor: Colors.black87,
            ),
          ),
          Positioned(
            right: 12,
            bottom: 12,
            child: _badgeLegenda(
              titulo: 'DEPOIS',
              detalhe: temAvaliacoes ? '$dataDepois • $pesoDepois kg' : 'Sem foto cadastrada',
              cor: accentGreen.withValues(alpha: 0.9),
            ),
          ),

          // Mensagem de orientação no topo
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      temAvaliacoes
                          ? 'As avaliações físicas registradas pelo seu Personal carregarão as fotos aqui.'
                          : 'Seu Personal poderá anexar fotos de bioimpedância e avaliação postural.',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _badgeLegenda({
    required String titulo,
    required String detalhe,
    required Color cor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 10,
              letterSpacing: 0.8,
            ),
          ),
          Text(
            detalhe,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorImage(String label) {
    return Container(
      color: Colors.black26,
      alignment: Alignment.center,
      child: Text(
        'Foto $label Indisponível',
        style: const TextStyle(color: Colors.white54, fontSize: 12),
      ),
    );
  }
}

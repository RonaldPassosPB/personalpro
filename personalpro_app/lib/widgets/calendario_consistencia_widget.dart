import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../theme.dart';

class CalendarioConsistenciaWidget extends StatefulWidget {
  final List<dynamic> historicoTreinos;

  const CalendarioConsistenciaWidget({
    super.key,
    required this.historicoTreinos,
  });

  @override
  State<CalendarioConsistenciaWidget> createState() =>
      _CalendarioConsistenciaWidgetState();
}

class _CalendarioConsistenciaWidgetState
    extends State<CalendarioConsistenciaWidget> {
  late DateTime _mesExibicao;

  @override
  void initState() {
    super.initState();
    final agora = DateTime.now();
    _mesExibicao = DateTime(agora.year, agora.month, 1);
  }

  void _navegarMes(int delta) {
    HapticFeedback.selectionClick();
    setState(() {
      _mesExibicao = DateTime(
        _mesExibicao.year,
        _mesExibicao.month + delta,
        1,
      );
    });
  }

  Map<int, List<Map<String, dynamic>>> _filtrarTreinosPorDia() {
    final mapa = <int, List<Map<String, dynamic>>>{};

    for (final item in widget.historicoTreinos) {
      if (item == null) continue;
      final rawData = item['dataHora'] ?? item['dataExecucao'] ?? item['dataRegistro'];
      if (rawData == null) continue;

      DateTime? dt;
      try {
        dt = DateTime.parse(rawData.toString());
      } catch (_) {}

      if (dt != null &&
          dt.year == _mesExibicao.year &&
          dt.month == _mesExibicao.month) {
        final dia = dt.day;
        if (!mapa.containsKey(dia)) {
          mapa[dia] = [];
        }
        mapa[dia]!.add(Map<String, dynamic>.from(item));
      }
    }

    return mapa;
  }

  int _calcularStreakAtual() {
    final hoje = DateTime.now();
    final diasTreinados = <String>{};

    for (final item in widget.historicoTreinos) {
      final rawData = item['dataHora'] ?? item['dataExecucao'] ?? item['dataRegistro'];
      if (rawData == null) continue;
      try {
        final dt = DateTime.parse(rawData.toString());
        diasTreinados.add('${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}');
      } catch (_) {}
    }

    int streak = 0;
    DateTime cursor = hoje;

    final hojeStr = '${hoje.year}-${hoje.month.toString().padLeft(2, '0')}-${hoje.day.toString().padLeft(2, '0')}';
    if (!diasTreinados.contains(hojeStr)) {
      cursor = hoje.subtract(const Duration(days: 1));
    }

    while (true) {
      final str = '${cursor.year}-${cursor.month.toString().padLeft(2, '0')}-${cursor.day.toString().padLeft(2, '0')}';
      if (diasTreinados.contains(str)) {
        streak++;
        cursor = cursor.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  void _exibirDetalhesDia(int dia, List<Map<String, dynamic>> treinos) {
    HapticFeedback.lightImpact();
    final dataFormatada = DateFormat("d 'de' MMMM", 'pt_BR')
        .format(DateTime(_mesExibicao.year, _mesExibicao.month, dia));

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.calendar_month_rounded,
                          color: AppTheme.primaryAccent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        dataFormatada,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...treinos.map((t) {
                final duracao = t['duracaoMinutos'] ?? 45;
                final obs = t['observacaoAluno']?.toString() ?? 'Concluído';
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.bgDark,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppTheme.primaryAccent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primaryAccent.withValues(alpha: 0.2),
                        ),
                        child: Icon(
                          Icons.check_rounded,
                          color: AppTheme.primaryAccent,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t['nomeTreino']?.toString() ?? 'Treino do Dia',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Duração: $duracao min • $obs',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLight = AppTheme.isLight;
    final accentGreen = AppTheme.primaryAccent;
    final borderSubtle = isLight
        ? const Color(0xFFE2E8F0)
        : const Color(0xFF1E293B);

    final treinosPorDia = _filtrarTreinosPorDia();
    final totalTreinosMes = treinosPorDia.values
        .fold<int>(0, (prev, list) => prev + list.length);
    final streak = _calcularStreakAtual();

    final agora = DateTime.now();
    final ehMesAtual =
        _mesExibicao.year == agora.year && _mesExibicao.month == agora.month;
    final diaAtual = agora.day;

    final nomeMesAno =
        DateFormat('MMMM yyyy', 'pt_BR').format(_mesExibicao);
    final nomeMesCapitalizado =
        nomeMesAno[0].toUpperCase() + nomeMesAno.substring(1);

    final primeiroDiaSemana = _mesExibicao.weekday % 7; // 0 = Domingo
    final diasNoMes = DateTime(
      _mesExibicao.year,
      _mesExibicao.month + 1,
      0,
    ).day;

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
          // Header com Navegação e Streak
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accentGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.insights_rounded,
                      color: AppTheme.primaryAccent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Consistência de Treinos',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        '$totalTreinosMes treinos em $nomeMesCapitalizado',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (streak > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.warningAmber.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.warningAmber.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.local_fire_department_rounded,
                        color: AppTheme.warningAmber,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$streak dias seguidos',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: isLight
                              ? const Color(0xFFB45309)
                              : AppTheme.warningAmber,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Seletor de Mês (< Mês Ano >)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () => _navegarMes(-1),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Text(
                nomeMesCapitalizado,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () => _navegarMes(1),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Dias da semana (D, S, T, Q, Q, S, S)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const ['D', 'S', 'T', 'Q', 'Q', 'S', 'S']
                .map(
                  (d) => SizedBox(
                    width: 34,
                    child: Center(
                      child: Text(
                        d,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),

          const SizedBox(height: 8),

          // Grade do Calendário (Heatmap)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: primeiroDiaSemana + diasNoMes,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
              childAspectRatio: 1.0,
            ),
            itemBuilder: (context, index) {
              if (index < primeiroDiaSemana) {
                return const SizedBox();
              }

              final dia = index - primeiroDiaSemana + 1;
              final treinos = treinosPorDia[dia];
              final treinou = treinos != null && treinos.isNotEmpty;
              final ehHoje = ehMesAtual && dia == diaAtual;

              return InkWell(
                onTap: treinou ? () => _exibirDetalhesDia(dia, treinos) : null,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: treinou
                        ? const LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF059669)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: treinou
                        ? null
                        : (isLight
                            ? const Color(0xFFF1F5F9)
                            : const Color(0xFF141C2E)),
                    border: Border.all(
                      color: ehHoje
                          ? accentGreen
                          : (treinou ? Colors.transparent : borderSubtle),
                      width: ehHoje ? 2.0 : 1.0,
                    ),
                    boxShadow: treinou
                        ? [
                            BoxShadow(
                              color: accentGreen.withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$dia',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight:
                                treinou ? FontWeight.w900 : FontWeight.w600,
                            color: treinou
                                ? Colors.white
                                : (ehHoje
                                    ? accentGreen
                                    : AppTheme.textPrimary),
                          ),
                        ),
                        if (treinou) ...[
                          const SizedBox(height: 1),
                          const Icon(
                            Icons.check_rounded,
                            size: 11,
                            color: Colors.white,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // Legenda e Resumo Inferior
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: accentGreen,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Dia com treino concluído',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              Text(
                'Meta: 16-20 treinos/mês',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

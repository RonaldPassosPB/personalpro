import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/whatsapp_service.dart';
import '../theme.dart';

class StoryCardTreinoModal extends StatelessWidget {
  final String nomeAluno;
  final String nomeTreino;
  final int duracaoMinutos;
  final int totalExercicios;
  final int totalSeries;
  final List<String> novosRecordes;
  final int treinosNoMes;
  final VoidCallback? onConcluir;

  const StoryCardTreinoModal({
    super.key,
    required this.nomeAluno,
    required this.nomeTreino,
    required this.duracaoMinutos,
    required this.totalExercicios,
    required this.totalSeries,
    this.novosRecordes = const [],
    this.treinosNoMes = 1,
    this.onConcluir,
  });

  static Future<void> exibir({
    required BuildContext context,
    required String nomeAluno,
    required String nomeTreino,
    required int duracaoMinutos,
    required int totalExercicios,
    required int totalSeries,
    List<String> novosRecordes = const [],
    int treinosNoMes = 1,
    VoidCallback? onConcluir,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StoryCardTreinoModal(
        nomeAluno: nomeAluno,
        nomeTreino: nomeTreino,
        duracaoMinutos: duracaoMinutos,
        totalExercicios: totalExercicios,
        totalSeries: totalSeries,
        novosRecordes: novosRecordes,
        treinosNoMes: treinosNoMes,
        onConcluir: onConcluir,
      ),
    );
  }

  void _compartilhar(BuildContext context) {
    HapticFeedback.mediumImpact();
    final prsTexto = novosRecordes.isNotEmpty
        ? '\n🏆 *Novos Recordes Batidos:*\n${novosRecordes.map((r) => '• $r').join('\n')}'
        : '';

    final texto = '''
💪 *TREINO CONCLUÍDO NO PERSONALPRO!*
🏋️‍♂️ *$nomeAluno* finalizou *$nomeTreino*

⏱️ *Duração:* $duracaoMinutos minutos
📊 *Séries:* $totalSeries séries em $totalExercicios exercícios
🔥 *Consistência:* Treino #$treinosNoMes deste mês$prsTexto

Foco e consistência geram resultados! 🚀
#PersonalPro #TreinoDeElite #Musculacao
''';

    WhatsAppService.abrirMensagem(null, texto);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.primaryAccent,
        content: const Text(
          'Texto do treino pronto para compartilhamento no WhatsApp e Redes!',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLight = AppTheme.isLight;
    final dataFormatada =
        DateFormat("d 'de' MMMM", 'pt_BR').format(DateTime.now());

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 390),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isLight
                      ? [
                          const Color(0xFFFFFFFF),
                          const Color(0xFFF1F5F9),
                          const Color(0xFFE2E8F0),
                        ]
                      : [
                          const Color(0xFF0F172A),
                          const Color(0xFF090D16),
                          const Color(0xFF04060A),
                        ],
                ),
                border: Border.all(
                  color: AppTheme.primaryAccent.withValues(alpha: 0.35),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryAccent.withValues(alpha: 0.18),
                    blurRadius: 36,
                    spreadRadius: 2,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Watermark / Brand Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryAccent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.fitness_center_rounded,
                              size: 16,
                              color: AppTheme.primaryAccent,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'PERSONALPRO',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                              color: AppTheme.primaryAccent,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isLight
                              ? const Color(0xFFE2E8F0)
                              : const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          dataFormatada,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Hero Icon with pulsing aura
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primaryAccent.withValues(alpha: 0.12),
                        ),
                      ),
                      Container(
                        width: 66,
                        height: 66,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF059669)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryAccent.withValues(alpha: 0.4),
                              blurRadius: 18,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 38,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  Text(
                    'Treino Concluído!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    nomeTreino,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryAccent,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Atleta: $nomeAluno',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppTheme.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Stats Grid
                  Row(
                    children: [
                      Expanded(
                        child: _statBox(
                          icon: Icons.timer_outlined,
                          titulo: 'Duração',
                          valor: '$duracaoMinutos min',
                          cor: AppTheme.electricBlue,
                          isLight: isLight,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _statBox(
                          icon: Icons.fitness_center_rounded,
                          titulo: 'Séries',
                          valor: '$totalSeries séries',
                          cor: AppTheme.primaryAccent,
                          isLight: isLight,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _statBox(
                          icon: Icons.local_fire_department_rounded,
                          titulo: 'Mês',
                          valor: '#$treinosNoMes',
                          cor: AppTheme.warningAmber,
                          isLight: isLight,
                        ),
                      ),
                    ],
                  ),

                  // Personal Record (PR) Section if any
                  if (novosRecordes.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.warningAmber.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppTheme.warningAmber.withValues(alpha: 0.4),
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.emoji_events_rounded,
                                color: AppTheme.warningAmber,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'RECORDES PESSOAIS SUPERADOS!',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.6,
                                  color: isLight
                                      ? const Color(0xFFB45309)
                                      : AppTheme.warningAmber,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ...novosRecordes.map(
                            (rec) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.arrow_upward_rounded,
                                    size: 13,
                                    color: AppTheme.primaryAccent,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      rec,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Actions
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => _compartilhar(context),
                      icon: const Icon(Icons.share_rounded, size: 18),
                      label: const Text(
                        'Compartilhar Conquista',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textPrimary,
                        side: BorderSide(
                          color: isLight
                              ? const Color(0xFFCBD5E1)
                              : const Color(0xFF334155),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        onConcluir?.call();
                      },
                      child: const Text(
                        'Voltar aos Treinos',
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statBox({
    required IconData icon,
    required String titulo,
    required String valor,
    required Color cor,
    required bool isLight,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: isLight ? Colors.white : const Color(0xFF141C2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: cor, size: 20),
          const SizedBox(height: 6),
          Text(
            valor,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            titulo,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

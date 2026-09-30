import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_service.dart';
import '../../services/ficha_pdf_service.dart';
import '../../services/notification_service.dart';
import '../../services/whatsapp_service.dart';
import '../../theme.dart';
import '../../widgets/evolucao_charts_widget.dart';
import '../../widgets/exercicio_animado_dieta_agenda_widget.dart';
import '../../widgets/notificacoes_sheet.dart';
import '../../widgets/pix_modal.dart';
import '../auth/login_screen.dart';

class AlunoHomeScreen extends StatefulWidget {
  final Map<String, dynamic> session;
  const AlunoHomeScreen({super.key, required this.session});

  @override
  State<AlunoHomeScreen> createState() => _AlunoHomeScreenState();
}

class _AlunoHomeScreenState extends State<AlunoHomeScreen> {
  int _abaAtual = 0;
  bool _carregando = true;
  final Set<int> _fichasRecolhidas = {};

  Map<String, dynamic> _aluno = {};
  List<dynamic> _fichas = [];
  int _treinosMes = 0;
  int _treinosTotal = 0;

  List<dynamic> _avaliacoes = [];
  List<dynamic> _historicoTreinos = [];
  List<dynamic> _progressaoCargas = [];

  Map<String, dynamic>? _meuPlanoDieta;
  List<dynamic> _minhasRefeicoes = [];
  List<dynamic> _minhasAulasAgenda = [];

  List<dynamic> _pagamentos = [];
  String _chavePixPersonal = '';
  String _nomePersonal = '';

  @override
  void initState() {
    super.initState();
    _carregarDadosAluno();
  }

  Future<void> _carregarDadosAluno() async {
    setState(() => _carregando = true);
    try {
      dynamic homeData;
      dynamic evoData;
      dynamic finData;
      dynamic dietaData;
      List<dynamic> agendaData = [];

      try {
        final resp = await ApiService().dio.get('/api/aluno/home');
        homeData = resp.data;
      } catch (e) {
        debugPrint('Erro ao carregar /api/aluno/home: $e');
      }

      try {
        final resp = await ApiService().dio.get('/api/aluno/evolucao');
        evoData = resp.data;
      } catch (e) {
        debugPrint('Erro ao carregar /api/aluno/evolucao: $e');
      }

      try {
        final resp = await ApiService().dio.get('/api/aluno/financeiro');
        finData = resp.data;
      } catch (e) {
        debugPrint('Erro ao carregar /api/aluno/financeiro: $e');
      }

      try {
        final resp = await ApiService().dio.get('/api/dieta/minha-dieta');
        dietaData = resp.data;
      } catch (e) {
        debugPrint('Erro ao carregar /api/dieta/minha-dieta: $e');
      }

      try {
        final resp = await ApiService().dio.get('/api/agenda/minhas-aulas');
        if (resp.data is List) agendaData = resp.data;
      } catch (e) {
        debugPrint('Erro ao carregar /api/agenda/minhas-aulas: $e');
      }

      if (!mounted) return;
      setState(() {
        if (homeData != null && homeData is Map) {
          _aluno = Map<String, dynamic>.from(homeData['aluno'] ?? {});
          _fichas = homeData['fichas'] ?? [];
          _treinosMes = homeData['treinosMes'] ?? 0;
          _treinosTotal = homeData['treinosTotal'] ?? 0;
        }
        if (evoData != null && evoData is Map) {
          _avaliacoes = evoData['avaliacoes'] ?? [];
          _historicoTreinos = evoData['historicoTreinos'] ?? [];
          _progressaoCargas = evoData['progressaoCargas'] ?? [];
        }
        if (finData != null && finData is Map) {
          _pagamentos = finData['pagamentos'] ?? [];
          _chavePixPersonal = finData['chavePixPersonal']?.toString() ?? '';
          _nomePersonal = finData['nomePersonal']?.toString() ?? 'PersonalPro';
        }
        if (dietaData != null && dietaData is Map && dietaData['plano'] != null) {
          _meuPlanoDieta = Map<String, dynamic>.from(dietaData['plano']);
          _minhasRefeicoes = dietaData['refeicoes'] ?? [];
        }
        _minhasAulasAgenda = agendaData;
        _carregando = false;
      });
    } catch (_) {
      if (mounted) setState(() => _carregando = false);
    }
  }

  void _abrirModoExecucaoTreino(Map<String, dynamic> ficha) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ModoExecucaoTreinoScreen(
          ficha: ficha,
          nomeAluno: _aluno['nome']?.toString() ?? 'Aluno',
          onTreinoConcluido: _carregarDadosAluno,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 920;
    final isLight = AppTheme.isLight;
    final borderSubtle = isLight
        ? const Color(0xFF0F172A).withValues(alpha: 0.10)
        : Colors.white.withValues(alpha: 0.10);

    final bodyContent = _carregando
        ? const Center(child: CircularProgressIndicator())
        : IndexedStack(
            index: _abaAtual,
            children: [
              _buildAbaMeusTreinos(isLight, borderSubtle),
              _buildAbaMinhaDietaAluno(isLight, borderSubtle),
              _buildAbaMinhaEvolucao(isLight, borderSubtle),
              _buildAbaFinanceiroAluno(isLight, borderSubtle),
            ],
          );

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(68),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            border: Border(bottom: BorderSide(color: borderSubtle, width: 1)),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: isDesktop ? 32 : 16),
              child: Row(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () async {
                      final novaFoto = await ImageHelper.selecionarImagemBase64();
                      if (novaFoto != null) {
                        await ApiService().dio.put('/api/aluno/foto-perfil', data: {
                          'fotoUrl': novaFoto,
                        });
                        _carregarDadosAluno();
                      }
                    },
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ImageHelper.renderAvatarOrImage(
                          _aluno['fotoUrl']?.toString(),
                          radius: 20,
                          fallbackText: _aluno['nome']?.toString() ?? 'A',
                        ),
                        Positioned(
                          right: -1,
                          bottom: -1,
                          child: Container(
                            width: 11,
                            height: 11,
                            decoration: BoxDecoration(
                              color: AppTheme.neonGreen,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppTheme.surfaceCard, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Consultoria: ${_aluno['nomePersonal'] ?? _nomePersonal}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'Olá, ${_aluno['nome'] ?? widget.session['nome'] ?? 'Atleta'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isDesktop) ...[
                    Container(
                      height: 28,
                      width: 1,
                      margin: const EdgeInsets.symmetric(horizontal: 18),
                      color: borderSubtle,
                    ),
                    const BotaoAlternarTema(mostrarTexto: true),
                    const SizedBox(width: 24),
                    _buildTopNavTab(0, Icons.list_alt_rounded, 'Meus Treinos', isLight),
                    _buildTopNavTab(1, Icons.restaurant_menu_rounded, 'Minha Dieta', isLight),
                    _buildTopNavTab(2, Icons.show_chart_rounded, 'Minha Evolução', isLight),
                    _buildTopNavTab(3, Icons.paid_outlined, 'Financeiro PIX', isLight),
                    const SizedBox(width: 12),
                  ] else ...[
                    const BotaoAlternarTema(mostrarTexto: false),
                  ],
                  IconButton(
                    tooltip: 'Notificações',
                    icon: Icon(
                      Icons.notifications_none_rounded,
                      color: isLight ? const Color(0xFF008744) : AppTheme.neonGreen,
                    ),
                    onPressed: () => NotificacoesSheet.abrir(context),
                  ),
                  IconButton(
                    tooltip: 'Sair da conta',
                    icon: const Icon(Icons.logout_rounded, color: AppTheme.performanceRed, size: 20),
                    onPressed: () async {
                      await ApiService().logout();
                      if (!context.mounted) return;
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: bodyContent,
        ),
      ),
      bottomNavigationBar: isDesktop
          ? null
          : NavigationBar(
              selectedIndex: _abaAtual,
              backgroundColor: AppTheme.surfaceCard,
              indicatorColor: AppTheme.neonGreen.withValues(alpha: 0.20),
              onDestinationSelected: (i) => setState(() => _abaAtual = i),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.list_alt_outlined),
                  selectedIcon: Icon(Icons.list_alt_rounded, color: AppTheme.neonGreen),
                  label: 'Meus Treinos',
                ),
                NavigationDestination(
                  icon: Icon(Icons.restaurant_menu_outlined),
                  selectedIcon: Icon(Icons.restaurant_menu_rounded, color: AppTheme.neonGreen),
                  label: 'Minha Dieta',
                ),
                NavigationDestination(
                  icon: Icon(Icons.show_chart_outlined),
                  selectedIcon: Icon(Icons.show_chart_rounded, color: AppTheme.neonGreen),
                  label: 'Evolução',
                ),
                NavigationDestination(
                  icon: Icon(Icons.paid_outlined),
                  selectedIcon: Icon(Icons.paid_rounded, color: AppTheme.neonGreen),
                  label: 'Financeiro PIX',
                ),
              ],
            ),
    );
  }

  Widget _buildTopNavTab(int index, IconData icon, String label, bool isLight) {
    final selected = _abaAtual == index;
    final activeColor = isLight ? const Color(0xFF008744) : AppTheme.neonGreen;

    return InkWell(
      onTap: () => setState(() => _abaAtual = index),
      child: Container(
        height: 68,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? activeColor : Colors.transparent,
              width: 2.5,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 19,
              color: selected ? activeColor : AppTheme.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? activeColor : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── ABA 1: MEUS TREINOS (DIVISÕES A, B, C...) + AGENDA + EXECUÇÃO ANIMADA ────
  Widget _buildAbaMeusTreinos(bool isLight, Color borderSubtle) {
    final accentGreen = isLight ? const Color(0xFF008744) : AppTheme.neonGreen;

    return RefreshIndicator(
      onRefresh: _carregarDadosAluno,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        children: [
          // Header de Telemetria de Frequência + Botão Exportar PDF
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 14,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Frequência de Treino',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.7,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 20,
                        fontFamily: 'Plus Jakarta Sans',
                        color: AppTheme.textSecondary,
                      ),
                      children: [
                        TextSpan(
                          text: '$_treinosMes ',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: accentGreen,
                          ),
                        ),
                        const TextSpan(
                          text: 'Treinos no Mês   •   ',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        TextSpan(
                          text: '$_treinosTotal ',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: accentGreen,
                          ),
                        ),
                        const TextSpan(
                          text: 'Acumulados',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (_fichas.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () => FichaPdfService.exportarFichaPdf(
                    nomeAluno: _aluno['nome']?.toString() ?? 'Aluno',
                    objetivo: _aluno['objetivo']?.toString() ?? 'Hipertrofia',
                    nomePersonal: _aluno['nomePersonal']?.toString() ?? _nomePersonal,
                    crefPersonal: _aluno['crefPersonal']?.toString() ?? '',
                    fichas: _fichas,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textPrimary,
                    side: BorderSide(color: borderSubtle, width: 1.2),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Icon(Icons.picture_as_pdf_outlined, size: 18, color: AppTheme.textSecondary),
                  label: const Text(
                    'Exportar PDF',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                  ),
                ),
            ],
          ),

          if (_minhasAulasAgenda.isNotEmpty) ...[
            const SizedBox(height: 22),
            Builder(
              builder: (_) {
                final ag = _minhasAulasAgenda.first;
                final dt = DateTime.tryParse((ag['dataHoraInicio'] ?? '').toString()) ?? DateTime.now();
                final fmt = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} às ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderSubtle, width: 1.1),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 18, color: AppTheme.textSecondary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 13.5,
                              fontFamily: 'Plus Jakarta Sans',
                              color: AppTheme.textSecondary,
                            ),
                            children: [
                              const TextSpan(text: 'Próxima sessão agendada com o Personal: '),
                              TextSpan(
                                text: '$fmt — ${ag['tituloTreino']} (${ag['status']})',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],

          const SizedBox(height: 24),

          if (_fichas.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: borderSubtle, width: 1.2),
              ),
              child: Column(
                children: [
                  Icon(Icons.fitness_center_outlined, size: 48, color: AppTheme.textSecondary),
                  const SizedBox(height: 14),
                  Text(
                    'Nenhuma Ficha de Treino Ativa no Momento',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Seu Personal Trainer ainda está finalizando a periodização das suas divisões de treino. Assim que publicada, ela aparecerá aqui instantaneamente com vídeos demonstrativos em PT-BR.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13.5, height: 1.5, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),

          ..._fichas.asMap().entries.map((entry) {
            final idx = entry.key;
            final fichaMap = Map<String, dynamic>.from(entry.value);
            final fichaId = (fichaMap['id'] as int?) ?? idx;
            final recolhida = _fichasRecolhidas.contains(fichaId);
            final exercicios = (fichaMap['exercicios'] as List<dynamic>?) ?? [];
            final nomeDivisao = fichaMap['nomeDivisao']?.toString() ?? 'Treino';
            final descricao = fichaMap['descricao']?.toString() ?? '';
            final tituloCompleto = descricao.isNotEmpty
                ? '$nomeDivisao — $descricao'
                : nomeDivisao;

            return Container(
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: borderSubtle, width: 1.2),
              ),
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        setState(() {
                          if (recolhida) {
                            _fichasRecolhidas.remove(fichaId);
                          } else {
                            _fichasRecolhidas.add(fichaId);
                          }
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                tituloCompleto,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${exercicios.length} exercícios (PT-BR)',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: accentGreen,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              recolhida
                                  ? Icons.keyboard_arrow_down_rounded
                                  : Icons.keyboard_arrow_up_rounded,
                              color: AppTheme.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (!recolhida) ...[
                      if (exercicios.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 126,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: exercicios.length,
                            separatorBuilder: (_, _) => const SizedBox(width: 14),
                            itemBuilder: (ctx, i) {
                              final exMap = Map<String, dynamic>.from(exercicios[i] as Map);
                              return ExercicioAnimadoThumbnail(
                                nomeExercicio: (exMap['nomeExercicio'] ?? '').toString(),
                                grupoMuscular: (exMap['grupoMuscular'] ?? '').toString(),
                                videoUrl: exMap['videoUrl']?.toString(),
                                width: 210,
                                height: 126,
                                onTap: () => ExercicioExecucaoModal.abrir(context, exMap),
                              );
                            },
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: 0.38,
                          minHeight: 3.5,
                          color: accentGreen,
                          backgroundColor: borderSubtle,
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () => _abrirModoExecucaoTreino(fichaMap),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.neonGreen,
                            foregroundColor: const Color(0xFF0A0E12),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'INICIAR EXECUÇÃO NA ACADEMIA (VÍDEOS PT-BR & CRONÔMETRO)',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─── ABA 2: MINHA DIETA & MACROS (TMB / GET / REFEIÇÕES) ─────────────────────
  Widget _buildAbaMinhaDietaAluno(bool isLight, Color borderSubtle) {
    final plano = _meuPlanoDieta;
    final accentGreen = isLight ? const Color(0xFF008744) : AppTheme.neonGreen;

    if (plano == null) {
      return Center(
        child: Text(
          'Seu Personal Trainer ainda está configurando seu Plano Alimentar.',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderSubtle, width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (plano['titulo'] ?? 'Meu Plano Alimentar').toString(),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Objetivo: ${plano['objetivo']} • Prescrito por $_nomePersonal',
                        style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                  OutlinedButton.icon(
                    onPressed: () => DietaPdfService.exportarPlanoAlimentarPdf(
                      nomeAluno: _aluno['nome']?.toString() ?? 'Aluno',
                      nomePersonal: _nomePersonal,
                      plano: plano,
                      refeicoes: _minhasRefeicoes,
                    ),
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                    label: const Text('Exportar Dieta PDF'),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _statPill('META CALÓRICA', '${plano['metaKcal']} kcal', accentGreen),
                  _statPill('PROTEÍNAS', '${plano['proteinaG']}g', const Color(0xFFFF5252)),
                  _statPill('CARBOIDRATOS', '${plano['carboidratoG']}g', AppTheme.warningAmber),
                  _statPill('GORDURAS', '${plano['gorduraG']}g', Colors.orange),
                  _statPill('META DE ÁGUA', '${plano['aguaLitros']} Litros', AppTheme.electricBlue),
                ],
              ),
              if ((plano['observacoes'] ?? '').toString().isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  'Recomendação do Personal: ${plano['observacoes']}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Refeições do Dia e Opções de Substituição',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ..._minhasRefeicoes.map((r) {
          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: 10,
                  runSpacing: 6,
                  children: [
                    Text(
                      '${r['horario']} — ${r['nomeRefeicao']}',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15.5,
                        color: accentGreen,
                      ),
                    ),
                    Text(
                      '${r['kcalEstimada']} kcal  (P: ${r['proteinaG']}g • C: ${r['carboG']}g • G: ${r['gorduraG']}g)',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  (r['alimentosDescricao'] ?? '').toString(),
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: AppTheme.textPrimary,
                  ),
                ),
                if ((r['substituicoes'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: accentGreen.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: accentGreen.withValues(alpha: 0.28)),
                    ),
                    child: Text(
                      'Substituições equivalentes: ${r['substituicoes']}',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: accentGreen,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }

  // ─── ABA 3: MINHA EVOLUÇÃO, GRÁFICOS & COMPOSIÇÃO CORPORAL ──────────────────
  Widget _buildAbaMinhaEvolucao(bool isLight, Color borderSubtle) {
    final ultimaAval = _avaliacoes.isNotEmpty ? _avaliacoes.first : null;
    final accentGreen = isLight ? const Color(0xFF008744) : AppTheme.neonGreen;
    Map<String, dynamic> medidas = {};
    if (ultimaAval != null && ultimaAval['medidasJson'] != null) {
      try {
        medidas = Map<String, dynamic>.from(jsonDecode(ultimaAval['medidasJson'].toString()));
      } catch (_) {}
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      children: [
        EvolucaoCompletaPanel(
          avaliacoes: _avaliacoes,
          progressaoCargas: _progressaoCargas,
        ),
        const SizedBox(height: 20),
        Text(
          'Composição Corporal e Avaliação Física',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        if (ultimaAval != null)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    _statPill('PESO ATUAL', '${ultimaAval['peso']} kg', accentGreen),
                    _statPill('ALTURA', '${ultimaAval['altura']} m', AppTheme.electricBlue),
                    _statPill(
                      '% GORDURA (BF)',
                      '${ultimaAval['percentualGordura'] ?? '-'}%',
                      AppTheme.warningAmber,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (medidas.isNotEmpty) ...[
                  Text(
                    'Circunferências Corporais (cm)',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: medidas.entries
                        .map(
                          (e) => Chip(
                            backgroundColor: AppTheme.bgDark,
                            label: Text('${e.key}: ${e.value} cm'),
                          ),
                        )
                        .toList(),
                  ),
                ],
                const SizedBox(height: 10),
                Text(
                  'Restrições / Lesões: ${ultimaAval['restricoesLesoes'] ?? 'Nenhuma'}',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  'Parecer Técnico do Personal: ${ultimaAval['observacoes'] ?? '-'}',
                  style: TextStyle(
                    color: accentGreen,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 24),
        Text(
          'Histórico de Treinos Realizados',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ..._historicoTreinos.map((h) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderSubtle),
            ),
            child: ListTile(
              leading: Icon(Icons.check_circle_outline_rounded, color: accentGreen),
              title: Text(
                h['nomeTreino']?.toString() ?? '',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              subtitle: Text(
                'Duração: ${h['duracaoMinutos']} min • ${h['observacaoAluno'] ?? 'Concluído'}',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5),
              ),
            ),
          );
        }),
      ],
    );
  }

  // ─── ABA 4: FINANCEIRO & PAGAR COM PIX ───────────────────────────────────────
  Widget _buildAbaFinanceiroAluno(bool isLight, Color borderSubtle) {
    final accentGreen = isLight ? const Color(0xFF008744) : AppTheme.neonGreen;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderSubtle),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: Icon(Icons.verified_user_outlined, color: accentGreen, size: 30),
            title: Text(
              'Consultoria: $_nomePersonal',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            subtitle: Text(
              'Chave PIX Oficial: $_chavePixPersonal',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            trailing: OutlinedButton.icon(
              onPressed: () => WhatsAppService.abrirMensagem(
                _aluno['telefonePersonal']?.toString(),
                'Olá, Professor! Estou falando pelo app PersonalPro.',
              ),
              icon: Icon(Icons.chat_bubble_outline_rounded, size: 16, color: accentGreen),
              label: const Text('Falar com Personal'),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Minhas Mensalidades',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ..._pagamentos.map((p) {
          final pago = p['status'] == 'PAGO';
          final valor = (p['valor'] ?? 0).toDouble();

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderSubtle),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Competência: ${p['mesReferencia']}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'R\$ ${valor.toStringAsFixed(2)} • Status: ${pago ? 'EM DIA (PAGO)' : 'PENDENTE'}',
                        style: TextStyle(
                          color: pago ? accentGreen : AppTheme.warningAmber,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!pago)
                  ElevatedButton.icon(
                    onPressed: () => PixModal.mostrar(
                      context,
                      nomeBeneficiario: _nomePersonal,
                      chavePix: _chavePixPersonal,
                      valor: valor,
                      mesReferencia: p['mesReferencia']?.toString() ?? '',
                      pixCopiaECola: p['pixCopiaECola']?.toString() ?? '',
                    ),
                    icon: const Icon(Icons.pix),
                    label: const Text('PAGAR COM PIX'),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _statPill(String titulo, String valor, Color cor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cor.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            valor,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: cor,
            ),
          ),
        ],
      ),
    );
  }
}

// ====================================================================================
// TELA INTERATIVA DE EXECUÇÃO DE TREINO NA ACADEMIA (CHECKLIST + CARGA + CRONÔMETRO)
// ====================================================================================
class ModoExecucaoTreinoScreen extends StatefulWidget {
  final Map<String, dynamic> ficha;
  final String nomeAluno;
  final VoidCallback onTreinoConcluido;

  const ModoExecucaoTreinoScreen({
    super.key,
    required this.ficha,
    required this.nomeAluno,
    required this.onTreinoConcluido,
  });

  @override
  State<ModoExecucaoTreinoScreen> createState() => _ModoExecucaoTreinoScreenState();
}

class _ModoExecucaoTreinoScreenState extends State<ModoExecucaoTreinoScreen> {
  late List<Map<String, dynamic>> _exercicios;
  final Set<int> _exerciciosConcluidos = {};
  final Set<int> _exerciciosComVideoInline = {};
  final DateTime _inicioTreino = DateTime.now();

  Timer? _timerDescanso;
  int _segundosRestantes = 0;
  int _segundosTotaisCronometro = 60;
  bool _finalizando = false;

  @override
  void initState() {
    super.initState();
    final rawList = (widget.ficha['exercicios'] as List<dynamic>?) ?? [];
    _exercicios = rawList.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  @override
  void dispose() {
    _timerDescanso?.cancel();
    super.dispose();
  }

  void _iniciarCronometroDescanso(int segundos) {
    _timerDescanso?.cancel();
    setState(() {
      _segundosTotaisCronometro = segundos > 0 ? segundos : 60;
      _segundosRestantes = _segundosTotaisCronometro;
    });

    _timerDescanso = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_segundosRestantes <= 1) {
        timer.cancel();
        setState(() => _segundosRestantes = 0);
        HapticFeedback.heavyImpact();
        NotificationService.exibirNotificacaoLocal(
          titulo: 'Descanso Finalizado!',
          corpo: 'Hora da próxima série! Vamos pra cima!',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppTheme.neonGreen,
            duration: Duration(seconds: 3),
            content: Text(
              'TEMPO DE DESCANSO CONCLUÍDO! Hora da próxima série.',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800),
            ),
          ),
        );
      } else {
        setState(() => _segundosRestantes--);
      }
    });
  }

  Future<void> _alterarCarga(int index, double delta) async {
    final ex = _exercicios[index];
    final atual = ((ex['cargaKg'] ?? 0) as num).toDouble();
    final novaCarga = (atual + delta).clamp(0.0, 999.0);
    setState(() {
      _exercicios[index]['cargaKg'] = novaCarga;
    });

    try {
      await ApiService().dio.patch(
        '/api/aluno/exercicios/${ex['id']}/carga',
        data: {'cargaKg': novaCarga},
      );
    } catch (_) {}
  }

  Future<void> _finalizarTreinoDeHoje() async {
    setState(() => _finalizando = true);
    final duracaoMin = DateTime.now().difference(_inicioTreino).inMinutes.clamp(25, 120);

    try {
      final resp = await ApiService().dio.post('/api/aluno/finalizar-treino', data: {
        'fichaId': widget.ficha['id'],
        'nomeTreino': widget.ficha['nomeDivisao'],
        'duracaoMinutos': duracaoMin,
        'observacaoAluno':
            'Concluídos ${_exerciciosConcluidos.length}/${_exercicios.length} exercícios com progressão de carga!',
      });

      if (!mounted) return;
      widget.onTreinoConcluido();

      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.surfaceCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.emoji_events_outlined, color: AppTheme.neonGreen, size: 30),
              SizedBox(width: 10),
              Expanded(child: Text('Treino Finalizado!')),
            ],
          ),
          content: Text(
            resp.data['mensagem']?.toString() ??
                'Seu Personal Trainer acabou de receber a confirmação de conclusão do seu treino!',
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text('VOLTAR PARA MEUS TREINOS'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _finalizando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLight = AppTheme.isLight;
    final accentGreen = isLight ? const Color(0xFF008744) : AppTheme.neonGreen;
    final borderSubtle = isLight
        ? const Color(0xFF0F172A).withValues(alpha: 0.10)
        : Colors.white.withValues(alpha: 0.10);

    final progresso = _exercicios.isEmpty
        ? 1.0
        : (_exerciciosConcluidos.length / _exercicios.length);

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: Text(
          widget.ficha['nomeDivisao']?.toString() ?? 'Execução de Treino',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: BotaoAlternarTema(mostrarTexto: true),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              border: Border(bottom: BorderSide(color: borderSubtle)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progresso: ${_exerciciosConcluidos.length} de ${_exercicios.length} exercícios concluídos',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      '${(progresso * 100).round()}%',
                      style: TextStyle(
                        color: accentGreen,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progresso,
                  minHeight: 7,
                  borderRadius: BorderRadius.circular(8),
                  color: accentGreen,
                  backgroundColor: borderSubtle,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: _segundosRestantes > 0
                        ? accentGreen.withValues(alpha: 0.14)
                        : AppTheme.bgDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _segundosRestantes > 0 ? accentGreen : borderSubtle,
                    ),
                  ),
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            color: _segundosRestantes > 0
                                ? accentGreen
                                : AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              _segundosRestantes > 0
                                  ? 'CRONÔMETRO DE DESCANSO: ${_segundosRestantes}s'
                                  : 'Cronômetro de Descanso Regressivo:',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: _segundosRestantes > 0
                                    ? accentGreen
                                    : AppTheme.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _timerBtn(45, accentGreen),
                          const SizedBox(width: 6),
                          _timerBtn(60, accentGreen),
                          const SizedBox(width: 6),
                          _timerBtn(90, accentGreen),
                          if (_segundosRestantes > 0) ...[
                            const SizedBox(width: 6),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.stop_circle_outlined, color: AppTheme.performanceRed),
                              onPressed: () {
                                _timerDescanso?.cancel();
                                setState(() => _segundosRestantes = 0);
                              },
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(18),
              itemCount: _exercicios.length,
              itemBuilder: (context, index) {
                final ex = _exercicios[index];
                final id = ex['id'] as int;
                final concluido = _exerciciosConcluidos.contains(id);
                final videoAberto = _exerciciosComVideoInline.contains(id);
                final descanso = (ex['descansoSegundos'] ?? 60) as int;
                final carga = ((ex['cargaKg'] ?? 0) as num).toDouble();

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: concluido
                          ? accentGreen
                          : (videoAberto ? accentGreen.withValues(alpha: 0.6) : borderSubtle),
                      width: concluido ? 1.8 : 1.1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isMobileCard = constraints.maxWidth < 540;
                            final btnVideo = ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: videoAberto
                                    ? AppTheme.surfaceElevated
                                    : AppTheme.neonGreen,
                                foregroundColor: videoAberto
                                    ? accentGreen
                                    : const Color(0xFF0A0E12),
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              onPressed: () {
                                setState(() {
                                  if (videoAberto) {
                                    _exerciciosComVideoInline.remove(id);
                                  } else {
                                    _exerciciosComVideoInline.add(id);
                                  }
                                });
                              },
                              icon: Icon(
                                videoAberto ? Icons.stop_circle_outlined : Icons.play_circle_outline_rounded,
                                size: 16,
                              ),
                              label: Text(
                                videoAberto ? 'Fechar Vídeo' : 'Ver Vídeo PT-BR',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                              ),
                            );

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Checkbox(
                                      value: concluido,
                                      activeColor: AppTheme.neonGreen,
                                      checkColor: Colors.black,
                                      onChanged: (v) {
                                        setState(() {
                                          if (v == true) {
                                            _exerciciosConcluidos.add(id);
                                            _iniciarCronometroDescanso(descanso);
                                          } else {
                                            _exerciciosConcluidos.remove(id);
                                          }
                                        });
                                      },
                                    ),
                                    ExercicioAnimadoThumbnail(
                                      nomeExercicio: (ex['nomeExercicio'] ?? '').toString(),
                                      grupoMuscular: (ex['grupoMuscular'] ?? '').toString(),
                                      videoUrl: ex['videoUrl']?.toString(),
                                      width: 108,
                                      height: 74,
                                      onTap: () {
                                        setState(() {
                                          if (videoAberto) {
                                            _exerciciosComVideoInline.remove(id);
                                          } else {
                                            _exerciciosComVideoInline.add(id);
                                          }
                                        });
                                      },
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            ex['nomeExercicio']?.toString() ?? '',
                                            style: TextStyle(
                                              fontSize: 15.5,
                                              fontWeight: FontWeight.w800,
                                              color: AppTheme.textPrimary,
                                              decoration: concluido
                                                  ? TextDecoration.lineThrough
                                                  : null,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${ex['grupoMuscular']} • ${ex['series']} séries x ${ex['repeticoes']} reps',
                                            style: TextStyle(
                                              color: accentGreen,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (!isMobileCard) ...[
                                      const SizedBox(width: 8),
                                      btnVideo,
                                    ],
                                  ],
                                ),
                                if (isMobileCard) ...[
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 6,
                                    children: [
                                      btnVideo,
                                      OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          visualDensity: VisualDensity.compact,
                                        ),
                                        onPressed: () => ExercicioExecucaoModal.abrir(context, ex),
                                        icon: const Icon(Icons.open_in_full, size: 14),
                                        label: const Text('Guia Técnico'),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            );
                          },
                        ),
                        if (videoAberto)
                          PlayerVideoExercicioInline(
                            nomeExercicio: (ex['nomeExercicio'] ?? '').toString(),
                            grupoMuscular: (ex['grupoMuscular'] ?? '').toString(),
                            videoUrl: ex['videoUrl']?.toString(),
                            exercicioId: id,
                            onFechar: () => setState(() => _exerciciosComVideoInline.remove(id)),
                            onAbrirModalCompleto: () => ExercicioExecucaoModal.abrir(context, ex),
                          ),
                        if ((ex['observacaoTecnica']?.toString() ?? '').isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.bgDark,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Instrução do Personal: ${ex['observacaoTecnica']}',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 10,
                          runSpacing: 8,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Carga (kg): ',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () => _alterarCarga(index, -2.5),
                                  icon: const Icon(Icons.remove_circle_outline),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.bgDark,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${carga.toStringAsFixed(1)} kg',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: accentGreen,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () => _alterarCarga(index, 2.5),
                                  icon: Icon(
                                    Icons.add_circle_outline,
                                    color: accentGreen,
                                  ),
                                ),
                              ],
                            ),
                            OutlinedButton.icon(
                              onPressed: () => _iniciarCronometroDescanso(descanso),
                              icon: const Icon(Icons.timer_outlined, size: 16),
                              label: Text('Descansar ${descanso}s'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _finalizando ? null : _finalizarTreinoDeHoje,
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 22),
                  label: Text(
                    _finalizando
                        ? 'ENVIANDO NOTIFICAÇÃO AO PERSONAL...'
                        : 'FINALIZAR TREINO DE HOJE',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _timerBtn(int seg, Color accentGreen) {
    return InkWell(
      onTap: () => _iniciarCronometroDescanso(seg),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: accentGreen.withValues(alpha: 0.4)),
        ),
        child: Text(
          '${seg}s',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: accentGreen,
          ),
        ),
      ),
    );
  }
}

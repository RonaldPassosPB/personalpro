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
      final results = await Future.wait([
        ApiService().dio.get('/api/aluno/home'),
        ApiService().dio.get('/api/aluno/evolucao'),
        ApiService().dio.get('/api/aluno/financeiro'),
        ApiService().dio.get('/api/dieta/minha-dieta'),
        ApiService().dio.get('/api/agenda/minhas-aulas'),
      ]);

      final homeData = results[0].data;
      final evoData = results[1].data;
      final finData = results[2].data;
      final dietaData = results[3].data;
      final agendaData = results[4].data as List<dynamic>? ?? [];

      if (!mounted) return;
      setState(() {
        _aluno = Map<String, dynamic>.from(homeData['aluno'] ?? {});
        _fichas = homeData['fichas'] ?? [];
        _treinosMes = homeData['treinosMes'] ?? 0;
        _treinosTotal = homeData['treinosTotal'] ?? 0;
        _avaliacoes = evoData['avaliacoes'] ?? [];
        _historicoTreinos = evoData['historicoTreinos'] ?? [];
        _progressaoCargas = evoData['progressaoCargas'] ?? [];
        _meuPlanoDieta = dietaData['plano'] != null
            ? Map<String, dynamic>.from(dietaData['plano'])
            : null;
        _minhasRefeicoes = dietaData['refeicoes'] ?? [];
        _minhasAulasAgenda = agendaData;
        _pagamentos = finData['pagamentos'] ?? [];
        _chavePixPersonal = finData['chavePixPersonal']?.toString() ?? '';
        _nomePersonal = finData['nomePersonal']?.toString() ?? 'PersonalPro';
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
    final appBarWidget = AppBar(
      title: Row(
        children: [
          InkWell(
            onTap: () async {
              final novaFoto = await ImageHelper.selecionarImagemBase64();
              if (novaFoto != null) {
                await ApiService().dio.put('/api/aluno/foto-perfil', data: {
                  'fotoUrl': novaFoto,
                });
                _carregarDadosAluno();
              }
            },
            child: ImageHelper.renderAvatarOrImage(
              _aluno['fotoUrl']?.toString(),
              radius: 20,
              fallbackText: _aluno['nome']?.toString() ?? 'A',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Olá, ${_aluno['nome'] ?? widget.session['nome'] ?? 'Atleta'}! 💪',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Personal: ${_aluno['nomePersonal'] ?? _nomePersonal} • Toque na foto p/ alterar',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Notificações',
          icon: const Icon(Icons.notifications_active_outlined, color: AppTheme.neonGreen),
          onPressed: () => NotificacoesSheet.abrir(context),
        ),
        IconButton(
          tooltip: 'Sair',
          icon: const Icon(Icons.logout, color: AppTheme.performanceRed),
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
    );

    final bodyContent = _carregando
        ? const Center(child: CircularProgressIndicator())
        : IndexedStack(
            index: _abaAtual,
            children: [
              _buildAbaMeusTreinos(),
              _buildAbaMinhaDietaAluno(),
              _buildAbaMinhaEvolucao(),
              _buildAbaFinanceiroAluno(),
            ],
          );

    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      appBar: appBarWidget,
      body: isDesktop
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: _abaAtual,
                  backgroundColor: const Color(0xFF13151B),
                  indicatorColor: AppTheme.neonGreen.withValues(alpha: 0.22),
                  labelType: NavigationRailLabelType.all,
                  onDestinationSelected: (i) => setState(() => _abaAtual = i),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.ondemand_video_outlined),
                      selectedIcon: Icon(Icons.ondemand_video, color: AppTheme.neonGreen),
                      label: Text('Treinos (Vídeo)'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.restaurant_menu_outlined),
                      selectedIcon: Icon(Icons.restaurant_menu, color: AppTheme.neonGreen),
                      label: Text('Minha Dieta'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.insights_outlined),
                      selectedIcon: Icon(Icons.insights, color: AppTheme.neonGreen),
                      label: Text('Minha Evolução'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.pix_outlined),
                      selectedIcon: Icon(Icons.pix, color: AppTheme.neonGreen),
                      label: Text('Financeiro PIX'),
                    ),
                  ],
                ),
                const VerticalDivider(width: 1, color: Colors.white10),
                Expanded(child: bodyContent),
              ],
            )
          : bodyContent,
      bottomNavigationBar: isDesktop
          ? null
          : NavigationBar(
              selectedIndex: _abaAtual,
              backgroundColor: const Color(0xFF16181D),
              indicatorColor: AppTheme.neonGreen.withValues(alpha: 0.22),
              onDestinationSelected: (i) => setState(() => _abaAtual = i),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.ondemand_video_outlined),
                  selectedIcon: Icon(Icons.ondemand_video, color: AppTheme.neonGreen),
                  label: 'Treinos (Vídeo)',
                ),
                NavigationDestination(
                  icon: Icon(Icons.restaurant_menu_outlined),
                  selectedIcon: Icon(Icons.restaurant_menu, color: AppTheme.neonGreen),
                  label: 'Minha Dieta',
                ),
                NavigationDestination(
                  icon: Icon(Icons.insights_outlined),
                  selectedIcon: Icon(Icons.insights, color: AppTheme.neonGreen),
                  label: 'Evolução',
                ),
                NavigationDestination(
                  icon: Icon(Icons.pix_outlined),
                  selectedIcon: Icon(Icons.pix, color: AppTheme.neonGreen),
                  label: 'Financeiro PIX',
                ),
              ],
            ),
    );
  }

  // ─── ABA 1: MEUS TREINOS (DIVISÕES A, B, C...) + AGENDA + EXECUÇÃO ANIMADA ────
  Widget _buildAbaMeusTreinos() {
    return RefreshIndicator(
      onRefresh: _carregarDadosAluno,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Banner de Frequência do Aluno
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.neonGreen.withValues(alpha: 0.22),
                  AppTheme.surfaceCard,
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.neonGreen.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_fire_department, color: AppTheme.neonGreen, size: 42),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$_treinosMes TREINOS CONCLUÍDOS ESTE MÊS!',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: AppTheme.neonGreen,
                        ),
                      ),
                      Text(
                        'Total acumulado: $_treinosTotal treinos • Toque em qualquer exercício para ver o GIF/Vídeo de execução!',
                        style: const TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                if (_fichas.isNotEmpty)
                  IconButton(
                    tooltip: 'Exportar Minha Ficha em PDF',
                    icon: const Icon(Icons.picture_as_pdf, color: AppTheme.neonGreen),
                    onPressed: () => FichaPdfService.exportarFichaPdf(
                      nomeAluno: _aluno['nome']?.toString() ?? 'Aluno',
                      objetivo: _aluno['objetivo']?.toString() ?? 'Hipertrofia',
                      nomePersonal: _aluno['nomePersonal']?.toString() ?? _nomePersonal,
                      crefPersonal: _aluno['crefPersonal']?.toString() ?? '',
                      fichas: _fichas,
                    ),
                  ),
              ],
            ),
          ),

          if (_minhasAulasAgenda.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF141B24),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.35)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.calendar_month, color: Colors.cyanAccent, size: 18),
                      SizedBox(width: 8),
                      Text(
                        '📅 SUAS PRÓXIMAS AULAS / AVALIAÇÕES AGENDADAS COM O PERSONAL',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Colors.cyanAccent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ..._minhasAulasAgenda.take(2).map((ag) {
                    final dt = DateTime.tryParse((ag['dataHoraInicio'] ?? '').toString()) ?? DateTime.now();
                    final fmt = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} às ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '• $fmt — ${ag['tituloTreino']} (${ag['status']})',
                        style: const TextStyle(fontSize: 12.5, color: Colors.white),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),
          const Text(
            '🏋️ SUAS DIVISÕES DE TREINO ATIVAS (COM DEMONSTRAÇÃO ANIMADA DE EXECUÇÃO)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),

          ..._fichas.map((f) {
            final fichaMap = Map<String, dynamic>.from(f);
            final exercicios = (fichaMap['exercicios'] as List<dynamic>?) ?? [];

            return Card(
              margin: const EdgeInsets.only(bottom: 14),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _abrirModoExecucaoTreino(fichaMap),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.neonGreen,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              fichaMap['nomeDivisao']?.toString() ?? 'Treino',
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${exercicios.length} exercícios com GIF/Animação',
                            style: const TextStyle(
                              color: AppTheme.neonGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                      if ((fichaMap['descricao']?.toString() ?? '').isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          fichaMap['descricao'].toString(),
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                        ),
                      ],
                      if (exercicios.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 86,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: exercicios.length,
                            separatorBuilder: (_, _) => const SizedBox(width: 10),
                            itemBuilder: (ctx, i) {
                              final exMap = Map<String, dynamic>.from(exercicios[i] as Map);
                              return ExercicioAnimadoThumbnail(
                                nomeExercicio: (exMap['nomeExercicio'] ?? '').toString(),
                                grupoMuscular: (exMap['grupoMuscular'] ?? '').toString(),
                                videoUrl: exMap['videoUrl']?.toString(),
                                onTap: () => ExercicioExecucaoModal.abrir(context, exMap),
                              );
                            },
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _abrirModoExecucaoTreino(fichaMap),
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('ABRIR MODO EXECUÇÃO NA ACADEMIA (COM GIFS & CRONÔMETRO)'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─── ABA 2: MINHA DIETA & MACROS (TMB / GET / REFEIÇÕES) ─────────────────────
  Widget _buildAbaMinhaDietaAluno() {
    final plano = _meuPlanoDieta;
    if (plano == null) {
      return const Center(
        child: Text('Seu Personal Trainer ainda está configurando seu Plano Alimentar.'),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.neonGreen.withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🥗 ${plano['titulo'] ?? 'Meu Plano Alimentar'}',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.neonGreen,
                          ),
                        ),
                        Text(
                          'Objetivo: ${plano['objetivo']} • Prescrito por $_nomePersonal',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => DietaPdfService.exportarPlanoAlimentarPdf(
                      nomeAluno: _aluno['nome']?.toString() ?? 'Aluno',
                      nomePersonal: _nomePersonal,
                      plano: plano,
                      refeicoes: _minhasRefeicoes,
                    ),
                    icon: const Icon(Icons.picture_as_pdf, size: 16),
                    label: const Text('Baixar Dieta PDF'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _statPill('META CALÓRICA', '${plano['metaKcal']} kcal', AppTheme.neonGreen),
                  _statPill('PROTEÍNAS', '${plano['proteinaG']}g', const Color(0xFFFF5252)),
                  _statPill('CARBOIDRATOS', '${plano['carboidratoG']}g', Colors.amberAccent),
                  _statPill('GORDURAS', '${plano['gorduraG']}g', Colors.orangeAccent),
                  _statPill('META DE ÁGUA', '${plano['aguaLitros']} Litros', Colors.cyanAccent),
                ],
              ),
              if ((plano['observacoes'] ?? '').toString().isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  '💡 Recomendação do Personal: ${plano['observacoes']}',
                  style: const TextStyle(fontSize: 12.5, color: Colors.amberAccent),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          '🍽️ SUAS REFEIÇÕES DO DIA E OPÇÕES DE SUBSTITUIÇÃO',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        ..._minhasRefeicoes.map((r) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '⏰ ${r['horario']} — ${r['nomeRefeicao']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          color: AppTheme.neonGreen,
                        ),
                      ),
                      Text(
                        '${r['kcalEstimada']} kcal (P:${r['proteinaG']}g | C:${r['carboG']}g | G:${r['gorduraG']}g)',
                        style: const TextStyle(fontSize: 12, color: Colors.cyanAccent),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    (r['alimentosDescricao'] ?? '').toString(),
                    style: const TextStyle(fontSize: 13.5, height: 1.45),
                  ),
                  if ((r['substituicoes'] ?? '').toString().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.neonGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '🔄 Opções de Substituição: ${r['substituicoes']}',
                        style: const TextStyle(fontSize: 12, color: AppTheme.neonGreen),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // ─── ABA 2: MINHA EVOLUÇÃO, GRÁFICOS & FOTOS ANTES x DEPOIS ──────────────────
  Widget _buildAbaMinhaEvolucao() {
    final ultimaAval = _avaliacoes.isNotEmpty ? _avaliacoes.first : null;
    Map<String, dynamic> medidas = {};
    if (ultimaAval != null && ultimaAval['medidasJson'] != null) {
      try {
        medidas = Map<String, dynamic>.from(jsonDecode(ultimaAval['medidasJson'].toString()));
      } catch (_) {}
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        EvolucaoCompletaPanel(
          avaliacoes: _avaliacoes,
          progressaoCargas: _progressaoCargas,
        ),
        const SizedBox(height: 16),
        const Text(
          '📏 MINHA FICHA FÍSICA & COMPOSIÇÃO CORPORAL',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        if (ultimaAval != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 16,
                    runSpacing: 12,
                    children: [
                      _statPill('PESO ATUAL', '${ultimaAval['peso']} kg', AppTheme.neonGreen),
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
                    const Text(
                      'Circunferências Corporais (cm):',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
                    '🩺 Restrições / Lesões: ${ultimaAval['restricoesLesoes'] ?? 'Nenhuma'}',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '📝 Parecer do Personal: ${ultimaAval['observacoes'] ?? '-'}',
                    style: const TextStyle(color: AppTheme.neonGreen, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 22),
        const Text(
          '📅 HISTÓRICO DE TREINOS REALIZADOS',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        ..._historicoTreinos.map((h) {
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: const Icon(Icons.check_circle, color: AppTheme.neonGreen),
              title: Text(
                h['nomeTreino']?.toString() ?? '',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'Duração: ${h['duracaoMinutos']} min • ${h['observacaoAluno'] ?? 'Concluído'}',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
            ),
          );
        }),
      ],
    );
  }

  // ─── ABA 3: FINANCEIRO & PAGAR COM PIX ───────────────────────────────────────
  Widget _buildAbaFinanceiroAluno() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.support_agent, color: AppTheme.neonGreen, size: 32),
            title: Text(
              'Consultoria: $_nomePersonal',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Chave PIX Oficial: $_chavePixPersonal'),
            trailing: OutlinedButton.icon(
              onPressed: () => WhatsAppService.abrirMensagem(
                _aluno['telefonePersonal']?.toString(),
                'Olá, Professor! Estou falando pelo app PersonalPro.',
              ),
              icon: const Icon(Icons.chat, size: 16, color: AppTheme.neonGreen),
              label: const Text('Falar com Personal'),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          '💳 MINHAS MENSALIDADES',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        ..._pagamentos.map((p) {
          final pago = p['status'] == 'PAGO';
          final valor = (p['valor'] ?? 0).toDouble();

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Competência: ${p['mesReferencia']}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'R\$ ${valor.toStringAsFixed(2)} • Status: ${pago ? '✅ EM DIA (PAGO)' : '⏳ PENDENTE'}',
                          style: TextStyle(
                            color: pago ? AppTheme.neonGreen : AppTheme.warningAmber,
                            fontWeight: FontWeight.bold,
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
            ),
          );
        }),
      ],
    );
  }

  Widget _statPill(String titulo, String valor, Color cor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cor.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
          Text(valor, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: cor)),
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

  // Cronômetro de descanso regressivo
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
          titulo: '⏰ Descanso Finalizado!',
          corpo: 'Hora da próxima série! Vamos pra cima! 💪🔥',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppTheme.neonGreen,
            duration: Duration(seconds: 3),
            content: Text(
              '🔔 TEMPO DE DESCANSO CONCLUÍDO! Bora para a próxima série! 💪',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900),
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
              Icon(Icons.emoji_events, color: AppTheme.neonGreen, size: 32),
              SizedBox(width: 10),
              Expanded(child: Text('Treino Finalizado! 💪🔥')),
            ],
          ),
          content: Text(
            resp.data['mensagem']?.toString() ??
                'Seu Personal Trainer acabou de receber a notificação da conclusão do seu treino!',
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
    final progresso = _exercicios.isEmpty
        ? 1.0
        : (_exerciciosConcluidos.length / _exercicios.length);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.ficha['nomeDivisao']?.toString() ?? 'Execução de Treino',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Barra de Progresso + Cronômetro de Descanso Regressivo Integrado
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.surfaceCard,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progresso: ${_exerciciosConcluidos.length} de ${_exercicios.length} exercícios concluídos ✅',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    Text(
                      '${(progresso * 100).round()}%',
                      style: const TextStyle(
                        color: AppTheme.neonGreen,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progresso,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(8),
                  color: AppTheme.neonGreen,
                  backgroundColor: Colors.white12,
                ),
                const SizedBox(height: 12),

                // Cronômetro de Descanso Regressivo
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: _segundosRestantes > 0
                        ? AppTheme.neonGreen.withValues(alpha: 0.16)
                        : AppTheme.bgDark,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _segundosRestantes > 0 ? AppTheme.neonGreen : Colors.white12,
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
                            Icons.timer,
                            color: _segundosRestantes > 0
                                ? AppTheme.neonGreen
                                : AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              _segundosRestantes > 0
                                  ? 'CRONÔMETRO DE DESCANSO: ${_segundosRestantes}s'
                                  : 'Cronômetro de Descanso Regressivo:',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: _segundosRestantes > 0
                                    ? AppTheme.neonGreen
                                    : AppTheme.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _timerBtn(45),
                          const SizedBox(width: 6),
                          _timerBtn(60),
                          const SizedBox(width: 6),
                          _timerBtn(90),
                          if (_segundosRestantes > 0) ...[
                            const SizedBox(width: 6),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.stop_circle, color: AppTheme.performanceRed),
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

          // Lista de Exercícios Interativa
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _exercicios.length,
              itemBuilder: (context, index) {
                final ex = _exercicios[index];
                final id = ex['id'] as int;
                final concluido = _exerciciosConcluidos.contains(id);
                final videoAberto = _exerciciosComVideoInline.contains(id);
                final descanso = (ex['descansoSegundos'] ?? 60) as int;
                final carga = ((ex['cargaKg'] ?? 0) as num).toDouble();

                return Card(
                  margin: const EdgeInsets.only(bottom: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: concluido
                          ? AppTheme.neonGreen
                          : (videoAberto
                              ? AppTheme.neonGreen.withValues(alpha: 0.6)
                              : Colors.white12),
                      width: concluido ? 2 : 1,
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
                                    ? AppTheme.surfaceCard
                                    : AppTheme.neonGreen,
                                foregroundColor: videoAberto
                                    ? AppTheme.neonGreen
                                    : Colors.black,
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                                videoAberto ? Icons.stop_circle_outlined : Icons.play_circle_fill,
                                size: 16,
                              ),
                              label: Text(
                                videoAberto ? 'Fechar Vídeo' : '🎬 Ver Vídeo',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
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
                                      width: 96,
                                      height: 70,
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
                                              fontWeight: FontWeight.bold,
                                              decoration: concluido
                                                  ? TextDecoration.lineThrough
                                                  : null,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            '${ex['grupoMuscular']} • ${ex['series']} séries x ${ex['repeticoes']} reps',
                                            style: const TextStyle(
                                              color: AppTheme.neonGreen,
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
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.bgDark,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '💡 Instrução do Personal: ${ex['observacaoTecnica']}',
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),

                        // Controles de Progressão de Carga (kg) + Botão de Descanso
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 10,
                          runSpacing: 8,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Carga (kg): ',
                                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
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
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      color: AppTheme.neonGreen,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () => _alterarCarga(index, 2.5),
                                  icon: const Icon(
                                    Icons.add_circle_outline,
                                    color: AppTheme.neonGreen,
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

          // Botão Grande: FINALIZAR TREINO DE HOJE
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _finalizando ? null : _finalizarTreinoDeHoje,
                  icon: const Icon(Icons.check_circle, size: 24),
                  label: Text(
                    _finalizando
                        ? 'ENVIANDO NOTIFICAÇÃO AO PERSONAL...'
                        : '✅ FINALIZAR TREINO DE HOJE',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _timerBtn(int seg) {
    return InkWell(
      onTap: () => _iniciarCronometroDescanso(seg),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.neonGreen.withValues(alpha: 0.4)),
        ),
        child: Text(
          '${seg}s',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppTheme.neonGreen,
          ),
        ),
      ),
    );
  }
}

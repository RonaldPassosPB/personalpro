import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/ficha_pdf_service.dart';
import '../../services/whatsapp_service.dart';
import '../../theme.dart';
import '../../widgets/evolucao_charts_widget.dart';
import '../../widgets/exercicio_animado_dieta_agenda_widget.dart';
import '../../widgets/notificacoes_sheet.dart';
import '../../widgets/pix_modal.dart';
import '../auth/login_screen.dart';

class PersonalDashboardScreen extends StatefulWidget {
  final Map<String, dynamic> session;
  const PersonalDashboardScreen({super.key, required this.session});

  @override
  State<PersonalDashboardScreen> createState() => _PersonalDashboardScreenState();
}

class _PersonalDashboardScreenState extends State<PersonalDashboardScreen> {
  int _abaAtual = 0;
  bool _carregando = true;

  // Dados Dashboard
  Map<String, dynamic> _personal = {};
  Map<String, dynamic> _metricas = {};
  List<dynamic> _alunosSumidos = [];
  List<dynamic> _ultimosTreinos = [];

  // Dados Alunos
  List<dynamic> _alunos = [];
  int? _alunoSelecionadoTreinoId;
  int? _alunoSelecionadoEvolucaoId;
  List<dynamic> _fichasDoAlunoSelecionado = [];
  List<dynamic> _avaliacoesDoAlunoSelecionado = [];
  List<dynamic> _progressaoCargasDoAlunoSelecionado = [];
  List<dynamic> _exerciciosBiblioteca = [];

  // Dados Financeiro
  Map<String, dynamic> _resumoFinanceiro = {};
  List<dynamic> _pagamentos = [];
  String _chavePixPersonal = '';
  final Set<int> _exerciciosPlayerInlineAbertos = {};

  @override
  void initState() {
    super.initState();
    _carregarTudo();
  }

  Future<void> _carregarTudo() async {
    setState(() => _carregando = true);
    try {
      final results = await Future.wait([
        ApiService().dio.get('/api/personal/dashboard'),
        ApiService().dio.get('/api/personal/alunos'),
        ApiService().dio.get('/api/treinos/exercicios-base'),
        ApiService().dio.get('/api/financeiro/pagamentos'),
      ]);

      final dashData = results[0].data;
      final listaAlunos = results[1].data as List<dynamic>;
      final listaExBase = results[2].data as List<dynamic>;
      final finData = results[3].data;

      int? selAlunoId = _alunoSelecionadoTreinoId;
      if (selAlunoId == null && listaAlunos.isNotEmpty) {
        selAlunoId = listaAlunos.first['id'];
      }
      int? selEvolucaoId = _alunoSelecionadoEvolucaoId ?? selAlunoId;

      List<dynamic> fichas = [];
      List<dynamic> avaliacoes = [];
      List<dynamic> progressaoCargas = [];

      if (selAlunoId != null) {
        final respFichas = await ApiService().dio.get('/api/treinos/aluno/$selAlunoId');
        fichas = respFichas.data as List<dynamic>;
      }
      if (selEvolucaoId != null) {
        final respAv = await ApiService().dio.get('/api/personal/alunos/$selEvolucaoId/avaliacoes');
        final rawAv = respAv.data;
        avaliacoes = rawAv is Map ? (rawAv['avaliacoes'] ?? []) : (rawAv as List<dynamic>);
        progressaoCargas = rawAv is Map ? (rawAv['progressaoCargas'] ?? []) : [];
      }

      if (!mounted) return;
      setState(() {
        _personal = Map<String, dynamic>.from(dashData['personal'] ?? {});
        _metricas = Map<String, dynamic>.from(dashData['metricas'] ?? {});
        _alunosSumidos = dashData['alunosSumidos'] ?? [];
        _ultimosTreinos = dashData['ultimosTreinos'] ?? [];
        _alunos = listaAlunos;
        _exerciciosBiblioteca = listaExBase;
        _alunoSelecionadoTreinoId = selAlunoId;
        _alunoSelecionadoEvolucaoId = selEvolucaoId;
        _fichasDoAlunoSelecionado = fichas;
        _avaliacoesDoAlunoSelecionado = avaliacoes;
        _progressaoCargasDoAlunoSelecionado = progressaoCargas;
        _resumoFinanceiro = Map<String, dynamic>.from(finData['resumo'] ?? {});
        _pagamentos = finData['pagamentos'] ?? [];
        _chavePixPersonal = finData['chavePixPersonal']?.toString() ?? '';
        _carregando = false;
      });
    } catch (_) {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _carregarFichasDoAluno(int alunoId) async {
    setState(() => _alunoSelecionadoTreinoId = alunoId);
    try {
      final resp = await ApiService().dio.get('/api/treinos/aluno/$alunoId');
      if (mounted) {
        setState(() {
          _fichasDoAlunoSelecionado = resp.data as List<dynamic>;
        });
      }
    } catch (_) {}
  }

  Future<void> _carregarEvolucaoDoAluno(int alunoId) async {
    setState(() => _alunoSelecionadoEvolucaoId = alunoId);
    try {
      final resp = await ApiService().dio.get('/api/personal/alunos/$alunoId/avaliacoes');
      final raw = resp.data;
      if (mounted) {
        setState(() {
          _avaliacoesDoAlunoSelecionado = raw is Map ? (raw['avaliacoes'] ?? []) : (raw as List<dynamic>);
          _progressaoCargasDoAlunoSelecionado = raw is Map ? (raw['progressaoCargas'] ?? []) : [];
        });
      }
    } catch (_) {}
  }

  Future<void> _trocarFotoRapidaDoAluno(dynamic a) async {
    final b64 = await ImageHelper.selecionarImagemBase64();
    if (b64 == null) return;
    try {
      await ApiService().dio.put(
        '/api/personal/alunos/${a['id']}',
        data: {
          'nome': a['nome'],
          'email': a['email'],
          'cpf': a['cpf'],
          'telefone': a['telefone'],
          'objetivo': a['objetivo'] ?? 'Hipertrofia',
          'fotoUrl': b64,
          'valorMensalidade': a['valorMensalidade'] ?? 250.0,
          'diaVencimento': a['diaVencimento'] ?? 10,
          'status': a['status'] ?? true,
        },
      );
      await _carregarTudo();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Foto de perfil de ${a['nome']} atualizada com sucesso!'),
          backgroundColor: AppTheme.neonGreen,
        ),
      );
    } catch (_) {}
  }

  // ─── MODAL CADASTRO / EDIÇÃO DE ALUNO ─────────────────────────────────────────
  void _abrirModalAluno({dynamic alunoExistente}) {
    final editando = alunoExistente != null;
    final nomeCtrl = TextEditingController(
      text: editando ? alunoExistente['nome']?.toString() : '',
    );
    final emailCtrl = TextEditingController(
      text: editando ? alunoExistente['email']?.toString() : '',
    );
    final senhaCtrl = TextEditingController(text: 'admin123');
    final cpfCtrl = TextEditingController(
      text: editando ? alunoExistente['cpf']?.toString() : '',
    );
    final whatsCtrl = TextEditingController(
      text: editando ? alunoExistente['telefone']?.toString() : '5511999990000',
    );
    final valorCtrl = TextEditingController(
      text: editando
          ? (alunoExistente['valorMensalidade'] ?? 200.0).toString()
          : '200.00',
    );
    final diaCtrl = TextEditingController(
      text: editando ? (alunoExistente['diaVencimento'] ?? 10).toString() : '10',
    );
    String objetivo = editando
        ? (alunoExistente['objetivo']?.toString() ?? 'Hipertrofia')
        : 'Hipertrofia';
    bool statusAtivo = editando ? (alunoExistente['status'] == true) : true;
    String? fotoUrlAluno = editando ? alunoExistente['fotoUrl']?.toString() : null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          backgroundColor: AppTheme.surfaceCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(editando ? 'Editar Aluno' : '+ Cadastrar Novo Aluno'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      ImageHelper.renderAvatarOrImage(
                        fotoUrlAluno,
                        radius: 28,
                        fallbackText: nomeCtrl.text.isNotEmpty ? nomeCtrl.text : 'A',
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final b64 = await ImageHelper.selecionarImagemBase64();
                          if (b64 != null) {
                            setModalState(() => fotoUrlAluno = b64);
                          }
                        },
                        icon: const Icon(Icons.camera_alt, size: 18, color: AppTheme.neonGreen),
                        label: const Text('Foto de Perfil do Aluno'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nomeCtrl,
                    decoration: const InputDecoration(labelText: 'Nome Completo do Aluno *'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(labelText: 'E-mail de Login do Aluno *'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: senhaCtrl,
                    decoration: InputDecoration(
                      labelText: editando
                          ? 'Nova Senha (deixe em branco para manter)'
                          : 'Senha Inicial do Aluno *',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: cpfCtrl,
                          decoration: const InputDecoration(labelText: 'CPF'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: whatsCtrl,
                          decoration: const InputDecoration(labelText: 'WhatsApp'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: [
                      'Hipertrofia',
                      'Emagrecimento',
                      'Condicionamento',
                      'Força'
                    ].contains(objetivo)
                        ? objetivo
                        : 'Hipertrofia',
                    decoration: const InputDecoration(labelText: 'Objetivo Principal'),
                    items: const [
                      DropdownMenuItem(value: 'Hipertrofia', child: Text('💪 Hipertrofia Muscular')),
                      DropdownMenuItem(value: 'Emagrecimento', child: Text('🔥 Emagrecimento / Definição')),
                      DropdownMenuItem(value: 'Condicionamento', child: Text('⚡ Condicionamento Físico')),
                      DropdownMenuItem(value: 'Força', child: Text('🏋️ Ganho de Força Pura')),
                    ],
                    onChanged: (v) => setModalState(() => objetivo = v ?? 'Hipertrofia'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: valorCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Mensalidade (R\$)'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: diaCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Dia Vencimento'),
                        ),
                      ),
                    ],
                  ),
                  if (editando) ...[
                    const SizedBox(height: 10),
                    SwitchListTile(
                      title: const Text('Aluno Ativo'),
                      value: statusAtivo,
                      activeThumbColor: AppTheme.neonGreen,
                      onChanged: (v) => setModalState(() => statusAtivo = v),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                final payload = {
                  'nome': nomeCtrl.text.trim(),
                  'email': emailCtrl.text.trim(),
                  'senha': senhaCtrl.text.trim(),
                  'cpf': cpfCtrl.text.trim(),
                  'telefone': whatsCtrl.text.trim(),
                  'objetivo': objetivo,
                  'fotoUrl': fotoUrlAluno,
                  'valorMensalidade':
                      double.tryParse(valorCtrl.text.replaceAll(',', '.')) ?? 200.0,
                  'diaVencimento': int.tryParse(diaCtrl.text) ?? 10,
                  'status': statusAtivo,
                };
                if (editando) {
                  await ApiService().dio.put(
                    '/api/personal/alunos/${alunoExistente['id']}',
                    data: payload,
                  );
                } else {
                  await ApiService().dio.post('/api/personal/alunos', data: payload);
                }
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                _carregarTudo();
              },
              child: Text(editando ? 'SALVAR' : 'CADASTRAR ALUNO'),
            ),
          ],
        ),
      ),
    );
  }

  // ─── MODAL AVALIAÇÃO FÍSICA, GRÁFICOS & FOTOS ANTES x DEPOIS ─────────────────
  Future<void> _abrirModalAvaliacaoFisica(dynamic aluno) async {
    final resp = await ApiService().dio.get('/api/personal/alunos/${aluno['id']}/avaliacoes');
    final dataResp = resp.data;
    final List<dynamic> avaliacoes = dataResp is Map
        ? (dataResp['avaliacoes'] ?? [])
        : (dataResp as List<dynamic>);
    final List<dynamic> progressaoCargas = dataResp is Map
        ? (dataResp['progressaoCargas'] ?? [])
        : [];

    final pesoCtrl = TextEditingController(text: '81.5');
    final alturaCtrl = TextEditingController(text: '1.78');
    final bfCtrl = TextEditingController(text: '13.8');
    final bracoCtrl = TextEditingController(text: '39.5');
    final peitoCtrl = TextEditingController(text: '107.0');
    final cinturaCtrl = TextEditingController(text: '79.0');
    final coxaCtrl = TextEditingController(text: '61.0');
    final lesoesCtrl = TextEditingController(text: 'Sem restrições articulares.');
    final obsCtrl = TextEditingController(text: 'Ótima evolução estética e ganho de força.');
    String? fotoFrenteB64;
    String? fotoCostasB64;

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          backgroundColor: AppTheme.surfaceCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('📏 Avaliação Física, Gráficos & Fotos — ${aluno['nome']}'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Painel de Gráficos Visuais + Comparativo Antes x Depois
                  if (avaliacoes.isNotEmpty || progressaoCargas.isNotEmpty) ...[
                    EvolucaoCompletaPanel(
                      avaliacoes: avaliacoes,
                      progressaoCargas: progressaoCargas,
                    ),
                    const Divider(color: Colors.white24, height: 28),
                  ],

                  const Text(
                    '➕ REGISTRAR NOVA AVALIAÇÃO FÍSICA + FOTOS ANTES/DEPOIS:',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.neonGreen),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: pesoCtrl,
                          decoration: const InputDecoration(labelText: 'Peso (kg)'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: alturaCtrl,
                          decoration: const InputDecoration(labelText: 'Altura (m)'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: bfCtrl,
                          decoration: const InputDecoration(labelText: '% Gordura'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: bracoCtrl,
                          decoration: const InputDecoration(labelText: 'Braço (cm)'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: peitoCtrl,
                          decoration: const InputDecoration(labelText: 'Peitoral (cm)'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: cinturaCtrl,
                          decoration: const InputDecoration(labelText: 'Cintura (cm)'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: coxaCtrl,
                          decoration: const InputDecoration(labelText: 'Coxa (cm)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final img = await ImageHelper.selecionarImagemBase64();
                            if (img != null) setModalState(() => fotoFrenteB64 = img);
                          },
                          icon: Icon(
                            fotoFrenteB64 != null ? Icons.check_circle : Icons.add_a_photo,
                            color: AppTheme.neonGreen,
                          ),
                          label: Text(
                            fotoFrenteB64 != null
                                ? 'Foto Frente Anexada ✅'
                                : '📸 Anexar Foto Frente (Antes/Depois)',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final img = await ImageHelper.selecionarImagemBase64();
                            if (img != null) setModalState(() => fotoCostasB64 = img);
                          },
                          icon: Icon(
                            fotoCostasB64 != null ? Icons.check_circle : Icons.add_a_photo,
                            color: AppTheme.electricBlue,
                          ),
                          label: Text(
                            fotoCostasB64 != null
                                ? 'Foto Costas Anexada ✅'
                                : '📸 Anexar Foto Costas/Perfil',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: lesoesCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Restrições Articulares / Lesões (Anamnese)',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: obsCtrl,
                    decoration: const InputDecoration(labelText: 'Observações da Evolução'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fechar')),
            ElevatedButton.icon(
              onPressed: () async {
                final medidasJson = jsonEncode({
                  'bracoDireito': double.tryParse(bracoCtrl.text) ?? 38.0,
                  'peitoral': double.tryParse(peitoCtrl.text) ?? 102.0,
                  'cintura': double.tryParse(cinturaCtrl.text) ?? 80.0,
                  'coxaDireita': double.tryParse(coxaCtrl.text) ?? 58.0,
                });
                await ApiService().dio.post(
                  '/api/personal/alunos/${aluno['id']}/avaliacoes',
                  data: {
                    'peso': double.tryParse(pesoCtrl.text.replaceAll(',', '.')) ?? 78.0,
                    'altura': double.tryParse(alturaCtrl.text.replaceAll(',', '.')) ?? 1.75,
                    'percentualGordura':
                        double.tryParse(bfCtrl.text.replaceAll(',', '.')) ?? 15.0,
                    'medidasJson': medidasJson,
                    'restricoesLesoes': lesoesCtrl.text.trim(),
                    'observacoes': obsCtrl.text.trim(),
                    'fotoFrenteUrl': fotoFrenteB64,
                    'fotoLadoCostasUrl': fotoCostasB64,
                  },
                );
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppTheme.primaryAccent,
                    content: const Text(
                      'Avaliação física e fotos salvas com sucesso!',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.save),
              label: const Text('Salvar Avaliação'),
            ),
          ],
        ),
      ),
    );
  }

  // ─── CRIAR FICHA OU APLICAR MODELO PRONTO ────────────────────────────────────
  void _abrirModalNovaFicha({List<Map<String, dynamic>>? exerciciosIniciais, String? nomeSugerido}) {
    if (_alunoSelecionadoTreinoId == null) return;
    final nomeDivCtrl = TextEditingController(
      text: nomeSugerido ?? 'Treino D - Ombros Completo e Core',
    );
    final descCtrl = TextEditingController(
      text: 'Execução controlada, respeitando o intervalo de descanso.',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        title: const Text('+ Criar Nova Divisão de Treino'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomeDivCtrl,
              decoration: const InputDecoration(
                labelText: 'Nome da Divisão (Ex: Treino A - Peito e Tríceps)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: 'Instruções Gerais do Treino'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              await ApiService().dio.post('/api/treinos/fichas', data: {
                'alunoId': _alunoSelecionadoTreinoId,
                'nomeDivisao': nomeDivCtrl.text.trim(),
                'descricao': descCtrl.text.trim(),
                'exercicios': exerciciosIniciais ?? [],
              });
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              _carregarFichasDoAluno(_alunoSelecionadoTreinoId!);
            },
            child: const Text('Criar Ficha'),
          ),
        ],
      ),
    );
  }

  // ─── MODAL ADICIONAR EXERCÍCIO DA BIBLIOTECA (120+ EXERCÍCIOS + BUSCA + NOVO) ──
  void _abrirModalAdicionarExercicio(int fichaId) {
    String grupoFiltro = 'Todos';
    String termoBusca = '';
    bool salvarNaBiblioteca = false;

    dynamic exercicioSelecionado =
        _exerciciosBiblioteca.isNotEmpty ? _exerciciosBiblioteca.first : null;

    final buscaCtrl = TextEditingController();
    final nomeCtrl = TextEditingController(
      text: exercicioSelecionado?['nome']?.toString() ?? 'Supino Reto com Barra',
    );
    final grupoCtrl = TextEditingController(
      text: exercicioSelecionado?['grupoMuscular']?.toString() ?? 'Peito',
    );
    final seriesCtrl = TextEditingController(text: '4');
    final repsCtrl = TextEditingController(text: '10 a 12');
    final cargaCtrl = TextEditingController(text: '30');
    final descansoCtrl = TextEditingController(text: '60');
    final obsCtrl = TextEditingController(text: 'Drop-set na última série / Cadência controlada');
    final videoCtrl = TextEditingController(
      text: exercicioSelecionado?['videoUrl']?.toString() ?? '',
    );

    final gruposDisponiveis = <String>{
      'Peito',
      'Costas',
      'Pernas',
      'Glúteos',
      'Ombros',
      'Bíceps',
      'Tríceps',
      'Abdômen',
      'Cardio & HIIT',
      ..._exerciciosBiblioteca
          .map((e) => (e['grupoMuscular'] ?? '').toString())
          .where((g) => g.isNotEmpty),
    }.toList();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final filtrados = _exerciciosBiblioteca.where((e) {
            final matchGrupo =
                grupoFiltro == 'Todos' || e['grupoMuscular'] == grupoFiltro;
            final matchBusca = termoBusca.isEmpty ||
                (e['nome'] ?? '')
                    .toString()
                    .toLowerCase()
                    .contains(termoBusca.toLowerCase()) ||
                (e['grupoMuscular'] ?? '')
                    .toString()
                    .toLowerCase()
                    .contains(termoBusca.toLowerCase());
            return matchGrupo && matchBusca;
          }).toList();

          return AlertDialog(
            backgroundColor: AppTheme.surfaceCard,
            title: Row(
              children: [
                const Icon(Icons.fitness_center, color: AppTheme.neonGreen),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '+ Adicionar Exercício (${_exerciciosBiblioteca.length}+ na Biblioteca)',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: grupoFiltro,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText:
                            '1. Filtrar por Grupo Muscular (${_exerciciosBiblioteca.length} exercícios)',
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'Todos',
                          child: Text('Todos os Grupos (${_exerciciosBiblioteca.length} exercícios)'),
                        ),
                        ...gruposDisponiveis.map(
                          (g) => DropdownMenuItem(
                            value: g,
                            child: Text(
                              '$g (${_exerciciosBiblioteca.where((x) => x['grupoMuscular'] == g).length} exercícios)',
                            ),
                          ),
                        ),
                      ],
                      onChanged: (g) {
                        if (g != null) {
                          setModalState(() {
                            grupoFiltro = g;
                            final novaLista = _exerciciosBiblioteca.where((e) {
                              return (g == 'Todos' || e['grupoMuscular'] == g) &&
                                  (termoBusca.isEmpty ||
                                      (e['nome'] ?? '')
                                          .toString()
                                          .toLowerCase()
                                          .contains(termoBusca.toLowerCase()));
                            }).toList();
                            if (novaLista.isNotEmpty) {
                              exercicioSelecionado = novaLista.first;
                              nomeCtrl.text = exercicioSelecionado['nome']?.toString() ?? '';
                              grupoCtrl.text =
                                  exercicioSelecionado['grupoMuscular']?.toString() ?? '';
                              videoCtrl.text =
                                  exercicioSelecionado['videoUrl']?.toString() ?? '';
                            }
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: buscaCtrl,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search, color: AppTheme.neonGreen),
                        labelText: '🔍 Pesquisar exercício pelo nome (ex: Búlgaro, Polia, Halter...)',
                      ),
                      onChanged: (val) {
                        setModalState(() {
                          termoBusca = val.trim();
                          final novaLista = _exerciciosBiblioteca.where((e) {
                            final matchGrupo =
                                grupoFiltro == 'Todos' || e['grupoMuscular'] == grupoFiltro;
                            final matchBusca = termoBusca.isEmpty ||
                                (e['nome'] ?? '')
                                    .toString()
                                    .toLowerCase()
                                    .contains(termoBusca.toLowerCase());
                            return matchGrupo && matchBusca;
                          }).toList();
                          if (novaLista.isNotEmpty) {
                            exercicioSelecionado = novaLista.first;
                            nomeCtrl.text = exercicioSelecionado['nome']?.toString() ?? '';
                            grupoCtrl.text =
                                exercicioSelecionado['grupoMuscular']?.toString() ?? '';
                            videoCtrl.text = exercicioSelecionado['videoUrl']?.toString() ?? '';
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<dynamic>(
                      initialValue: filtrados.contains(exercicioSelecionado)
                          ? exercicioSelecionado
                          : (filtrados.isNotEmpty ? filtrados.first : null),
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: '2. Escolher da Biblioteca (${filtrados.length} encontrados)',
                      ),
                      items: filtrados
                          .map(
                            (e) => DropdownMenuItem(
                              value: e,
                              child: Text(
                                '${e['nome']} (${e['grupoMuscular']})',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (e) {
                        if (e != null) {
                          setModalState(() {
                            exercicioSelecionado = e;
                            nomeCtrl.text = e['nome']?.toString() ?? '';
                            grupoCtrl.text = e['grupoMuscular']?.toString() ?? '';
                            videoCtrl.text = e['videoUrl']?.toString() ?? '';
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: nomeCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Nome do Exercício (ou digite um novo)',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: grupoCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Grupo Muscular',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: seriesCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Séries (ex: 4)'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: repsCtrl,
                            decoration: const InputDecoration(labelText: 'Repetições (10 a 12)'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: cargaCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Carga Sugerida (kg)'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: descansoCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Descanso (segundos)'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: obsCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Técnica Avançada / Observação (Drop-set, Cadência...)',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: videoCtrl,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.ondemand_video, color: AppTheme.neonGreen),
                        labelText: 'Link do Vídeo YouTube PT-BR / MP4 (opcional)',
                      ),
                    ),
                    const SizedBox(height: 6),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      activeColor: AppTheme.neonGreen,
                      checkColor: Colors.black,
                      value: salvarNaBiblioteca,
                      title: const Text(
                        'Salvar também na Minha Biblioteca para usar em outros alunos',
                        style: TextStyle(fontSize: 12.5),
                      ),
                      onChanged: (v) => setModalState(() => salvarNaBiblioteca = v ?? false),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: () async {
                  final nomeFinal = nomeCtrl.text.trim();
                  final grupoFinal = grupoCtrl.text.trim().isEmpty ? 'Geral' : grupoCtrl.text.trim();
                  final videoFinal = videoCtrl.text.trim();

                  // Se marcou salvar na biblioteca ou se não existe ainda na biblioteca, salva em EXERCICIOS_BASE
                  final jaExisteNaBib = _exerciciosBiblioteca.any(
                    (x) =>
                        (x['nome'] ?? '').toString().toLowerCase() == nomeFinal.toLowerCase(),
                  );
                  if (salvarNaBiblioteca && !jaExisteNaBib && nomeFinal.isNotEmpty) {
                    try {
                      await ApiService().dio.post(
                        '/api/treinos/exercicios-base',
                        data: {
                          'nome': nomeFinal,
                          'grupoMuscular': grupoFinal,
                          'videoUrl': videoFinal,
                        },
                      );
                      final respBib = await ApiService().dio.get('/api/treinos/exercicios-base');
                      if (mounted) {
                        setState(() {
                          _exerciciosBiblioteca = respBib.data as List<dynamic>;
                        });
                      }
                    } catch (_) {}
                  }

                  await ApiService().dio.post(
                    '/api/treinos/fichas/$fichaId/exercicios',
                    data: {
                      'nomeExercicio': nomeFinal,
                      'grupoMuscular': grupoFinal,
                      'series': int.tryParse(seriesCtrl.text) ?? 4,
                      'repeticoes': repsCtrl.text.trim(),
                      'cargaKg': double.tryParse(cargaCtrl.text.replaceAll(',', '.')) ?? 0,
                      'descansoSegundos': int.tryParse(descansoCtrl.text) ?? 60,
                      'observacaoTecnica': obsCtrl.text.trim(),
                      'videoUrl': videoFinal,
                    },
                  );
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  _carregarFichasDoAluno(_alunoSelecionadoTreinoId!);
                },
                child: const Text('Adicionar Exercício'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── MODAL DUPLICAR / COPIAR FICHA PARA OUTRO ALUNO ──────────────────────────
  void _abrirModalDuplicarFicha(dynamic ficha) {
    int? destinoId = _alunos.isNotEmpty ? _alunos.first['id'] : null;
    final novoNomeCtrl = TextEditingController(
      text: '${ficha['nomeDivisao']} (Cópia)',
    );

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          backgroundColor: AppTheme.surfaceCard,
          title: const Text('📋 Duplicar / Copiar Ficha de Treino'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: destinoId,
                decoration: const InputDecoration(labelText: 'Copiar Ficha para o Aluno:'),
                items: _alunos
                    .map(
                      (a) => DropdownMenuItem<int>(
                        value: a['id'],
                        child: Text('${a['nome']} (${a['objetivo']})'),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setModalState(() => destinoId = v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: novoNomeCtrl,
                decoration: const InputDecoration(labelText: 'Nome da Ficha no Aluno Destino'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton.icon(
              onPressed: () async {
                if (destinoId == null) return;
                await ApiService().dio.post(
                  '/api/treinos/fichas/${ficha['id']}/duplicar',
                  data: {
                    'alunoDestinoId': destinoId,
                    'novoNomeDivisao': novoNomeCtrl.text.trim(),
                  },
                );
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppTheme.primaryAccent,
                    content: const Text(
                      'Ficha copiada com sucesso!',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                );
                _carregarFichasDoAluno(destinoId!);
              },
              icon: const Icon(Icons.copy_all),
              label: const Text('Copiar Ficha'),
            ),
          ],
        ),
      ),
    );
  }

  void _abrirModalEditarPerfilPersonal() {
    final nomeCtrl = TextEditingController(
      text: _personal['nomeProfissional']?.toString() ?? widget.session['nome']?.toString() ?? '',
    );
    final crefCtrl = TextEditingController(text: _personal['cref']?.toString() ?? '');
    final telefoneCtrl = TextEditingController(text: _personal['telefone']?.toString() ?? '');
    final chavePixCtrl = TextEditingController(text: _personal['chavePix']?.toString() ?? '');
    String? fotoAtual = _personal['logoUrl']?.toString() ?? _personal['fotoUrl']?.toString();
    bool salvando = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final isLight = AppTheme.isLight;
          return AlertDialog(
            backgroundColor: AppTheme.surfaceCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isLight
                    ? const Color(0xFF0F172A).withValues(alpha: 0.10)
                    : Colors.white.withValues(alpha: 0.10),
              ),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.neonGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.person, color: AppTheme.neonGreen, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Editar Meus Dados',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Personal Trainer • Perfil e Foto',
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              ImageHelper.renderAvatarOrImage(
                                fotoAtual,
                                radius: 46,
                                fallbackIcon: Icons.fitness_center,
                              ),
                              Material(
                                color: AppTheme.neonGreen,
                                shape: const CircleBorder(),
                                elevation: 3,
                                child: InkWell(
                                  customBorder: const CircleBorder(),
                                  onTap: () async {
                                    final nova = await ImageHelper.selecionarImagemBase64();
                                    if (nova != null) {
                                      setModalState(() => fotoAtual = nova);
                                    }
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.all(7),
                                    child: Icon(Icons.photo_camera, size: 16, color: Color(0xFF0A0E12)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () async {
                              final nova = await ImageHelper.selecionarImagemBase64();
                              if (nova != null) {
                                setModalState(() => fotoAtual = nova);
                              }
                            },
                            icon: const Icon(Icons.image_outlined, size: 16, color: AppTheme.neonGreen),
                            label: Text(
                              (fotoAtual != null && fotoAtual!.trim().isNotEmpty)
                                  ? 'Alterar Foto de Perfil'
                                  : 'Adicionar Foto de Perfil',
                              style: const TextStyle(
                                color: AppTheme.neonGreen,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          if (fotoAtual != null && fotoAtual!.trim().isNotEmpty)
                            TextButton(
                              onPressed: () {
                                setModalState(() => fotoAtual = '');
                              },
                              child: const Text(
                                'Remover foto (usar halter padrão)',
                                style: TextStyle(color: AppTheme.performanceRed, fontSize: 11),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nomeCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nome Profissional / Coach',
                        prefixIcon: Icon(Icons.badge_outlined, color: AppTheme.neonGreen, size: 20),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: telefoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'WhatsApp / Telefone',
                        prefixIcon: Icon(Icons.phone_outlined, color: AppTheme.neonGreen, size: 20),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: crefCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Registro Profissional (CREF)',
                        prefixIcon: Icon(Icons.verified_outlined, color: AppTheme.neonGreen, size: 20),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: chavePixCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Chave PIX (para cobranças)',
                        prefixIcon: Icon(Icons.pix, color: AppTheme.neonGreen, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: salvando ? null : () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.neonGreen,
                  foregroundColor: const Color(0xFF0A0E12),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onPressed: salvando
                    ? null
                    : () async {
                        setModalState(() => salvando = true);
                        try {
                          await ApiService().dio.put('/api/personal/meu-perfil', data: {
                            'nomeProfissional': nomeCtrl.text.trim(),
                            'cref': crefCtrl.text.trim(),
                            'telefone': telefoneCtrl.text.trim(),
                            'chavePix': chavePixCtrl.text.trim(),
                            'logoUrl': fotoAtual ?? '',
                            'fotoUrl': fotoAtual ?? '',
                          });
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                          if (!mounted) return;
                          setState(() {
                            _personal['nomeProfissional'] = nomeCtrl.text.trim();
                            _personal['cref'] = crefCtrl.text.trim();
                            _personal['telefone'] = telefoneCtrl.text.trim();
                            _personal['chavePix'] = chavePixCtrl.text.trim();
                            _personal['logoUrl'] = fotoAtual;
                            _personal['fotoUrl'] = fotoAtual;
                            widget.session['nome'] = nomeCtrl.text.trim();
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: AppTheme.neonGreen,
                              content: Text(
                                'Dados do perfil salvos com sucesso!',
                                style: TextStyle(color: Color(0xFF0A0E12), fontWeight: FontWeight.bold),
                              ),
                            ),
                          );
                          _carregarTudo();
                        } catch (e) {
                          setModalState(() => salvando = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: AppTheme.performanceRed,
                              content: Text('Falha ao salvar dados do perfil.'),
                            ),
                          );
                        }
                      },
                icon: salvando
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0A0E12)),
                      )
                    : const Icon(Icons.check, size: 18),
                label: Text(
                  salvando ? 'Salvando...' : 'Salvar Alterações',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 920;
    final isMobile = screenWidth < 600;

    final conteudoPrincipal = _carregando
        ? const Center(child: CircularProgressIndicator())
        : IndexedStack(
            index: _abaAtual,
            children: [
              _buildAbaVisaoGeralFrequencia(),
              _buildAbaGestaoAlunos(),
              _buildAbaCriadorFichas(),
              PainelDietaPersonalWidget(
                alunos: _alunos,
                nomePersonal: _personal['nomeProfissional']?.toString() ?? 'Personal',
              ),
              PainelAgendaPersonalWidget(alunos: _alunos),
              _buildAbaFinanceiroPersonal(),
            ],
          );

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: _abrirModalEditarPerfilPersonal,
              child: Tooltip(
                message: 'Toque para alterar foto ou dados',
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ImageHelper.renderAvatarOrImage(
                      _personal['logoUrl']?.toString() ?? _personal['fotoUrl']?.toString(),
                      radius: 20,
                      fallbackIcon: Icons.fitness_center,
                    ),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        padding: const EdgeInsets.all(2.5),
                        decoration: BoxDecoration(
                          color: AppTheme.neonGreen,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.surfaceCard, width: 1.5),
                        ),
                        child: const Icon(
                          Icons.photo_camera,
                          size: 9,
                          color: Color(0xFF0A0E12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: _abrirModalEditarPerfilPersonal,
                child: Tooltip(
                  message: 'Toque para editar seus dados',
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                _personal['nomeProfissional']?.toString() ??
                                    widget.session['nome']?.toString() ??
                                    'Painel do Personal Trainer',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: isMobile ? 14.5 : 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.edit_outlined,
                              size: 14,
                              color: AppTheme.textSecondary.withValues(alpha: 0.7),
                            ),
                          ],
                        ),
                        Text(
                          'CREF: ${_personal['cref'] ?? 'Ativo'} • Plano ${_personal['plano'] ?? 'ELITE'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          BotaoAlternarTema(mostrarTexto: !isMobile),
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
      ),
      body: isDesktop
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: _abaAtual,
                  backgroundColor: AppTheme.surfaceCard,
                  indicatorColor: AppTheme.neonGreen.withValues(alpha: 0.22),
                  labelType: NavigationRailLabelType.all,
                  onDestinationSelected: (i) => setState(() => _abaAtual = i),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard, color: AppTheme.neonGreen),
                      label: Text('Frequência'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.people_outline),
                      selectedIcon: Icon(Icons.people, color: AppTheme.neonGreen),
                      label: Text('Alunos'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.ondemand_video_outlined),
                      selectedIcon: Icon(Icons.ondemand_video, color: AppTheme.neonGreen),
                      label: Text('Treinos (Vídeo)'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.restaurant_menu_outlined),
                      selectedIcon: Icon(Icons.restaurant_menu, color: AppTheme.neonGreen),
                      label: Text('Dieta & Macros'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.calendar_month_outlined),
                      selectedIcon: Icon(Icons.calendar_month, color: AppTheme.neonGreen),
                      label: Text('Agenda'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.pix_outlined),
                      selectedIcon: Icon(Icons.pix, color: AppTheme.neonGreen),
                      label: Text('Financeiro PIX'),
                    ),
                  ],
                ),
                const VerticalDivider(width: 1, color: Colors.white10),
                Expanded(child: conteudoPrincipal),
              ],
            )
          : conteudoPrincipal,
      bottomNavigationBar: isDesktop
          ? null
          : NavigationBar(
              selectedIndex: _abaAtual,
              backgroundColor: AppTheme.surfaceCard,
              indicatorColor: AppTheme.neonGreen.withValues(alpha: 0.22),
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              onDestinationSelected: (i) => setState(() => _abaAtual = i),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard, color: AppTheme.neonGreen),
                  label: 'Frequência',
                ),
                NavigationDestination(
                  icon: Icon(Icons.people_outline),
                  selectedIcon: Icon(Icons.people, color: AppTheme.neonGreen),
                  label: 'Alunos',
                ),
                NavigationDestination(
                  icon: Icon(Icons.ondemand_video_outlined),
                  selectedIcon: Icon(Icons.ondemand_video, color: AppTheme.neonGreen),
                  label: 'Treinos',
                ),
                NavigationDestination(
                  icon: Icon(Icons.restaurant_menu_outlined),
                  selectedIcon: Icon(Icons.restaurant_menu, color: AppTheme.neonGreen),
                  label: 'Dieta',
                ),
                NavigationDestination(
                  icon: Icon(Icons.calendar_month_outlined),
                  selectedIcon: Icon(Icons.calendar_month, color: AppTheme.neonGreen),
                  label: 'Agenda',
                ),
                NavigationDestination(
                  icon: Icon(Icons.pix_outlined),
                  selectedIcon: Icon(Icons.pix, color: AppTheme.neonGreen),
                  label: 'PIX',
                ),
              ],
            ),
    );
  }

  // ─── ABA 1: VISÃO GERAL & MONITORAMENTO DE FREQUÊNCIA ────────────────────────
  Widget _buildAbaVisaoGeralFrequencia() {
    return RefreshIndicator(
      onRefresh: _carregarTudo,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              _kpiBox(
                'ALUNOS ATIVOS',
                '${_metricas['totalAlunosAtivos'] ?? 0}',
                Icons.groups,
                AppTheme.neonGreen,
              ),
              _kpiBox(
                'TREINOS CONCLUÍDOS (7D)',
                '${_metricas['treinosSemana'] ?? 0}',
                Icons.check_circle,
                AppTheme.electricBlue,
              ),
              _kpiBox(
                'Receita Recebida Mês',
                'R\$ ${((_metricas['receitaRecebidaMes'] ?? 0) as num).toStringAsFixed(2)}',
                Icons.attach_money,
                AppTheme.primaryAccent,
              ),
              _kpiBox(
                'Alunos em Risco (+7d)',
                '${_alunosSumidos.length}',
                Icons.warning_amber_rounded,
                AppTheme.warningAmber,
              ),
            ],
          ),
          const SizedBox(height: 22),

          // RADAR DE RETENÇÃO: ATLETAS EM RISCO (+7 DIAS SEM TREINAR)
          if (_alunosSumidos.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(18),
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
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.warningAmber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.radar_rounded,
                          color: AppTheme.warningAmber,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Radar de Retenção: Alunos em Risco',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              '${_alunosSumidos.length} aluno(s) sem treinar há mais de 7 dias. Envie um lembrete com 1 toque.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ..._alunosSumidos.map((al) {
                    final dias = al['diasSemTreinar'] ?? 7;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.bgDark,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppTheme.isLight
                              ? const Color(0xFFE2E8F0)
                              : const Color(0xFF1E293B),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.warningAmber.withValues(alpha: 0.15),
                            ),
                            child: Center(
                              child: Text(
                                '${dias}d',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.warningAmber,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  al['nome']?.toString() ?? '',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Inativo há $dias dias • Objetivo: ${al['objetivo'] ?? 'Musculação'}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () => WhatsAppService.chamarAlunoSumido(
                              telefoneAluno: al['telefone']?.toString(),
                              nomeAluno: al['nome']?.toString() ?? 'Aluno',
                              diasSemTreinar: int.tryParse(dias.toString()) ?? 7,
                            ),
                            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                            label: const Text(
                              'Reengajar Aluno',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 22),
          ],

          // HISTÓRICO DOS TREINOS FINALIZADOS PELOS ALUNOS
          const Text(
            '💪 ÚLTIMOS TREINOS FINALIZADOS PELOS ALUNOS',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          ..._ultimosTreinos.map((t) {
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.neonGreen.withValues(alpha: 0.15),
                  child: const Icon(Icons.bolt, color: AppTheme.neonGreen),
                ),
                title: Text(
                  '${t['nomeAluno']} concluiu ${t['nomeTreino']}',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '⏱️ ${t['duracaoMinutos']} min • 💬 "${t['observacaoAluno'] ?? 'Treino concluído com sucesso!'}"',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5),
                ),
                trailing: IconButton(
                  tooltip: 'Parabenizar no WhatsApp',
                  icon: const Icon(Icons.chat, color: AppTheme.neonGreen),
                  onPressed: () => WhatsAppService.abrirMensagem(
                    t['telefoneAluno']?.toString(),
                    'Parabéns pelo treino de hoje (${t['nomeTreino']}), ${t['nomeAluno']}! Vi aqui no PersonalPro que você mandou muito bem! 💪🔥',
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─── ABA 2: GESTÃO DE ALUNOS & AVALIAÇÃO FÍSICA ──────────────────────────────
  Widget _buildAbaGestaoAlunos() {
    final alunoEvolucaoSelecionado = _alunos.firstWhere(
      (a) => a['id'] == _alunoSelecionadoEvolucaoId,
      orElse: () => _alunos.isNotEmpty ? _alunos.first : null,
    );

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'CARTEIRA DE ALUNOS (${_alunos.length})',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            ElevatedButton.icon(
              onPressed: () => _abrirModalAluno(),
              icon: const Icon(Icons.person_add),
              label: const Text('+ NOVO ALUNO'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ..._alunos.map((a) {
          final ativo = a['status'] == true || a['status'] == 1;
          final selecionadoParaGrafico = a['id'] == _alunoSelecionadoEvolucaoId;
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: selecionadoParaGrafico
                    ? AppTheme.neonGreen.withValues(alpha: 0.6)
                    : Colors.white10,
                width: selecionadoParaGrafico ? 1.5 : 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      InkWell(
                        onTap: () => _trocarFotoRapidaDoAluno(a),
                        child: ImageHelper.renderAvatarOrImage(
                          a['fotoUrl']?.toString(),
                          radius: 24,
                          fallbackText: a['nome']?.toString() ?? 'A',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  a['nome']?.toString() ?? 'Aluno',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.neonGreen.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    a['objetivo']?.toString() ?? 'Hipertrofia',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.neonGreen,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: ativo
                                        ? AppTheme.neonGreen.withValues(alpha: 0.12)
                                        : AppTheme.performanceRed.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    ativo ? 'ATIVO' : 'INATIVO',
                                    style: TextStyle(
                                      color: ativo ? AppTheme.neonGreen : AppTheme.performanceRed,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 3),
                            Text(
                              '${a['email']} • WhatsApp: ${a['telefone'] ?? '-'} • Mensalidade: R\$ ${((a['valorMensalidade'] ?? 0) as num).toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          _carregarFichasDoAluno(a['id']);
                          setState(() => _abaAtual = 2);
                        },
                        icon: const Icon(Icons.fitness_center, size: 16),
                        label: Text('Fichas de Treino (${a['totalFichas'] ?? 0})'),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00B0FF),
                          foregroundColor: Colors.black,
                        ),
                        onPressed: () {
                          _carregarEvolucaoDoAluno(a['id']);
                          _abrirModalAvaliacaoFisica(a);
                        },
                        icon: const Icon(Icons.insights, size: 16),
                        label: const Text('📊 Gráficos, Carga & Antes/Depois'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => setState(() => _abaAtual = 3),
                        icon: const Icon(Icons.restaurant_menu, size: 16, color: AppTheme.neonGreen),
                        label: const Text('🥗 Dieta & Macros'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _trocarFotoRapidaDoAluno(a),
                        icon: const Icon(Icons.camera_alt, size: 16, color: AppTheme.neonGreen),
                        label: const Text('📷 Foto Perfil'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _abrirModalAluno(alunoExistente: a),
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Editar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),

        // ─── PAINEL VISUAL COMPLETO v2 EMBUTIDO NA TELA DE ALUNOS ──────────────────
        if (alunoEvolucaoSelecionado != null) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF151922),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.neonGreen.withValues(alpha: 0.35), width: 1.5),
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
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_graph, color: AppTheme.neonGreen, size: 24),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CENTRAL DE EVOLUÇÃO, CARGA & ANTES/DEPOIS — ${alunoEvolucaoSelecionado['nome']?.toString().toUpperCase()}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.neonGreen,
                              ),
                            ),
                            Text(
                              'Selecione o aluno abaixo para visualizar gráficos de Peso/Gordura, Progressão de Carga (kg) e Fotos Antes x Depois',
                              style: TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _abrirModalAvaliacaoFisica(alunoEvolucaoSelecionado),
                      icon: const Icon(Icons.add_photo_alternate, size: 16),
                      label: const Text('+ NOVA AVALIAÇÃO / ENVIAR FOTOS ANTES & DEPOIS'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _alunos.map((al) {
                    final sel = al['id'] == _alunoSelecionadoEvolucaoId;
                    return ChoiceChip(
                      label: Text(al['nome']?.toString() ?? 'Aluno'),
                      selected: sel,
                      selectedColor: AppTheme.neonGreen.withValues(alpha: 0.25),
                      labelStyle: TextStyle(
                        color: sel ? AppTheme.neonGreen : Colors.white70,
                        fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (_) => _carregarEvolucaoDoAluno(al['id']),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                EvolucaoCompletaPanel(
                  avaliacoes: _avaliacoesDoAlunoSelecionado,
                  progressaoCargas: _progressaoCargasDoAlunoSelecionado,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ─── ABA 3: CRIADOR DE FICHAS DE TREINO (A, B, C, D, E) & EXPORTAÇÃO PDF ────
  Widget _buildAbaCriadorFichas() {
    final alunoAtual = _alunos.firstWhere(
      (a) => a['id'] == _alunoSelecionadoTreinoId,
      orElse: () => _alunos.isNotEmpty ? _alunos.first : null,
    );

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Barra superior de Seleção de Aluno + Exportar PDF + Modelos Prontos
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: _alunoSelecionadoTreinoId,
                        decoration: const InputDecoration(
                          labelText: 'Selecionar Aluno para Prescrever / Editar Fichas',
                          prefixIcon: Icon(Icons.person, color: AppTheme.neonGreen),
                        ),
                        items: _alunos
                            .map(
                              (a) => DropdownMenuItem<int>(
                                value: a['id'],
                                child: Text('${a['nome']} — ${a['objetivo']}'),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v != null) _carregarFichasDoAluno(v);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _abrirModalNovaFicha(),
                      icon: const Icon(Icons.add),
                      label: const Text('+ NOVA DIVISÃO (A, B, C, D, E)'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _abrirModalNovaFicha(
                        nomeSugerido: 'Modelo Push (Peito, Ombros e Tríceps)',
                        exerciciosIniciais: [
                          {
                            'nomeExercicio': 'Supino Reto com Barra',
                            'grupoMuscular': 'Peito',
                            'series': 4,
                            'repeticoes': '8 a 10',
                            'cargaKg': 60,
                            'descansoSegundos': 90,
                            'observacaoTecnica': 'Cadência 3010 controlada',
                          },
                          {
                            'nomeExercicio': 'Desenvolvimento com Halteres Sentado',
                            'grupoMuscular': 'Ombros',
                            'series': 4,
                            'repeticoes': '10 a 12',
                            'cargaKg': 20,
                            'descansoSegundos': 75,
                            'observacaoTecnica': 'Amplitude completa',
                          },
                          {
                            'nomeExercicio': 'Tríceps Pulley com Corda',
                            'grupoMuscular': 'Tríceps',
                            'series': 4,
                            'repeticoes': '12 a 15',
                            'cargaKg': 30,
                            'descansoSegundos': 60,
                            'observacaoTecnica': 'Drop-set na última série',
                          },
                        ],
                      ),
                      icon: const Icon(Icons.auto_awesome, color: AppTheme.neonGreen),
                      label: const Text('Aplicar Modelo Pronto de Treino'),
                    ),
                    if (alunoAtual != null && _fichasDoAlunoSelecionado.isNotEmpty)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.electricBlue,
                          foregroundColor: Colors.black,
                        ),
                        onPressed: () => FichaPdfService.exportarFichaPdf(
                          nomeAluno: alunoAtual['nome']?.toString() ?? 'Aluno',
                          objetivo: alunoAtual['objetivo']?.toString() ?? 'Hipertrofia',
                          nomePersonal:
                              _personal['nomeProfissional']?.toString() ?? 'PersonalPro',
                          crefPersonal: _personal['cref']?.toString() ?? '',
                          fichas: _fichasDoAlunoSelecionado,
                        ),
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('Exportar Ficha em PDF'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Lista de Fichas (Treino A, B, C...)
        ..._fichasDoAlunoSelecionado.map((ficha) {
          final exercicios = (ficha['exercicios'] as List<dynamic>?) ?? [];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
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
                          ficha['nomeDivisao']?.toString() ?? '',
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => _abrirModalDuplicarFicha(ficha),
                        icon: const Icon(Icons.copy_all, size: 18, color: AppTheme.neonGreen),
                        label: const Text('Duplicar p/ Aluno'),
                      ),
                      IconButton(
                        tooltip: 'Excluir Ficha',
                        icon: const Icon(Icons.delete_outline, color: AppTheme.performanceRed),
                        onPressed: () async {
                          await ApiService().dio.delete('/api/treinos/fichas/${ficha['id']}');
                          _carregarFichasDoAluno(_alunoSelecionadoTreinoId!);
                        },
                      ),
                    ],
                  ),
                  if ((ficha['descricao']?.toString() ?? '').isNotEmpty) ...[
                    SizedBox(height: 6),
                    Text(
                      ficha['descricao'].toString(),
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5),
                    ),
                  ],
                  const Divider(color: Colors.white12, height: 22),
                  ...exercicios.map((ex) {
                    final exMap = Map<String, dynamic>.from(ex as Map);
                    final exId = (exMap['id'] as num?)?.toInt() ?? exMap.hashCode;
                    final playerAberto = _exerciciosPlayerInlineAbertos.contains(exId);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.bgDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: playerAberto
                              ? AppTheme.neonGreen.withValues(alpha: 0.6)
                              : Colors.white10,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isNarrow = constraints.maxWidth < 620;
                              final thumb = ExercicioAnimadoThumbnail(
                                nomeExercicio: (exMap['nomeExercicio'] ?? '').toString(),
                                grupoMuscular: (exMap['grupoMuscular'] ?? '').toString(),
                                videoUrl: exMap['videoUrl']?.toString(),
                                onTap: () {
                                  setState(() {
                                    if (playerAberto) {
                                      _exerciciosPlayerInlineAbertos.remove(exId);
                                    } else {
                                      _exerciciosPlayerInlineAbertos.add(exId);
                                    }
                                  });
                                },
                              );

                              final infoColumn = Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${exMap['nomeExercicio']} (${exMap['grupoMuscular']})',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '🎯 ${exMap['series']} séries x ${exMap['repeticoes']} reps  |  🏋️ ${exMap['cargaKg']} kg  |  ⏱️ ${exMap['descansoSegundos']}s descanso',
                                    style: const TextStyle(
                                      color: AppTheme.neonGreen,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if ((exMap['observacaoTecnica']?.toString() ?? '').isNotEmpty)
                                    Padding(
                                      padding: EdgeInsets.only(top: 4),
                                      child: Text(
                                        '💡 Técnica: ${exMap['observacaoTecnica']}',
                                        style: TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                ],
                              );

                              final botoesAcao = Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: playerAberto
                                          ? AppTheme.surfaceCard
                                          : AppTheme.neonGreen,
                                      foregroundColor: playerAberto
                                          ? AppTheme.neonGreen
                                          : Colors.black,
                                      visualDensity: VisualDensity.compact,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        if (playerAberto) {
                                          _exerciciosPlayerInlineAbertos.remove(exId);
                                        } else {
                                          _exerciciosPlayerInlineAbertos.add(exId);
                                        }
                                      });
                                    },
                                    icon: Icon(
                                      playerAberto ? Icons.stop_circle_outlined : Icons.play_circle_fill,
                                      size: 16,
                                    ),
                                    label: Text(
                                      playerAberto ? 'Fechar Vídeo' : '🎬 Assistir Vídeo',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                                    ),
                                  ),
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    ),
                                    onPressed: () => ExercicioExecucaoModal.abrir(context, exMap),
                                    icon: const Icon(Icons.video_settings, size: 15, color: Colors.cyanAccent),
                                    label: const Text(
                                      'Guia / Editar Link',
                                      style: TextStyle(fontSize: 11.5, color: Colors.cyanAccent),
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Remover Exercício',
                                    visualDensity: VisualDensity.compact,
                                    icon: const Icon(Icons.close, size: 18, color: Colors.white54),
                                    onPressed: () async {
                                      await ApiService()
                                          .dio
                                          .delete('/api/treinos/exercicios/${exMap['id']}');
                                      _carregarFichasDoAluno(_alunoSelecionadoTreinoId!);
                                    },
                                  ),
                                ],
                              );

                              if (isNarrow) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        thumb,
                                        const SizedBox(width: 12),
                                        Expanded(child: infoColumn),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    botoesAcao,
                                  ],
                                );
                              }

                              return Row(
                                children: [
                                  thumb,
                                  const SizedBox(width: 14),
                                  Expanded(child: infoColumn),
                                  const SizedBox(width: 10),
                                  botoesAcao,
                                ],
                              );
                            },
                          ),
                          if (playerAberto)
                            PlayerVideoExercicioInline(
                              nomeExercicio: (exMap['nomeExercicio'] ?? '').toString(),
                              grupoMuscular: (exMap['grupoMuscular'] ?? '').toString(),
                              videoUrl: exMap['videoUrl']?.toString(),
                              exercicioId: exId,
                              onFechar: () => setState(() => _exerciciosPlayerInlineAbertos.remove(exId)),
                              onAbrirModalCompleto: () => ExercicioExecucaoModal.abrir(context, exMap),
                            ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => _abrirModalAdicionarExercicio(ficha['id']),
                    icon: const Icon(Icons.add_circle_outline, color: AppTheme.neonGreen),
                    label: Text('+ Adicionar Exercício da Biblioteca (${_exerciciosBiblioteca.length}+ exercícios)'),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // ─── ABA 4: CONTROLE FINANCEIRO DO PERSONAL & CHAVE PIX ──────────────────────
  Widget _buildAbaFinanceiroPersonal() {
    final pixCtrl = TextEditingController(text: _chavePixPersonal);
    final totalRecebido = (_resumoFinanceiro['totalRecebido'] ?? 0).toDouble();
    final totalPendente = (_resumoFinanceiro['totalPendente'] ?? 0).toDouble();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _kpiBox(
              'RECEBIDO NO MÊS',
              'R\$ ${totalRecebido.toStringAsFixed(2)}',
              Icons.check_circle_outline,
              AppTheme.neonGreen,
            ),
            _kpiBox(
              'PENDENTE NO MÊS',
              'R\$ ${totalPendente.toStringAsFixed(2)}',
              Icons.pending_actions,
              AppTheme.warningAmber,
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Card de Configuração da Chave PIX do Personal
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '⚡ CONFIGURAÇÃO DA SUA CHAVE PIX (GERAÇÃO AUTOMÁTICA DE QR CODE)',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.neonGreen),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: pixCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Sua Chave PIX (CPF, CNPJ, E-mail, Celular ou Aleatória)',
                          prefixIcon: Icon(Icons.pix, color: AppTheme.neonGreen),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await ApiService().dio.put('/api/personal/meu-perfil', data: {
                          'nomeProfissional':
                              _personal['nomeProfissional']?.toString() ?? 'Personal',
                          'cref': _personal['cref']?.toString() ?? '',
                          'telefone': _personal['telefone']?.toString() ?? '',
                          'chavePix': pixCtrl.text.trim(),
                        });
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppTheme.primaryAccent,
                            content: const Text(
                              'Chave PIX atualizada com sucesso!',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                          ),
                        );
                        _carregarTudo();
                      },
                      icon: const Icon(Icons.save),
                      label: const Text('Salvar Chave PIX'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.electricBlue,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        final resp =
                            await ApiService().dio.post('/api/financeiro/gerar-mensalidades-mes');
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppTheme.primaryAccent,
                            content: Text(
                              resp.data['mensagem']?.toString() ?? '',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                        _carregarTudo();
                      },
                      icon: const Icon(Icons.autorenew),
                      label: const Text('Gerar Cobranças PIX do Mês p/ Todos Alunos'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Lista de Mensalidades dos Alunos
        ..._pagamentos.map((p) {
          final pago = p['status'] == 'PAGO';
          final valor = (p['valor'] ?? 0).toDouble();
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
                        '${p['nomeAluno']} • Ref: ${p['mesReferencia']}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: pago
                              ? AppTheme.neonGreen.withValues(alpha: 0.15)
                              : AppTheme.warningAmber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          pago ? '✅ PAGO' : '⏳ PENDENTE',
                          style: TextStyle(
                            color: pago ? AppTheme.neonGreen : AppTheme.warningAmber,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Valor: R\$ ${valor.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.neonGreen,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (!pago) ...[
                        ElevatedButton.icon(
                          onPressed: () async {
                            await ApiService().dio.post(
                              '/api/financeiro/pagamentos/${p['id']}/confirmar',
                              data: {'formaPagamento': 'PIX'},
                            );
                            _carregarTudo();
                          },
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Confirmar Recebimento'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => WhatsAppService.cobrarMensalidadePix(
                            telefoneAluno: p['telefoneAluno']?.toString(),
                            nomeAluno: p['nomeAluno']?.toString() ?? 'Aluno',
                            mesReferencia: p['mesReferencia']?.toString() ?? '',
                            valor: valor,
                            pixCopiaECola: p['pixCopiaECola']?.toString() ?? '',
                            nomePersonal:
                                _personal['nomeProfissional']?.toString() ?? 'PersonalPro',
                          ),
                          icon: const Icon(Icons.chat, size: 16, color: AppTheme.neonGreen),
                          label: const Text('Cobrar com PIX no WhatsApp'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => PixModal.mostrar(
                            context,
                            nomeBeneficiario:
                                _personal['nomeProfissional']?.toString() ?? 'PersonalPro',
                            chavePix: _chavePixPersonal,
                            valor: valor,
                            mesReferencia: p['mesReferencia']?.toString() ?? '',
                            pixCopiaECola: p['pixCopiaECola']?.toString() ?? '',
                          ),
                          icon: const Icon(Icons.qr_code, size: 16),
                          label: const Text('QR Code PIX'),
                        ),
                      ] else
                        OutlinedButton.icon(
                          onPressed: () => WhatsAppService.enviarReciboPagamento(
                            telefoneAluno: p['telefoneAluno']?.toString(),
                            nomeAluno: p['nomeAluno']?.toString() ?? 'Aluno',
                            mesReferencia: p['mesReferencia']?.toString() ?? '',
                            valor: valor,
                            formaPagamento: p['formaPagamento']?.toString() ?? 'PIX',
                            nomePersonal:
                                _personal['nomeProfissional']?.toString() ?? 'PersonalPro',
                          ),
                          icon: const Icon(Icons.receipt_long, size: 16, color: AppTheme.neonGreen),
                          label: const Text('Enviar Recibo no WhatsApp'),
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

  Widget _kpiBox(String label, String valor, IconData icone, Color cor) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cor.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textSecondary,
                ),
              ),
              Icon(icone, color: cor, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            valor,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: cor),
          ),
        ],
      ),
    );
  }
}

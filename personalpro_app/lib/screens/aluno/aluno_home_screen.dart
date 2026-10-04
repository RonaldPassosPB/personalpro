import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_service.dart';
import '../../services/evolucao_pdf_service.dart';
import '../../services/ficha_pdf_service.dart';
import '../../services/notification_service.dart';
import '../../services/whatsapp_service.dart';
import '../../theme.dart';
import '../../widgets/evolucao_charts_widget.dart';
import '../../widgets/exercicio_animado_dieta_agenda_widget.dart';
import '../../widgets/notificacoes_sheet.dart';
import '../../widgets/pix_modal.dart';
import '../../widgets/story_card_treino_modal.dart';
import '../../widgets/antes_depois_slider_widget.dart';
import '../../widgets/calendario_consistencia_widget.dart';
import '../../widgets/calculadora_equivalencia_dieta_modal.dart';
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
          _nomePersonal = finData['nomePersonal']?.toString() ?? 'Coach Center';
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
          treinosNoMes: _treinosMes,
          progressaoCargas: _progressaoCargas,
          onTreinoConcluido: _carregarDadosAluno,
        ),
      ),
    );
  }

  void _abrirModalDietaAluno() {
    final plano = _meuPlanoDieta;
    final tituloCtrl = TextEditingController(text: plano?['titulo'] ?? 'Minha Dieta Personalizada');
    final metaKcalCtrl = TextEditingController(text: (plano?['metaKcal'] ?? 2600).toString());
    final aguaCtrl = TextEditingController(text: (plano?['aguaLitros'] ?? 3.5).toString());
    final protCtrl = TextEditingController(text: (plano?['proteinaG'] ?? 160).toString());
    final carbCtrl = TextEditingController(text: (plano?['carboidratoG'] ?? 280).toString());
    final gordCtrl = TextEditingController(text: (plano?['gorduraG'] ?? 65).toString());
    final obsCtrl = TextEditingController(text: plano?['observacoes'] ?? '');
    String objetivo = plano?['objetivo'] ?? 'Hipertrofia';

    List<Map<String, dynamic>> refeicoesTemp = [];
    if (_minhasRefeicoes.isNotEmpty) {
      refeicoesTemp = _minhasRefeicoes.map((r) => Map<String, dynamic>.from(r as Map)).toList();
    } else {
      refeicoesTemp = [
        {
          'horario': '07:30',
          'nomeRefeicao': 'Refeição 1 — Café da Manhã',
          'alimentosDescricao': '• 3 Ovos mexidos + 2 fatias de pão integral\n• 1 Banana com aveia\n• Café preto',
          'substituicoes': 'Crepioca (2 ovos + 30g tapioca)',
          'kcalEstimada': 500,
          'proteinaG': 30,
          'carboG': 50,
          'gorduraG': 15,
        },
        {
          'horario': '12:30',
          'nomeRefeicao': 'Refeição 2 — Almoço',
          'alimentosDescricao': '• 180g Frango grelhado\n• 200g Arroz + 100g Feijão\n• Salada à vontade',
          'substituicoes': '180g Patinho moído + 200g Batata doce',
          'kcalEstimada': 700,
          'proteinaG': 50,
          'carboG': 70,
          'gorduraG': 18,
        },
        {
          'horario': '16:30',
          'nomeRefeicao': 'Refeição 3 — Lanche / Pré-Treino',
          'alimentosDescricao': '• 40g Whey Protein + 40g Aveia\n• 1 Banana + 15g Pasta de amendoim',
          'substituicoes': 'Iogurte natural com frutas e chia',
          'kcalEstimada': 450,
          'proteinaG': 35,
          'carboG': 45,
          'gorduraG': 12,
        },
        {
          'horario': '20:30',
          'nomeRefeicao': 'Refeição 4 — Jantar',
          'alimentosDescricao': '• 180g Carne magra ou Peixe\n• 150g Mandioca ou Batata\n• Legumes no vapor',
          'substituicoes': 'Omelete de 3 ovos com legumes',
          'kcalEstimada': 550,
          'proteinaG': 45,
          'carboG': 45,
          'gorduraG': 15,
        },
      ];
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return AlertDialog(
            backgroundColor: AppTheme.surfaceCard,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            title: Row(
              children: [
                Icon(
                  Icons.restaurant_menu_rounded,
                  color: AppTheme.primaryAccent,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Cadastrar / Ajustar Minha Dieta',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 580, maxHeight: 650),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: tituloCtrl,
                      decoration: const InputDecoration(labelText: 'Título da Dieta'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: objetivo,
                      decoration: const InputDecoration(labelText: 'Objetivo Nutricional'),
                      items: const [
                        DropdownMenuItem(value: 'Hipertrofia', child: Text('Hipertrofia')),
                        DropdownMenuItem(value: 'Emagrecimento', child: Text('Emagrecimento')),
                        DropdownMenuItem(value: 'Definição', child: Text('Definição Muscular')),
                        DropdownMenuItem(value: 'Manutenção', child: Text('Manutenção')),
                      ],
                      onChanged: (v) => setModalState(() => objetivo = v ?? 'Hipertrofia'),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: metaKcalCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Meta Calórica (kcal)'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: aguaCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Meta de Água (L)'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: protCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Proteínas (g)'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: carbCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Carboidratos (g)'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: gordCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Gorduras (g)'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: obsCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Observações / Recomendações',
                        hintText: 'Ex: Beber 500ml de água antes de cada refeição',
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Refeições (${refeicoesTemp.length})',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            setModalState(() {
                              refeicoesTemp.add({
                                'horario': '15:00',
                                'nomeRefeicao': 'Refeição ${refeicoesTemp.length + 1}',
                                'alimentosDescricao': '• Alimento 1\n• Alimento 2',
                                'substituicoes': '',
                                'kcalEstimada': 400,
                                'proteinaG': 25,
                                'carboG': 40,
                                'gorduraG': 10,
                              });
                            });
                          },
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Adicionar Refeição'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...refeicoesTemp.asMap().entries.map((entry) {
                      final i = entry.key;
                      final r = entry.value;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.bgDark,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                SizedBox(
                                  width: 80,
                                  child: TextFormField(
                                    initialValue: r['horario']?.toString(),
                                    decoration: const InputDecoration(labelText: 'Horário', isDense: true),
                                    onChanged: (v) => r['horario'] = v,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    initialValue: r['nomeRefeicao']?.toString(),
                                    decoration: const InputDecoration(labelText: 'Nome da Refeição', isDense: true),
                                    onChanged: (v) => r['nomeRefeicao'] = v,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: AppTheme.performanceRed, size: 20),
                                  onPressed: () {
                                    setModalState(() => refeicoesTemp.removeAt(i));
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              initialValue: (r['alimentosDescricao'] ?? '').toString().replaceAll(r'\n', '\n'),
                              maxLines: 3,
                              decoration: const InputDecoration(
                                labelText: 'Alimentos (1 por linha)',
                                isDense: true,
                              ),
                              onChanged: (v) => r['alimentosDescricao'] = v,
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              initialValue: r['substituicoes']?.toString(),
                              decoration: const InputDecoration(
                                labelText: 'Opções de Substituição',
                                isDense: true,
                              ),
                              onChanged: (v) => r['substituicoes'] = v,
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  try {
                    await ApiService().dio.post(
                      '/api/dieta/salvar',
                      data: {
                        'titulo': tituloCtrl.text.trim(),
                        'objetivo': objetivo,
                        'metaKcal': int.tryParse(metaKcalCtrl.text) ?? 2600,
                        'aguaLitros': double.tryParse(aguaCtrl.text.replaceAll(',', '.')) ?? 3.5,
                        'proteinaG': int.tryParse(protCtrl.text) ?? 160,
                        'carboidratoG': int.tryParse(carbCtrl.text) ?? 280,
                        'gorduraG': int.tryParse(gordCtrl.text) ?? 65,
                        'observacoes': obsCtrl.text.trim(),
                        'refeicoes': refeicoesTemp,
                      },
                    );
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    _carregarDadosAluno();
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Dieta atualizada com sucesso!'),
                        backgroundColor: AppTheme.primaryAccent,
                      ),
                    );
                  } catch (e) {
                    if (!ctx.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erro ao salvar dieta: $e'),
                        backgroundColor: AppTheme.performanceRed,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('Salvar Dieta'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _abrirModalEditarPerfilAluno() {
    final nomeCtrl = TextEditingController(
      text: _aluno['nome']?.toString() ?? widget.session['nome']?.toString() ?? '',
    );
    final telefoneCtrl = TextEditingController(text: _aluno['telefone']?.toString() ?? '');
    String objetivoSelecionado = _aluno['objetivo']?.toString() ?? 'Hipertrofia';
    final objetivos = [
      'Hipertrofia',
      'Emagrecimento',
      'Definição Muscular',
      'Condicionamento Físico',
      'Força & Performance',
      'Saúde & Bem-Estar',
    ];
    if (!objetivos.contains(objetivoSelecionado)) {
      objetivos.add(objetivoSelecionado);
    }
    String? fotoAtual = _aluno['fotoUrl']?.toString();
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
                    color: AppTheme.primaryAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.person, color: AppTheme.primaryAccent, size: 22),
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
                        'Informações do Aluno • Perfil e Foto',
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
                                color: AppTheme.primaryAccent,
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
                            icon: Icon(Icons.image_outlined, size: 16, color: AppTheme.primaryAccent),
                            label: Text(
                              (fotoAtual != null && fotoAtual!.trim().isNotEmpty)
                                  ? 'Alterar Foto de Perfil'
                                  : 'Adicionar Foto de Perfil',
                              style: TextStyle(
                                color: AppTheme.primaryAccent,
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
                      decoration: InputDecoration(
                        labelText: 'Meu Nome Completo',
                        prefixIcon: Icon(Icons.badge_outlined, color: AppTheme.primaryAccent, size: 20),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: telefoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'WhatsApp / Telefone',
                        prefixIcon: Icon(Icons.phone_outlined, color: AppTheme.primaryAccent, size: 20),
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: objetivoSelecionado,
                      decoration: InputDecoration(
                        labelText: 'Objetivo Principal',
                        prefixIcon: Icon(Icons.flag_outlined, color: AppTheme.primaryAccent, size: 20),
                      ),
                      items: objetivos.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => objetivoSelecionado = val);
                      },
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
                  backgroundColor: AppTheme.primaryAccent,
                  foregroundColor: const Color(0xFF0A0E12),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onPressed: salvando
                    ? null
                    : () async {
                        setModalState(() => salvando = true);
                        try {
                          await ApiService().dio.put('/api/aluno/meu-perfil', data: {
                            'nome': nomeCtrl.text.trim(),
                            'telefone': telefoneCtrl.text.trim(),
                            'objetivo': objetivoSelecionado,
                            'fotoUrl': fotoAtual ?? '',
                          });
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                          if (!mounted) return;
                          setState(() {
                            _aluno['nome'] = nomeCtrl.text.trim();
                            _aluno['telefone'] = telefoneCtrl.text.trim();
                            _aluno['objetivo'] = objetivoSelecionado;
                            _aluno['fotoUrl'] = fotoAtual;
                            widget.session['nome'] = nomeCtrl.text.trim();
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppTheme.primaryAccent,
                              content: const Text(
                                'Dados do aluno salvos com sucesso!',
                                style: TextStyle(color: Color(0xFF0A0E12), fontWeight: FontWeight.bold),
                              ),
                            ),
                          );
                          _carregarDadosAluno();
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
                    onTap: _abrirModalEditarPerfilAluno,
                    child: Tooltip(
                      message: 'Toque para alterar foto ou dados',
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          ImageHelper.renderAvatarOrImage(
                            _aluno['fotoUrl']?.toString(),
                            radius: 20,
                            fallbackIcon: Icons.fitness_center,
                          ),
                          Positioned(
                            right: -2,
                            bottom: -2,
                            child: Container(
                              padding: const EdgeInsets.all(2.5),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryAccent,
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
                      onTap: _abrirModalEditarPerfilAluno,
                      child: Tooltip(
                        message: 'Toque para editar seus dados',
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
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
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      'Olá, ${_aluno['nome'] ?? widget.session['nome'] ?? 'Atleta'}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.textPrimary,
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
                            ],
                          ),
                        ),
                      ),
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
                    _buildTopNavTab(0, Icons.fitness_center_rounded, 'Meus Treinos', isLight),
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
                      color: AppTheme.primaryAccent,
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
              indicatorColor: AppTheme.primaryAccent.withValues(alpha: 0.15),
              onDestinationSelected: (i) => setState(() => _abaAtual = i),
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.fitness_center_outlined),
                  selectedIcon: Icon(Icons.fitness_center_rounded, color: AppTheme.primaryAccent),
                  label: 'Treinos',
                ),
                NavigationDestination(
                  icon: const Icon(Icons.restaurant_menu_outlined),
                  selectedIcon: Icon(Icons.restaurant_menu_rounded, color: AppTheme.primaryAccent),
                  label: 'Dieta',
                ),
                NavigationDestination(
                  icon: const Icon(Icons.show_chart_outlined),
                  selectedIcon: Icon(Icons.show_chart_rounded, color: AppTheme.primaryAccent),
                  label: 'Evolução',
                ),
                NavigationDestination(
                  icon: const Icon(Icons.paid_outlined),
                  selectedIcon: Icon(Icons.paid_rounded, color: AppTheme.primaryAccent),
                  label: 'Financeiro',
                ),
              ],
            ),
    );
  }

  Widget _buildTopNavTab(int index, IconData icon, String label, bool isLight) {
    final selected = _abaAtual == index;
    final activeColor = AppTheme.primaryAccent;

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
    final accentGreen = AppTheme.primaryAccent;

    return RefreshIndicator(
      onRefresh: _carregarDadosAluno,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        children: [
          // Header Executivo: Meus Treinos + Resumo de Consistência + Ação PDF
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderSubtle, width: 1.0),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 16,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: accentGreen.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.fitness_center_rounded, color: accentGreen, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Meus Treinos',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$_treinosMes treinos no mês • $_treinosTotal concluídos no total',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
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
                      side: BorderSide(color: borderSubtle, width: 1.1),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: Icon(Icons.picture_as_pdf_outlined, size: 17, color: accentGreen),
                    label: const Text(
                      'Exportar Ficha',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
              ],
            ),
          ),

          if (_minhasAulasAgenda.isNotEmpty) ...[
            const SizedBox(height: 18),
            Builder(
              builder: (_) {
                final ag = _minhasAulasAgenda.first;
                final dt = DateTime.tryParse((ag['dataHoraInicio'] ?? '').toString()) ?? DateTime.now();
                final fmt = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} às ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderSubtle, width: 1.0),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.electricBlue.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.calendar_today_rounded, size: 16, color: AppTheme.electricBlue),
                      ),
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
                              const TextSpan(text: 'Próxima sessão com Personal: '),
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

          const SizedBox(height: 20),

          if (_fichas.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderSubtle, width: 1.0),
              ),
              child: Column(
                children: [
                  Icon(Icons.fitness_center_outlined, size: 44, color: AppTheme.textSecondary),
                  const SizedBox(height: 14),
                  Text(
                    'Nenhuma ficha ativa no momento',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Seu Personal Trainer está preparando sua periodização. Assim que disponibilizada, você poderá acompanhar seus exercícios e registrar cargas aqui.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13.5, height: 1.45, color: AppTheme.textSecondary),
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
            final letraBadge = nomeDivisao.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
            final badgeDisplay = letraBadge.isNotEmpty ? letraBadge.substring(letraBadge.length - 1).toUpperCase() : 'T';

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderSubtle, width: 1.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
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
                            Container(
                              width: 34,
                              height: 34,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: accentGreen.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                badgeDisplay,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: accentGreen,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                nomeDivisao,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceElevated,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${exercicios.length} exercícios',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              recolhida
                                  ? Icons.keyboard_arrow_down_rounded
                                  : Icons.keyboard_arrow_up_rounded,
                              color: AppTheme.textSecondary,
                              size: 20,
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
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () => _abrirModoExecucaoTreino(fichaMap),
                          icon: const Icon(Icons.play_arrow_rounded, size: 20),
                          label: const Text(
                            'Iniciar Treino',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
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
    final accentGreen = AppTheme.primaryAccent;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      children: [
        if (plano == null)
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderSubtle, width: 1.0),
            ),
            child: Column(
              children: [
                Icon(Icons.restaurant_menu_rounded, size: 44, color: AppTheme.textSecondary),
                const SizedBox(height: 14),
                Text(
                  'Nenhum plano alimentar ativo',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Você pode cadastrar sua rotina alimentar ou aguardar a prescrição do seu Personal Trainer.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13.5, color: AppTheme.textSecondary, height: 1.45),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _abrirModalDietaAluno,
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: const Text(
                    'Cadastrar Dieta',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderSubtle, width: 1.0),
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
                          (plano['titulo'] ?? 'Plano Alimentar').toString(),
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
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
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _abrirModalDietaAluno,
                          icon: const Icon(Icons.edit_note_rounded, size: 18),
                          label: const Text(
                            'Editar Dieta',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => CalculadoraSubstituicaoAlimentosModal.abrir(context),
                          icon: Icon(Icons.swap_horiz_rounded, size: 18, color: accentGreen),
                          label: const Text(
                            'Substituição de Alimentos',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.textPrimary,
                            side: BorderSide(color: borderSubtle, width: 1.1),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => DietaPdfService.exportarPlanoAlimentarPdf(
                            nomeAluno: _aluno['nome']?.toString() ?? 'Aluno',
                            nomePersonal: _nomePersonal,
                            plano: plano,
                            refeicoes: _minhasRefeicoes,
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.textPrimary,
                            side: BorderSide(color: borderSubtle, width: 1.1),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: Icon(Icons.picture_as_pdf_outlined, size: 16, color: accentGreen),
                          label: const Text('Exportar PDF'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _statPill('Meta Calórica', '${plano['metaKcal']} kcal', accentGreen),
                    _statPill('Proteínas', '${plano['proteinaG']}g', const Color(0xFFFF5252)),
                    _statPill('Carboidratos', '${plano['carboidratoG']}g', AppTheme.warningAmber),
                    _statPill('Gorduras', '${plano['gorduraG']}g', Colors.orange),
                    _statPill('Meta de Água', '${plano['aguaLitros']} L', AppTheme.electricBlue),
                  ],
                ),
                if ((plano['observacoes'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    'Recomendação: ${plano['observacoes']}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
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
          final alimentosTexto = (r['alimentosDescricao'] ?? '').toString().replaceAll(r'\n', '\n');

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
                  alimentosTexto,
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
    final accentGreen = AppTheme.primaryAccent;
    Map<String, dynamic> medidas = {};
    if (ultimaAval != null && ultimaAval['medidasJson'] != null) {
      try {
        medidas = Map<String, dynamic>.from(jsonDecode(ultimaAval['medidasJson'].toString()));
      } catch (_) {}
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderSubtle, width: 1.0),
          ),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 16,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: accentGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.show_chart_rounded, color: accentGreen, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Minha Evolução',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Histórico de bioimpedância e progressão de cargas',
                        style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: () => EvolucaoPdfService.exportarEvolucaoPdf(
                  nomeAluno: _aluno['nome']?.toString() ?? 'Aluno',
                  nomePersonal: _aluno['nomePersonal']?.toString() ?? _nomePersonal,
                  avaliacoes: _avaliacoes,
                  progressaoCargas: _progressaoCargas,
                  historicoTreinos: _historicoTreinos,
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textPrimary,
                  side: BorderSide(color: borderSubtle, width: 1.1),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: Icon(Icons.picture_as_pdf_outlined, size: 16, color: accentGreen),
                label: const Text('Exportar PDF'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        EvolucaoCompletaPanel(
          avaliacoes: _avaliacoes,
          progressaoCargas: _progressaoCargas,
        ),
        const SizedBox(height: 20),

        // Comparador Interativo de Fotos Antes & Depois
        ComparadorFotosAntesDepoisWidget(
          avaliacoes: _avaliacoes,
        ),
        const SizedBox(height: 20),

        // Heatmap Mensal de Consistência e Streaks de Treino
        CalendarioConsistenciaWidget(
          historicoTreinos: _historicoTreinos,
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
                    _statPill('Peso Atual', '${ultimaAval['peso']} kg', accentGreen),
                    _statPill('Altura', '${ultimaAval['altura']} m', AppTheme.electricBlue),
                    _statPill(
                      'Gordura Corporal (BF)',
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
    final accentGreen = AppTheme.primaryAccent;

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
            leading: Icon(Icons.verified_user_outlined, color: accentGreen, size: 28),
            title: Text(
              'Consultoria: $_nomePersonal',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            subtitle: Text(
              'Chave PIX: $_chavePixPersonal',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            trailing: OutlinedButton.icon(
              onPressed: () => WhatsAppService.abrirMensagem(
                _aluno['telefonePersonal']?.toString(),
                'Olá, Professor! Estou falando pelo app Coach Center.',
              ),
              icon: Icon(Icons.chat_bubble_outline_rounded, size: 16, color: accentGreen),
              label: const Text('Falar no WhatsApp'),
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
                        'R\$ ${valor.toStringAsFixed(2)} • ${pago ? 'Pago' : 'Pendente'}',
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
                    icon: const Icon(Icons.pix, size: 18),
                    label: const Text('Pagar com PIX'),
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
        color: cor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            titulo,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            valor,
            style: TextStyle(
              fontSize: 17,
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
  final int treinosNoMes;
  final List<dynamic> progressaoCargas;
  final VoidCallback onTreinoConcluido;

  const ModoExecucaoTreinoScreen({
    super.key,
    required this.ficha,
    required this.nomeAluno,
    this.treinosNoMes = 1,
    this.progressaoCargas = const [],
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

  double _obterCargaAnterior(Map<String, dynamic> ex) {
    final nome = (ex['nomeExercicio'] ?? '').toString().toLowerCase().trim();
    if (nome.isEmpty) return 0.0;
    double maxCarga = 0.0;
    for (final item in widget.progressaoCargas) {
      if (item == null) continue;
      final n = (item['nomeExercicio'] ?? '').toString().toLowerCase().trim();
      if (n == nome || (n.isNotEmpty && (n.contains(nome) || nome.contains(n)))) {
        final c = ((item['cargaKg'] ?? 0) as num).toDouble();
        if (c > maxCarga) maxCarga = c;
      }
    }
    return maxCarga;
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
          SnackBar(
            backgroundColor: AppTheme.primaryAccent,
            duration: const Duration(seconds: 3),
            content: const Text(
              'Tempo de descanso finalizado. Pronto para a próxima série.',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
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
      await ApiService().dio.post('/api/aluno/finalizar-treino', data: {
        'fichaId': widget.ficha['id'],
        'nomeTreino': widget.ficha['nomeDivisao'],
        'duracaoMinutos': duracaoMin,
        'observacaoAluno':
            'Concluídos ${_exerciciosConcluidos.length}/${_exercicios.length} exercícios com progressão de carga!',
      });

      final novosRecordes = <String>[];
      int totalSeries = 0;
      for (final ex in _exercicios) {
        final carga = ((ex['cargaKg'] ?? 0) as num).toDouble();
        final anterior = _obterCargaAnterior(ex);
        final series = (ex['series'] ?? 3) as int;
        totalSeries += series;
        if (anterior > 0 && carga > anterior) {
          final diff = carga - anterior;
          novosRecordes.add('${ex['nomeExercicio']}: ${carga.toStringAsFixed(1)} kg (+${diff.toStringAsFixed(1)} kg)');
        }
      }

      if (!mounted) return;

      await StoryCardTreinoModal.exibir(
        context: context,
        nomeAluno: widget.nomeAluno,
        nomeTreino: widget.ficha['nomeDivisao']?.toString() ?? 'Treino de Hoje',
        duracaoMinutos: duracaoMin,
        totalExercicios: _exercicios.length,
        totalSeries: totalSeries,
        novosRecordes: novosRecordes,
        treinosNoMes: widget.treinosNoMes + 1,
        onConcluir: () {
          widget.onTreinoConcluido();
          Navigator.pop(context);
        },
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao registrar treino. Verifique sua conexão.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _finalizando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLight = AppTheme.isLight;
    final accentGreen = AppTheme.primaryAccent;
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
                                  ? 'Descanso: ${_segundosRestantes}s'
                                  : 'Cronômetro de Descanso:',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
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
                final cargaAnterior = _obterCargaAnterior(ex);
                final ehNovoRecorde = cargaAnterior > 0 && carga > cargaAnterior;

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
                                    : AppTheme.primaryAccent,
                                foregroundColor: videoAberto
                                    ? accentGreen
                                    : Colors.white,
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
                                videoAberto ? 'Fechar Vídeo' : 'Ver Vídeo',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
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
                                      activeColor: AppTheme.primaryAccent,
                                      checkColor: Colors.white,
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
                                          if (cargaAnterior > 0 || ehNovoRecorde) ...[
                                            const SizedBox(height: 6),
                                            Wrap(
                                              spacing: 6,
                                              runSpacing: 4,
                                              children: [
                                                if (cargaAnterior > 0)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: isLight ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                                                      borderRadius: BorderRadius.circular(6),
                                                      border: Border.all(
                                                        color: isLight ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                                                      ),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Icon(Icons.history_rounded, size: 11, color: AppTheme.textSecondary),
                                                        const SizedBox(width: 3),
                                                        Text(
                                                          'Último: ${cargaAnterior.toStringAsFixed(1)} kg',
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            fontWeight: FontWeight.w600,
                                                            color: AppTheme.textSecondary,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                if (ehNovoRecorde)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: AppTheme.warningAmber.withValues(alpha: 0.15),
                                                      borderRadius: BorderRadius.circular(6),
                                                      border: Border.all(
                                                        color: AppTheme.warningAmber.withValues(alpha: 0.4),
                                                      ),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        const Icon(Icons.emoji_events_rounded, size: 12, color: AppTheme.warningAmber),
                                                        const SizedBox(width: 3),
                                                        Text(
                                                          '🏆 Novo Recorde (+${(carga - cargaAnterior).toStringAsFixed(1)} kg)',
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            fontWeight: FontWeight.w800,
                                                            color: isLight ? const Color(0xFFB45309) : AppTheme.warningAmber,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ],
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
                                if (carga == 0 && cargaAnterior > 0) ...[
                                  const SizedBox(width: 6),
                                  InkWell(
                                    onTap: () => _alterarCarga(index, cargaAnterior),
                                    borderRadius: BorderRadius.circular(6),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: accentGreen.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: accentGreen.withValues(alpha: 0.3)),
                                      ),
                                      child: Text(
                                        'Repetir ${cargaAnterior.toStringAsFixed(1)} kg',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: accentGreen,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
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
                        ? 'Concluindo treino...'
                        : 'Concluir Treino',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
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

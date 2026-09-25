import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/whatsapp_service.dart';
import '../../theme.dart';
import '../auth/login_screen.dart';

class SuperAdminScreen extends StatefulWidget {
  final Map<String, dynamic> session;
  const SuperAdminScreen({super.key, required this.session});

  @override
  State<SuperAdminScreen> createState() => _SuperAdminScreenState();
}

class _SuperAdminScreenState extends State<SuperAdminScreen> {
  bool _carregando = true;
  String _filtroAtual = 'TODOS';
  Map<String, dynamic> _resumo = {};
  List<dynamic> _personais = [];
  String _mesReferencia = '';

  @override
  void initState() {
    super.initState();
    _carregarDashboard();
  }

  Future<void> _carregarDashboard() async {
    setState(() => _carregando = true);
    try {
      final resp = await ApiService().dio.get(
        '/api/superadmin/dashboard',
        queryParameters: {'filtro': _filtroAtual},
      );
      setState(() {
        _mesReferencia = resp.data['mesReferencia']?.toString() ?? '';
        _resumo = Map<String, dynamic>.from(resp.data['resumoFinanceiro'] ?? {});
        _personais = resp.data['personais'] ?? [];
        _carregando = false;
      });
    } catch (_) {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _alternarKillSwitch(dynamic p) async {
    final bool ativoAtual = p['status'] == true;
    final novoStatus = !ativoAtual;

    final resp = await ApiService().dio.patch(
      '/api/superadmin/personais/${p['id']}/status',
      data: {'ativo': novoStatus},
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: novoStatus ? AppTheme.neonGreen : AppTheme.performanceRed,
        content: Text(
          resp.data['mensagem']?.toString() ?? '',
          style: TextStyle(
            color: novoStatus ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
    _carregarDashboard();
  }

  Future<void> _confirmarPagamentoSaaS(dynamic p) async {
    final resp = await ApiService().dio.post(
      '/api/superadmin/personais/${p['id']}/confirmar-pagamento',
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.neonGreen,
        content: Text(
          resp.data['mensagem']?.toString() ?? 'Pagamento confirmado!',
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
    );
    _carregarDashboard();
  }

  void _abrirModalNovoOuEditarPersonal({dynamic personalExistente}) {
    final editando = personalExistente != null;
    final nomeCtrl = TextEditingController(
      text: editando ? personalExistente['nomeProfissional']?.toString() : '',
    );
    final crefCtrl = TextEditingController(
      text: editando ? personalExistente['cref']?.toString() : 'CREF 000000-G/SP',
    );
    final cpfCtrl = TextEditingController(
      text: editando ? personalExistente['cpfCnpj']?.toString() : '',
    );
    final whatsCtrl = TextEditingController(
      text: editando ? personalExistente['telefone']?.toString() : '5511999990000',
    );
    final emailCtrl = TextEditingController(
      text: editando ? personalExistente['email']?.toString() : '',
    );
    final senhaCtrl = TextEditingController(text: 'admin123');
    final valorCtrl = TextEditingController(
      text: editando
          ? (personalExistente['valorAssinatura'] ?? 99.90).toString()
          : '99.90',
    );
    final diaCtrl = TextEditingController(
      text: editando ? (personalExistente['diaVencimento'] ?? 10).toString() : '10',
    );
    String planoSelecionado =
        editando ? (personalExistente['plano']?.toString() ?? 'PRO') : 'PRO';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          backgroundColor: AppTheme.surfaceCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.person_add_alt_1, color: AppTheme.neonGreen),
              const SizedBox(width: 10),
              Text(editando ? 'Editar Personal Trainer' : '+ Novo Personal Trainer (Tenant)'),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nomeCtrl,
                    decoration: const InputDecoration(labelText: 'Nome do Personal / Consultoria *'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: crefCtrl,
                          decoration: const InputDecoration(labelText: 'CREF'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: cpfCtrl,
                          decoration: const InputDecoration(labelText: 'CPF / CNPJ'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: whatsCtrl,
                          decoration: const InputDecoration(labelText: 'WhatsApp (com DDD)'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: ['BASICO', 'PRO', 'ELITE'].contains(planoSelecionado)
                              ? planoSelecionado
                              : 'PRO',
                          decoration: const InputDecoration(labelText: 'Plano SaaS'),
                          items: const [
                            DropdownMenuItem(value: 'BASICO', child: Text('PLANO BÁSICO')),
                            DropdownMenuItem(value: 'PRO', child: Text('PLANO PRO')),
                            DropdownMenuItem(value: 'ELITE', child: Text('PLANO ELITE')),
                          ],
                          onChanged: (v) {
                            if (v != null) {
                              setModalState(() {
                                planoSelecionado = v;
                                if (!editando) {
                                  valorCtrl.text = v == 'BASICO'
                                      ? '59.90'
                                      : v == 'PRO'
                                          ? '99.90'
                                          : '149.90';
                                }
                              });
                            }
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
                          controller: valorCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Valor Assinatura (R\$)'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: diaCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Dia de Vencimento'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(labelText: 'E-mail de Login do Personal *'),
                  ),
                  if (!editando) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: senhaCtrl,
                      decoration: const InputDecoration(labelText: 'Senha Inicial do Personal *'),
                    ),
                  ],
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
                final payload = {
                  'nomeProfissional': nomeCtrl.text.trim(),
                  'cref': crefCtrl.text.trim(),
                  'cpfCnpj': cpfCtrl.text.trim(),
                  'telefone': whatsCtrl.text.trim(),
                  'chavePix': whatsCtrl.text.trim(),
                  'plano': planoSelecionado,
                  'valorAssinatura': double.tryParse(valorCtrl.text.replaceAll(',', '.')) ?? 99.90,
                  'diaVencimento': int.tryParse(diaCtrl.text) ?? 10,
                  'email': emailCtrl.text.trim(),
                  'senha': senhaCtrl.text.trim(),
                  'marcarPagoNoMes': true,
                };

                if (editando) {
                  await ApiService().dio.put(
                    '/api/superadmin/personais/${personalExistente['id']}',
                    data: payload,
                  );
                } else {
                  await ApiService().dio.post('/api/superadmin/personais', data: payload);
                }
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                _carregarDashboard();
              },
              icon: const Icon(Icons.check),
              label: Text(editando ? 'SALVAR ALTERAÇÕES' : 'CADASTRAR PERSONAL'),
            ),
          ],
        ),
      ),
    );
  }

  void _abrirModalRedefinirSenha(dynamic p) {
    final novaSenhaCtrl = TextEditingController(text: 'admin123');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        title: Text('Redefinir Senha — ${p['nomeProfissional']}'),
        content: TextField(
          controller: novaSenhaCtrl,
          decoration: const InputDecoration(labelText: 'Nova Senha (mín. 6 caracteres)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              await ApiService().dio.post(
                '/api/superadmin/personais/${p['id']}/redefinir-senha',
                data: {'novaSenha': novaSenhaCtrl.text.trim()},
              );
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: AppTheme.neonGreen,
                  content: Text(
                    '🔑 Senha redefinida com sucesso!',
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ),
              );
            },
            child: const Text('REDEFINIR SENHA'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final receitaPrevista = (_resumo['receitaPrevista'] ?? 0).toDouble();
    final receitaRecebida = (_resumo['receitaRecebida'] ?? 0).toDouble();
    final emDia = _resumo['personaisEmDia'] ?? 0;
    final pendentes = _resumo['personaisPendentes'] ?? 0;
    final totalAlunosSaaS = _resumo['totalAlunosSaaS'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.electricBlue.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.shield, color: AppTheme.electricBlue),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PERSONALPRO — PAINEL MASTER SAAS',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
                Text(
                  'SuperAdmin • Competência $_mesReferencia • $totalAlunosSaaS alunos ativos na plataforma',
                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ],
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () => _abrirModalNovoOuEditarPersonal(),
            icon: const Icon(Icons.add),
            label: const Text('+ NOVO PERSONAL TRAINER'),
          ),
          const SizedBox(width: 10),
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
          const SizedBox(width: 8),
        ],
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _carregarDashboard,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Cards Financeiros do SaaS
                  Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    children: [
                      _kpiCard(
                        titulo: 'RECEITA MENSAL RECEBIDA',
                        valor: 'R\$ ${receitaRecebida.toStringAsFixed(2)}',
                        subtitulo: 'Assinaturas quitadas no mês $_mesReferencia',
                        icone: Icons.payments,
                        cor: AppTheme.neonGreen,
                      ),
                      _kpiCard(
                        titulo: 'RECEITA MENSAL PREVISTA (MRR)',
                        valor: 'R\$ ${receitaPrevista.toStringAsFixed(2)}',
                        subtitulo: 'Potencial mensal recorrente ativo',
                        icone: Icons.trending_up,
                        cor: AppTheme.electricBlue,
                      ),
                      _kpiCard(
                        titulo: 'PERSONAIS EM DIA',
                        valor: '$emDia',
                        subtitulo: 'Pagaram no mês atual',
                        icone: Icons.verified,
                        cor: AppTheme.neonGreen,
                      ),
                      _kpiCard(
                        titulo: 'PAGAMENTO PENDENTE',
                        valor: '$pendentes',
                        subtitulo: 'Aguardando confirmação ou cobrança',
                        icone: Icons.warning_amber_rounded,
                        cor: AppTheme.warningAmber,
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // Filtros de Status Financeiro SaaS
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _filtroChip('TODOS', 'Todos os Personais'),
                        const SizedBox(width: 8),
                        _filtroChip('EM_DIA', '✅ Em Dia no Mês ($emDia)'),
                        const SizedBox(width: 8),
                        _filtroChip('PENDENTE', '⏳ Pagamento Pendente ($pendentes)'),
                        const SizedBox(width: 8),
                        _filtroChip(
                          'BLOQUEADOS',
                          '🚫 Bloqueados Kill-Switch (${_resumo['personaisBloqueados'] ?? 0})',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Lista de Personais (Tenants)
                  ..._personais.map((p) {
                    final ativo = p['status'] == true;
                    final pagoNoMes = p['pagoNoMes'] == 1;
                    final plano = p['plano']?.toString() ?? 'PRO';
                    final valorAssinatura = (p['valorAssinatura'] ?? 0).toDouble();

                    return Card(
                      margin: const EdgeInsets.only(bottom: 14),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: ativo
                                      ? AppTheme.neonGreen.withValues(alpha: 0.15)
                                      : AppTheme.performanceRed.withValues(alpha: 0.2),
                                  child: Icon(
                                    ativo ? Icons.fitness_center : Icons.lock,
                                    color: ativo ? AppTheme.neonGreen : AppTheme.performanceRed,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 6,
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        children: [
                                          Text(
                                            p['nomeProfissional']?.toString() ?? '',
                                            style: const TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          _badge(
                                            plano,
                                            AppTheme.electricBlue,
                                          ),
                                          _badge(
                                            pagoNoMes ? 'EM DIA' : 'PAGAMENTO PENDENTE',
                                            pagoNoMes ? AppTheme.neonGreen : AppTheme.warningAmber,
                                          ),
                                          _badge(
                                            ativo ? 'ACESSO LIBERADO' : 'BLOQUEADO (KILL-SWITCH)',
                                            ativo ? AppTheme.neonGreen : AppTheme.performanceRed,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'E-mail: ${p['email']} • CREF: ${p['cref'] ?? '-'} • CPF/CNPJ: ${p['cpfCnpj'] ?? '-'}',
                                        style: const TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 12.5,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Assinatura: R\$ ${valorAssinatura.toStringAsFixed(2)} (Venc. dia ${p['diaVencimento']})  |  👥 ${p['totalAlunos']} Alunos  |  📋 ${p['totalFichasAtivas']} Fichas Ativas',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            const Divider(color: Colors.white12, height: 1),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                if (!pagoNoMes)
                                  ElevatedButton.icon(
                                    onPressed: () => _confirmarPagamentoSaaS(p),
                                    icon: const Icon(Icons.check_circle_outline, size: 18),
                                    label: const Text('Confirmar Pagamento'),
                                  ),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: ativo
                                        ? AppTheme.performanceRed
                                        : AppTheme.neonGreen,
                                    foregroundColor: ativo ? Colors.white : Colors.black,
                                  ),
                                  onPressed: () => _alternarKillSwitch(p),
                                  icon: Icon(
                                    ativo ? Icons.block : Icons.lock_open,
                                    size: 18,
                                  ),
                                  label: Text(
                                    ativo
                                        ? 'Bloquear Acesso (Kill-Switch)'
                                        : 'Liberar Acesso Personal + Alunos',
                                  ),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () =>
                                      _abrirModalNovoOuEditarPersonal(personalExistente: p),
                                  icon: const Icon(Icons.edit, size: 18),
                                  label: const Text('Editar Dados'),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () => _abrirModalRedefinirSenha(p),
                                  icon: const Icon(Icons.key, size: 18),
                                  label: const Text('Redefinir Senha'),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () => WhatsAppService.abrirMensagem(
                                    p['telefone']?.toString(),
                                    'Olá, ${p['nomeProfissional']}! Tudo bem? Aqui é do suporte Master PersonalPro SaaS.',
                                  ),
                                  icon: const Icon(Icons.chat, size: 18, color: AppTheme.neonGreen),
                                  label: const Text('Chamar no WhatsApp'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }

  Widget _kpiCard({
    required String titulo,
    required String valor,
    required String subtitulo,
    required IconData icone,
    required Color cor,
  }) {
    return Container(
      width: 265,
      padding: const EdgeInsets.all(18),
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
                titulo,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textSecondary,
                ),
              ),
              Icon(icone, color: cor, size: 22),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            valor,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: cor),
          ),
          const SizedBox(height: 4),
          Text(
            subtitulo,
            style: const TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _filtroChip(String codigo, String label) {
    final selecionado = _filtroAtual == codigo;
    return ChoiceChip(
      label: Text(label),
      selected: selecionado,
      selectedColor: AppTheme.neonGreen,
      labelStyle: TextStyle(
        color: selecionado ? Colors.black : AppTheme.textPrimary,
        fontWeight: FontWeight.bold,
      ),
      onSelected: (_) {
        setState(() => _filtroAtual = codigo);
        _carregarDashboard();
      },
    );
  }

  Widget _badge(String texto, Color cor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cor.withValues(alpha: 0.5)),
      ),
      child: Text(
        texto,
        style: TextStyle(color: cor, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}

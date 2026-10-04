import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme.dart';

class MiniTutorialDialog extends StatefulWidget {
  final bool isPersonal;

  const MiniTutorialDialog({super.key, required this.isPersonal});

  /// Exibe o tutorial caso ainda não tenha sido visto pelo usuário, ou obrigatoriamente se [forcar] = true.
  static Future<void> mostrar(
    BuildContext context, {
    required bool isPersonal,
    bool forcar = false,
  }) async {
    final chaveStorage = isPersonal ? 'tutorial_personal_visto' : 'tutorial_aluno_visto';
    if (!forcar) {
      final jaVisto = await ApiService().storage.read(key: chaveStorage);
      if (jaVisto == 'true') return;
    }

    if (!context.mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => MiniTutorialDialog(isPersonal: isPersonal),
    );

    // Marca como visto após fechar
    await ApiService().storage.write(key: chaveStorage, value: 'true');
  }

  @override
  State<MiniTutorialDialog> createState() => _MiniTutorialDialogState();
}

class _MiniTutorialDialogState extends State<MiniTutorialDialog> {
  final PageController _pageController = PageController();
  int _paginaAtual = 0;

  late final List<TutorialStep> _passos;

  @override
  void initState() {
    super.initState();
    _passos = widget.isPersonal ? _passosPersonal : _passosAluno;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 600;
    final primary = widget.isPersonal ? AppTheme.neonGreen : AppTheme.primaryAccent;
    final totalPassos = _passos.length;

    return Dialog(
      backgroundColor: AppTheme.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: primary.withValues(alpha: 0.35), width: 1.5),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isDesktop ? 520 : 420,
          maxHeight: 640,
        ),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Cabeçalho com Badge e Fechar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: primary.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lightbulb_outline_rounded, size: 15, color: primary),
                        const SizedBox(width: 6),
                        Text(
                          widget.isPersonal ? 'TUTORIAL DO PERSONAL' : 'TUTORIAL DO ALUNO',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    tooltip: 'Fechar',
                    color: AppTheme.textSecondary,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Conteúdo em Carrossel (PageView)
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: totalPassos,
                  onPageChanged: (i) => setState(() => _paginaAtual = i),
                  itemBuilder: (context, i) {
                    final passo = _passos[i];
                    return SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 12),
                          // Ícone Ilustrado
                          Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  passo.corDestaque.withValues(alpha: 0.25),
                                  passo.corDestaque.withValues(alpha: 0.05),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              border: Border.all(
                                color: passo.corDestaque.withValues(alpha: 0.5),
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              passo.icone,
                              size: 42,
                              color: passo.corDestaque,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Indicador de Passo
                          Text(
                            'ETAPA ${_paginaAtual + 1} DE $totalPassos',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: passo.corDestaque,
                            ),
                          ),
                          const SizedBox(height: 6),

                          // Título Principal
                          Text(
                            passo.titulo,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18.5,
                              fontWeight: FontWeight.w800,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Descrição
                          Text(
                            passo.descricao,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13.5,
                              height: 1.45,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Cards de Destaques Rápidos
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppTheme.bgDark.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.07),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: passo.destaques.map((d) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 3.5),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.check_circle_outline_rounded,
                                        size: 16,
                                        color: passo.corDestaque,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          d,
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            color: AppTheme.textPrimary,
                                            height: 1.3,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Barra de Paginação (Dots) + Botões de Navegação
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Botão Pular
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Pular',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  // Indicadores de Bolinhas
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(totalPassos, (i) {
                      final ativa = i == _paginaAtual;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        height: 7,
                        width: ativa ? 22 : 7,
                        decoration: BoxDecoration(
                          color: ativa ? primary : AppTheme.textSecondary.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),

                  // Botão Próximo ou Concluir
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: const Color(0xFF0A0E12),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      if (_paginaAtual < totalPassos - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _paginaAtual == totalPassos - 1 ? 'Concluir' : 'Próximo',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          _paginaAtual == totalPassos - 1 ? Icons.check : Icons.arrow_forward_rounded,
                          size: 16,
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
    );
  }
}

class TutorialStep {
  final String titulo;
  final String descricao;
  final IconData icone;
  final Color corDestaque;
  final List<String> destaques;

  TutorialStep({
    required this.titulo,
    required this.descricao,
    required this.icone,
    required this.corDestaque,
    required this.destaques,
  });
}

// ─── ETAPAS DO TUTORIAL DO PERSONAL TRAINER ─────────────────────────────────
final List<TutorialStep> _passosPersonal = [
  TutorialStep(
    titulo: 'Bem-vindo ao Coach Center!',
    descricao:
        'Sua central executiva e inteligente de consultoria fitness. Gerencie alunos, prescreva treinos e automatize suas cobranças em um só lugar.',
    icone: Icons.fitness_center_rounded,
    corDestaque: AppTheme.neonGreen,
    destaques: [
      'Controle completo de múltiplos alunos sem burocracia.',
      'Plataforma 100% responsiva para celular, tablet e computador.',
      'Suporte a modelos de treino pré-configurados e salvos.',
    ],
  ),
  TutorialStep(
    titulo: 'Carteira de Alunos & Fotos',
    descricao:
        'Adicione novos alunos com nome, WhatsApp e mensalidade. Você pode tirar ou trocar a foto do aluno tocando no avatar a qualquer momento.',
    icone: Icons.people_alt_rounded,
    corDestaque: Colors.blueAccent,
    destaques: [
      'Radar de Alunos Ausentes: saiba quem não treina há mais de 7 dias.',
      'Contato direto com o aluno via WhatsApp com 1 toque.',
      'Acompanhamento de objetivos individuais de cada atleta.',
    ],
  ),
  TutorialStep(
    titulo: 'Prescrição de Fichas e Modelos',
    descricao:
        'Crie divisões de treino (A, B, C, Push/Pull/Legs) ou use seus próprios modelos salvos para prescrever treinos em segundos.',
    icone: Icons.playlist_add_check_circle_rounded,
    corDestaque: AppTheme.neonGreen,
    destaques: [
      'Mais de 120 exercícios com animações 3D e instruções técnicas.',
      'Salve divisões como modelo rápido para reaproveitar com próximos alunos.',
      'Exportação da ficha completa em PDF oficial com seu CREF.',
    ],
  ),
  TutorialStep(
    titulo: 'Avaliação Física & Perimetria MFIT',
    descricao:
        'Lançamento completo de peso, altura, % de gordura, fotos de evolução antes/depois e todas as medidas corporais por fita métrica.',
    icone: Icons.straighten_rounded,
    corDestaque: Colors.amber,
    destaques: [
      'Perimetria completa: tórax, braços, cintura, quadril, coxas e panturrilhas.',
      'Gráficos comparativos automáticos da evolução física do aluno.',
      'Histórico seguro e auditável de todas as avaliações passadas.',
    ],
  ),
  TutorialStep(
    titulo: 'Cobranças PIX e Notificações',
    descricao:
        'Configure sua chave PIX no seu perfil. O sistema gera automaticamente o QR Code Copia e Cola para cada mensalidade.',
    icone: Icons.qr_code_2_rounded,
    corDestaque: AppTheme.neonGreen,
    destaques: [
      'Alunos copiam a chave PIX e pagam diretamente para você.',
      'Notificações em tempo real sempre que um aluno finalizar o treino.',
      'Acesso seguro e proteção multi-tenant completa.',
    ],
  ),
];

// ─── ETAPAS DO TUTORIAL DO ALUNO (ATLETA) ───────────────────────────────────
final List<TutorialStep> _passosAluno = [
  TutorialStep(
    titulo: 'Seu Treino Personalizado',
    descricao:
        'Aqui você acessa os treinos prescritos com exclusividade pelo seu Personal Trainer para alcançar seu objetivo de forma rápida e segura.',
    icone: Icons.sports_gymnastics_rounded,
    corDestaque: AppTheme.primaryAccent,
    destaques: [
      'Visualize suas divisões de treino (A, B, C, etc.) ativas.',
      'Acesse orientações técnicas e detalhes passados pelo seu coach.',
      'Toque no seu nome ou foto no topo para personalizar seu perfil.',
    ],
  ),
  TutorialStep(
    titulo: 'Exercícios com Demonstração 3D',
    descricao:
        'Toque em qualquer exercício para abrir o Story Card interativo com vídeo de execução correta e músculos trabalhados.',
    icone: Icons.play_circle_fill_rounded,
    corDestaque: Colors.tealAccent,
    destaques: [
      'Animação 3D mostrando a postura exata para evitar lesões.',
      'Contagem de séries, repetições e descanso sugerido pelo coach.',
      'Timer com cronômetro integrado de descanso entre as séries.',
    ],
  ),
  TutorialStep(
    titulo: 'Registro de Carga & Evolução',
    descricao:
        'Conforme for ficando mais forte, digite o novo peso utilizado em cada exercício. O app registra todo seu histórico de cargas.',
    icone: Icons.trending_up_rounded,
    corDestaque: AppTheme.primaryAccent,
    destaques: [
      'Gráficos automáticos mostram sua progressão de força em cada exercício.',
      'Compare seu peso inicial com o peso atual.',
      'Estimule seu músculo com o princípio de sobrecarga progressiva.',
    ],
  ),
  TutorialStep(
    titulo: 'Finalizar Treino & Consistência',
    descricao:
        'Ao concluir seus exercícios, toque no botão "Finalizar Treino". Seu personal é notificado instantaneamente e seu calendário pontua consistência.',
    icone: Icons.check_circle_outline_rounded,
    corDestaque: Colors.greenAccent,
    destaques: [
      'Calendário de consistência estilo GitHub registrando seus dias de treino.',
      'Seu treinador sabe que você treinou e acompanha sua disciplina.',
      'Total de treinos no mês e estatísticas de frequência acumulada.',
    ],
  ),
  TutorialStep(
    titulo: 'Dieta, Medidas e Fotos',
    descricao:
        'Acompanhe seu plano alimentar com metas de proteínas, carboidratos e água diária, além de comparar suas fotos de antes e depois.',
    icone: Icons.restaurant_menu_rounded,
    corDestaque: Colors.orangeAccent,
    destaques: [
      'Calculadora de substituição de alimentos para flexibilizar a dieta.',
      'Visualizador comparativo de fotos Antes & Depois.',
      'Acesso fácil ao PIX da consultoria na aba Financeiro.',
    ],
  ),
];

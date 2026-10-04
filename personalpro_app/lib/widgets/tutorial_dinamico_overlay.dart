import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/api_service.dart';

class TutorialPasso {
  final int abaIndex;
  final String numeroPasso; // Ex: "1 / 5"
  final String titulo;
  final String descricao;
  final IconData icone;
  final String dica;

  TutorialPasso({
    required this.abaIndex,
    required this.numeroPasso,
    required this.titulo,
    required this.descricao,
    required this.icone,
    required this.dica,
  });
}

class TutorialDinamicoOverlay {
  static const String _prefKeyPersonal = 'tutorial_dinamico_personal_v1';
  static const String _prefKeyAluno = 'tutorial_dinamico_aluno_v1';

  static final List<TutorialPasso> passosPersonal = [
    TutorialPasso(
      abaIndex: 0,
      numeroPasso: '1 / 5',
      titulo: 'Início & Métricas da Consultoria',
      descricao:
          'Aqui você tem a visão geral do seu negócio: total de alunos ativos, frequência de treinos concluídos na semana, receita mensal recebida e o Radar de Alunos em Risco (+7 dias sem treinar).',
      icone: Icons.dashboard_rounded,
      dica: '💡 Dica: No Radar de Alunos, você pode mandar mensagem de incentivo no WhatsApp com 1 clique!',
    ),
    TutorialPasso(
      abaIndex: 1,
      numeroPasso: '2 / 5',
      titulo: 'Gestão de Alunos & Avaliações',
      descricao:
          'Cadastre novos alunos, visualize fotos de perfil, edite planos e acerte mensalidades. Na Central de Evolução, analise gráficos de peso, medidas corporais, percentual de gordura e fotos antes x depois.',
      icone: Icons.group_rounded,
      dica: '💡 Dica: Agora você também pode excluir alunos ou inativar perfis com segurança.',
    ),
    TutorialPasso(
      abaIndex: 2,
      numeroPasso: '3 / 5',
      titulo: 'Montagem de Treinos & Fichas',
      descricao:
          'Monte fichas completas para cada aluno. Escolha a divisão desejada (A, B, C, D, E, Push/Pull/Legs), salve seus próprios modelos de treino e adicione exercícios com demonstração em GIF animado.',
      icone: Icons.fitness_center_rounded,
      dica: '💡 Dica: O aluno vê o cronômetro de descanso e GIF animado durante o treino no app dele!',
    ),
    TutorialPasso(
      abaIndex: 3,
      numeroPasso: '4 / 5',
      titulo: 'Dieta Inteligente & Macros',
      descricao:
          'Calcule TMB e GET pelo método Mifflin-St Jeor. Se o aluno não tiver dieta cadastrada, use o botão "Gerar Dieta Inteligente" para criar um protocolo com macros e refeições ajustadas ao objetivo dele.',
      icone: Icons.restaurant_menu_rounded,
      dica: '💡 Dica: Você e o aluno podem exportar o plano alimentar em PDF estilizado para imprimir ou salvar!',
    ),
    TutorialPasso(
      abaIndex: 4,
      numeroPasso: '5 / 5',
      titulo: 'PIX Automático & Cobranças',
      descricao:
          'Configure sua Chave PIX uma única vez. No início do mês, gere as cobranças com 1 toque! O sistema cria QR Codes e mensagens prontas com PIX Copia-e-Cola para cobrar no WhatsApp.',
      icone: Icons.pix_rounded,
      dica: '💡 Dica: Ao confirmar o recebimento, envie o recibo oficial de pagamento direto no WhatsApp do aluno.',
    ),
  ];

  static final List<TutorialPasso> passosAluno = [
    TutorialPasso(
      abaIndex: 0,
      numeroPasso: '1 / 4',
      titulo: 'Meu Treino do Dia & Execução',
      descricao:
          'Visualize sua ficha prescrita pelo seu Personal Trainer, acompanhe suas séries, cargas e repetições com cronômetro de descanso e animações explicativas de cada exercício.',
      icone: Icons.fitness_center_rounded,
      dica: '💡 Dica: Ao concluir seu treino, seu Personal recebe uma notificação instantânea!',
    ),
    TutorialPasso(
      abaIndex: 1,
      numeroPasso: '2 / 4',
      titulo: 'Minha Dieta & Equivalência',
      descricao:
          'Acompanhe suas refeições do dia, metas calóricas, proteínas, carboidratos e consumo diário de água. Use a Calculadora de Substituições para trocar alimentos mantendo os mesmos macros.',
      icone: Icons.restaurant_menu_rounded,
      dica: '💡 Dica: Você pode gerar uma dieta sugerida inteligente baseada no seu objetivo e medidas!',
    ),
    TutorialPasso(
      abaIndex: 2,
      numeroPasso: '3 / 4',
      titulo: 'Minha Evolução & Gráficos',
      descricao:
          'Confira suas avaliações físicas, histórico de pesagem, percentual de gordura, medidas corporais, evolução de carga nos exercícios e comparativo visual de fotos antes e depois.',
      icone: Icons.auto_graph_rounded,
      dica: '💡 Dica: Veja no gráfico de linha o progresso das suas cargas semana a semana!',
    ),
    TutorialPasso(
      abaIndex: 3,
      numeroPasso: '4 / 4',
      titulo: 'Minhas Mensalidades & PIX',
      descricao:
          'Acompanhe o status das suas mensalidades, copie o código PIX Copia-e-Cola com 1 toque ou escaneie o QR Code para pagar sua consultoria sem complicação.',
      icone: Icons.pix_rounded,
      dica: '💡 Dica: Após pagar, seu Personal confirma o recebimento e emite seu recibo digital.',
    ),
  ];

  static Future<void> verificarEExibirSePrimeiraVez(
    BuildContext context, {
    required bool isPersonal,
    required Function(int aba) onMudarAba,
  }) async {
    final chave = isPersonal ? _prefKeyPersonal : _prefKeyAluno;
    final val = await ApiService().storage.read(key: chave);
    final jaViu = val == 'true';
    if (!jaViu && context.mounted) {
      exibir(context, isPersonal: isPersonal, onMudarAba: onMudarAba);
    }
  }

  static void exibir(
    BuildContext context, {
    required bool isPersonal,
    required Function(int aba) onMudarAba,
  }) {
    final passos = isPersonal ? passosPersonal : passosAluno;
    int passoAtual = 0;

    // Coloca na primeira aba
    onMudarAba(passos[0].abaIndex);

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final passo = passos[passoAtual];
            final isUltimo = passoAtual == passos.length - 1;

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161B26),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFFFB300), width: 1.8),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFB300).withValues(alpha: 0.25),
                        blurRadius: 28,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cabeçalho do Passo (Estilo Tutorial Oficial Image 3)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFB300).withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFFFB300), width: 1.2),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(passo.icone, size: 16, color: const Color(0xFFFFB300)),
                                const SizedBox(width: 6),
                                Text(
                                  passo.numeroPasso,
                                  style: const TextStyle(
                                    color: Color(0xFFFFB300),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white60, size: 20),
                            onPressed: () {
                              _marcarVisto(isPersonal);
                              Navigator.pop(ctx);
                            },
                            tooltip: 'Fechar Tutorial',
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Título do Passo em Amarelo/Dourado Destacado
                      Text(
                        passo.titulo,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFFFB300),
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Descrição Clara
                      Text(
                        passo.descricao,
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: Colors.white,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Card de Dica Prática
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F131C),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Text(
                          passo.dica,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.neonGreen.withValues(alpha: 0.9),
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),

                      // Barra de Progresso
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: (passoAtual + 1) / passos.length,
                          backgroundColor: Colors.white10,
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFB300)),
                          minHeight: 4,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Botões de Ação: [Pular] [< Anterior] [Próximo >]
                      Row(
                        children: [
                          TextButton(
                            onPressed: () {
                              _marcarVisto(isPersonal);
                              Navigator.pop(ctx);
                            },
                            child: const Text(
                              'Pular',
                              style: TextStyle(color: Colors.white60, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const Spacer(),
                          if (passoAtual > 0)
                            TextButton.icon(
                              onPressed: () {
                                setDialogState(() {
                                  passoAtual--;
                                  onMudarAba(passos[passoAtual].abaIndex);
                                });
                              },
                              icon: const Icon(Icons.chevron_left, size: 18, color: Colors.white70),
                              label: const Text(
                                'Anterior',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFB300),
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              if (isUltimo) {
                                _marcarVisto(isPersonal);
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    backgroundColor: Color(0xFFFFB300),
                                    content: Text(
                                      '🎉 Tutorial concluído! Você está pronto para dominar a plataforma.',
                                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                );
                              } else {
                                setDialogState(() {
                                  passoAtual++;
                                  onMudarAba(passos[passoAtual].abaIndex);
                                });
                              }
                            },
                            child: Text(
                              isUltimo ? 'Concluir 🎉' : 'Próximo >',
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  static Future<void> _marcarVisto(bool isPersonal) async {
    final chave = isPersonal ? _prefKeyPersonal : _prefKeyAluno;
    await ApiService().storage.write(key: chave, value: 'true');
  }
}

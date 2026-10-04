import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/whatsapp_service.dart';
import '../../theme.dart';

class PlanosApresentacaoScreen extends StatefulWidget {
  const PlanosApresentacaoScreen({super.key});

  @override
  State<PlanosApresentacaoScreen> createState() => _PlanosApresentacaoScreenState();
}

class _PlanosApresentacaoScreenState extends State<PlanosApresentacaoScreen> {
  static const String whatsappRonald = '27996234460';
  bool _planoAnual = false;

  void _abrirWhatsApp(String mensagem) {
    WhatsAppService.abrirMensagem(whatsappRonald, mensagem);
  }

  void _abrirSiteWeb() async {
    if (kIsWeb) {
      final uri = Uri.parse('/site/index.html');
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    } else {
      _abrirWhatsApp('Olá Ronald! Gostaria de receber o link do site do Coach Center para conhecer todos os recursos.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;
    final isMobile = screenW < 700;

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceCard,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.fitness_center_rounded, color: AppTheme.primaryAccent, size: 18),
            ),
            const SizedBox(width: 8),
            Text(
              'COACH CENTER',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                letterSpacing: 0.8,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => _abrirWhatsApp('Olá Ronald! Quero falar com você sobre a plataforma Coach Center.'),
            icon: const Icon(Icons.chat, size: 16, color: Color(0xFF25D366)),
            label: Text(
              isMobile ? 'WhatsApp' : 'Falar no WhatsApp: (27) 99623-4460',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xFF25D366)),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 32, vertical: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1080),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. HERO TAG & TITULO
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.primaryAccent.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.neonGreen,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'A PLATAFORMA Nº 1 EM LUCRO DO PERSONAL • 0% TAXA PIX',
                        style: TextStyle(
                          color: AppTheme.primaryAccent,
                          fontWeight: FontWeight.w800,
                          fontSize: isMobile ? 11 : 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Multiplique seus alunos de consultoria e receba via PIX com ZERO taxa',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isMobile ? 24 : 34,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.6,
                    color: AppTheme.textPrimary,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Fichas com GIFs biomecânicos e vídeos reais, dieta inteligente com macros automáticos (Mifflin-St Jeor), fotos antes e depois e cobrança PIX direto na sua conta bancária sem intermediação.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isMobile ? 13 : 15,
                    color: AppTheme.textSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 24),

                // BOTOES DE CONTATO HERO
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _abrirWhatsApp('Olá Ronald! Quero começar um teste grátis do Coach Center na minha consultoria.'),
                      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
                      label: const Text(
                        'Testar Grátis no WhatsApp',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                      ),
                    ),
                    if (kIsWeb)
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _abrirSiteWeb,
                        icon: const Icon(Icons.open_in_browser_rounded, size: 18),
                        label: const Text(
                          'Acessar Site Institucional Completo',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 36),

                // 2. TOGGLE ANUAL VS MENSAL
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () => setState(() => _planoAnual = false),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                          decoration: BoxDecoration(
                            color: !_planoAnual ? AppTheme.primaryAccent : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Plano Mensal',
                            style: TextStyle(
                              color: !_planoAnual ? Colors.black : AppTheme.textSecondary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => setState(() => _planoAnual = true),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                          decoration: BoxDecoration(
                            color: _planoAnual ? AppTheme.primaryAccent : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Text(
                                'Plano Anual',
                                style: TextStyle(
                                  color: _planoAnual ? Colors.black : AppTheme.textSecondary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _planoAnual ? Colors.black : AppTheme.primaryAccent,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '35% OFF',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: _planoAnual ? AppTheme.primaryAccent : Colors.black,
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
                const SizedBox(height: 24),

                // 3. CARDS DE PLANOS
                LayoutBuilder(
                  builder: (ctx, constraints) {
                    final useColumn = constraints.maxWidth < 850;
                    return Flex(
                      direction: useColumn ? Axis.vertical : Axis.horizontal,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // PLANO START
                        Expanded(
                          flex: useColumn ? 0 : 1,
                          child: _buildCardPlano(
                            titulo: 'Plano START',
                            badge: 'INICIANTE',
                            preco: _planoAnual ? 'R\$ 20,75' : 'R\$ 29,90',
                            periodo: _planoAnual ? '/mês (R\$ 249/ano)' : '/mês',
                            descricao: 'Para quem está começando a consultoria e tem até 5 alunos.',
                            itens: [
                              'Até 5 alunos ativos',
                              'Fichas de Treino Ilimitadas (A, B, C, D, E)',
                              'Biblioteca de Exercícios com GIFs e Vídeos',
                              'Prescrição de Dieta Inteligente c/ Macros',
                              'Cobrança PIX Direta (0% de Taxa)',
                            ],
                            destaque: false,
                            onAssinar: () => _abrirWhatsApp('Olá Ronald! Quero assinar o Plano START (Até 5 alunos).'),
                          ),
                        ),
                        if (useColumn) const SizedBox(height: 20) else const SizedBox(width: 16),

                        // PLANO PRO (DESTAQUE)
                        Expanded(
                          flex: useColumn ? 0 : 1,
                          child: _buildCardPlano(
                            titulo: 'Plano PRO',
                            badge: '⭐ MAIS ESCOLHIDO',
                            preco: _planoAnual ? 'R\$ 41,50' : 'R\$ 59,90',
                            periodo: _planoAnual ? '/mês (R\$ 499/ano)' : '/mês',
                            descricao: 'Para personais que vivem de consultoria e querem máxima escala.',
                            itens: [
                              'Até 30 alunos ativos',
                              'Tudo do Plano Start incluso',
                              'Fotos Antes x Depois c/ Slider Interativo',
                              'Histórico de Progressão de Carga',
                              'Envio de Recibos no WhatsApp c/ 1 Toque',
                              'Suporte VIP no WhatsApp c/ o Ronald',
                            ],
                            destaque: true,
                            onAssinar: () => _abrirWhatsApp('Olá Ronald! Quero assinar o Plano PRO (Até 30 alunos).'),
                          ),
                        ),
                        if (useColumn) const SizedBox(height: 20) else const SizedBox(width: 16),

                        // PLANO ELITE
                        Expanded(
                          flex: useColumn ? 0 : 1,
                          child: _buildCardPlano(
                            titulo: 'Plano ELITE',
                            badge: 'ILIMITADO',
                            preco: _planoAnual ? 'R\$ 66,50' : 'R\$ 89,90',
                            periodo: _planoAnual ? '/mês (R\$ 799/ano)' : '/mês',
                            descricao: 'Para grandes consultorias, academias e estúdios sem limites.',
                            itens: [
                              'Alunos ILIMITADOS (Sem travas)',
                              'Todas as ferramentas desbloqueadas',
                              'Radar de alunos inativos em risco',
                              'Onboarding dedicado na migração de alunos',
                              'Canal direto de suporte 24h',
                            ],
                            destaque: false,
                            onAssinar: () => _abrirWhatsApp('Olá Ronald! Quero assinar o Plano ELITE (Alunos Ilimitados).'),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 40),

                // 4. BOX DE CONTATO DIRETO COM O RONALD
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.primaryAccent.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF25D366).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.support_agent_rounded, color: Color(0xFF25D366), size: 36),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Tem alguma dúvida ou precisa de uma demonstração?',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Fale diretamente com Ronald Passos pelo WhatsApp: (27) 99623-4460.\nAtendimento ágil para tirar dúvidas técnicas e liberar seu teste gratuito na hora.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
                      ),
                      const SizedBox(height: 18),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _abrirWhatsApp('Olá Ronald! Estou na tela de planos do Coach Center e gostaria de falar com você.'),
                        icon: const Icon(Icons.chat, size: 20),
                        label: const Text(
                          'Chamar no WhatsApp: (27) 99623-4460',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardPlano({
    required String titulo,
    required String badge,
    required String preco,
    required String periodo,
    required String descricao,
    required List<String> itens,
    required bool destaque,
    required VoidCallback onAssinar,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: destaque ? AppTheme.primaryAccent.withValues(alpha: 0.08) : AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: destaque ? AppTheme.primaryAccent : Colors.white12,
          width: destaque ? 2.0 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: destaque ? AppTheme.primaryAccent : Colors.white10,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    color: destaque ? Colors.black : Colors.white70,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            titulo,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            descricao,
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                preco,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: destaque ? AppTheme.primaryAccent : Colors.white,
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  periodo,
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: Colors.white12),
          const SizedBox(height: 16),
          ...itens.map((it) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_outline, color: AppTheme.neonGreen, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        it,
                        style: const TextStyle(fontSize: 12.5, height: 1.3),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: destaque ? AppTheme.primaryAccent : Colors.white10,
                foregroundColor: destaque ? Colors.black : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: onAssinar,
              child: Text(
                'Assinar no WhatsApp',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  color: destaque ? Colors.black : Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

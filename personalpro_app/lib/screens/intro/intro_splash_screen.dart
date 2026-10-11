import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../aluno/aluno_home_screen.dart';
import '../auth/login_screen.dart';
import '../personal/personal_dashboard_screen.dart';
import '../superadmin/superadmin_screen.dart';

class IntroSplashScreen extends StatefulWidget {
  const IntroSplashScreen({super.key});

  @override
  State<IntroSplashScreen> createState() => _IntroSplashScreenState();
}

class _IntroSplashScreenState extends State<IntroSplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceCtrl;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnimation;

  Map<String, dynamic>? _sessaoRecuperada;
  bool _jaNavegou = false;

  @override
  void initState() {
    super.initState();

    // Animação de entrada (logo + títulos)
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _scaleAnimation = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOutCubic),
    );

    // Efeito pulsante neon contínuo para o halo do escudo
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _entranceCtrl.forward();
    _iniciarFluxoAutenticacaoETransicao();
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _iniciarFluxoAutenticacaoETransicao() async {
    // 1. Inicia verificação silenciosa de sessão salva enquanto a intro roda
    try {
      _sessaoRecuperada = await ApiService().getSavedSession();
    } catch (_) {
      _sessaoRecuperada = null;
    }

    // 2. Tempo de apreciação da animação intro (2.4 segundos)
    await Future.delayed(const Duration(milliseconds: 2400));

    if (mounted && !_jaNavegou) {
      _concluirIntro();
    }
  }

  void _concluirIntro() {
    if (_jaNavegou || !mounted) return;
    _jaNavegou = true;

    Widget destino;
    if (_sessaoRecuperada != null && _sessaoRecuperada!['token'] != null) {
      final int perfil = _sessaoRecuperada!['perfil'] ?? 2;
      if (perfil == 3) {
        destino = SuperAdminScreen(session: _sessaoRecuperada!);
      } else if (perfil == 1) {
        destino = PersonalDashboardScreen(session: _sessaoRecuperada!);
      } else {
        destino = AlunoHomeScreen(session: _sessaoRecuperada!);
      }
    } else {
      destino = const LoginScreen();
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 650),
        pageBuilder: (context, animation, secondaryAnimation) => destino,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubic,
            ),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070A11),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _concluirIntro, // Toque na tela permite pular a intro instantaneamente
        child: Stack(
          children: [
            // Fundo dinâmico com gradiente e aura neon central
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF06090F),
                      Color(0xFF090E18),
                      Color(0xFF05070C),
                    ],
                  ),
                ),
              ),
            ),

            // Halo radial verde neon atrás do logo
            Center(
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Container(
                    width: 320 * _pulseAnimation.value,
                    height: 320 * _pulseAnimation.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF00F59B).withValues(alpha: 0.18),
                          const Color(0xFF00F59B).withValues(alpha: 0.05),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Conteúdo principal centralizado
            Center(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo com Escudo e Animação de Escala + Glow
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(28),
                                  boxShadow: [
                                    // Sombra de profundidade escura
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.8),
                                      blurRadius: 30,
                                      offset: const Offset(0, 15),
                                    ),
                                    // Halo neon verde
                                    BoxShadow(
                                      color: const Color(0xFF00F59B).withValues(
                                        alpha: 0.35 * _pulseAnimation.value,
                                      ),
                                      blurRadius: 36 * _pulseAnimation.value,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(28),
                                  child: Image.asset(
                                    'assets/images/app_icon.png',
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      // Fallback elegante caso a imagem esteja carregando
                                      return Container(
                                        color: const Color(0xFF0E1626),
                                        child: const Center(
                                          child: Icon(
                                            Icons.fitness_center_rounded,
                                            size: 56,
                                            color: Color(0xFF00F59B),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 36),

                      // Título "COACH CENTER" com Tipografia Atlética
                      SlideTransition(
                        position: _slideAnimation,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Column(
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    'COACH',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 3.5,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'CENTER',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 3.5,
                                      color: const Color(0xFF00F59B),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              // Badge / Tagline de Alta Performance
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00F59B).withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: const Color(0xFF00F59B).withValues(alpha: 0.28),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  'ALTA PERFORMANCE EM GESTÃO FITNESS',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.6,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 52),

                      // Indicador de Carregamento Neon Discreto
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          children: [
                            SizedBox(
                              width: 140,
                              height: 3,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: const LinearProgressIndicator(
                                  backgroundColor: Color(0xFF1E293B),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFF00F59B),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Iniciando sistema...',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF64748B),
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Rodapé com versão e toque para pular
            Positioned(
              left: 0,
              right: 0,
              bottom: 24,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF00F59B),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'COACH CENTER v1.0 • Toque para avançar',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF475569),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

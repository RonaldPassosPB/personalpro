import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../../services/api_service.dart';
import '../../theme.dart';
import '../aluno/aluno_home_screen.dart';
import '../personal/personal_dashboard_screen.dart';
import '../superadmin/superadmin_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController(text: 'personal@personalpro.com');
  final _senhaCtrl = TextEditingController(text: 'admin123');
  bool _carregando = false;
  bool _ocultarSenha = true;
  bool _temCredencialSalva = false;
  final LocalAuthentication _localAuth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _verificarSessaoSalva();
  }

  Future<void> _verificarSessaoSalva() async {
    final savedEmail = await ApiService().storage.read(key: 'saved_email');
    if (savedEmail != null && savedEmail.isNotEmpty && mounted) {
      setState(() => _temCredencialSalva = true);
    }
  }

  Future<void> _entrarComBiometria() async {
    try {
      if (!kIsWeb) {
        final podeAutenticar = await _localAuth.canCheckBiometrics ||
            await _localAuth.isDeviceSupported();
        if (podeAutenticar) {
          final ok = await _localAuth.authenticate(
            localizedReason: 'Autentique-se para acessar o PersonalPro',
          );
          if (!ok) return;
        }
      }
      final email = await ApiService().storage.read(key: 'saved_email');
      final senha = await ApiService().storage.read(key: 'saved_password');
      if (email != null && senha != null) {
        _emailCtrl.text = email;
        _senhaCtrl.text = senha;
        await _fazerLogin();
      }
    } catch (_) {}
  }

  Future<void> _fazerLogin() async {
    setState(() => _carregando = true);
    try {
      final session = await ApiService().login(_emailCtrl.text, _senhaCtrl.text);
      if (!mounted) return;
      final int perfil = session['perfil'] ?? 2;

      Widget telaDestino;
      if (perfil == 3) {
        telaDestino = SuperAdminScreen(session: session);
      } else if (perfil == 1) {
        telaDestino = PersonalDashboardScreen(session: session);
      } else {
        telaDestino = AlunoHomeScreen(session: session);
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => telaDestino),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      final status = e.response?.statusCode;
      final data = e.response?.data;
      String msg = 'Falha ao conectar com a API PersonalPro. Verifique sua conexão e tente novamente.';
      bool bloqueadoSaaS = false;

      if (data is Map) {
        msg = data['mensagem']?.toString() ?? msg;
        bloqueadoSaaS = data['bloqueadoSaaS'] == true || status == 403;
      }

      if (bloqueadoSaaS) {
        _mostrarAlertaBloqueioKillSwitch(msg);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.performanceRed,
            content: Text(msg, style: const TextStyle(color: Colors.white)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  void _mostrarAlertaBloqueioKillSwitch(String mensagem) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.performanceRed, width: 1.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.lock_person, color: AppTheme.performanceRed, size: 28),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Acesso Suspenso (Kill-Switch)',
                style: TextStyle(
                  color: AppTheme.performanceRed,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          mensagem,
          style: const TextStyle(fontSize: 15, height: 1.45),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.performanceRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('ENTENDI'),
          ),
        ],
      ),
    );
  }

  void _preencherDemo(String email) {
    setState(() {
      _emailCtrl.text = email;
      _senhaCtrl.text = 'admin123';
    });
    _fazerLogin();
  }

  void _abrirModalRecuperarSenha() {
    final emailRecCtrl = TextEditingController(text: _emailCtrl.text.trim());
    final codigoCtrl = TextEditingController();
    final novaSenhaCtrl = TextEditingController();
    String? codigoGeradoDev;
    bool etapaCodigo = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          backgroundColor: AppTheme.surfaceCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.lock_reset, color: AppTheme.neonGreen),
              SizedBox(width: 10),
              Expanded(child: Text('Recuperar Senha (6 Dígitos)')),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: emailRecCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Seu E-mail Cadastrado',
                    prefixIcon: Icon(Icons.email_outlined, color: AppTheme.neonGreen),
                  ),
                ),
                if (codigoGeradoDev != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.neonGreen.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.neonGreen),
                    ),
                    child: Text(
                      'Código de verificação gerado: $codigoGeradoDev (válido por 15 min)',
                      style: const TextStyle(
                        color: AppTheme.neonGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
                if (etapaCodigo) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: codigoCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Código de 6 Dígitos',
                      prefixIcon: Icon(Icons.pin, color: AppTheme.neonGreen),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: novaSenhaCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Nova Senha (mín. 6 caracteres)',
                      prefixIcon: Icon(Icons.lock_outline, color: AppTheme.neonGreen),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            if (!etapaCodigo)
              ElevatedButton.icon(
                onPressed: () async {
                  try {
                    final resp = await ApiService().dio.post(
                      '/api/auth/solicitar-codigo-recuperacao',
                      data: {'email': emailRecCtrl.text.trim()},
                    );
                    setModalState(() {
                      codigoGeradoDev = resp.data['codigoDev']?.toString();
                      codigoCtrl.text = codigoGeradoDev ?? '';
                      etapaCodigo = true;
                    });
                  } catch (_) {}
                },
                icon: const Icon(Icons.send),
                label: const Text('GERAR CÓDIGO DE 6 DÍGITOS'),
              )
            else
              ElevatedButton.icon(
                onPressed: () async {
                  await ApiService().dio.post(
                    '/api/auth/redefinir-senha',
                    data: {
                      'email': emailRecCtrl.text.trim(),
                      'codigo': codigoCtrl.text.trim(),
                      'novaSenha': novaSenhaCtrl.text.trim(),
                    },
                  );
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  if (!mounted) return;
                  setState(() {
                    _emailCtrl.text = emailRecCtrl.text.trim();
                    _senhaCtrl.text = novaSenhaCtrl.text.trim();
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: AppTheme.neonGreen,
                      content: Text(
                        'Senha redefinida com sucesso!',
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.check_circle),
                label: const Text('CONFIRMAR NOVA SENHA'),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLight = AppTheme.isLight;
    final borderSubtle = isLight
        ? const Color(0xFF0F172A).withValues(alpha: 0.10)
        : Colors.white.withValues(alpha: 0.10);

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 920;

            return Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: isWide ? const Alignment(-0.45, -0.35) : const Alignment(0, -0.6),
                  radius: 1.25,
                  colors: [
                    isLight ? const Color(0xFFE4F8ED) : const Color(0xFF15261D),
                    AppTheme.bgDark,
                  ],
                ),
              ),
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isWide ? 56 : 20,
                    vertical: isWide ? 40 : 24,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: isWide ? 1140 : 460),
                    child: isWide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                flex: 11,
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 56),
                                  child: _buildEditorialColumn(isLight, borderSubtle, isWide: true),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: _buildAuthVault(isLight, borderSubtle),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildCompactBrandHeader(isLight),
                              const SizedBox(height: 20),
                              _buildAuthVault(isLight, borderSubtle),
                              const SizedBox(height: 20),
                              _buildTelemetryCard(isLight, borderSubtle),
                            ],
                          ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildWordmark(bool isLight, {double fontSize = 24}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppTheme.neonGreen.withValues(alpha: isLight ? 0.18 : 0.14),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppTheme.neonGreen.withValues(alpha: 0.65),
              width: 1.5,
            ),
          ),
          child: Icon(
            Icons.fitness_center,
            size: 18,
            color: isLight ? const Color(0xFF008744) : AppTheme.neonGreen,
          ),
        ),
        const SizedBox(width: 12),
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
              fontFamily: 'Plus Jakarta Sans',
            ),
            children: [
              TextSpan(
                text: 'PERSONAL',
                style: TextStyle(color: AppTheme.textPrimary),
              ),
              TextSpan(
                text: 'PRO',
                style: TextStyle(
                  color: isLight ? const Color(0xFF00A854) : AppTheme.neonGreen,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompactBrandHeader(bool isLight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildWordmark(isLight, fontSize: 22),
            const BotaoAlternarTema(mostrarTexto: false),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Prescrição biomecânica, nutrição e cobrança PIX em um só comando',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            height: 1.18,
            letterSpacing: -0.6,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildEditorialColumn(bool isLight, Color borderSubtle, {required bool isWide}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildWordmark(isLight, fontSize: 24),
        const SizedBox(height: 32),
        Text(
          'Prescrição biomecânica,\nnutrição e cobrança PIX\nem um só comando',
          style: TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.w800,
            height: 1.12,
            letterSpacing: -1.1,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 18),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Text(
            'Plataforma Multi-Tenant que conecta o catálogo de 121 exercícios com vídeo em português, calculadora Mifflin-St Jeor e liberação automática via PIX diretamente ao treino do aluno.',
            style: TextStyle(
              fontSize: 15.5,
              height: 1.55,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 34),
        _buildTelemetryCard(isLight, borderSubtle),
      ],
    );
  }

  Widget _buildTelemetryCard(bool isLight, Color borderSubtle) {
    final accentGreen = isLight ? const Color(0xFF008744) : AppTheme.neonGreen;
    final innerSurface = isLight ? const Color(0xFFF8FAFC) : const Color(0xFF171A21);

    return Container(
      constraints: const BoxConstraints(maxWidth: 520),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard.withValues(alpha: isLight ? 0.92 : 0.78),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderSubtle, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isLight ? 0.06 : 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Telemetria de prescrição em tempo real',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: accentGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: accentGreen.withValues(alpha: 0.45),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: accentGreen.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: innerSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Prescrição ativa no treino do aluno',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Supino Reto com Barra  •  4x 8–10 reps',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Icon(Icons.play_circle_outline, size: 15, color: accentGreen),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Descanso 90s  •  Vídeo PT-BR integrado  •  121 exercícios',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Divider(height: 1, color: borderSubtle),
                ),
                Text(
                  'Meta diária de macronutrientes (Mifflin-St Jeor)',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '2.450 kcal  •  180g Proteína  •  Status PIX Em Dia',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthVault(bool isLight, Color borderSubtle) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isLight
              ? const Color(0xFF0F172A).withValues(alpha: 0.10)
              : Colors.white.withValues(alpha: 0.10),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isLight ? 0.08 : 0.45),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: double.infinity,
            child: const BotaoAlternarTema(mostrarTexto: true),
          ),
          const SizedBox(height: 24),
          Text(
            'E-mail',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(color: AppTheme.textPrimary, fontSize: 14.5),
            decoration: const InputDecoration(
              hintText: 'seu@email.com',
              prefixIcon: Icon(Icons.alternate_email, color: AppTheme.neonGreen, size: 20),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Senha',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              TextButton(
                onPressed: _abrirModalRecuperarSenha,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  minimumSize: const Size(0, 28),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Esqueci minha senha',
                  style: TextStyle(
                    color: isLight ? const Color(0xFF008744) : AppTheme.neonGreen,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _senhaCtrl,
            obscureText: _ocultarSenha,
            onSubmitted: (_) => _fazerLogin(),
            style: TextStyle(color: AppTheme.textPrimary, fontSize: 14.5),
            decoration: InputDecoration(
              hintText: '••••••••',
              prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.neonGreen, size: 20),
              suffixIcon: IconButton(
                tooltip: _ocultarSenha ? 'Mostrar senha' : 'Ocultar senha',
                icon: Icon(
                  _ocultarSenha ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: 20,
                ),
                onPressed: () => setState(() => _ocultarSenha = !_ocultarSenha),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _carregando ? null : _fazerLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.neonGreen,
                foregroundColor: const Color(0xFF0A0E12),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _carregando
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Color(0xFF0A0E12),
                      ),
                    )
                  : const Text(
                      'ENTRAR NO SISTEMA',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
            ),
          ),
          if (_temCredencialSalva) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _entrarComBiometria,
                icon: const Icon(Icons.fingerprint, color: AppTheme.neonGreen),
                label: Text(
                  'Entrar com Biometria / Sessão Salva',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 26),
          Center(
            child: Text(
              'Acesso Rápido por Perfil (1 Clique)',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _demoChip(
                  titulo: 'Personal',
                  subtitulo: '(Coach)',
                  cor: AppTheme.neonGreen,
                  isLight: isLight,
                  onTap: () => _preencherDemo('personal@personalpro.com'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _demoChip(
                  titulo: 'Aluno',
                  subtitulo: '(Treino)',
                  cor: AppTheme.warningAmber,
                  isLight: isLight,
                  onTap: () => _preencherDemo('aluno1@personalpro.com'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _demoChip(
                  titulo: 'SuperAdmin',
                  subtitulo: '(SaaS)',
                  cor: AppTheme.electricBlue,
                  isLight: isLight,
                  onTap: () => _preencherDemo('superadmin@personalpro.com'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _demoChip({
    required String titulo,
    required String subtitulo,
    required Color cor,
    required bool isLight,
    required VoidCallback onTap,
  }) {
    final borderColor = isLight
        ? const Color(0xFF0F172A).withValues(alpha: 0.14)
        : Colors.white.withValues(alpha: 0.14);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(minHeight: 68),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: isLight
                ? const Color(0xFFF8FAFC)
                : Colors.white.withValues(alpha: 0.025),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1.1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                titulo,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitulo,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.5,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
      String msg = 'Falha ao conectar com a API PersonalPro.';
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
          side: const BorderSide(color: AppTheme.performanceRed, width: 2),
        ),
        title: const Row(
          children: [
            Icon(Icons.lock_person, color: AppTheme.performanceRed, size: 30),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Acesso Suspenso (Kill-Switch)',
                style: TextStyle(color: AppTheme.performanceRed, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          mensagem,
          style: const TextStyle(fontSize: 15, height: 1.4),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.6),
            radius: 1.1,
            colors: [
              Color(0xFF1A2E22),
              AppTheme.bgDark,
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppTheme.neonGreen.withValues(alpha: 0.25),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 30,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.neonGreen.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.neonGreen, width: 2),
                      ),
                      child: const Icon(
                        Icons.fitness_center,
                        size: 40,
                        color: AppTheme.neonGreen,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'PERSONALPRO',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: AppTheme.neonGreen,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Plataforma SaaS Multi-Tenant • Consultorias & Academias',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5),
                    ),
                    const SizedBox(height: 28),
                    TextField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'E-mail de Acesso',
                        prefixIcon: Icon(Icons.alternate_email, color: AppTheme.neonGreen),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _senhaCtrl,
                      obscureText: _ocultarSenha,
                      onSubmitted: (_) => _fazerLogin(),
                      decoration: InputDecoration(
                        labelText: 'Senha',
                        prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.neonGreen),
                        suffixIcon: IconButton(
                          icon: Icon(_ocultarSenha ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _ocultarSenha = !_ocultarSenha),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _carregando ? null : _fazerLogin,
                        icon: _carregando
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black),
                              )
                            : const Icon(Icons.login),
                        label: Text(_carregando ? 'AUTENTICANDO...' : 'ENTRAR NO SISTEMA'),
                      ),
                    ),
                    if (_temCredencialSalva) ...[
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: _entrarComBiometria,
                        icon: const Icon(Icons.fingerprint, color: AppTheme.neonGreen),
                        label: const Text(
                          'Entrar com Biometria / Sessão Salva',
                          style: TextStyle(color: AppTheme.neonGreen),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    const Divider(color: Colors.white12),
                    const SizedBox(height: 8),
                    const Text(
                      'ACESSO RÁPIDO DE DEMONSTRAÇÃO (1 CLIQUE):',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textSecondary,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _demoChip(
                            titulo: 'SuperAdmin',
                            subtitulo: 'Perfil 3 (SaaS)',
                            icone: Icons.shield_outlined,
                            cor: AppTheme.electricBlue,
                            onTap: () => _preencherDemo('superadmin@personalpro.com'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _demoChip(
                            titulo: 'Personal',
                            subtitulo: 'Perfil 1 (Coach)',
                            icone: Icons.sports_gymnastics,
                            cor: AppTheme.neonGreen,
                            onTap: () => _preencherDemo('personal@personalpro.com'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _demoChip(
                            titulo: 'Aluno',
                            subtitulo: 'Perfil 2 (Treino)',
                            icone: Icons.directions_run,
                            cor: AppTheme.warningAmber,
                            onTap: () => _preencherDemo('aluno1@personalpro.com'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _demoChip({
    required String titulo,
    required String subtitulo,
    required IconData icone,
    required Color cor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: cor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cor.withValues(alpha: 0.45)),
        ),
        child: Column(
          children: [
            Icon(icone, color: cor, size: 22),
            const SizedBox(height: 4),
            Text(
              titulo,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: cor),
            ),
            Text(
              subtitulo,
              style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

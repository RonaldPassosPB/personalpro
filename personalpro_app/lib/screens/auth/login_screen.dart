import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../../services/api_service.dart';
import '../../services/whatsapp_service.dart';
import '../../theme.dart';
import '../aluno/aluno_home_screen.dart';
import '../landing/planos_apresentacao_screen.dart';
import '../personal/personal_dashboard_screen.dart';
import '../superadmin/superadmin_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  bool _carregando = false;
  bool _ocultarSenha = true;
  bool _temCredencialSalva = false;
  bool _lembrarSessao = true;
  final LocalAuthentication _localAuth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _verificarSessaoSalva();
  }

  Future<void> _verificarSessaoSalva() async {
    try {
      final savedEmail = await ApiService().storage.read(key: 'saved_email');
      final savedPassword = await ApiService().storage.read(key: 'saved_password');
      final savedSession = await ApiService().getSavedSession();
      if (mounted) {
        setState(() {
          if (savedEmail != null && savedEmail.trim().isNotEmpty) {
            _emailCtrl.text = savedEmail.trim();
          }
          if (savedPassword != null && savedPassword.trim().isNotEmpty) {
            _senhaCtrl.text = savedPassword.trim();
          }
          _temCredencialSalva = (savedEmail != null && savedEmail.trim().isNotEmpty) ||
              (savedSession != null && savedSession['token'] != null);
        });
      }
    } catch (_) {}
  }

  Future<void> _entrarComSessaoSalva() async {
    setState(() => _carregando = true);
    try {
      final savedSession = await ApiService().getSavedSession();
      if (savedSession != null && savedSession['token'] != null) {
        final int perfil = savedSession['perfil'] ?? 2;
        Widget destino = perfil == 3
            ? SuperAdminScreen(session: savedSession)
            : (perfil == 1
                ? PersonalDashboardScreen(session: savedSession)
                : AlunoHomeScreen(session: savedSession));
        if (!mounted) return;
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => destino));
        return;
      }

      final email = await ApiService().storage.read(key: 'saved_email');
      final senha = await ApiService().storage.read(key: 'saved_password');
      if (email != null && email.isNotEmpty && senha != null && senha.isNotEmpty) {
        _emailCtrl.text = email;
        _senhaCtrl.text = senha;
        await _fazerLogin();
      } else {
        setState(() => _carregando = false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nenhuma sessão salva encontrada. Digite seu e-mail e senha.'),
            backgroundColor: AppTheme.warningAmber,
          ),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _entrarComBiometria() async {
    try {
      final podeAutenticar = await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();
      if (!podeAutenticar) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Biometria ou digital não configurada neste aparelho celular.'),
            backgroundColor: AppTheme.warningAmber,
          ),
        );
        return;
      }

      final ok = await _localAuth.authenticate(
        localizedReason: 'Autentique-se com biometria ou digital para acessar o Coach Center',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
          useErrorDialogs: true,
        ),
      );
      if (!ok) return;

      setState(() => _carregando = true);

      // 1. Tenta restaurar sessão ativa salva
      final savedSession = await ApiService().getSavedSession();
      if (savedSession != null && savedSession['token'] != null) {
        final int perfil = savedSession['perfil'] ?? 2;
        Widget destino = perfil == 3
            ? SuperAdminScreen(session: savedSession)
            : (perfil == 1
                ? PersonalDashboardScreen(session: savedSession)
                : AlunoHomeScreen(session: savedSession));
        if (!mounted) return;
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => destino));
        return;
      }

      // 2. Tenta login com credenciais seguras salvas
      final email = await ApiService().storage.read(key: 'saved_email');
      final senha = await ApiService().storage.read(key: 'saved_password');
      if (email != null && email.isNotEmpty && senha != null && senha.isNotEmpty) {
        _emailCtrl.text = email;
        _senhaCtrl.text = senha;
        await _fazerLogin();
      } else {
        setState(() => _carregando = false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Faça o primeiro login com e-mail e senha para ativar a biometria.'),
            backgroundColor: AppTheme.neonGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _carregando = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Falha ao autenticar com biometria: $e'),
          backgroundColor: AppTheme.performanceRed,
        ),
      );
    }
  }

  Future<void> _fazerLogin() async {
    final emailDigitado = _emailCtrl.text.trim();
    final senhaDigitada = _senhaCtrl.text;
    if (emailDigitado.isEmpty || senhaDigitada.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, informe seu e-mail e senha.'),
          backgroundColor: AppTheme.performanceRed,
        ),
      );
      return;
    }

    setState(() => _carregando = true);
    try {
      final session = await ApiService().login(emailDigitado, senhaDigitada);
      if (!mounted) return;

      // Salva ou remove credenciais de acordo com a opção de lembrar sessão
      try {
        if (_lembrarSessao) {
          await ApiService().storage.write(key: 'saved_email', value: emailDigitado);
          await ApiService().storage.write(key: 'saved_password', value: senhaDigitada);
        } else {
          await ApiService().storage.delete(key: 'saved_email');
          await ApiService().storage.delete(key: 'saved_password');
        }
      } catch (_) {}
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
      String msg = 'Falha ao conectar com a API Coach Center. Verifique sua conexão e tente novamente.';
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
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.4),
              radius: 1.2,
              colors: [
                isLight ? const Color(0xFFE4F8ED) : const Color(0xFF15261D),
                AppTheme.bgDark,
              ],
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: _buildAuthVault(isLight, borderSubtle),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWordmark(bool isLight, {double fontSize = 24}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
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
            size: 20,
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
                text: 'COACH ',
                style: TextStyle(color: AppTheme.textPrimary),
              ),
              TextSpan(
                text: 'CENTER',
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

  Widget _buildAuthVault(bool isLight, Color borderSubtle) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 500;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 32,
        vertical: isMobile ? 24 : 34,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: borderSubtle,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isLight ? 0.07 : 0.40),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildWordmark(isLight, fontSize: isMobile ? 18 : 22),
              const BotaoAlternarTema(mostrarTexto: false),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Acesse sua conta para continuar',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 22),
          Divider(height: 1, color: borderSubtle),
          const SizedBox(height: 22),
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
          // Checkbox para salvar sessão
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _lembrarSessao,
                    activeColor: AppTheme.neonGreen,
                    checkColor: const Color(0xFF0A0E12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    side: BorderSide(
                      color: isLight ? Colors.black38 : Colors.white38,
                    ),
                    onChanged: (v) => setState(() => _lembrarSessao = v ?? true),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => setState(() => _lembrarSessao = !_lembrarSessao),
                  child: Text(
                    kIsWeb ? 'Salvar sessão neste navegador' : 'Lembrar credenciais no aparelho',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
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
              child: kIsWeb
                  ? OutlinedButton.icon(
                      onPressed: _carregando ? null : _entrarComSessaoSalva,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.neonGreen, width: 1.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.lock_open_rounded, color: AppTheme.neonGreen, size: 20),
                      label: Text(
                        'Entrar com Sessão Salva',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                        ),
                      ),
                    )
                  : OutlinedButton.icon(
                      onPressed: _carregando ? null : _entrarComBiometria,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.neonGreen, width: 1.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.fingerprint, color: AppTheme.neonGreen, size: 22),
                      label: Text(
                        'Entrar com Biometria',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
            ),
          ],
          const SizedBox(height: 20),
          Divider(height: 1, color: borderSubtle),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.primaryAccent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primaryAccent.withValues(alpha: 0.25)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.workspace_premium_rounded, color: AppTheme.primaryAccent, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'Novo por aqui? Conheça os Planos',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryAccent,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const PlanosApresentacaoScreen()),
                          );
                        },
                        icon: const Icon(Icons.auto_awesome, size: 15),
                        label: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Ver Planos',
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF25D366),
                          side: const BorderSide(color: Color(0xFF25D366), width: 1.1),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          WhatsAppService.abrirMensagem(
                            '27996234460',
                            'Olá Ronald! Gostaria de conhecer a plataforma Coach Center e ver os planos.',
                          );
                        },
                        icon: const Icon(Icons.chat_bubble_outline, size: 15, color: Color(0xFF25D366)),
                        label: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'WhatsApp',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

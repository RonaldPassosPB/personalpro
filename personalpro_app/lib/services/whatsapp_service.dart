import 'package:url_launcher/url_launcher.dart';

class WhatsAppService {
  static String _limparTelefone(String? fone) {
    if (fone == null || fone.trim().isEmpty) return '5511999998888';
    final digitos = fone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitos.isEmpty) return '5511999998888';
    if (digitos.length <= 11 && !digitos.startsWith('55')) {
      return '55$digitos';
    }
    return digitos;
  }

  static Future<void> abrirMensagem(String? telefone, String mensagem) async {
    final numero = _limparTelefone(telefone);
    final textoEncoded = Uri.encodeComponent(mensagem);
    final url = Uri.parse('https://wa.me/$numero?text=$textoEncoded');
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  static Future<void> cobrarMensalidadePix({
    required String? telefoneAluno,
    required String nomeAluno,
    required String mesReferencia,
    required double valor,
    required String pixCopiaECola,
    required String nomePersonal,
  }) async {
    final msg =
        '''
Olá, *$nomeAluno*! Tudo bem? 💪🔥
Passando para enviar o lembrete da sua consultoria *$nomePersonal* referente ao mês *$mesReferencia*.

💰 *Valor:* R\$ ${valor.toStringAsFixed(2)}
⚡ *PIX Copia e Cola:*
$pixCopiaECola

Assim que realizar o pagamento, me avise por aqui. Vamos pra cima nos treinos! 🚀
''';
    await abrirMensagem(telefoneAluno, msg);
  }

  static Future<void> enviarReciboPagamento({
    required String? telefoneAluno,
    required String nomeAluno,
    required String mesReferencia,
    required double valor,
    required String formaPagamento,
    required String nomePersonal,
  }) async {
    final msg =
        '''
✅ *RECIBO DE PAGAMENTO — COACH CENTER*
Olá, *$nomeAluno*! Confirmamos o recebimento da sua mensalidade:

📌 *Referência:* $mesReferencia
💵 *Valor Pago:* R\$ ${valor.toStringAsFixed(2)}
💳 *Forma:* $formaPagamento
🏋️ *Profissional:* $nomePersonal

Obrigado pela confiança e foco total nos treinos! 💪🔥
''';
    await abrirMensagem(telefoneAluno, msg);
  }

  static Future<void> chamarAlunoSumido({
    required String? telefoneAluno,
    required String nomeAluno,
    required int diasSemTreinar,
  }) async {
    final msg =
        '''
Fala, *$nomeAluno*! Tudo certo por aí? 👀💪
Vi aqui no nosso sistema *Coach Center* que já faz *$diasSemTreinar dias* que você não registra treino concluído!
Aconteceu alguma coisa ou precisa que eu ajuste sua ficha de treino? Bora retomar o foco essa semana! 🚀🔥
''';
    await abrirMensagem(telefoneAluno, msg);
  }
}

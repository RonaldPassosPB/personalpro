import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../theme.dart';

class PixModal extends StatelessWidget {
  final String nomeBeneficiario;
  final String chavePix;
  final double valor;
  final String mesReferencia;
  final String pixCopiaECola;

  const PixModal({
    super.key,
    required this.nomeBeneficiario,
    required this.chavePix,
    required this.valor,
    required this.mesReferencia,
    required this.pixCopiaECola,
  });

  static Future<void> mostrar(
    BuildContext context, {
    required String nomeBeneficiario,
    required String chavePix,
    required double valor,
    required String mesReferencia,
    required String pixCopiaECola,
  }) {
    return showDialog(
      context: context,
      builder: (_) => PixModal(
        nomeBeneficiario: nomeBeneficiario,
        chavePix: chavePix,
        valor: valor,
        mesReferencia: mesReferencia,
        pixCopiaECola: pixCopiaECola,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surfaceCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.neonGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.pix, color: AppTheme.neonGreen, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pagamento via PIX EMV',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Referência: $mesReferencia • $nomeBeneficiario',
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                decoration: BoxDecoration(
                  color: AppTheme.neonGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.neonGreen.withValues(alpha: 0.4)),
                ),
                child: Text(
                  'R\$ ${valor.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.neonGreen,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: QrImageView(
                  data: pixCopiaECola,
                  version: QrVersions.auto,
                  size: 200,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Chave PIX: $chavePix',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.bgDark,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white12),
                ),
                child: SelectableText(
                  pixCopiaECola,
                  maxLines: 3,
                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: pixCopiaECola));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: AppTheme.neonGreen,
                        content: Text(
                          '✅ Código PIX Copia e Cola copiado para a área de transferência!',
                          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('COPIAR PIX COPIA E COLA'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme.dart';

class NotificacoesSheet extends StatefulWidget {
  const NotificacoesSheet({super.key});

  static Future<void> abrir(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => const FractionallySizedBox(
        heightFactor: 0.72,
        child: NotificacoesSheet(),
      ),
    );
  }

  @override
  State<NotificacoesSheet> createState() => _NotificacoesSheetState();
}

class _NotificacoesSheetState extends State<NotificacoesSheet> {
  bool _carregando = true;
  List<dynamic> _lista = [];

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      final resp = await ApiService().dio.get('/api/notificacoes');
      setState(() {
        _lista = resp.data['notificacoes'] ?? [];
        _carregando = false;
      });
      await ApiService().dio.post('/api/notificacoes/ler-todas');
    } catch (_) {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.notifications_active, color: AppTheme.neonGreen),
                  SizedBox(width: 10),
                  Text(
                    'Central de Notificações',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const Divider(color: Colors.white12),
          Expanded(
            child: _carregando
                ? Center(child: CircularProgressIndicator())
                : _lista.isEmpty
                    ? Center(
                        child: Text(
                          'Nenhuma notificação no momento.',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _lista.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final n = _lista[i];
                          final lida = n['lida'] == true;
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: lida
                                  ? AppTheme.bgDark
                                  : AppTheme.neonGreen.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: lida
                                    ? Colors.white12
                                    : AppTheme.neonGreen.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  n['tipo'] == 'TREINO_CONCLUIDO'
                                      ? Icons.fitness_center
                                      : n['tipo'] == 'FINANCEIRO'
                                          ? Icons.pix
                                          : Icons.bolt,
                                  color: AppTheme.neonGreen,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        n['titulo']?.toString() ?? '',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        n['mensagem']?.toString() ?? '',
                                        style: TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _canalAltaPrioridade =
      AndroidNotificationChannel(
    'personalpro_canal_alta_prioridade',
    'PersonalPro Notificações de Treino e PIX',
    description: 'Canal de alta prioridade para conclusão de treinos e avisos do Personal.',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  static Future<void> inicializar() async {
    if (kIsWeb) return;

    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings();
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(initSettings);

      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(_canalAltaPrioridade);
    } catch (e) {
      debugPrint('Aviso inicialização de notificações locais: $e');
    }
  }

  static Future<void> exibirNotificacaoLocal({
    required String titulo,
    required String corpo,
  }) async {
    if (kIsWeb) return;
    try {
      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        titulo,
        corpo,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _canalAltaPrioridade.id,
            _canalAltaPrioridade.name,
            channelDescription: _canalAltaPrioridade.description,
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
      );
    } catch (_) {}
  }

  static Future<void> registrarTokenDispositivo(String token) async {
    try {
      await ApiService().dio.post('/api/auth/fcm-token', data: {'token': token});
    } catch (_) {}
  }
}

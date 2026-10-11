import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';
import 'notification_web_stub.dart'
    if (dart.library.js_interop) 'notification_web_real.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _canalAltaPrioridade =
      AndroidNotificationChannel(
    'coachcenter_canal_alta_prioridade',
    'Coach Center Notificações de Treino e PIX',
    description:
        'Canal de alta prioridade para conclusão de treinos e avisos do Personal.',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  static Future<void> inicializar() async {
    if (kIsWeb) {
      requestWebNotificationPermission();
      return;
    }

    try {
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(initSettings);

      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidPlugin?.createNotificationChannel(_canalAltaPrioridade);
      // Solicita permissão explícita no Android 13+ (POST_NOTIFICATIONS)
      await androidPlugin?.requestNotificationsPermission();
    } catch (e) {
      debugPrint('Aviso inicialização de notificações locais: $e');
    }
  }

  static Future<void> exibirNotificacaoLocal({
    required String titulo,
    required String corpo,
  }) async {
    if (kIsWeb) {
      showWebNotification(titulo, corpo);
      return;
    }

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
            playSound: true,
            enableVibration: true,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Erro ao exibir notificação local: $e');
    }
  }

  static Future<void> registrarTokenDispositivo(String token) async {
    try {
      await ApiService().dio.post(
        '/api/auth/fcm-token',
        data: {'token': token},
      );
    } catch (_) {}
  }
}

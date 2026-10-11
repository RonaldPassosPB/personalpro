import 'package:web/web.dart' as web;

void requestWebNotificationPermission() {
  try {
    if (web.Notification.permission != 'granted' &&
        web.Notification.permission != 'denied') {
      web.Notification.requestPermission();
    }
  } catch (_) {}
}

void showWebNotification(String titulo, String corpo) {
  try {
    if (web.Notification.permission == 'granted') {
      web.Notification(
        titulo,
        web.NotificationOptions(
          body: corpo,
          icon: '/favicon.png',
        ),
      );
    }
  } catch (_) {}
}


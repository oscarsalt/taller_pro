import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings);
  }

  static Future<void> mostrarCitasHoy(List<dynamic> citas) async {
    print('Mostrando notificacion para ${citas.length} citas');
    if (citas.isEmpty) return;

    final cantidad = citas.length;
    final texto =
        cantidad == 1 ? 'Tienes 1 cita hoy' : 'Tienes $cantidad citas hoy';

    final detalle = citas
        .take(3)
        .map((c) =>
            '${(c['hora']?.toString() ?? '').length >= 5 ? c['hora'].toString().substring(0, 5) : ''} — ${c['nombre'] ?? ''}')
        .join('\n');

    print('Texto notificacion: $texto');
    print('Detalle: $detalle');

    const androidDetails = AndroidNotificationDetails(
      'citas_hoy',
      'Citas del día',
      channelDescription: 'Notificaciones de citas programadas para hoy',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    await _plugin.show(
      0,
      texto,
      detalle,
      const NotificationDetails(android: androidDetails),
    );

    print('Notificacion enviada correctamente');
  }
}

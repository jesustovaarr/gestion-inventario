import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class ServicioNotificaciones {
  static ServicioNotificaciones? _instancia;
  factory ServicioNotificaciones({FlutterLocalNotificationsPlugin? plugin}) {
    if (plugin != null) {
      _instancia = ServicioNotificaciones._conPlugin(plugin);
    }
    return _instancia ??= ServicioNotificaciones._();
  }

  ServicioNotificaciones._() : _plugin = FlutterLocalNotificationsPlugin();
  ServicioNotificaciones._conPlugin(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;
  bool _inicializado = false;

  bool get _enPruebas =>
      WidgetsBinding.instance.runtimeType
          .toString()
          .contains('TestWidgetsFlutterBinding');

  final List<Map<String, dynamic>> alertasProgramadasEnMemoria = [];

  void Function(String fechaIso)? onNotificationOpened;

  static const String canalId = 'alertas_caducidad';
  static const String canalNombre = 'Alertas de Caducidad';
  static const String canalDescripcion =
      'Notificaciones y alarmas locales para productos por caducar';

  /// Asegura la inicialización de la base de datos de zonas horarias.
  static void _asegurarZonasHorarias() {
    try {
      tz.initializeTimeZones();
      try {
        tz.setLocalLocation(tz.getLocation('America/Mexico_City'));
      } catch (_) {
        tz.setLocalLocation(tz.UTC);
      }
    } catch (_) {}
  }

  // Inicializa el servicio de notificaciones locales y la base de datos de zonas horarias
  Future<void> inicializar({
    void Function(String fechaIso)? onNotificationOpened,
  }) async {
    if (onNotificationOpened != null) {
      this.onNotificationOpened = onNotificationOpened;
    }
    if (_inicializado || _enPruebas) return;

    try {
      _asegurarZonasHorarias();

      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const linuxSettings = LinuxInitializationSettings(
        defaultActionName: 'Open',
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
        linux: linuxSettings,
      );

      await _plugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (response) {
          final payload = response.payload;
          if (payload != null && payload.isNotEmpty) {
            this.onNotificationOpened?.call(payload);
          }
        },
      );

      // Crear canal de notificación para Android
      final androidPlatform = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlatform != null) {
        await androidPlatform.createNotificationChannel(
          const AndroidNotificationChannel(
            canalId,
            canalNombre,
            description: canalDescripcion,
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
          ),
        );
      }

      // Verificar si la app fue lanzada al presionar una notificación
      final launchDetails =
          await _plugin.getNotificationAppLaunchDetails();
      if (launchDetails?.didNotificationLaunchApp ?? false) {
        final payload = launchDetails?.notificationResponse?.payload;
        if (payload != null && payload.isNotEmpty) {
          // Diferir ejecución para permitir que el árbol de navegación esté montado
          Future.microtask(() => this.onNotificationOpened?.call(payload));
        }
      }

      _inicializado = true;
    } catch (e) {
      debugPrint('Error al inicializar ServicioNotificaciones: $e');
    }
  }

  // Solicita permisos de notificación
  Future<bool?> solicitarPermisos() async {
    try {
      if (kIsWeb) return false;
      if (Platform.isAndroid) {
        final android = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        return await android?.requestNotificationsPermission();
      } else if (Platform.isIOS || Platform.isMacOS) {
        final ios = _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        return await ios?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
      }
    } catch (_) {}
    return null;
  }

  /// Parsea cadenas de hora como "09:00 AM", "09:00", "9:00 PM", "21:30".
  static (int hour, int minute) parsearHora(String horaStr) {
    final str = horaStr.trim().toUpperCase();
    final match = RegExp(r'(\d{1,2}):(\d{2})\s*(AM|PM)?').firstMatch(str);
    if (match != null) {
      int hour = int.parse(match.group(1)!);
      final minute = int.parse(match.group(2)!);
      final ampm = match.group(3);
      if (ampm == 'PM' && hour < 12) hour += 12;
      if (ampm == 'AM' && hour == 12) hour = 0;
      return (hour.clamp(0, 23), minute.clamp(0, 59));
    }
    return (9, 0); // Default 09:00 AM
  }

  // Valida si una fecha y hora de alarma están en el pasado respecto al momento actual
  // Retorna un mensaje descriptivo de error si es inválida, o null si es válida
  static String? validarMomentoAlarma({
    required DateTime fechaCaducidad,
    required String horaAviso,
    DateTime? ahora,
  }) {
    final now = ahora ?? DateTime.now();
    final fechaSinHora = DateTime(
      fechaCaducidad.year,
      fechaCaducidad.month,
      fechaCaducidad.day,
    );
    final hoySinHora = DateTime(now.year, now.month, now.day);

    if (fechaSinHora.isBefore(hoySinHora)) {
      return 'No se puede activar una alarma para una fecha que ya pasó.';
    }

    final (hora, minuto) = parsearHora(horaAviso);
    final momentoAlarma = DateTime(
      fechaCaducidad.year,
      fechaCaducidad.month,
      fechaCaducidad.day,
      hora,
      minuto,
    );

    if (momentoAlarma.isBefore(now)) {
      return 'La hora seleccionada ya pasó el día de hoy.';
    }

    return null;
  }

  // Programa una alarma local en el sistema para la fecha y hora de caducidad del lote
  Future<bool> programarAlertaLote({
    required int loteId,
    required String nombreProducto,
    required String fechaCaducidad,
    required String horaAviso,
  }) async {
    try {
      _asegurarZonasHorarias();
      final fecha = DateTime.tryParse(fechaCaducidad);
      if (fecha == null) return false;

      final (hora, minuto) = parsearHora(horaAviso);
      final fechaAlarma = DateTime(
        fecha.year,
        fecha.month,
        fecha.day,
        hora,
        minuto,
      );

      final tzFecha = tz.TZDateTime.from(fechaAlarma, tz.local);
      final tzAhora = tz.TZDateTime.now(tz.local);

      // Si la fecha y hora ya pasaron, no se programa en el pasado
      if (tzFecha.isBefore(tzAhora)) {
        return false;
      }

      if (_enPruebas) {
        alertasProgramadasEnMemoria.add({
          'id': loteId,
          'nombre': nombreProducto,
          'fechaCaducidad': fechaCaducidad,
          'horaAviso': horaAviso,
          'fechaAlarma': fechaAlarma,
        });
        return true;
      }

      final detalles = NotificationDetails(
        android: AndroidNotificationDetails(
          canalId,
          canalNombre,
          channelDescription: canalDescripcion,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          ticker: 'Alerta de caducidad',
        ),
        iOS: const DarwinNotificationDetails(
          sound: 'default',
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      await _plugin.zonedSchedule(
        id: loteId,
        title: 'Alerta de caducidad',
        body: '$nombreProducto caduca hoy.',
        scheduledDate: tzFecha,
        notificationDetails: detalles,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: fechaCaducidad,
      );

      return true;
    } catch (e) {
      debugPrint('Error al programar alerta para lote $loteId: $e');
      return false;
    }
  }

  /// Cancela la alarma asociada a un lote (por ejemplo, cuando se consume o descarta).
  Future<void> cancelarAlerta(int loteId) async {
    try {
      if (_enPruebas) {
        alertasProgramadasEnMemoria.removeWhere((a) => a['id'] == loteId);
        return;
      }
      await _plugin.cancel(id: loteId);
    } catch (e) {
      debugPrint('Error al cancelar alarma $loteId: $e');
    }
  }

  // Cancela todas las alarmas programadas
  Future<void> cancelarTodas() async {
    try {
      if (_enPruebas) {
        alertasProgramadasEnMemoria.clear();
        return;
      }
      await _plugin.cancelAll();
    } catch (_) {}
  }

  // Lanza una notificación de prueba para validar que el sistema responde y abre la pantalla
  Future<void> lanzarNotificacionPrueba({
    String nombreProducto = 'Producto de prueba',
    String? fechaIso,
    int segundos = 2,
  }) async {
    try {
      _asegurarZonasHorarias();
      final payloadFecha = fechaIso ??
          DateTime.now().toIso8601String().substring(0, 10);

      if (_enPruebas) {
        alertasProgramadasEnMemoria.add({
          'id': 999999,
          'nombre': nombreProducto,
          'fecha': payloadFecha,
          'esPrueba': true,
        });
        return;
      }

      final detalles = NotificationDetails(
        android: AndroidNotificationDetails(
          canalId,
          canalNombre,
          channelDescription: canalDescripcion,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          sound: 'default',
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      if (segundos <= 0) {
        await _plugin.show(
          id: 999999,
          title: 'Alerta de caducidad',
          body: '$nombreProducto caduca hoy.',
          notificationDetails: detalles,
          payload: payloadFecha,
        );
      } else {
        final tzFecha = tz.TZDateTime.now(tz.local).add(
          Duration(seconds: segundos),
        );
        await _plugin.zonedSchedule(
          id: 999999,
          title: 'Alerta de caducidad',
          body: '$nombreProducto caduca hoy.',
          scheduledDate: tzFecha,
          notificationDetails: detalles,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: payloadFecha,
        );
      }
    } catch (e) {
      debugPrint('Error en lanzarNotificacionPrueba: $e');
    }
  }
}

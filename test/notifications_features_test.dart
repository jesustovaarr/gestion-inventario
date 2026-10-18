import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_inventario/models/lote_model.dart';
import 'package:gestion_inventario/models/borrador_formulario.dart';
import 'package:gestion_inventario/presentation/modelos_vista_calendario.dart';
import 'package:gestion_inventario/presentation/modelos_vista_alacena.dart';
import 'package:gestion_inventario/screens/pantalla_alertas_dia.dart';
import 'package:gestion_inventario/screens/formulario_producto.dart';
import 'package:gestion_inventario/services/servicio_notificaciones.dart';
import 'package:gestion_inventario/widgets/campo_codigo_barras.dart';
import 'package:gestion_inventario/widgets/miniatura_producto.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ServicioNotificaciones - Parseo de Hora', () {
    test('Parsea correctamente formatos de 12 y 24 horas', () {
      final (h1, m1) = ServicioNotificaciones.parsearHora('09:00 AM');
      expect(h1, 9);
      expect(m1, 0);

      final (h2, m2) = ServicioNotificaciones.parsearHora('09:30 PM');
      expect(h2, 21);
      expect(m2, 30);

      final (h3, m3) = ServicioNotificaciones.parsearHora('14:45');
      expect(h3, 14);
      expect(m3, 45);

      final (h4, m4) = ServicioNotificaciones.parsearHora('12:00 AM');
      expect(h4, 0);
      expect(m4, 0);

      final (h5, m5) = ServicioNotificaciones.parsearHora('12:00 PM');
      expect(h5, 12);
      expect(m5, 0);
    });

    test('Usa valor por defecto ante formatos no reconocidos', () {
      final (h, m) = ServicioNotificaciones.parsearHora('hora_invalida');
      expect(h, 9);
      expect(m, 0);
    });
  });

  group('Modelo Lote - Campos de Alarma', () {
    test('Lote conserva alarmaId, alarmaActiva y horaAviso al serializar y deserializar', () {
      const lote = Lote(
        id: 42,
        productoId: 10,
        cantidad: 2.0,
        fechaCaducidad: '2026-12-31',
        alarmaId: 42,
        alarmaActiva: 1,
        horaAviso: '08:30 AM',
      );

      final map = lote.toMap();
      expect(map['alarma_id'], 42);
      expect(map['alarma_activa'], 1);
      expect(map['hora_aviso'], '08:30 AM');

      final deserializado = Lote.fromMap(map);
      expect(deserializado.id, 42);
      expect(deserializado.alarmaId, 42);
      expect(deserializado.alarmaActiva, 1);
      expect(deserializado.horaAviso, '08:30 AM');
    });

    test('Lote copyWith permite modificar alarmaId y alarmaActiva', () {
      const lote = Lote(
        id: 1,
        productoId: 2,
        cantidad: 1.0,
        fechaCaducidad: '2026-10-25',
        alarmaId: 1,
        alarmaActiva: 1,
      );

      final modificado = lote.copyWith(
        alarmaActiva: 0,
        alarmaId: 99,
      );

      expect(modificado.alarmaActiva, 0);
      expect(modificado.alarmaId, 99);
    });
  });

  group('DayAlertsScreen - Botón de prueba de alarma', () {
    testWidgets('Renderiza botón de prueba de alarma en la pantalla de alertas del día', (
      tester,
    ) async {
      final alertPrueba = CalendarAlertPreview(
        'Leche Lala 1 L',
        'Botella 1 L',
        '1 unidad',
        CalendarPreviewStatus.expiring,
        ProductThumbnailKind.placeholder,
        loteId: 1,
        productoId: 1,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: DayAlertsScreen(
            day: DateTime(2026, 10, 25),
            alerts: [alertPrueba],
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('btn_probar_alarma')), findsOneWidget);
      expect(find.text('Leche Lala 1 L'), findsOneWidget);

      // Tocar el botón de prueba de alarma
      await tester.tap(find.byKey(const Key('btn_probar_alarma')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Debe mostrar aviso de que la alarma fue lanzada
      expect(
        find.textContaining('Alarma lanzada'),
        findsOneWidget,
      );
    });
  });

  group('ProductFormScreen - Selector de hora de aviso', () {
    testWidgets('Tocar btn_hora_aviso abre el TimePicker y permite seleccionar hora', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(600, 1800);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: ProductFormScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Debe mostrar el botón con la hora inicial '09:00 AM'
      final btnHora = find.byKey(const Key('btn_hora_aviso'));
      expect(btnHora, findsOneWidget);
      expect(find.text('09:00 AM'), findsOneWidget);

      // Tocar el botón de hora
      await tester.tap(btnHora);
      await tester.pumpAndSettle();

      // Debe abrir el diálogo interactivo del reloj de Flutter (TimePickerDialog)
      expect(find.byType(TimePickerDialog), findsOneWidget);

      // Confirmar con OK
      final okBtn = find.text('OK');
      if (okBtn.evaluate().isNotEmpty) {
        await tester.tap(okBtn);
      } else {
        await tester.tap(find.text('Aceptar'));
      }
      await tester.pumpAndSettle();

      // El diálogo se cierra y el botón sigue presente
      expect(find.byType(TimePickerDialog), findsNothing);
      expect(find.byKey(const Key('btn_hora_aviso')), findsOneWidget);
    });
  });

  group('ServicioNotificaciones - Validación de fecha y hora pasada para alarmas', () {
    final ahoraFijo = DateTime(2026, 10, 18, 14, 30); // 18 de octubre de 2026 a las 14:30 (2:30 PM)

    test('Rechaza alarma con fecha anterior al día actual', () {
      final fechaAyer = DateTime(2026, 10, 17);
      final error = ServicioNotificaciones.validarMomentoAlarma(
        fechaCaducidad: fechaAyer,
        horaAviso: '09:00 AM',
        ahora: ahoraFijo,
      );
      expect(error, 'No se puede activar una alarma para una fecha que ya pasó.');
    });

    test('Rechaza alarma en el mismo día pero con hora ya transcurrida', () {
      final fechaHoy = DateTime(2026, 10, 18);
      // Las 09:00 AM ya pasaron si son las 14:30
      final error = ServicioNotificaciones.validarMomentoAlarma(
        fechaCaducidad: fechaHoy,
        horaAviso: '09:00 AM',
        ahora: ahoraFijo,
      );
      expect(error, 'La hora seleccionada ya pasó el día de hoy.');
    });

    test('Acepta alarma en el mismo día con hora futura', () {
      final fechaHoy = DateTime(2026, 10, 18);
      // Las 16:00 (4:00 PM) es posterior a las 14:30
      final error = ServicioNotificaciones.validarMomentoAlarma(
        fechaCaducidad: fechaHoy,
        horaAviso: '04:00 PM',
        ahora: ahoraFijo,
      );
      expect(error, isNull);
    });

    test('Acepta alarma en fechas futuras independientemente de la hora', () {
      final fechaFutura = DateTime(2026, 10, 25);
      final error = ServicioNotificaciones.validarMomentoAlarma(
        fechaCaducidad: fechaFutura,
        horaAviso: '08:00 AM',
        ahora: ahoraFijo,
      );
      expect(error, isNull);
    });
  });

  group('ProductFormScreen - Código de barras visible al editar y restricción de alarma pasada', () {
    testWidgets('Campo de código de barras está visible al editar un producto existente', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(600, 1800);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      const productoPrueba = PantryProductPreview(
        id: 99,
        name: 'Arroz Sinaloa',
        category: 'Granos',
        status: PantryPreviewStatus.healthy,
        note: 'Suficiente',
        quantity: '2 kg',
        thumbnail: ProductThumbnailKind.placeholder,
        unit: 'kg',
        minimumStock: 1,
        code: '',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: ProductFormScreen(product: productoPrueba),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // El campo de código de barras debe estar visible en la pantalla aunque isEditing sea true
      expect(find.byType(CampoCodigoBarras), findsOneWidget);
      expect(find.byKey(const Key('input_codigo_barras')), findsOneWidget);
      expect(find.byTooltip('Escanear código de barras'), findsOneWidget);
    });

    testWidgets('Alarma se desactiva y bloquea si la fecha de caducidad es en el pasado', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(600, 1800);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      // Abrir formulario con fecha de caducidad en el pasado (año 2020)
      final draftPasado = ProductFormDraft(
        name: 'Producto Viejo',
        category: 'Lácteos',
        unit: 'pza',
        minimum: 1,
        quantity: 1,
        fechaCaducidad: DateTime(2020, 1, 1),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ProductFormScreen(draft: draftPasado),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final switchAlarma = find.byType(Switch);
      expect(switchAlarma, findsOneWidget);

      // Como la fecha está en el pasado, el switch debe iniciar desactivado
      final switchWidget = tester.widget<Switch>(switchAlarma);
      expect(switchWidget.value, isFalse);

      // Si el usuario intenta activarlo, debe mostrar SnackBar de error y seguir apagado
      await tester.tap(switchAlarma);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.text('No se puede activar una alarma para una fecha que ya pasó.'),
        findsOneWidget,
      );
      final switchWidgetPost = tester.widget<Switch>(switchAlarma);
      expect(switchWidgetPost.value, isFalse);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_inventario/database/daos/lote_dao.dart';
import 'package:gestion_inventario/database/inventario_db.dart';
import 'package:gestion_inventario/presentation/modelos_vista_calendario.dart';
import 'package:gestion_inventario/screens/formulario_producto.dart';
import 'package:gestion_inventario/screens/pantalla_alertas_dia.dart';
import 'package:gestion_inventario/screens/pantalla_calendario.dart';
import 'package:gestion_inventario/widgets/editor_fecha_caducidad.dart';
import 'package:gestion_inventario/widgets/dialogo_configuracion_alerta.dart';
import 'package:gestion_inventario/widgets/miniatura_producto.dart';
import 'package:gestion_inventario/models/lote_model.dart';
import 'package:table_calendar/table_calendar.dart';

import 'purchase_flow_test.dart' show PurchaseDatabase;

class CalendarDatabase extends PurchaseDatabase {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #rawQuery) {
      final sql = invocation.positionalArguments.first as String;
      if (sql.contains('FROM Lote l')) {
        final args = invocation.positionalArguments.length > 1
            ? invocation.positionalArguments[1] as List?
            : null;
        return Future<List<Map<String, Object?>>>.value([
          for (final lot in tables['Lote']!)
            if ((lot['cantidad'] as num) > 0 &&
                (!sql.contains('l.fecha_caducidad = ?') ||
                    lot['fecha_caducidad'] == args?.first))
              {
                ...lot,
                'producto_nombre': tables['Producto']!.firstWhere(
                  (p) => p['id'] == lot['producto_id'],
                )['nombre'],
                'unidad': tables['Producto']!.firstWhere(
                  (p) => p['id'] == lot['producto_id'],
                )['unidad_medida'],
              },
        ]);
      }
    }
    return super.noSuchMethod(invocation);
  }
}

String iso(DateTime date) => date.toIso8601String().substring(0, 10);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'El calendario conserva la foto y distingue caducidad de existencias bajas',
    () {
      final preview = calendarAlertFromLot(
        const Lote(
          id: 1,
          productoId: 2,
          cantidad: 4,
          fechaCaducidad: '2999-01-01',
          productoNombre: 'Leche',
          productoImagen: '/fotos/leche.jpg',
          unidad: 'lt',
        ),
      );
      expect(preview.imagePath, '/fotos/leche.jpg');
      expect(preview.status, CalendarPreviewStatus.healthy);
      expect(preview.quantity, '4 L restantes');
    },
  );

  test('Cambiar la caducidad valida la fecha y no altera cantidades ni otros lotes', () async {
    final db = CalendarDatabase();
    db.tables['Lote']!.add({
      'id': 2,
      'producto_id': 2,
      'cantidad': 0.0,
      'fecha_caducidad': '2030-01-01',
    });
    final original = Map.of(db.tables['Lote']!.first);
    final movements = db.tables['Movimiento_Inventario']!
        .map((r) => Map.of(r))
        .toList();
    final dao = LoteDao(db);
    for (final date in ['', '2030-02-31', '2030-13-01']) {
      await expectLater(
        dao.actualizarFechaCaducidad(1, date),
        throwsArgumentError,
      );
    }
    expect(await dao.actualizarFechaCaducidad(1, '2030-02-15'), 1);
    expect(db.tables['Lote']!.first, {
      ...original,
      'fecha_caducidad': '2030-02-15',
    });
    expect(await dao.actualizarFechaCaducidad(2, '2030-02-15'), 0);
    expect(db.tables['Lote']!.last['fecha_caducidad'], '2030-01-01');
    expect(db.tables['Movimiento_Inventario'], movements);
  });

  testWidgets(
    'Calendario simplificado: editar una fecha mueve solo ese lote y actualiza los puntos',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final db = CalendarDatabase();
      final today = DateTime.now();
      final tomorrow = DateTime(today.year, today.month, today.day + 1);
      db.tables['Lote']!.first['fecha_caducidad'] = iso(today);
      db.tables['Lote']!.add({
        'id': 2,
        'producto_id': 2,
        'cantidad': 3.0,
        'fecha_caducidad': iso(today),
      });
      final firstLot = Map.of(db.tables['Lote']!.first);
      final secondLot = Map.of(db.tables['Lote']!.last);
      final movements = db.tables['Movimiento_Inventario']!
          .map((r) => Map.of(r))
          .toList();
      final inventory = InventarioDB.conDatabase(db);
      await tester.pumpWidget(const MaterialApp(home: CalendarScreen()));
      await tester.pumpAndSettle();
      final calendar = find.byType(TableCalendar<CalendarAlertPreview>);
      expect(find.text('Gestionar inventario de esta fecha'), findsOneWidget);
      expect(find.text('Leche'), findsNothing);
      expect(find.text('Arroz'), findsNothing);
      expect(find.text('Sin existencia'), findsNothing);
      expect(find.textContaining('Toca cualquier día'), findsNothing);
      expect(
        tester
            .widget<TableCalendar<CalendarAlertPreview>>(calendar)
            .eventLoader!(today),
        hasLength(2),
      );
      await tester.tap(find.text('Gestionar inventario de esta fecha'));
      await tester.pumpAndSettle();
      expect(find.byType(DayAlertsScreen), findsOneWidget);
      expect(find.text('Sin alerta (0)'), findsOneWidget);
      expect(find.textContaining('Día despejado'), findsNothing);
      expect(find.textContaining('Sin existencia'), findsNothing);
      Future<void> openDateEditor() async {
        await tester.tap(find.byTooltip('Editar fecha de caducidad'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(ListTile, 'Leche'));
        await tester.pumpAndSettle();
      }

      await openDateEditor();
      expect(find.byType(ExpiryDateEditorDialog), findsOneWidget);
      expect(find.byType(ProductFormScreen), findsNothing);
      expect(find.byType(TextFormField), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(db.tables['Lote']!.first, firstLot);
      await openDateEditor();
      await tester.enterText(find.byType(TextFormField), '31/02/2030');
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      expect(find.text('Escribe una fecha válida: dd/mm/aaaa'), findsOneWidget);
      expect(db.tables['Lote']!.first, firstLot);
      await tester.enterText(
        find.byType(TextFormField),
        '${tomorrow.day}/${tomorrow.month}/${tomorrow.year}',
      );
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      expect(find.byType(ExpiryDateEditorDialog), findsNothing);
      expect(db.tables['Lote']!.first, {
        ...firstLot,
        'fecha_caducidad': iso(tomorrow),
      });
      expect(db.tables['Lote']!.last, secondLot);
      expect(db.tables['Movimiento_Inventario'], movements);
      expect(find.text('Leche'), findsNothing);
      expect(find.text('Arroz'), findsOneWidget);
      await tester.tap(find.byTooltip('Cerrar productos del día'));
      await tester.pumpAndSettle();
      final updated = tester.widget<TableCalendar<CalendarAlertPreview>>(
        calendar,
      );
      expect(updated.eventLoader!(today), hasLength(1));
      expect(updated.eventLoader!(tomorrow), hasLength(1));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await inventory.close();
    },
  );

  testWidgets(
    'Calendario limita a 5 puntos y muestra indicador +N cuando hay más de 5 productos',
    (tester) async {
      final today = DateTime.now();
      final events = List.generate(
        8,
        (i) => CalendarAlertPreview(
          'Producto $i',
          'Alacena',
          '1 pza',
          CalendarPreviewStatus.expiring,
          ProductThumbnailKind.placeholder,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TableCalendar<CalendarAlertPreview>(
              firstDay: DateTime(2000),
              lastDay: DateTime(2100),
              focusedDay: today,
              eventLoader: (day) => isSameDay(day, today) ? events : const [],
              calendarBuilders: CalendarBuilders(
                markerBuilder: (_, day, evs) {
                  if (evs.isEmpty) return null;
                  final total = evs.length;
                  const maxDots = 5;
                  final mostrarBadge = total > maxDots;
                  final dotsCount = mostrarBadge ? maxDots : total;
                  final restantes = total - maxDots;

                  return Positioned(
                    left: 0,
                    right: 0,
                    bottom: 2,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < dotsCount; i++)
                          SizedBox(
                            key: ValueKey(
                              'calendar-marker-${day.year}-${day.month}-${day.day}-$i',
                            ),
                            width: 3.5,
                            height: 3.5,
                          ),
                        if (mostrarBadge)
                          Text(
                            '+$restantes',
                            key: ValueKey(
                              'calendar-more-${day.year}-${day.month}-${day.day}',
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Debe haber exactamente 5 marcadores individuales
      for (int i = 0; i < 5; i++) {
        expect(
          find.byKey(
            ValueKey(
              'calendar-marker-${today.year}-${today.month}-${today.day}-$i',
            ),
          ),
          findsOneWidget,
        );
      }
      // No debe haber marcador 5 (el 6to índice)
      expect(
        find.byKey(
          ValueKey(
            'calendar-marker-${today.year}-${today.month}-${today.day}-5',
          ),
        ),
        findsNothing,
      );
      // Debe haber un indicador de "+3"
      expect(find.text('+3'), findsOneWidget);
    },
  );

  testWidgets(
    'DayAlertsScreen muestra productos y permite abrir diálogo de configurar recordatorio',
    (tester) async {
      final today = DateTime(2030, 5, 20);
      const alertConAlarma = CalendarAlertPreview(
        'Yogurt',
        'Refrigerador',
        '2 pza',
        CalendarPreviewStatus.expiring,
        ProductThumbnailKind.placeholder,
        loteId: 10,
        alarmaActiva: 1,
        horaAviso: '08:00 AM',
      );
      const alertSinAlarma = CalendarAlertPreview(
        'Cereal',
        'Alacena',
        '1 pza',
        CalendarPreviewStatus.healthy,
        ProductThumbnailKind.placeholder,
        loteId: 11,
        alarmaActiva: 0,
        horaAviso: '09:00 AM',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: DayAlertsScreen(
            day: today,
            alerts: const [alertConAlarma, alertSinAlarma],
          ),
        ),
      );

      expect(find.text('Con alertas (1)'), findsOneWidget);
      expect(find.text('Sin alerta (1)'), findsOneWidget);

      // Tocar el botón de configurar alerta en el primer producto
      final btnConfig = find.byKey(const Key('btn_config_alerta_10'));
      expect(btnConfig, findsOneWidget);

      await tester.tap(btnConfig);
      await tester.pumpAndSettle();

      expect(find.byType(DialogoConfiguracionAlerta), findsOneWidget);
      expect(find.text('Configurar Alerta'), findsOneWidget);
      expect(find.text('08:00 AM'), findsOneWidget);

      // Cerrar diálogo
      await tester.tap(find.byKey(const Key('btn_cancelar_config_alerta')));
      await tester.pumpAndSettle();

      expect(find.byType(DialogoConfiguracionAlerta), findsNothing);
    },
  );

  test('calendarAlertFromLot asigna lowStock cuando lote.porAgotarse es true', () {
    const loteBajoStock = Lote(
      id: 5,
      productoId: 1,
      cantidad: 1.0,
      fechaCaducidad: '2030-01-01',
      stockTotalProducto: 1.0,
      stockMinimo: 2.0,
      productoNombre: 'Atún',
    );

    final preview = calendarAlertFromLot(loteBajoStock);
    expect(preview.porAgotarse, isTrue);
    expect(preview.status, CalendarPreviewStatus.lowStock);
    expect(preview.status.label, 'Por agotarse');
  });
}

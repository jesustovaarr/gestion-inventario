import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_inventario/main_diseno.dart';
import 'package:gestion_inventario/screens/pantalla_alertas_dia.dart';

void main() {
  testWidgets('Vista diaria permite filtrar y recorrer cinco productos', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    for (final width in [320.0, 390.0, 600.0]) {
      tester.view.physicalSize = Size(width, 844);
      await tester.pumpWidget(const AlacenaPreviewApp());
      await tester.tap(find.text('Calendario'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('calendar-day-2024-5-31')));
      await tester.pumpAndSettle();
      final day = find.byType(DayAlertsScreen);
      expect(day, findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(
        find.descendant(of: day, matching: find.text('Caducado (1)')),
      );
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: day, matching: find.text('Leche entera 1 L')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: day, matching: find.text('Atún en lata')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);

      await tester.tap(
        find.descendant(of: day, matching: find.text('Día despejado (0)')),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('No hay productos sin alertas para este día'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);

      await tester.tap(
        find.descendant(of: day, matching: find.text('Con alertas (5)')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(of: day, matching: find.text('Todos (5)')),
      );
      await tester.pumpAndSettle();
      for (var step = 0; step < 4; step++) {
        await tester.dragFrom(const Offset(10, 650), const Offset(0, -350));
        await tester.pumpAndSettle();
      }
      expect(find.text('Agregar los 5 productos al carrito'), findsOneWidget);
      expect(find.text('Gestionar lote'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(
        find.descendant(of: day, matching: find.text('Calendario')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      expect(find.text('Mayo 2024'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
}

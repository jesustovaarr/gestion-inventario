import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_inventario/main_diseno.dart';

void main() {
  testWidgets('Calendario adaptable con puntos y modal de pantalla completa', (
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
      expect(find.text('Mayo 2024'), findsOneWidget);
      for (var index = 0; index < 3; index++) {
        expect(
          find.byKey(ValueKey('calendar-marker-2024-5-13-$index')),
          findsOneWidget,
        );
      }
      expect(
        find.byKey(const ValueKey('calendar-marker-2024-5-13-3')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const ValueKey('calendar-day-2024-5-11')));
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(Dialog)), Size(width, 844));
      expect(
        find.descendant(
          of: find.byType(Dialog),
          matching: find.text('2 alertas activas'),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Cerrar productos del día'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('calendar-day-2024-5-14')));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(Dialog),
          matching: find.text('Sin alertas para este día'),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Cerrar productos del día'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Mes siguiente'));
      await tester.pumpAndSettle();
      expect(find.text('Junio 2024'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
}

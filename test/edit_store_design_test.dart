import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_inventario/main_diseno.dart';

void main() {
  testWidgets('Editar tienda abre desde el catálogo y se adapta al celular', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    for (final width in [320.0, 390.0, 600.0]) {
      tester.view.physicalSize = Size(width, 844);
      await tester.pumpWidget(const AlacenaPreviewApp());
      await tester.tap(find.text('Tiendas'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Opciones de Walmart Supercenter'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Editar tienda'));
      await tester.pumpAndSettle();
      expect(find.text('Editar tienda'), findsOneWidget);
      expect(find.text('Walmart Supercenter'), findsWidgets);
      expect(tester.takeException(), isNull);

      // Desplaza desde el margen para evitar el scroll interno de las notas.
      for (var step = 0; step < 5; step++) {
        await tester.dragFrom(const Offset(10, 650), const Offset(0, -400));
        await tester.pumpAndSettle();
      }
      expect(find.text('Guardar cambios'), findsOneWidget);
      expect(find.text('Bloqueado'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(find.text('CATÁLOGO DE TIENDAS'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
}

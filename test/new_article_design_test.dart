import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_inventario/main_diseno.dart';

import 'helpers/open_purchase.dart';

void main() {
  testWidgets('Nuevo artículo se abre desde Inicio y se adapta al celular', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    for (final width in [320.0, 390.0, 600.0]) {
      tester.view.physicalSize = Size(width, 844);
      await tester.pumpWidget(const AlacenaPreviewApp());
      await tester.tap(find.byTooltip('Agregar artículo'));
      await tester.pumpAndSettle();
      expect(find.text('Nuevo artículo'), findsOneWidget);
      expect(find.text('Foto opcional'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // El margen permite desplazar el formulario sin arrastrar campos internos.
      for (var step = 0; step < 5; step++) {
        await tester.dragFrom(const Offset(10, 650), const Offset(0, -400));
        await tester.pumpAndSettle();
      }
      expect(find.text('Guardar artículo'), findsOneWidget);
      expect(find.text('Congelador'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(find.text('Alacena'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('Nuevo producto en Registrar compra abre el formulario', (
    tester,
  ) async {
    await tester.pumpWidget(const AlacenaPreviewApp());
    await openPurchaseFromProduct(tester);
    await tester.tap(find.text('+ Nuevo producto'));
    await tester.pumpAndSettle();
    expect(find.text('Nuevo artículo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

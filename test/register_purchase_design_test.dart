import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_inventario/main_diseno.dart';

import 'helpers/open_purchase.dart';

void main() {
  testWidgets('Compra se abre desde el producto y se adapta al celular', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    for (final width in [320.0, 390.0, 600.0]) {
      tester.view.physicalSize = Size(width, 844);
      await tester.pumpWidget(const AlacenaPreviewApp());
      await openPurchaseFromProduct(tester);
      expect(find.text('Registrar compra'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.scrollUntilVisible(
        find.text('Guardar compra'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Guardar compra'));
      await tester.pumpAndSettle();
      expect(find.text('Registrar compra'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
}

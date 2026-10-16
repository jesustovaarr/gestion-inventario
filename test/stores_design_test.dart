import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_inventario/main_diseno.dart';

void main() {
  testWidgets('Tiendas abre desde Inicio y permite recorrer el catálogo', (
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
      expect(find.text('CATÁLOGO DE TIENDAS'), findsOneWidget);
      expect(find.text('Walmart Supercenter'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.scrollUntilVisible(
        find.text('Costco Wholesale'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Nueva tienda'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Opciones de Costco Wholesale'));
      await tester.pumpAndSettle();
      expect(find.text('Historial de compras'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
}

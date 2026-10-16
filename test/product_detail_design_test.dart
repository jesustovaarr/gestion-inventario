import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_inventario/main_diseno.dart';

void main() {
  testWidgets('Abre el detalle y cambia sus pestañas en un celular angosto', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const AlacenaPreviewApp());
    await tester.tap(find.text('Leche entera'));
    await tester.pumpAndSettle();
    expect(find.text('Detalle del producto'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.scrollUntilVisible(
      find.text('Lotes activos (3)'),
      250,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Historial (4)'));
    await tester.pumpAndSettle();
    expect(find.text('Compra en Walmart'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Tiendas y precios'));
    await tester.pumpAndSettle();
    expect(find.text('\$28.50 / pza'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

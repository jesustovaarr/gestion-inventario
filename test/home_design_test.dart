import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as badges;
import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_inventario/main_diseno.dart';

void main() {
  testWidgets('Inicio se adapta al celular y permite recorrer las secciones', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    for (final width in [320.0, 390.0, 600.0]) {
      tester.view.physicalSize = Size(width, 844);
      await tester.pumpWidget(const AlacenaPreviewApp());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Alacena'), findsOneWidget);
      expect(find.text('Tiendas'), findsOneWidget);
      expect(find.byType(badges.Badge), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
}

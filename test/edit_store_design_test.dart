import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_inventario/screens/pantalla_editar_tienda.dart';

void main() {
  testWidgets('Editar tienda se adapta al celular y permite editar/eliminar', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    for (final width in [320.0, 390.0, 600.0]) {
      tester.view.physicalSize = Size(width, 844);
      await tester.pumpWidget(
        const MaterialApp(
          home: EditStoreScreen(
            storeId: 1,
            storeName: 'Walmart Supercenter',
            address: 'Av. Siempre Viva 123',
            purchases: 0,
            tipoTiendaId: 1,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Editar tienda'), findsOneWidget);
      expect(find.text('Walmart Supercenter'), findsWidgets);
      expect(tester.takeException(), isNull);

      // Desplaza para ver los botones inferiores
      for (var step = 0; step < 5; step++) {
        await tester.dragFrom(const Offset(10, 650), const Offset(0, -400));
        await tester.pumpAndSettle();
      }
      expect(find.text('Guardar'), findsOneWidget);
      expect(find.text('Eliminar tienda definitivamente'), findsOneWidget);
      expect(find.text('Desactivar tienda temporalmente'), findsNothing);
      expect(find.text('Ubicar en mapa'), findsNothing);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
}

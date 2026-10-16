import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_inventario/main_diseno.dart';
import 'package:gestion_inventario/screens/pantalla_registrar_compra.dart';

void main() {
  testWidgets(
    'Una sola lista conserva cambios al navegar y se vacía al completar',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      for (final width in [320.0, 390.0, 600.0, 809.0]) {
        tester.view.physicalSize = Size(width, 844);
        await tester.pumpWidget(const AlacenaPreviewApp());
        await tester.tap(find.text('Carrito'));
        await tester.pumpAndSettle();
        expect(find.text('Mi lista de compras'), findsOneWidget);
        expect(find.text('Ver estado vacío'), findsNothing);
        expect(find.textContaining('Pendientes'), findsNothing);
        expect(find.textContaining('Historial'), findsNothing);
        expect(find.text('Guardar pendiente'), findsNothing);
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('Agregar del catálogo'));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Añadir Yogurt natural a la lista'));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Eliminar Leche entera de la lista'));
        await tester.pumpAndSettle();
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(find.byTooltip('Ver carrito, 3 artículos'), findsOneWidget);
        await tester.tap(find.text('Carrito'));
        await tester.pumpAndSettle();
        expect(
          find.byTooltip('Eliminar Leche entera de la lista'),
          findsNothing,
        );
        await tester.scrollUntilVisible(
          find.text('Yogurt natural'),
          180,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('Yogurt natural'), findsOneWidget);

        await tester.tap(find.text('Completar lista'));
        await tester.pumpAndSettle();
        expect(find.byType(RegisterPurchaseScreen), findsNothing);
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(find.byTooltip('Ver carrito, 0 artículos'), findsOneWidget);
        await tester.tap(find.text('Carrito'));
        await tester.pumpAndSettle();
        expect(find.text('Tu lista está vacía'), findsOneWidget);
        expect(find.textContaining('Pendientes'), findsNothing);
        expect(find.textContaining('Historial'), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      }
    },
  );
}

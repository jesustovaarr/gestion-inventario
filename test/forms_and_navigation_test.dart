import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_inventario/main_diseno.dart';
import 'package:gestion_inventario/screens/formulario_producto.dart';
import 'package:gestion_inventario/screens/formulario_tienda.dart';
import 'package:gestion_inventario/screens/pantalla_registrar_compra.dart';
import 'package:gestion_inventario/widgets/barra_navegacion_inferior.dart';

Finder navLabel(String label) => find.descendant(
  of: find.byType(AppBottomNavigation),
  matching: find.text(label),
);

void main() {
  testWidgets('Crear y editar reutilizan formularios y mantienen navegación', (
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
      expect(
        tester
            .widget<ProductFormScreen>(find.byType(ProductFormScreen))
            .product,
        isNull,
      );
      expect(find.byType(AppBottomNavigation), findsOneWidget);

      await tester.tap(navLabel('Tiendas'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nueva tienda'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<StoreFormScreen>(find.byType(StoreFormScreen)).isEditing,
        isFalse,
      );
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText).first)
            .controller
            .text,
        isEmpty,
      );
      expect(find.text('Bloqueado'), findsNothing);
      expect(find.byType(AppBottomNavigation), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(navLabel('Tiendas'));
      await tester.pumpAndSettle();
      await tester.drag(
        find.byKey(const ValueKey('store-swipe-Walmart Supercenter')),
        const Offset(-220, 0),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Editar Walmart Supercenter'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<StoreFormScreen>(find.byType(StoreFormScreen)).isEditing,
        isTrue,
      );
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText).first)
            .controller
            .text,
        'Walmart Supercenter',
      );
      expect(find.byType(AppBottomNavigation), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(navLabel('Inicio'));
      await tester.pumpAndSettle();
      await tester.drag(
        find.byKey(const ValueKey('product-swipe-Leche entera')),
        const Offset(-220, 0),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Editar Leche entera'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ProductFormScreen>(find.byType(ProductFormScreen))
            .product!
            .name,
        'Leche entera',
      );
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText).first)
            .controller
            .text,
        'Leche entera',
      );
      expect(find.text('Primer lote'), findsNothing);
      expect(find.byType(AppBottomNavigation), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(navLabel('Calendario'));
      await tester.pumpAndSettle();
      expect(find.text('Mayo 2024'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets(
    'Agregar en la lista abre Registrar compra, sin completar la lista',
    (tester) async {
      await tester.pumpWidget(const AlacenaPreviewApp());
      await tester.tap(find.text('Carrito'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('cart-register-purchase')),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('cart-register-purchase')));
      await tester.pumpAndSettle();
      expect(find.byType(RegisterPurchaseScreen), findsOneWidget);
      expect(find.text('Registrar compra'), findsOneWidget);
      expect(find.byType(AppBottomNavigation), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Completar lista'), findsOneWidget);
      expect(find.textContaining('Historial ('), findsNothing);
      expect(find.textContaining('Pendientes ('), findsNothing);
      expect(find.byType(AppBottomNavigation), findsOneWidget);
    },
  );
}

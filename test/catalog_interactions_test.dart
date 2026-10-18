import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_inventario/database/inventario_db.dart';
import 'package:gestion_inventario/main.dart';
import 'package:gestion_inventario/screens/formulario_producto.dart';
import 'package:gestion_inventario/screens/formulario_tienda.dart';
import 'package:gestion_inventario/screens/pantalla_tiendas.dart';

import 'purchase_flow_test.dart' show PurchaseDatabase;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Tocar una tienda permite editarla y deslizar permite borrarla', (
    tester,
  ) async {
    final db = PurchaseDatabase();
    final inventory = InventarioDB.conDatabase(db, verificarEsquema: true);
    await inventory.database;
    await tester.pumpWidget(const MaterialApp(home: StoresScreen()));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.more_vert_rounded), findsNothing);
    await tester.tap(find.text('Supermercado Uno'));
    await tester.pumpAndSettle();
    expect(find.byType(StoreFormScreen), findsOneWidget);
    final name = find.byWidgetPredicate(
      (w) => w is TextFormField && w.controller?.text == 'Supermercado Uno',
    );
    await tester.ensureVisible(name);
    await tester.enterText(name, 'Tienda actualizada');
    FocusManager.instance.primaryFocus?.unfocus();
    final save = find.widgetWithText(FilledButton, 'Guardar');
    await tester.scrollUntilVisible(
      save,
      -250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(db.tables['Tienda']!.single['nombre'], 'Tienda actualizada');
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('store-swipe-1')),
        matching: find.text('Tienda actualizada'),
      ),
      findsOneWidget,
    );

    final card = find.byKey(const ValueKey('store-swipe-1'));
    await tester.drag(card, const Offset(-350, 0));
    await tester.pumpAndSettle();
    expect(find.text('Editar'), findsNothing);
    await tester.tap(find.byTooltip('Borrar Tienda actualizada'));
    await tester.pumpAndSettle();
    expect(find.text('Eliminar tienda'), findsOneWidget);
    expect(db.tables['Tienda'], hasLength(1));
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(db.tables['Tienda'], hasLength(1));

    await tester.drag(card, const Offset(-350, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Borrar Tienda actualizada'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
    await tester.pumpAndSettle();
    expect(db.tables['Tienda'], isEmpty);
    expect(find.text('No hay tiendas registradas.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await inventory.close();
  });

  testWidgets('Inicio permite editar al tocar o deslizar, y confirma antes de borrar', (
    tester,
  ) async {
    final db = PurchaseDatabase();
    final inventory = InventarioDB.conDatabase(db, verificarEsquema: true);
    await inventory.database;
    await tester.pumpWidget(const AlacenaPreviewApp());
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Leche'));
    await tester.tap(find.text('Leche'));
    await tester.pumpAndSettle();
    expect(find.byType(ProductFormScreen), findsOneWidget);
    expect(
      tester
          .widget<ProductFormScreen>(find.byType(ProductFormScreen))
          .product
          ?.id,
      1,
    );
    await tester.pageBack();
    await tester.pumpAndSettle();

    final card = find.byKey(const ValueKey('product-swipe-1'));
    await tester.ensureVisible(card);
    await tester.drag(card, const Offset(-350, 0));
    await tester.pumpAndSettle();
    expect(find.text('Editar'), findsOneWidget);
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();
    expect(find.byType(ProductFormScreen), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.drag(card, const Offset(-350, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Borrar Leche'));
    await tester.pumpAndSettle();
    expect(find.text('Eliminar del inventario'), findsOneWidget);
    expect(db.tables['Producto'], hasLength(2));
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(db.tables['Producto'], hasLength(2));
    expect(db.tables['Lote'], hasLength(1));

    await tester.drag(card, const Offset(-350, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Borrar Leche'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
    await tester.pumpAndSettle();
    expect(db.tables['Producto']!.map((p) => p['nombre']), ['Arroz']);
    expect(find.text('Leche'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await inventory.close();
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_inventario/database/inventario_db.dart';
import 'package:gestion_inventario/database/daos/compra_dao.dart';
import 'package:gestion_inventario/database/daos/producto_dao.dart';
import 'package:gestion_inventario/models/compra_model.dart';
import 'package:gestion_inventario/presentation/controlador_carrito.dart';
import 'package:gestion_inventario/presentation/modelos_vista_alacena.dart';
import 'package:gestion_inventario/screens/pantalla_carrito.dart';
import 'package:gestion_inventario/screens/pantalla_registrar_compra.dart';
import 'package:gestion_inventario/utils/presentaciones.dart';
import 'package:gestion_inventario/widgets/editor_articulo_compra.dart';
import 'package:gestion_inventario/widgets/tarjeta_articulo_compra.dart';

import 'purchase_flow_test.dart' show PurchaseDatabase;

PurchaseDatabase packagedDatabase() {
  final db = PurchaseDatabase();
  db.tables['Producto']!.first.addAll({
    'presentacion': 'carton',
    'contenido_envase': 0.5,
    'precio': 20.0,
    'codigo': '7500000000001',
  });
  db.tables['Producto']!.last.addAll({
    'nombre': 'Papas',
    'presentacion': 'bolsa',
    'contenido_envase': 1.0,
    'precio': 15.0,
    'codigo': '7500000000002',
  });
  return db;
}

void phone(WidgetTester tester, [double width = 390]) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 844);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'Precio por envase y contenido dan el total y existencias correctos',
    () async {
      final db = packagedDatabase();
      final dao = CompraDao(db);
      final purchase = await dao.registrarCompraCompleta(
        tiendaId: 1,
        fechaCompra: '2030-01-01',
        articulos: const [
          ArticuloCompra(
            productoId: 1,
            cantidad: 1.5,
            precioUnitarioCentavos: 1000,
            fechaCaducidad: '2030-01-10',
            presentacion: PresentacionCompra.carton,
            numeroEnvases: 3,
            contenidoEnvase: 0.5,
          ),
          ArticuloCompra(
            productoId: 2,
            cantidad: 2,
            precioUnitarioCentavos: 1500,
            fechaCaducidad: '2030-01-10',
            presentacion: PresentacionCompra.bolsa,
            numeroEnvases: 2,
            contenidoEnvase: 1,
          ),
        ],
      );
      expect(purchase.totalCentavos, 6000);
      expect(db.tables['Lote']!.skip(1).map((l) => l['cantidad']), [1.5, 2.0]);
      final history = db.tables['Historial_Compras']!;
      expect(history.first['precio_unitario'], 20.0);
      expect(history.first['precio_envase_centavos'], 1000);
      expect(history.first['numero_envases'], 3);
      expect(history.first['contenido_envase'], 0.5);
      expect(db.tables['Producto']!.first['presentacion'], 'carton');
      for (final line in const [
        ArticuloCompra(
          productoId: 1,
          cantidad: 1,
          precioUnitarioCentavos: 1000,
          fechaCaducidad: '2030-01-10',
          presentacion: PresentacionCompra.carton,
          numeroEnvases: 3,
          contenidoEnvase: 0.5,
        ),
        ArticuloCompra(
          productoId: 1,
          cantidad: 1,
          precioUnitarioCentavos: 1000,
          fechaCaducidad: '2030-01-10',
          presentacion: PresentacionCompra.carton,
          numeroEnvases: 0,
          contenidoEnvase: 1,
        ),
      ]) {
        await expectLater(
          dao.registrarCompraCompleta(
            tiendaId: 1,
            fechaCompra: '2030-01-01',
            articulos: [line],
          ),
          throwsArgumentError,
        );
      }
      expect(db.tables['Compra']!.length, 1);
    },
  );
  test('Un carrito anterior mantiene su cantidad y precio por unidad al cambiar la presentación del catálogo', () async {
    final db = packagedDatabase();
    db.tables['Carrito']!.add({
      'id': 1,
      'producto_id': 1,
      'cantidad_a_comprar': 2.0,
    });
    final inventory = InventarioDB.conDatabase(db, verificarEsquema: true);
    await inventory.database;
    final controller = ShoppingListsPreviewController();
    await controller.cargarDesdeBD();
    final item = controller.current.items.single;
    expect(item.quantity, 2.0);
    expect(item.packaging, PresentacionCompra.granel);
    expect(item.priceCents, 2000);
    expect(item.subtotalCents, 4000);
    controller.dispose();
    await inventory.close();
  });
  testWidgets(
    'Dos bolsas y tres cartones; una sola fecha sobrevive al cerrar, recargar y sumar',
    (tester) async {
      phone(tester, 320);
      final db = packagedDatabase();
      final inventory = InventarioDB.conDatabase(db, verificarEsquema: true);
      await inventory.database;
      final controller = ShoppingListsPreviewController();
      await controller.cargarDesdeBD();
      final products = await ProductoDao(db).obtenerConStock();
      await controller.addProduct(products.first.toPreview());
      await controller.addProduct(products.last.toPreview());
      await controller.setItem(
        controller.current.items
            .firstWhere((i) => i.product.id == 1)
            .copyWith(packageCount: 3),
      );
      await controller.setItem(
        controller.current.items
            .firstWhere((i) => i.product.id == 2)
            .copyWith(packageCount: 2),
      );
      Widget app(Key key) => ShoppingListsPreviewScope(
        controller: controller,
        child: MaterialApp(home: CartScreen(key: key)),
      );
      await tester.pumpWidget(app(const ValueKey('first')));
      await tester.pumpAndSettle();
      expect(find.text('2 bolsas de 1 kg'), findsOneWidget);
      expect(find.text('3 cartones de 500 ml'), findsOneWidget);
      await tester.ensureVisible(find.text('Papas'));
      await tester.tap(find.text('Papas'));
      await tester.pumpAndSettle();
      final dateTile = tester.widget<ListTile>(
        find.widgetWithText(ListTile, 'Fecha de caducidad'),
      );
      dateTile.onTap!();
      dateTile.onTap!();
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsOneWidget);
      final expiry = DateTime.now().add(const Duration(days: 30));
      tester
          .widget<CalendarDatePicker>(find.byType(CalendarDatePicker))
          .onDateChanged(expiry);
      await tester.pump();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      // Cerrar sin otro botón de "aplicar" conserva la fecha elegida.
      await tester.tap(find.byTooltip('Cerrar artículo'));
      await tester.pumpAndSettle();
      final saved = db.tables['Carrito']!.firstWhere(
        (r) => r['producto_id'] == 2,
      );
      expect(
        saved['fecha_caducidad'],
        expiry.toIso8601String().substring(0, 10),
      );
      await controller.cargarDesdeBD();
      await tester.pumpAndSettle();
      await tester.pumpWidget(app(const ValueKey('reopened')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Papas'));
      await tester.tap(find.text('Papas'));
      await tester.pumpAndSettle();
      expect(find.byType(CalendarDatePicker), findsNothing);
      expect(
        find.text('${expiry.day}/${expiry.month}/${expiry.year}'),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('Cerrar artículo'));
      await tester.pumpAndSettle();
      final plus = find.byTooltip('Sumar una unidad de Papas');
      await tester.ensureVisible(plus);
      await tester.tap(plus);
      await tester.pumpAndSettle();
      expect(find.text('3 bolsas de 1 kg'), findsOneWidget);
      expect(
        db.tables['Carrito']!.firstWhere(
          (r) => r['producto_id'] == 2,
        )['fecha_caducidad'],
        saved['fecha_caducidad'],
      );
      expect(db.tables['Lote']!.length, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
      await inventory.close();
    },
  );
  testWidgets(
    'Editar la compra cambia cantidad y precio; el tamaño pertenece al catálogo',
    (tester) async {
      phone(tester);
      final db = packagedDatabase();
      final inventory = InventarioDB.conDatabase(db, verificarEsquema: true);
      await inventory.database;
      await tester.pumpWidget(
        const MaterialApp(home: RegisterPurchaseScreen(productoId: 2)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Papas'));
      await tester.pumpAndSettle();
      expect(find.text('Precio por bolsa'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('purchase-quantity')),
        '2',
      );
      expect(
        find.byType(DropdownButtonFormField<PresentacionCompra>),
        findsNothing,
      );
      expect(find.byKey(const ValueKey('purchase-content')), findsNothing);
      expect(find.text('Bolsa de 1 kg'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('purchase-unit-price')),
        '20',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      expect(find.text('2 bolsas de 1 kg · Total: 2 kg'), findsOneWidget);
      expect(find.text('Subtotal: \$40.00'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('purchase-quantity')),
        '2.5',
      );
      await tester.pump();
      await tester.ensureVisible(find.text('Listo'));
      await tester.tap(find.text('Listo'));
      await tester.pumpAndSettle();
      expect(find.text('Indica una cantidad válida'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await inventory.close();
    },
  );
  testWidgets(
    'El carrito selecciona productos existentes y permite editar la compra',
    (tester) async {
      phone(tester);
      final db = packagedDatabase();
      final inventory = InventarioDB.conDatabase(db, verificarEsquema: true);
      await inventory.database;
      await tester.pumpWidget(
        const MaterialApp(home: RegisterPurchaseScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.byTooltip('Escanear QR o código'), findsNothing);
      expect(find.byTooltip('Nuevo producto'), findsNothing);
      await tester.tap(find.text('Agregar productos'));
      await tester.pumpAndSettle();
      expect(find.text('Crear producto en el catálogo'), findsNothing);
      final search = find.byWidgetPredicate(
        (w) =>
            w is TextField && w.decoration?.hintText == 'Buscar en tu alacena',
      );
      await tester.enterText(search, 'Sin coincidencias');
      await tester.pumpAndSettle();
      expect(
        find.text('No hay productos que coincidan con la búsqueda.'),
        findsOneWidget,
      );
      await tester.enterText(search, 'papas');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(CheckboxListTile, 'Papas'));
      await tester.pump();
      await tester.tap(find.text('Usar selección (1)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Papas'));
      await tester.pumpAndSettle();
      expect(find.byType(PurchaseArticleEditor), findsOneWidget);
      expect(find.text('Cámara'), findsNothing);
      expect(find.text('Galería'), findsNothing);
      expect(db.tables['Producto']!.length, 2);
      expect(db.tables['Lote']!.length, 1);
      expect(db.tables['Compra'], isEmpty);
      expect(find.text('Fecha de caducidad'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await inventory.close();
    },
  );
  testWidgets('Tarjetas de compra se mantienen compactas a distintos anchos', (
    tester,
  ) async {
    final db = packagedDatabase();
    final product = (await ProductoDao(db).obtenerPorId(2))!.toPreview();
    final item = ShoppingListItemPreview(
      product,
      2,
      packaging: PresentacionCompra.bolsa,
      packageCount: 2,
      packageContent: 1,
      priceCents: 1500,
    );
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    for (final width in [320.0, 390.0, 600.0]) {
      tester.view.physicalSize = Size(width, 844);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(20),
              child: PurchaseArticleCard(
                item: item,
                onTap: () {},
                onRemove: () {},
                onIncrease: () {},
                onDecrease: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byType(PurchaseArticleCard)).height,
        lessThan(200),
      );
      expect(tester.takeException(), isNull);
    }
  });
}

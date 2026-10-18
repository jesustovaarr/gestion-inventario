import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_inventario/database/daos/compra_dao.dart';
import 'package:gestion_inventario/database/daos/lote_dao.dart';
import 'package:gestion_inventario/database/daos/producto_dao.dart';
import 'package:gestion_inventario/database/inventario_db.dart';
import 'package:gestion_inventario/models/compra_model.dart';
import 'package:gestion_inventario/presentation/controlador_carrito.dart';
import 'package:gestion_inventario/presentation/modelos_vista_alacena.dart';
import 'package:gestion_inventario/screens/formulario_producto.dart';
import 'package:gestion_inventario/utils/presentaciones.dart';

import 'purchase_history_test.dart' show HistoryDatabase;

HistoryDatabase chipsDatabase() {
  final db = HistoryDatabase();
  db.tables['Lote']!.clear();
  db.tables['Movimiento_Inventario']!.clear();
  for (final p in db.tables['Producto']!) {
    p.addAll({
      'nombre': 'Sabritas originales',
      'unidad_medida': 'g',
      'presentacion': 'bolsa',
      'contenido_envase': p['id'] == 1 ? 500.0 : 1000.0,
      'precio': p['id'] == 1 ? 0.04 : 0.035,
    });
  }
  return db;
}

ArticuloCompra bag(int productId, int count) => ArticuloCompra(
  productoId: productId,
  cantidad: count * (productId == 1 ? 500.0 : 1000.0),
  precioUnitarioCentavos: productId == 1 ? 2000 : 3500,
  fechaCaducidad: '2030-01-20',
  presentacion: PresentacionCompra.bolsa,
  numeroEnvases: count,
  contenidoEnvase: productId == 1 ? 500 : 1000,
);

Future<void> buy(
  HistoryDatabase db,
  List<ArticuloCompra> items, {
  bool clear = false,
}) async {
  await CompraDao(db).registrarCompraCompleta(
    tiendaId: 1,
    fechaCompra: '2030-01-01',
    articulos: items,
    quitarDelCarrito: clear,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Mismo nombre, dos productos: cada tamaño tiene stock, precio e historial propios', () async {
    final db = chipsDatabase();
    await buy(db, [bag(1, 10), bag(2, 3)]);
    final products = await ProductoDao(db).obtenerConStock();
    expect(products.map((p) => p.toPreview().stockLabel), [
      '10 bolsas de 500 g',
      '3 bolsas de 1000 g',
    ]);
    expect(products.map((p) => p.id).toSet(), {1, 2});
    final receipt = (await CompraDao(db).obtenerCompras()).single;
    expect(receipt.articulos.map((a) => a.descripcionCantidad), [
      '10 bolsas de 500 g',
      '3 bolsas de 1000 g',
    ]);
    expect(receipt.totalCentavos, 30500);
    expect(await LoteDao(db).descontarStockFEFO(1, 500), isTrue);
    expect((await ProductoDao(db).obtenerPorId(1))!.stockActual, 4500);
    expect((await ProductoDao(db).obtenerPorId(2))!.stockActual, 3000);
  });

  test('Carrito agrupa por producto: sumar, quitar y comprar un tamaño conserva el otro', () async {
    final db = chipsDatabase();
    final inventory = InventarioDB.conDatabase(db);
    final cart = ShoppingListsPreviewController();
    await cart.cargarDesdeBD();
    final small = (await ProductoDao(db).obtenerPorId(1))!.toPreview();
    final large = (await ProductoDao(db).obtenerPorId(2))!.toPreview();
    await cart.addProduct(small);
    await cart.addProduct(small);
    await cart.addProduct(large);
    await cart.cargarDesdeBD();
    expect(cart.current.items, hasLength(2));
    expect(
      cart.current.items.singleWhere((i) => i.product.id == 1).packageCount,
      2,
    );
    expect(
      cart.current.items.singleWhere((i) => i.product.id == 2).packageCount,
      1,
    );
    await cart.removeProduct(small);
    expect(db.tables['Carrito']!.single['producto_id'], 2);
    await cart.addProduct(small);
    await buy(db, [bag(1, 1)], clear: true);
    await cart.cargarDesdeBD();
    expect(cart.current.items.single.product.id, 2);
    expect(cart.current.items.single.quantity, 1000);
    cart.dispose();
    await inventory.close();
  });

  test(
    'Editar y eliminar un ID conserva todas las propiedades del otro tamaño',
    () async {
      final db = chipsDatabase();
      await InventarioDB.asegurarEsquema(db);
      await buy(db, [bag(1, 2), bag(2, 3)]);
      final dao = ProductoDao(db);
      final original = (await dao.obtenerPorId(2))!;
      final small = (await dao.obtenerPorId(1))!;
      db.tables['Carrito']!.addAll([
        {
          'id': 1,
          'producto_id': 1,
          'numero_envases': 2,
          'cantidad_a_comprar': 1000.0,
        },
        {
          'id': 2,
          'producto_id': 2,
          'numero_envases': 3,
          'cantidad_a_comprar': 3000.0,
        },
      ]);
      await dao.guardarConLotes(
        small.copyWith(nombre: 'Papas editadas', contenidoEnvase: 600),
        small.lotesActivos
            .map((l) => l.copyWith(contenidoEnvase: 600))
            .toList(),
      );
      expect(db.tables['Carrito']!.first['cantidad_a_comprar'], 1200);
      expect(db.tables['Carrito']!.last['cantidad_a_comprar'], 3000);
      await dao.eliminar(1);
      expect(await dao.obtenerPorId(1), isNull);
      final untouched = (await dao.obtenerPorId(2))!;
      expect(untouched.toMap(), original.toMap());
      expect(untouched.stockActual, 3000);
      expect(
        untouched.lotesActivos.single.toMap(),
        original.lotesActivos.single.toMap(),
      );
    },
  );

  test('La actualización separa formatos anteriores y conserva compras, lotes y movimientos', () async {
    final db = chipsDatabase();
    await buy(db, [bag(1, 10)]);
    // Simula la versión anterior: el mismo ID se había usado para otro tamaño.
    final large = bag(2, 3);
    await buy(db, [
      ArticuloCompra(
        productoId: 1,
        cantidad: large.cantidad,
        precioUnitarioCentavos: large.precioUnitarioCentavos,
        fechaCaducidad: large.fechaCaducidad,
        presentacion: large.presentacion,
        numeroEnvases: large.numeroEnvases,
        contenidoEnvase: large.contenidoEnvase,
      ),
    ]);
    db.tables['Movimiento_Inventario']!.add({
      'id': 1,
      'producto_id': 1,
      'lote_id': 1,
      'tipo': 'consumo',
      'cantidad': 100.0,
      'fecha': '2030-01-02T10:00:00',
    });
    db.tables['Carrito']!.addAll([
      {
        'id': 1,
        'producto_id': 1,
        'presentacion': 'bolsa',
        'contenido_envase': 500.0,
        'numero_envases': 2,
        'cantidad_a_comprar': 1000.0,
      },
      {
        'id': 2,
        'producto_id': 1,
        'presentacion': 'bolsa',
        'contenido_envase': 1000.0,
        'numero_envases': 1,
        'cantidad_a_comprar': 1000.0,
      },
    ]);
    final inventory = InventarioDB.conDatabase(db, verificarEsquema: true);
    await inventory.database;
    final oldReceipts = db.tables['Compra']!.map((r) => Map.of(r)).toList();
    await InventarioDB.migrarProductosIndependientes(db);
    final smallId = db.tables['Lote']!.first['producto_id'] as int;
    expect(smallId, isNot(1));
    expect(db.tables['Lote']!.last['producto_id'], 1);
    expect(db.tables['Lote']!.map((l) => l['cantidad']), [5000.0, 3000.0]);
    expect(db.tables['Historial_Compras']!.map((h) => h['producto_id']), [
      smallId,
      1,
    ]);
    expect(db.tables['Movimiento_Inventario']!.single['producto_id'], smallId);
    expect(db.tables['Movimiento_Inventario']!.single['cantidad'], 100.0);
    expect(db.tables['Carrito']!.map((c) => c['producto_id']), [smallId, 1]);
    expect(db.tables['Compra'], oldReceipts);
    final before = db.tables['Producto']!.length;
    await InventarioDB.migrarProductosIndependientes(db);
    expect(db.tables['Producto'], hasLength(before));
    expect(
      (await ProductoDao(db).obtenerPorId(smallId))!.toPreview().stockLabel,
      '10 bolsas de 500 g',
    );
    await inventory.close();
  });
  testWidgets(
    'Registrar diez bolsas de 50 g almacena 500 g con el precio por bolsa',
    (tester) async {
      final db = chipsDatabase();
      final inventory = InventarioDB.conDatabase(db, verificarEsquema: true);
      await inventory.database;
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(ctx).push<bool>(
                  MaterialPageRoute(builder: (_) => const ProductFormScreen()),
                ),
                child: const Text('Nuevo'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Nuevo'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, 'Papas nuevas');
      final packaging = find.byType(
        DropdownButtonFormField<PresentacionCompra>,
      );
      await tester.scrollUntilVisible(
        packaging,
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(packaging);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bolsa').last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('g').first);
      await tester.tap(find.text('g').first);
      await tester.pumpAndSettle();
      final content = find.byWidgetPredicate(
        (w) =>
            w is TextField && w.decoration?.labelText == 'Contenido por bolsa',
      );
      await tester.enterText(content, '50');
      final quantity = find.byKey(const ValueKey('quantity-cantidad inicial'));
      await tester.ensureVisible(quantity);
      await tester.enterText(quantity, '10');
      final price = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.prefixText == r'$ ',
      );
      await tester.scrollUntilVisible(
        price,
        -300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.enterText(price, '10');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.scrollUntilVisible(
        find.text('Guardar artículo'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -150));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar artículo'));
      await tester.pumpAndSettle();
      final saved = db.tables['Producto']!.singleWhere(
        (p) => p['nombre'] == 'Papas nuevas',
      );
      expect(saved['precio'], 0.2);
      expect(db.tables['Lote']!.single['cantidad'], 500.0);
      expect(db.tables['Lote']!.single['contenido_envase'], 50.0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await inventory.close();
    },
  );
}

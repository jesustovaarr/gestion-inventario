import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_inventario/components/tema_alacena.dart';
import 'package:gestion_inventario/database/daos/compra_dao.dart';
import 'package:gestion_inventario/database/inventario_db.dart';
import 'package:gestion_inventario/main.dart';
import 'package:gestion_inventario/models/compra_model.dart';
import 'package:gestion_inventario/screens/pantalla_carrito.dart';
import 'package:gestion_inventario/screens/pantalla_historial_compras.dart';
import 'package:gestion_inventario/utils/presentaciones.dart';

import 'purchase_flow_test.dart' show PurchaseDatabase;

class HistoryDatabase extends PurchaseDatabase {
  bool failReading = false;
  bool failDeleting = false;

  Map<String, Object?>? _row(String table, Object? id) =>
      tables[table]!.where((r) => r['id'] == id).firstOrNull;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #delete &&
        invocation.positionalArguments.first == 'Compra' &&
        failDeleting) {
      throw StateError('Fallo al eliminar la compra');
    }
    if (invocation.memberName == #rawQuery) {
      final sql = invocation.positionalArguments.first as String;
      if (sql.contains('FROM Compra c')) {
        if (failReading) throw StateError('Fallo al leer la base');
        return Future<List<Map<String, Object?>>>.value([
          for (final c in tables['Compra']!)
            {...c, 'tienda_nombre': _row('Tienda', c['tienda_id'])?['nombre']},
        ]);
      }
      if (sql.contains('FROM Historial_Compras hc')) {
        return Future<List<Map<String, Object?>>>.value([
          for (final r in tables['Historial_Compras']!)
            {
              ...r,
              'producto_nombre': _row('Producto', r['producto_id'])?['nombre'],
              'unidad_medida': _row(
                'Producto',
                r['producto_id'],
              )?['unidad_medida'],
              'imagen': _row('Producto', r['producto_id'])?['imagen'],
              'tienda_nombre': _row('Tienda', r['tienda_id'])?['nombre'],
              'fecha_caducidad': _row('Lote', r['lote_id'])?['fecha_caducidad'],
            },
        ]);
      }
    }
    return super.noSuchMethod(invocation);
  }
}

Future<HistoryDatabase> historyFixture() async {
  final db = HistoryDatabase();
  db.tables['Tienda']!.add({'id': 2, 'nombre': 'Mercado Dos'});
  await CompraDao(db).registrarCompraCompleta(
    tiendaId: 1,
    fechaCompra: '2030-01-01',
    articulos: const [
      ArticuloCompra(
        productoId: 1,
        cantidad: 1,
        precioUnitarioCentavos: 2390,
        fechaCaducidad: '2030-01-15',
        presentacion: PresentacionCompra.carton,
        numeroEnvases: 2,
        contenidoEnvase: 0.5,
      ),
      ArticuloCompra(
        productoId: 2,
        cantidad: 2,
        precioUnitarioCentavos: 1500,
        fechaCaducidad: '2030-01-20',
      ),
    ],
  );
  await CompraDao(db).registrarCompraCompleta(
    tiendaId: 2,
    fechaCompra: '2030-01-02',
    articulos: const [
      ArticuloCompra(
        productoId: 2,
        cantidad: 1,
        precioUnitarioCentavos: 1600,
        fechaCaducidad: '2030-01-25',
      ),
    ],
  );
  db.tables['Historial_Compras']!.addAll([
    {
      'id': 4,
      'producto_id': 1,
      'tienda_id': 1,
      'fecha_compra': '2029-12-31',
      'cantidad': 1.25,
      'precio_unitario': 7.10,
    },
    {
      'id': 5,
      'producto_id': 2,
      'tienda_id': 1,
      'fecha_compra': '2029-12-31',
      'cantidad': 1,
      'precio_unitario': null,
    },
  ]);
  return db;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'Borrar un recibo o registro antiguo elimina solo su historial',
    () async {
      final db = await historyFixture();
      final dao = CompraDao(db);
      final inventoryBefore = {
        for (final table in [
          'Producto',
          'Lote',
          'Movimiento_Inventario',
          'Carrito',
        ])
          table: db.tables[table]!.map((r) => Map.of(r)).toList(),
      };
      final purchases = await dao.obtenerCompras();
      await dao.eliminarDelHistorial(purchases.singleWhere((c) => c.id == 1));
      expect(db.tables['Compra']!.map((r) => r['id']), [2]);
      expect(db.tables['Historial_Compras']!.map((r) => r['id']), [3, 4, 5]);
      await dao.eliminarDelHistorial(
        purchases.singleWhere((c) => c.clave == 'registro-5'),
      );
      expect(db.tables['Historial_Compras']!.map((r) => r['id']), [3, 4]);
      expect((await dao.obtenerCompras()).map((c) => c.clave), [
        'compra-2',
        'registro-4',
      ]);
      for (final entry in inventoryBefore.entries) {
        expect(db.tables[entry.key], entry.value, reason: entry.key);
      }
    },
  );

  test(
    'Si falla el borrado del recibo, se conservan todos sus artículos',
    () async {
      final db = await historyFixture();
      final dao = CompraDao(db);
      final purchases = await dao.obtenerCompras();
      final before = {
        for (final table in db.tables.entries)
          table.key: table.value.map((r) => Map.of(r)).toList(),
      };
      db.failDeleting = true;
      await expectLater(
        dao.eliminarDelHistorial(purchases.first),
        throwsStateError,
      );
      expect(db.tables, before);
    },
  );

  testWidgets(
    'Deslizar permite cancelar, reintentar y borrar compras sin cambiar existencias',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final db = await historyFixture();
      final inventory = InventarioDB.conDatabase(db);
      final lots = db.tables['Lote']!.map((r) => Map.of(r)).toList();
      await tester.pumpWidget(const MaterialApp(home: PurchaseHistoryScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('purchase-history-store-2')));
      await tester.pumpAndSettle();

      Future<void> revealDelete(String key) async {
        final card = find.byKey(ValueKey('purchase-swipe-$key'));
        await tester.scrollUntilVisible(
          card,
          180,
          scrollable: find.byType(Scrollable).first,
        );
        await Scrollable.ensureVisible(tester.element(card), alignment: 0.4);
        await tester.pumpAndSettle();
        await tester.drag(card, const Offset(-300, 0));
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(of: card, matching: find.text('Borrar')),
        );
        await tester.pumpAndSettle();
      }

      await revealDelete('compra-2');
      expect(find.text('Eliminar compra'), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(db.tables['Compra'], hasLength(2));
      expect(db.tables['Historial_Compras'], hasLength(5));
      db.failDeleting = true;
      await revealDelete('compra-2');
      await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
      await tester.pumpAndSettle();
      expect(
        find.text('No se pudo eliminar la compra. Inténtalo de nuevo.'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('compra-2')), findsOneWidget);
      expect(db.tables['Historial_Compras'], hasLength(5));
      db.failDeleting = false;
      await revealDelete('compra-2');
      await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('compra-2')), findsNothing);
      expect(find.text('3 compras · Más recientes primero'), findsOneWidget);
      expect(
        tester
            .widget<ChoiceChip>(
              find.byKey(const ValueKey('purchase-history-store-1')),
            )
            .selected,
        isFalse,
      );
      expect(
        find.byKey(const ValueKey('purchase-history-store-2')),
        findsNothing,
      );
      expect(db.tables['Compra']!.single['id'], 1);
      expect(db.tables['Historial_Compras']!.map((r) => r['id']), [1, 2, 4, 5]);
      await revealDelete('registro-5');
      await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
      await tester.pumpAndSettle();
      expect(db.tables['Historial_Compras']!.map((r) => r['id']), [1, 2, 4]);
      expect(db.tables['Lote'], lots);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(const MaterialApp(home: PurchaseHistoryScreen()));
      await tester.pumpAndSettle();
      expect(find.text('2 compras · Más recientes primero'), findsOneWidget);
      expect(find.byKey(const ValueKey('compra-2')), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await inventory.close();
    },
  );

  test('Agrupa recibos, mantiene registros antiguos y usa el precio de la compra', () async {
    final db = await historyFixture();
    // El catálogo y las existencias actuales no sustituyen los datos comprados.
    db.tables['Producto']!.first.addAll({
      'precio': 999.0,
      'presentacion': 'botella',
      'contenido_envase': 1.0,
    });
    for (final lote in db.tables['Lote']!) {
      lote['cantidad'] = 0.0;
    }
    final writes = db.writes.toList();
    final compras = await CompraDao(db).obtenerCompras();
    expect(compras.map((c) => c.clave), [
      'compra-2',
      'compra-1',
      'registro-5',
      'registro-4',
    ]);
    expect(compras[1].articulos, hasLength(2));
    expect(compras[1].totalCentavos, 7780);
    final leche = compras[1].articulos.first;
    expect(leche.descripcionCantidad, '2 cartones de 500 ml');
    expect(leche.precioVisibleCentavos, 2390);
    expect(leche.subtotalCentavos, 4780);
    expect(compras[2].totalCentavos, isNull);
    expect(compras[3].totalCentavos, 888);
    expect(db.writes, writes);
  });

  testWidgets(
    'Historial muestra recibos y permite filtrar por producto y tienda',
    (tester) async {
      final db = await historyFixture();
      final inventory = InventarioDB.conDatabase(db);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        MaterialApp(
          theme: PantryTheme.light,
          home: const PurchaseHistoryScreen(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('4 compras · Más recientes primero'), findsOneWidget);
      expect(find.text(r'Total: $16.00'), findsOneWidget);
      final search = find.byKey(const ValueKey('purchase-history-search'));
      await tester.enterText(search, 'Leche');
      await tester.pumpAndSettle();
      expect(find.text('2 compras · Más recientes primero'), findsOneWidget);
      final receipt = find.byKey(const ValueKey('compra-1'));
      await tester.ensureVisible(receipt);
      await tester.tap(
        find.descendant(of: receipt, matching: find.byType(ExpansionTile)),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('2 cartones de 500 ml'));
      expect(find.text('2 cartones de 500 ml'), findsOneWidget);
      expect(find.text(r'Subtotal: $47.80'), findsOneWidget);
      expect(find.text(r'$23.90 por cartón'), findsOneWidget);
      await tester.ensureVisible(search);
      await tester.enterText(search, '');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      final store = find.byKey(const ValueKey('purchase-history-store-2'));
      await Scrollable.ensureVisible(tester.element(store), alignment: 0.4);
      await tester.pumpAndSettle();
      await tester.tap(store);
      await tester.pumpAndSettle();
      expect(find.text('1 compra · Más recientes primero'), findsOneWidget);
      await tester.tap(store);
      await tester.pumpAndSettle();
      expect(find.text('4 compras · Más recientes primero'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('purchase-history-store-1')));
      await tester.pumpAndSettle();
      expect(find.text('3 compras · Más recientes primero'), findsOneWidget);
      await tester.tap(store);
      await tester.pumpAndSettle();
      expect(find.text('1 compra · Más recientes primero'), findsOneWidget);
      expect(find.text('Todas las tiendas'), findsNothing);
      await tester.enterText(search, 'Leche');
      await tester.pumpAndSettle();
      expect(
        find.text('No hay compras que coincidan con la búsqueda.'),
        findsOneWidget,
      );
      await tester.tap(store);
      await tester.pumpAndSettle();
      expect(find.text('2 compras · Más recientes primero'), findsOneWidget);
      expect(tester.widget<TextField>(search).controller!.text, 'Leche');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await inventory.close();
    },
  );

  testWidgets(
    'El historial vacío se adapta y un fallo de lectura permite reintentar',
    (tester) async {
      final db = HistoryDatabase();
      final inventory = InventarioDB.conDatabase(db);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      for (final width in [320.0, 390.0, 600.0]) {
        tester.view.physicalSize = Size(width, 844);
        await tester.pumpWidget(
          MaterialApp(
            theme: PantryTheme.light,
            home: const PurchaseHistoryScreen(),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.text(
            'No hay compras registradas. Las compras que guardes desde Carrito aparecerán aquí.',
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      }
      db.failReading = true;
      await tester.pumpWidget(const MaterialApp(home: PurchaseHistoryScreen()));
      await tester.pumpAndSettle();
      expect(
        find.text('No se pudo cargar el historial de compras.'),
        findsOneWidget,
      );
      db.failReading = false;
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      expect(find.text('0 compras · Más recientes primero'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await inventory.close();
    },
  );

  testWidgets(
    'Los detalles de una compra se adaptan a diferentes tamaños de celular',
    (tester) async {
      final db = await historyFixture();
      final inventory = InventarioDB.conDatabase(db);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      for (final width in [320.0, 390.0, 600.0]) {
        tester.view.physicalSize = Size(width, 844);
        await tester.pumpWidget(
          MaterialApp(
            theme: PantryTheme.light,
            home: const PurchaseHistoryScreen(),
          ),
        );
        await tester.pumpAndSettle();
        final receipt = find.byKey(const ValueKey('compra-1'));
        await tester.scrollUntilVisible(
          receipt,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(
          find.descendant(of: receipt, matching: find.byType(ExpansionTile)),
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('2 cartones de 500 ml'));
        await tester.pumpAndSettle();
        expect(find.text(r'Total: $77.80'), findsOneWidget);
        expect(find.text(r'Subtotal: $47.80'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      }
      await inventory.close();
    },
  );

  testWidgets(
    'Carrito abre el historial por su ruta y conserva la lista al volver',
    (tester) async {
      final db = await historyFixture();
      db.tables['Carrito']!.add({
        'id': 1,
        'producto_id': 1,
        'cantidad_a_comprar': 2.0,
      });
      final before = db.tables['Carrito']!
          .map((r) => Map<String, Object?>.from(r))
          .toList();
      final inventory = InventarioDB.conDatabase(db);
      await tester.pumpWidget(const AlacenaPreviewApp());
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Carrito'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CartScreen), findsOneWidget);
      await tester.tap(find.text('Historial de compras'));
      await tester.pumpAndSettle();
      expect(find.byType(PurchaseHistoryScreen), findsOneWidget);
      expect(find.text('4 compras · Más recientes primero'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(CartScreen), findsOneWidget);
      expect(db.tables['Carrito'], before);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await inventory.close();
    },
  );
}

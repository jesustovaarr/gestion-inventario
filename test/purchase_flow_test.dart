import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_inventario/database/inventario_db.dart';
import 'package:gestion_inventario/database/daos/compra_dao.dart';
import 'package:gestion_inventario/models/compra_model.dart';
import 'package:gestion_inventario/presentation/controlador_carrito.dart';
import 'package:gestion_inventario/screens/pantalla_carrito.dart';
import 'package:gestion_inventario/screens/pantalla_registrar_compra.dart';
import 'package:gestion_inventario/utils/importes.dart';

import 'product_editing_test.dart' show EditingDatabase;

class PurchaseDatabase extends EditingDatabase {
  PurchaseDatabase() {
    tables['Producto']!.add({
      'id': 2,
      'nombre': 'Arroz',
      'precio': 10.0,
      'imagen': '',
      'unidad_medida': 'kg',
      'stock_minimo': 0.5,
      'categoria_id': 1,
      'ultima_tienda_id': null,
    });
    tables['Tienda']!.add({
      'id': 1,
      'nombre': 'Supermercado Uno',
      'tipo_tienda_id': 1,
      'tipo_tienda_nombre': 'Supermercado',
    });
  }
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #rawQuery) {
      final sql = invocation.positionalArguments.first as String;
      if (sql.contains('FROM Tienda')) {
        return Future<List<Map<String, Object?>>>.value(
          tables['Tienda']!.map((r) => Map<String, Object?>.from(r)).toList(),
        );
      }
      if (sql.contains('FROM Producto p')) {
        final args = invocation.positionalArguments.length > 1
            ? invocation.positionalArguments[1] as List?
            : null;
        final products = tables['Producto']!.where(
          (p) => !sql.contains('WHERE p.id = ?') || p['id'] == args?.first,
        );
        return Future<List<Map<String, Object?>>>.value(
          products.map((p) {
            final lots =
                tables['Lote']!
                    .where(
                      (l) =>
                          l['producto_id'] == p['id'] &&
                          (l['cantidad'] as num) > 0,
                    )
                    .toList()
                  ..sort(
                    (a, b) => (a['fecha_caducidad'] as String).compareTo(
                      b['fecha_caducidad'] as String,
                    ),
                  );
            return {
              ...p,
              'categoria_nombre': 'Abarrotes',
              'stock_actual': lots.fold<double>(
                0,
                (s, l) => s + (l['cantidad'] as num).toDouble(),
              ),
              'proxima_caducidad': lots.firstOrNull?['fecha_caducidad'],
              'primer_lote_id': lots.firstOrNull?['id'],
              'cantidad_primer_lote': lots.firstOrNull?['cantidad'],
            };
          }).toList(),
        );
      }
      if (sql.contains('FROM Carrito c')) {
        return Future<List<Map<String, Object?>>>.value([
          for (final row in tables['Carrito']!)
            {
              ...row,
              'producto_nombre': tables['Producto']!.firstWhere(
                (p) => p['id'] == row['producto_id'],
              )['nombre'],
            },
        ]);
      }
    }
    return super.noSuchMethod(invocation);
  }
}

List<ArticuloCompra> lines() => const [
  ArticuloCompra(
    productoId: 1,
    cantidad: 0.5,
    precioUnitarioCentavos: 2550,
    fechaCaducidad: '2030-01-10',
  ),
  ArticuloCompra(
    productoId: 2,
    cantidad: 2.25,
    precioUnitarioCentavos: 1000,
    fechaCaducidad: '2030-01-15',
  ),
];

Future<void> editArticle(
  WidgetTester tester,
  String name,
  String quantity,
  String price,
) async {
  final card = find.text(name);
  await tester.scrollUntilVisible(
    card,
    -200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(card);
  await tester.pumpAndSettle();
  await tester.tap(card);
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byKey(const ValueKey('purchase-quantity')),
    quantity,
  );
  await tester.enterText(
    find.byKey(const ValueKey('purchase-unit-price')),
    price,
  );
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  final expiry = find.text('Fecha de caducidad');
  await tester.ensureVisible(expiry);
  await tester.pumpAndSettle();
  await tester.tap(expiry);
  await tester.pumpAndSettle();
  tester
      .widget<CalendarDatePicker>(find.byType(CalendarDatePicker))
      .onDateChanged(DateTime.now().add(const Duration(days: 30)));
  await tester.pump();
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('Listo'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Listo'));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Importes usan centavos y el total suma subtotales sin residuos', () {
    expect(leerPrecioCentavos('25'), 2500);
    expect(leerPrecioCentavos('25,50'), 2550);
    expect(leerPrecioCentavos('0'), 0);
    expect(leerPrecioCentavos('.5'), 50);
    for (final value in ['NaN', '1e8', '-1', '1.234', '1000000']) {
      expect(leerPrecioCentavos(value), isNull);
    }
    expect(lines().fold<int>(0, (s, i) => s + i.subtotalCentavos), 3525);
    expect(formatearImporte(3525), '35.25');
  });
  test(
    'Guarda una compra con tienda, fechas, dos lotes, historial y total',
    () async {
      final db = PurchaseDatabase();
      db.tables['Carrito']!.addAll([
        {'id': 1, 'producto_id': 1, 'cantidad_a_comprar': 0.5},
        {'id': 2, 'producto_id': 2, 'cantidad_a_comprar': 2.25},
      ]);
      final result = await CompraDao(db).registrarCompraCompleta(
        tiendaId: 1,
        fechaCompra: '2030-01-01',
        articulos: lines(),
        quitarDelCarrito: true,
      );
      expect(result.totalCentavos, 3525);
      expect(result.articulos, 2);
      expect(db.tables['Compra']!.single['total_centavos'], 3525);
      expect(db.tables['Compra']!.single['tienda_id'], 1);
      expect(db.tables['Lote']!.length, 3);
      expect(db.tables['Lote']!.last['cantidad'], 2.25);
      expect(db.tables['Lote']!.last['fecha_caducidad'], '2030-01-15');
      expect(db.tables['Historial_Compras']!.length, 2);
      expect(
        db.tables['Historial_Compras']!.every(
          (r) =>
              r['compra_id'] == result.id &&
              r['tienda_id'] == 1 &&
              r['fecha_compra'] == '2030-01-01',
        ),
        isTrue,
      );
      expect(db.tables['Carrito'], isEmpty);
      expect(db.tables['Producto']!.first['precio'], 25.5);
    },
  );
  test('Un fallo revierte toda la compra y conserva el carrito', () async {
    final db = PurchaseDatabase();
    db.tables['Carrito']!.add({
      'id': 1,
      'producto_id': 1,
      'cantidad_a_comprar': 1.0,
    });
    await expectLater(
      CompraDao(db).registrarCompraCompleta(
        tiendaId: 1,
        fechaCompra: '2030-01-01',
        quitarDelCarrito: true,
        articulos: [
          lines().first,
          const ArticuloCompra(
            productoId: 999,
            cantidad: 1,
            precioUnitarioCentavos: 100,
            fechaCaducidad: '2030-01-10',
          ),
        ],
      ),
      throwsStateError,
    );
    expect(db.tables['Compra'], isEmpty);
    expect(db.tables['Historial_Compras'], isEmpty);
    expect(db.tables['Lote']!.length, 1);
    expect(db.tables['Lote']!.single['cantidad'], 2.0);
    expect(db.tables['Carrito']!.length, 1);
  });
  test('Rechaza duplicados, cantidades inválidas y caducidades anteriores a la compra', () async {
    final db = PurchaseDatabase();
    final dao = CompraDao(db);
    for (final items in [
      <ArticuloCompra>[],
      [lines().first, lines().first],
      [
        const ArticuloCompra(
          productoId: 1,
          cantidad: 0.0001,
          precioUnitarioCentavos: 100,
          fechaCaducidad: '2030-01-10',
        ),
      ],
      [
        const ArticuloCompra(
          productoId: 1,
          cantidad: 1,
          precioUnitarioCentavos: 100,
          fechaCaducidad: '2029-12-31',
        ),
      ],
    ]) {
      await expectLater(
        dao.registrarCompraCompleta(
          tiendaId: 1,
          fechaCompra: '2030-01-01',
          articulos: items,
        ),
        throwsArgumentError,
      );
    }
    expect(db.tables['Compra'], isEmpty);
    expect(db.tables['Lote']!.length, 1);
  });
  testWidgets(
    'Selecciona varios productos, edita datos de compra y guarda el total',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final db = PurchaseDatabase();
      final inventory = InventarioDB.conDatabase(db, verificarEsquema: true);
      await inventory.database;
      final controller = ShoppingListsPreviewController();
      await controller.cargarDesdeBD();
      await tester.pumpWidget(
        ShoppingListsPreviewScope(
          controller: controller,
          child: const MaterialApp(home: CartScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byTooltip('Agregar productos existentes'), findsOneWidget);
      await tester.tap(find.text('Agregar productos'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(CheckboxListTile, 'Leche'));
      await tester.tap(find.widgetWithText(CheckboxListTile, 'Arroz'));
      await tester.pump();
      await tester.tap(find.text('Usar selección (2)'));
      await tester.pumpAndSettle();
      expect(db.tables['Lote']!.length, 1);
      await editArticle(tester, 'Leche', '0,5', '25,50');
      await editArticle(tester, 'Arroz', '2,25', '10');
      await controller.cargarDesdeBD();
      await tester.pumpAndSettle();
      expect(
        controller.current.items.map((i) => i.quantity),
        unorderedEquals([0.5, 2.25]),
      );
      expect(db.tables['Lote']!.length, 1);
      final shop = find.byType(DropdownButtonFormField<int>);
      await tester.scrollUntilVisible(
        shop,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(shop);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Supermercado Uno').last);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Guardar compra'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('\$35.25'), findsOneWidget);
      await tester.tap(find.text('Guardar compra'));
      await tester.pumpAndSettle();
      expect(db.tables['Compra']!.single['total_centavos'], 3525);
      expect(db.tables['Historial_Compras']!.length, 2);
      expect(db.tables['Lote']!.length, 3);
      expect(db.tables['Carrito'], isEmpty);
      expect(controller.current.items, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
      await inventory.close();
    },
  );
  testWidgets(
    'El carrito vacío indica registrar productos desde Inicio sin crear compras',
    (tester) async {
      final db = PurchaseDatabase();
      db.tables['Producto']!.clear();
      db.tables['Lote']!.clear();
      db.tables['Movimiento_Inventario']!.clear();
      final inventory = InventarioDB.conDatabase(db, verificarEsquema: true);
      await inventory.database;
      await tester.pumpWidget(
        const MaterialApp(home: RegisterPurchaseScreen()),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Agregar productos'));
      await tester.pumpAndSettle();
      expect(find.text('Crear producto en el catálogo'), findsNothing);
      expect(
        find.text(
          'No hay productos registrados. Agrega productos desde Inicio.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Usar selección (0)'));
      await tester.pumpAndSettle();
      expect(db.tables['Producto'], isEmpty);
      expect(db.tables['Lote'], isEmpty);
      expect(db.tables['Compra'], isEmpty);
      expect(find.text('Agrega productos a esta compra'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await inventory.close();
    },
  );
}

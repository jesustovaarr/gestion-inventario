import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_inventario/database/daos/compra_dao.dart';
import 'package:gestion_inventario/database/daos/lote_dao.dart';
import 'package:gestion_inventario/database/daos/producto_dao.dart';
import 'package:gestion_inventario/database/inventario_db.dart';
import 'package:gestion_inventario/models/compra_model.dart';
import 'package:gestion_inventario/models/producto_model.dart';
import 'package:gestion_inventario/models/lote_model.dart';
import 'package:gestion_inventario/presentation/acciones_inventario.dart';
import 'package:gestion_inventario/presentation/controlador_carrito.dart';
import 'package:gestion_inventario/presentation/modelos_vista_alacena.dart';
import 'package:gestion_inventario/screens/pantalla_inicio.dart';
import 'package:gestion_inventario/utils/presentaciones.dart';
import 'package:gestion_inventario/widgets/miniatura_producto.dart';
import 'package:gestion_inventario/widgets/tarjeta_producto.dart';

import 'purchase_flow_test.dart' show PurchaseDatabase;

Future<void> buyMilk(
  PurchaseDatabase db, {
  required int count,
  required double content,
  required String expiry,
}) async {
  await CompraDao(db).registrarCompraCompleta(
    tiendaId: 1,
    fechaCompra: '2030-01-01',
    articulos: [
      ArticuloCompra(
        productoId: 1,
        cantidad: count * content,
        precioUnitarioCentavos: 1000,
        fechaCaducidad: expiry,
        presentacion: PresentacionCompra.carton,
        numeroEnvases: count,
        contenidoEnvase: content,
      ),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Inicio muestra cada tamaño como un producto independiente', () async {
    final db = PurchaseDatabase();
    db.tables['Lote']!.clear();
    db.tables['Producto']!.last.addAll({
      'nombre': 'Leche',
      'unidad_medida': 'lt',
      'presentacion': 'carton',
      'contenido_envase': 1.0,
    });
    await buyMilk(db, count: 2, content: 0.5, expiry: '2030-01-10');
    await CompraDao(db).registrarCompraCompleta(
      tiendaId: 1,
      fechaCompra: '2030-01-01',
      articulos: const [
        ArticuloCompra(
          productoId: 2,
          cantidad: 1,
          precioUnitarioCentavos: 2000,
          fechaCaducidad: '2030-01-20',
          presentacion: PresentacionCompra.carton,
          contenidoEnvase: 1,
        ),
      ],
    );
    final small = (await ProductoDao(db).obtenerPorId(1))!.toPreview();
    final large = (await ProductoDao(db).obtenerPorId(2))!.toPreview();
    expect(small.stockLabel, '2 cartones de 500 ml');
    expect(large.stockLabel, '1 cartón de 1 L');
    expect(await LoteDao(db).descontarStockFEFO(1, 0.25), isTrue);
    final updated = (await ProductoDao(db).obtenerPorId(1))!.toPreview();
    expect(updated.availableQuantity, 0.75);
    expect(updated.stockLabel, '1 cartón de 500 ml + 250 ml');
    expect((await ProductoDao(db).obtenerPorId(2))!.stockActual, 1.0);
    expect(updated.expiryDate, '2030-01-10');
  });
  test('Agotado y por agotarse son estados diferentes', () {
    final empty = Producto.fromMap({'stock_actual': 0, 'stock_minimo': 1})
        .toPreview();
    final low = Producto.fromMap({'stock_actual': 0.5, 'stock_minimo': 1})
        .toPreview();
    expect(empty.status, PantryPreviewStatus.empty);
    expect(empty.hasStock, isFalse);
    expect(low.status, PantryPreviewStatus.lowStock);
    expect(low.hasStock, isTrue);
  });
  test('Una compra a granel cuenta como un artículo en el badge y conserva su peso', () async {
    final db = PurchaseDatabase();
    final inventory = InventarioDB.conDatabase(db, verificarEsquema: true);
    await inventory.database;
    final controller = ShoppingListsPreviewController();
    await controller.cargarDesdeBD();
    final product = (await ProductoDao(db).obtenerPorId(2))!.toPreview();
    await controller.addProduct(product);
    await controller.setItem(
      controller.current.items.single.copyWith(quantity: 0.5),
    );
    expect(controller.current.units, 1);
    expect(controller.current.items.single.quantity, 0.5);
    expect(db.tables['Carrito']!.single['cantidad_a_comprar'], 0.5);
    controller.dispose();
    await inventory.close();
  });
  testWidgets(
    'Los filtros actuales encuentran productos dentro de la lista general',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      PantryProductPreview p(
        String name,
        PantryPreviewStatus status,
        double amount,
      ) => PantryProductPreview(
        name: name,
        category: 'Abarrotes',
        status: status,
        note: '',
        quantity: '$amount kg',
        unit: 'kg',
        totalStock: amount,
        thumbnail: ProductThumbnailKind.placeholder,
      );
      final products = [
        p('Vencido', PantryPreviewStatus.expired, 1),
        p('Poco arroz', PantryPreviewStatus.lowStock, 0.5),
        p('Vacío', PantryPreviewStatus.empty, 0),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            sections: [
              PantrySectionPreview(
                title: 'Productos',
                caption: 'Primero los que caducan antes',
                status: PantryPreviewStatus.healthy,
                products: products,
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Caducados').first);
      await tester.pumpAndSettle();
      expect(find.text('Vencido'), findsOneWidget);
      expect(find.text('Poco arroz'), findsNothing);
      await tester.tap(find.text('Caducados').first);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Por agotarse').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Por agotarse').first);
      await tester.pumpAndSettle();
      expect(find.text('Poco arroz'), findsOneWidget);
      expect(find.text('Vacío'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Por caducar muestra el siguiente lote sin perder la prioridad del caducado',
    (tester) async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      String iso(int days) =>
          today.add(Duration(days: days)).toIso8601String().substring(0, 10);
      final product =
          Producto.fromMap({
                'id': 1,
                'nombre': 'Leche',
                'stock_actual': 2.0,
                'stock_minimo': 0.5,
                'tiene_caducado': 1,
                'tiene_por_caducar': 1,
                'proxima_caducidad': iso(-1),
                'primer_lote_id': 10,
                'cantidad_primer_lote': 1.0,
              })
              .copyWith(
                lotesActivos: [
                  Lote(
                    id: 10,
                    productoId: 1,
                    cantidad: 1,
                    fechaCaducidad: iso(-1),
                  ),
                  Lote(
                    id: 11,
                    productoId: 1,
                    cantidad: 1,
                    fechaCaducidad: iso(1),
                  ),
                  Lote(
                    id: 12,
                    productoId: 1,
                    cantidad: 0,
                    fechaCaducidad: iso(0),
                  ),
                ],
              )
              .toPreview();
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            onInventoryAction: (_) {},
            sections: [
              PantrySectionPreview(
                title: 'Productos',
                caption: '',
                status: PantryPreviewStatus.healthy,
                products: [product],
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      ProductCard card() =>
          tester.widget<ProductCard>(find.byType(ProductCard));
      expect(card().product.lotId, 10);
      expect(card().product.status, PantryPreviewStatus.expired);
      expect(card().onInventoryAction, isNotNull);
      await tester.tap(find.text('Por caducar').first);
      await tester.pumpAndSettle();
      expect(card().product.lotId, 11);
      expect(card().product.status, PantryPreviewStatus.expiring);
      expect(card().product.expiryDate, iso(1));
      expect(find.text('Caduca mañana'), findsOneWidget);
      expect(card().product.availableQuantity, 2);
      expect(card().onInventoryAction, isNull);
      await tester.tap(find.text('Caducados').first);
      await tester.pumpAndSettle();
      expect(card().product.lotId, 10);
      expect(card().onInventoryAction, isNotNull);
      await tester.tap(find.text('Caducados').first);
      await tester.pumpAndSettle();
      expect(card().product.lotId, 10);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Consumir usa la unidad indicada y permite terminar lotes con FEFO',
    (tester) async {
      final db = PurchaseDatabase();
      db.tables['Lote']!.clear();
      await buyMilk(db, count: 1, content: 0.5, expiry: '2030-01-10');
      await buyMilk(db, count: 2, content: 0.5, expiry: '2030-01-20');
      final inventory = InventarioDB.conDatabase(db, verificarEsquema: true);
      await inventory.database;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) => Scaffold(
              body: TextButton(
                onPressed: () => actuarSobrePrimerLote(ctx, 1),
                child: const Text('Consumir'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Consumir'));
      await tester.pumpAndSettle();
      final input = find.byType(TextField);
      expect(tester.widget<TextField>(input).controller!.text, '0.5');
      expect(tester.widget<TextField>(input).decoration!.suffixText, 'L');
      await tester.enterText(input, '0.75');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Registrar consumo'));
      await tester.pumpAndSettle();
      expect(db.tables['Lote']!.first['cantidad'], 0);
      expect(db.tables['Lote']!.last['cantidad'], 0.75);
      expect(
        db.tables['Movimiento_Inventario']!
            .where((r) => r['tipo'] == 'consumo')
            .length,
        3,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await inventory.close();
    },
  );
  testWidgets(
    'Inicio muestra total y envases con etiquetas legibles en el celular',
    (tester) async {
      final db = PurchaseDatabase();
      db.tables['Lote']!.clear();
      await buyMilk(db, count: 2, content: 0.5, expiry: '2030-01-10');
      final product = (await ProductoDao(db).obtenerPorId(1))!.toPreview();
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
                child: ProductCard(
                  product: product,
                  onInventoryAction: () {},
                  onAddToCart: () {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('2 cartones de 500 ml'), findsOneWidget);
        expect(find.text('1 L en total'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    },
  );
}

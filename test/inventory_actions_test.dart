import 'package:flutter/services.dart';

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:gestion_inventario/utils/cantidades.dart';
import 'package:gestion_inventario/models/producto_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_inventario/database/daos/lote_dao.dart';
import 'package:gestion_inventario/presentation/modelos_vista_alacena.dart';
import 'package:gestion_inventario/widgets/miniatura_producto.dart';
import 'package:gestion_inventario/widgets/tarjeta_producto.dart';
import 'package:sqflite/sqflite.dart';

class MemoryTransaction implements Transaction {
  MemoryTransaction(this.lotes);
  final List<Map<String, Object?>> lotes;
  final movimientos = <Map<String, Object?>>[];
  @override
  dynamic noSuchMethod(Invocation invocation) {
    final name = invocation.memberName;
    if (name == #query) {
      final args = invocation.namedArguments[#whereArgs] as List<Object?>;
      final where = invocation.namedArguments[#where] as String;
      final result =
          lotes
              .where(
                (l) =>
                    (where.startsWith('id =') ? l['id'] : l['producto_id']) ==
                        args.first &&
                    (l['cantidad'] as num) > 0,
              )
              .map((l) => Map<String, Object?>.from(l))
              .toList()
            ..sort(
              (a, b) => (a['fecha_caducidad'] as String).compareTo(
                b['fecha_caducidad'] as String,
              ),
            );
      return Future<List<Map<String, Object?>>>.value(result);
    }
    if (name == #update) {
      final id = (invocation.namedArguments[#whereArgs] as List).first;
      final row = lotes.firstWhere((l) => l['id'] == id);
      row.addAll(
        Map<String, Object?>.from(invocation.positionalArguments[1] as Map),
      );
      return Future<int>.value(1);
    }
    if (name == #insert) {
      movimientos.add(
        Map<String, Object?>.from(invocation.positionalArguments[1] as Map),
      );
      return Future<int>.value(movimientos.length);
    }
    return super.noSuchMethod(invocation);
  }
}

class MemoryDatabase implements Database {
  MemoryDatabase(this.txn);
  final MemoryTransaction txn;
  @override
  Future<T> transaction<T>(
    Future<T> Function(Transaction txn) action, {
    bool? exclusive,
  }) async => action(txn);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Map<String, Object?> lot(int id, double cantidad, String fecha) => {
  'id': id,
  'producto_id': 1,
  'cantidad': cantidad,
  'fecha_caducidad': fecha,
};
PantryProductPreview preview(String date) => PantryProductPreview(
  id: 1,
  name: 'Yogur',
  category: 'Lácteos',
  status: PantryPreviewStatus.healthy,
  note: '',
  quantity: '3 pza',
  thumbnail: ProductThumbnailKind.placeholder,
  expiryDate: date,
  lotId: 2,
  lotQuantity: 3,
  price: 25.5,
);

void main() {
  test('Bloquea consumo caducado; desechar permite consumir el siguiente y registra ambos', () async {
    final txn = MemoryTransaction([
      lot(1, 2, '2000-01-01'),
      lot(2, 3, '2999-01-01'),
    ]);
    final dao = LoteDao(MemoryDatabase(txn));
    expect(await dao.descontarStockFEFO(1, 1), isFalse);
    expect(txn.movimientos, isEmpty);
    expect(txn.lotes.first['cantidad'], 2);
    expect(await dao.descartarLote(1), 1);
    expect(txn.movimientos.single['cantidad'], isNull);
    expect(txn.movimientos.single['cantidad_descartada'], 2.0);
    expect(txn.lotes.first['cantidad'], 0);
    expect(await dao.descontarStockFEFO(1, 1.5), isTrue);
    expect(txn.lotes.last['cantidad'], 1.5);
    expect(txn.movimientos.map((m) => m['tipo']), ['desecho', 'consumo']);
    expect(txn.movimientos.last['cantidad'], 1.5);
    expect(txn.movimientos.last['lote_id'], 2);
    expect(txn.movimientos.last['fecha'], isNotEmpty);
  });
  test(
    'Stock insuficiente no descuenta ni registra; consumo sigue FEFO',
    () async {
      final txn = MemoryTransaction([
        lot(1, 1, '2999-01-01'),
        lot(2, 2, '2999-02-01'),
      ]);
      final dao = LoteDao(MemoryDatabase(txn));
      expect(await dao.descontarStockFEFO(1, 4), isFalse);
      expect(txn.lotes.first['cantidad'], 1);
      expect(txn.movimientos, isEmpty);
      expect(await dao.descontarStockFEFO(1, 2), isTrue);
      expect(txn.lotes.first['cantidad'], 0);
      expect(txn.lotes.last['cantidad'], 1);
      expect(txn.movimientos.map((m) => m['cantidad']), [1.0, 1.0]);
    },
  );
  test('Cantidades legibles, entradas limitadas y fracciones conservadas', () {
    expect(formatearCantidad(9.99999994736442e-8), '0');
    expect(formatearCantidad(0.1 + 0.2), '0.3');
    expect(formatearCantidad(2), '2');
    expect(formatearCantidad(1.25), '1.25');
    expect(formatearCantidad(0.001), '0.001');
    expect(leerCantidad('1,25'), 1.25);
    expect(leerCantidad('0.001'), 0.001);
    for (final input in [
      '1e7',
      '9.99999999e-8',
      '1.2345',
      '-1',
      'NaN',
      'Infinity',
      '1000000',
      '0.0001',
    ]) {
      expect(leerCantidad(input), isNull, reason: input);
    }
    final producto = Producto.fromMap({
      'stock_actual': 9.99999994736442e-8,
      'cantidad_primer_lote': 9.99999994736442e-8,
      'primer_lote_id': 1,
      'proxima_caducidad': '2999-01-01',
      'stock_minimo': 0.5,
    });
    expect(producto.estado, EstadoProducto.agotado);
    expect(producto.toPreview().hasStock, isFalse);
    expect(producto.toPreview().minimumStock, 0.5);
  });

  test(
    'Consumos decimales y restos antiguos terminan exactamente en cero',
    () async {
      final txn = MemoryTransaction([lot(1, 0.3, '2999-01-01')]);
      final dao = LoteDao(MemoryDatabase(txn));
      for (var i = 0; i < 3; i++) {
        expect(await dao.descontarStockFEFO(1, 0.1), isTrue);
      }
      expect(txn.lotes.first['cantidad'], 0.0);
      expect(txn.lotes.first['alarma_activa'], 0);
      expect(txn.movimientos.map((m) => m['cantidad']), [0.1, 0.1, 0.1]);
      final antiguo = MemoryTransaction([lot(1, 1.00000009999, '2999-01-01')]);
      expect(
        await LoteDao(MemoryDatabase(antiguo)).descontarStockFEFO(1, 1),
        isTrue,
      );
      expect(antiguo.lotes.first['cantidad'], 0.0);
      expect(await dao.descontarStockFEFO(1, double.nan), isFalse);
      expect(await dao.descontarStockFEFO(1, 1e-8), isFalse);
    },
  );

  testWidgets(
    'Tarjetas adaptables: carrito muestra precio sin acciones; productos muestran lote y acción',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      for (final width in [320.0, 390.0, 600.0]) {
        tester.view.physicalSize = Size(width, 844);
        for (final shopping in [true, false]) {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: ProductCard(
                      product: preview('2000-01-01'),
                      shoppingQuantity: shopping ? '2' : null,
                      onInventoryAction: () {},
                      onAddToCart: () {},
                    ),
                  ),
                ),
              ),
            ),
          );
          expect(find.text('Caducado'), findsOneWidget);
          expect(find.text('Cad: 01/01/2000'), findsOneWidget);
          if (shopping) {
            expect(find.text('\$25.50 / pza'), findsOneWidget);
            expect(find.text('2 pza agregadas'), findsOneWidget);
            expect(find.text('Desechar'), findsNothing);
            expect(find.textContaining('Lote:'), findsNothing);
          } else {
            expect(find.text('Lote: #2'), findsOneWidget);
            expect(find.text('Desechar'), findsOneWidget);
            expect(
              tester.getCenter(find.text('3 pza restantes')).dy,
              closeTo(tester.getCenter(find.text('Desechar')).dy, 1),
            );
            expect(
              tester.getTopLeft(find.text('Caducado')).dx,
              greaterThan(tester.getTopLeft(find.text('Yogur')).dx),
            );
            expect(find.byIcon(Icons.kitchen_outlined), findsOneWidget);
            expect(find.byIcon(Icons.calendar_today_outlined), findsOneWidget);
            expect(
              find.byIcon(Icons.pie_chart_outline_rounded),
              findsOneWidget,
            );
          }
          expect(tester.takeException(), isNull);
        }
      }
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCard(
              product: preview('2999-01-01'),
              onInventoryAction: () {},
            ),
          ),
        ),
      );
      expect(find.text('Consumir'), findsOneWidget);
      expect(find.text('Reordenar'), findsNothing);
    },
  );
  testWidgets('Estado sin existencias y vista de revisión', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(
      double.tryParse(Platform.environment['CARD_PREVIEW_WIDTH'] ?? '') ?? 600,
      640,
    );
    final fontDir = Platform.environment['PREVIEW_FONT_DIR'];
    if (fontDir != null) {
      await tester.runAsync(() async {
        final body = FontLoader('Roboto');
        body.addFont(
          File('$fontDir/Roboto-Regular.ttf')
              .readAsBytes()
              .then((b) => ByteData.sublistView(b)),
        );
        body.addFont(
          File('$fontDir/Roboto-Bold.ttf')
              .readAsBytes()
              .then((b) => ByteData.sublistView(b)),
        );
        await body.load();
        final icons = FontLoader('MaterialIcons');
        icons.addFont(
          File('$fontDir/MaterialIcons-Regular.otf')
              .readAsBytes()
              .then((b) => ByteData.sublistView(b)),
        );
        await icons.load();
      });
    }
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    const captureKey = ValueKey('card-preview');
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(fontFamily: fontDir == null ? null : 'Roboto'),
        home: Scaffold(
          body: RepaintBoundary(
            key: captureKey,
            child: ColoredBox(
              color: const Color(0xFFF0F8F2),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    ProductCard(
                      product: PantryProductPreview(
                        id: 1,
                        name: 'Leche Lala 1 L',
                        category: 'Lácteos',
                        storageZone: 'Nevera',
                        status: PantryPreviewStatus.healthy,
                        note: '',
                        quantity: '1.25 lt',
                        unit: 'lt',
                        thumbnail: ProductThumbnailKind.milk,
                        expiryDate: '2026-10-24',
                        lotId: 1,
                        lotQuantity: 1.25,
                      ),
                      onInventoryAction: () {},
                      onAddToCart: () {},
                    ),
                    const SizedBox(height: 14),
                    ProductCard(
                      product: const PantryProductPreview(
                        id: 2,
                        name: 'Pan multigrano 6 cereales',
                        category: 'Panadería',
                        storageZone: 'Alacena central',
                        status: PantryPreviewStatus.lowStock,
                        note: '',
                        quantity: '0 pza',
                        thumbnail: ProductThumbnailKind.placeholder,
                        lotId: 3,
                        lotQuantity: 9.99999994736442e-8,
                      ),
                      onAddToCart: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Sin existencia'), findsOneWidget);
    expect(find.text('0 pza en stock'), findsOneWidget);
    expect(find.text('Consumir'), findsOneWidget);
    expect(find.textContaining('e-8'), findsNothing);
    expect(tester.takeException(), isNull);
    final output = Platform.environment['CARD_PREVIEW_PATH'];
    if (output != null) {
      await tester.runAsync(() async {
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(captureKey),
        );
        final picture = await boundary.toImage(pixelRatio: 2);
        final bytes = await picture.toByteData(format: ui.ImageByteFormat.png);
        await File(output).writeAsBytes(bytes!.buffer.asUint8List());
        picture.dispose();
      });
    }
  });
}

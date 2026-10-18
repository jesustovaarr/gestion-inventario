import 'package:gestion_inventario/widgets/editor_articulo_compra.dart';
import 'package:gestion_inventario/main.dart';
import 'package:gestion_inventario/screens/pantalla_carrito.dart';
import 'package:gestion_inventario/widgets/tarjeta_movimiento.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_inventario/database/inventario_db.dart';
import 'package:gestion_inventario/database/daos/lote_dao.dart';
import 'package:gestion_inventario/database/daos/producto_dao.dart';
import 'package:gestion_inventario/models/lote_model.dart';
import 'package:gestion_inventario/models/producto_model.dart';
import 'package:gestion_inventario/presentation/controlador_carrito.dart';
import 'package:gestion_inventario/presentation/modelos_vista_alacena.dart';
import 'package:gestion_inventario/screens/formulario_producto.dart';
import 'package:gestion_inventario/widgets/editor_movimiento.dart';
import 'package:sqflite/sqflite.dart';

/// Base de prueba que reproduce una conexión antigua sin zona_almacenamiento.
class EditingDatabase implements Database, Transaction {
  final columns = <String, Set<String>>{
    'Producto': {
      'id',
      'nombre',
      'precio',
      'imagen',
      'unidad_medida',
      'stock_minimo',
      'categoria_id',
      'ultima_tienda_id',
      'codigo',
      'presentacion',
      'contenido_envase',
    },
    'Lote': {
      'id',
      'producto_id',
      'cantidad',
      'fecha_caducidad',
      'alarma_id',
      'alarma_activa',
      'presentacion',
      'contenido_envase',
    },
    'Historial_Compras': {
      'id',
      'producto_id',
      'tienda_id',
      'fecha_compra',
      'cantidad',
      'precio_unitario',
      'compra_id',
      'lote_id',
      'presentacion',
      'numero_envases',
      'contenido_envase',
      'precio_envase_centavos',
    },
    'Carrito': {
      'id',
      'producto_id',
      'cantidad_a_comprar',
      'presentacion',
      'numero_envases',
      'contenido_envase',
      'precio_envase_centavos',
      'fecha_caducidad',
    },
    'Movimiento_Inventario': {
      'id',
      'producto_id',
      'lote_id',
      'tipo',
      'cantidad',
      'cantidad_descartada',
      'fecha',
    },
  };
  final tables = <String, List<Map<String, Object?>>>{
    'Producto': [
      {
        'id': 1,
        'nombre': 'Leche',
        'precio': 25.5,
        'imagen': '',
        'unidad_medida': 'lt',
        'stock_minimo': 1.0,
        'categoria_id': 1,
        'ultima_tienda_id': null,
      },
    ],
    'Lote': [
      {
        'id': 1,
        'producto_id': 1,
        'cantidad': 2.0,
        'fecha_caducidad': '2999-01-01',
        'alarma_activa': 1,
      },
    ],
    'Movimiento_Inventario': [
      {
        'id': 1,
        'producto_id': 1,
        'lote_id': 1,
        'tipo': 'consumo',
        'cantidad': 0.5,
        'fecha': '2026-10-17T10:00:00',
      },
    ],
    'Categoria': [
      {'id': 1, 'nombre': 'Lácteos'},
    ],
    'Tienda': [],
    'Carrito': [],
    'Historial_Compras': [],
    'Compra': [],
  };
  final writes = <String>[];
  int alterations = 0;
  bool open = true;
  @override
  bool get isOpen => open;
  @override
  Future<void> close() async {
    open = false;
  }

  @override
  Future<T> transaction<T>(
    Future<T> Function(Transaction txn) action, {
    bool? exclusive,
  }) async {
    final previous = {
      for (final e in tables.entries)
        e.key: e.value.map((r) => Map<String, Object?>.from(r)).toList(),
    };
    try {
      return await action(this);
    } catch (_) {
      tables
        ..clear()
        ..addAll(previous);
      rethrow;
    }
  }

  List<Map<String, Object?>> _selected(
    String table,
    String? where,
    List<Object?>? args,
  ) {
    return (tables[table] ?? []).where((row) {
      var i = 0;
      for (final clause in (where ?? '').split(' AND ')) {
        final eq = RegExp(r'^(\w+) = \?$').firstMatch(clause);
        final value =
            row[eq?[1]] ??
            (eq?[1] == 'presentacion'
                ? 'granel'
                : eq?[1] == 'contenido_envase'
                ? 1.0
                : null);
        if (eq != null && value != args![i++]) return false;
        if (clause == 'cantidad > 0' && (row['cantidad'] as num) <= 0) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final p = invocation.positionalArguments;
    final n = invocation.namedArguments;
    if (invocation.memberName == #rawQuery) {
      final sql = p[0] as String;
      if (sql.startsWith('PRAGMA table_info(')) {
        final table = sql.substring(18, sql.length - 1);
        return Future<List<Map<String, Object?>>>.value([
          for (final c in columns[table] ?? <String>{}) {'name': c},
        ]);
      }
      if (sql.startsWith('PRAGMA index_list(')) {
        return Future<List<Map<String, Object?>>>.value([]);
      }
      if (sql.contains('FROM Tienda')) {
        return Future<List<Map<String, Object?>>>.value([]);
      }
      if (sql.contains('FROM Carrito')) {
        final product = tables['Producto']!.single;
        return Future<List<Map<String, Object?>>>.value([
          for (final row in tables['Carrito']!)
            {
              ...row,
              'producto_nombre': product['nombre'],
              'unidad_medida': product['unidad_medida'],
              'stock_actual': 2.0,
              'stock_minimo': 1.0,
            },
        ]);
      }
      if (sql.contains('FROM Producto p')) {
        final product = Map<String, Object?>.from(tables['Producto']!.single);
        final lots =
            tables['Lote']!.where((l) => (l['cantidad'] as num) > 0).toList()
              ..sort(
                (a, b) => (a['fecha_caducidad'] as String).compareTo(
                  b['fecha_caducidad'] as String,
                ),
              );
        product.addAll({
          'categoria_nombre': 'Lácteos',
          'stock_actual': lots.fold<double>(
            0,
            (s, l) => s + (l['cantidad'] as num).toDouble(),
          ),
          'proxima_caducidad': lots.firstOrNull?['fecha_caducidad'],
          'primer_lote_id': lots.firstOrNull?['id'],
          'cantidad_primer_lote': lots.firstOrNull?['cantidad'],
        });
        return Future<List<Map<String, Object?>>>.value([product]);
      }
    }
    if (invocation.memberName == #execute) {
      final sql = p[0] as String;
      final alter = RegExp(r'ALTER TABLE (\w+) ADD COLUMN (\w+)')
          .firstMatch(sql);
      if (alter != null) {
        if (!columns[alter[1]]!.add(alter[2]!)) {
          throw StateError('duplicate column');
        }
        alterations++;
      }
      return Future<void>.value();
    }
    if (invocation.memberName == #query) {
      return Future<List<Map<String, Object?>>>.value(
        _selected(
          p[0] as String,
          n[#where] as String?,
          n[#whereArgs] as List<Object?>?,
        ).map((r) => Map<String, Object?>.from(r)).toList(),
      );
    }
    if (invocation.memberName == #update) {
      final table = p[0] as String;
      final values = Map<String, Object?>.from(p[1] as Map);
      for (final key in values.keys) {
        if (columns.containsKey(table) && !columns[table]!.contains(key)) {
          throw StateError('no such column: $key');
        }
      }
      final selected = _selected(
        table,
        n[#where] as String?,
        n[#whereArgs] as List<Object?>?,
      );
      for (final row in selected) {
        row.addAll(values);
      }
      writes.add(table);
      return Future<int>.value(selected.length);
    }
    if (invocation.memberName == #delete) {
      final table = p[0] as String;
      final selected = _selected(
        table,
        n[#where] as String?,
        n[#whereArgs] as List<Object?>?,
      );
      tables[table]!.removeWhere(selected.contains);
      writes.add(table);
      return Future<int>.value(selected.length);
    }
    if (invocation.memberName == #insert) {
      final table = p[0] as String;
      final rows = tables.putIfAbsent(table, () => []);
      final id =
          rows.fold<int>(
            0,
            (n, r) => (r['id'] as int? ?? 0) > n ? r['id'] as int : n,
          ) +
          1;
      rows.add({...Map<String, Object?>.from(p[1] as Map), 'id': id});
      writes.add(table);
      return Future<int>.value(id);
    }
    return super.noSuchMethod(invocation);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'Repara la conexión abierta y es idempotente; guardar no pierde datos',
    () async {
      final db = EditingDatabase();
      final inventario = InventarioDB.conDatabase(db, verificarEsquema: true);
      expect(await inventario.database, same(db));
      expect(db.columns['Producto'], contains('zona_almacenamiento'));
      expect(db.columns['Lote'], contains('hora_aviso'));
      final count = db.alterations;
      await InventarioDB.asegurarEsquema(db);
      expect(db.alterations, count);
      expect(db.tables['Lote']!.single['cantidad'], 2);
      await ProductoDao(db).guardarConLotes(
        const Producto(
          id: 1,
          nombre: 'Leche editada',
          precio: 38,
          imagen: '/foto.jpg',
          zonaAlmacenamiento: 'Nevera',
          unidadMedida: 'lt',
          stockMinimo: 0.5,
          categoriaId: 1,
        ),
        const [
          Lote(
            id: 1,
            productoId: 1,
            cantidad: 1.25,
            fechaCaducidad: '2999-02-01',
            alarmaActiva: 0,
            horaAviso: '15:30',
          ),
        ],
      );
      expect(db.tables['Producto']!.single['nombre'], 'Leche editada');
      expect(db.tables['Producto']!.single['imagen'], '/foto.jpg');
      expect(db.tables['Lote']!.single['cantidad'], 1.25);
      expect(db.tables['Lote']!.single['fecha_caducidad'], '2999-02-01');
      expect(db.tables['Lote']!.single['hora_aviso'], '15:30');
      await inventario.close();
    },
  );
  for (final tipo in ['consumo', 'desecho']) {
    test('Editar y borrar $tipo modifica solo el historial', () async {
      final db = EditingDatabase();
      db.tables['Movimiento_Inventario']!.single['tipo'] = tipo;
      db.tables['Lote']!.single['cantidad'] = 0.0;
      final lotBefore = Map<String, Object?>.from(db.tables['Lote']!.single);
      final productBefore = Map<String, Object?>.from(
        db.tables['Producto']!.single,
      );
      final dao = LoteDao(db);
      await dao.editarMovimiento(
        1,
        tipo: tipo,
        cantidad: 9.25,
        fecha: DateTime(2026, 10, 16, 12, 30),
      );
      expect(
        db.tables['Movimiento_Inventario']!.single['cantidad'],
        tipo == 'consumo' ? 9.25 : isNull,
      );
      expect(db.tables['Lote']!.single, lotBefore);
      expect(db.tables['Producto']!.single, productBefore);
      await dao.eliminarMovimiento(1);
      expect(db.tables['Movimiento_Inventario'], isEmpty);
      expect(db.tables['Lote']!.single, lotBefore);
      expect(db.tables['Producto']!.single, productBefore);
      expect(db.writes, everyElement('Movimiento_Inventario'));
    });
  }
  testWidgets(
    'Editar producto carga lotes y guarda cantidad y nombre desde el formulario',
    (tester) async {
      final db = EditingDatabase();
      final inventario = InventarioDB.conDatabase(db, verificarEsquema: true);
      await inventario.database;
      final controller = ShoppingListsPreviewController();
      final product = (await ProductoDao(db).obtenerPorId(1))!.toPreview();
      await tester.pumpWidget(
        ShoppingListsPreviewScope(
          controller: controller,
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: FilledButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ProductFormScreen(product: product),
                    ),
                  ),
                  child: const Text('Abrir'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      final name = find.byWidgetPredicate(
        (w) => w is TextFormField && w.controller?.text == 'Leche',
      );
      await tester.scrollUntilVisible(
        name,
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.enterText(name, 'Leche nueva');
      await tester.scrollUntilVisible(
        find.text('Lotes y existencias'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      final qty = find.byWidgetPredicate(
        (w) =>
            w is TextField && w.decoration?.labelText == 'Cantidad disponible',
      );
      await tester.scrollUntilVisible(
        qty,
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.enterText(qty, '1,25');
      await tester.pump();
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Consumo registrado'),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Consumo registrado'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Consumo registrado'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String>).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Desecho').last);
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(MovementEditorDialog),
          matching: find.byType(TextField),
        ),
        findsNothing,
      );
      expect(find.text('Producto completo'), findsOneWidget);
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      expect(db.tables['Movimiento_Inventario']!.single['tipo'], 'desecho');
      expect(db.tables['Movimiento_Inventario']!.single['cantidad'], isNull);
      expect(db.tables['Lote']!.single['cantidad'], 2.0);

      await tester.scrollUntilVisible(
        find.text('Guardar cambios'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Guardar cambios'));
      await tester.pumpAndSettle();
      expect(db.tables['Producto']!.single['nombre'], 'Leche nueva');
      expect(db.tables['Lote']!.single['cantidad'], 1.25);
      expect(find.text('Abrir'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
      await inventario.close();
    },
  );
  for (final packaging in ['botella', 'bolsa', 'granel']) {
    testWidgets('El mínimo se captura por $packaging y conserva las alertas', (
      tester,
    ) async {
      final db = EditingDatabase();
      db.tables['Producto']!.single.addAll({
        'presentacion': packaging,
        'contenido_envase': 0.5,
        'stock_minimo': 1.0,
      });
      final inventario = InventarioDB.conDatabase(db, verificarEsquema: true);
      await inventario.database;
      final product = (await ProductoDao(db).obtenerPorId(1))!.toPreview();
      await tester.pumpWidget(
        MaterialApp(
          home: ProductFormScreen(product: product, catalogOnly: true),
        ),
      );
      await tester.pumpAndSettle();
      final minimum = find.byKey(const ValueKey('quantity-stock mínimo'));
      await tester.scrollUntilVisible(
        minimum,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await Scrollable.ensureVisible(tester.element(minimum), alignment: 0.3);
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(minimum).controller!.text,
        packaging == 'granel' ? '1' : '2',
      );
      expect(
        find.textContaining(
          packaging == 'granel'
              ? 'para productos a granel'
              : 'Expresado en ${packaging == 'botella' ? 'botellas' : 'bolsas'} de 500 ml',
        ),
        findsOneWidget,
      );
      await tester.enterText(minimum, '3');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Guardar cambios'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Guardar cambios'));
      await tester.pumpAndSettle();
      final saved = (await ProductoDao(db).obtenerPorId(1))!;
      expect(saved.stockMinimo, packaging == 'granel' ? 3 : 1.5);
      expect(
        saved.estado,
        packaging == 'granel'
            ? EstadoProducto.porAgotarse
            : EstadoProducto.enOrden,
      );
      db.tables['Lote']!.single['cantidad'] = 1.0;
      expect(
        (await ProductoDao(db).obtenerPorId(1))!.estado,
        EstadoProducto.porAgotarse,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await inventario.close();
    });
  }
  testWidgets(
    'El editor de movimientos entrega solo las propiedades del registro',
    (tester) async {
      MovementEdit? change;
      final row = EditingDatabase().tables['Movimiento_Inventario']!.single;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: FilledButton(
                onPressed: () async {
                  change = await showDialog<MovementEdit>(
                    context: context,
                    builder: (_) =>
                        MovementEditorDialog(movimiento: row, unit: 'lt'),
                  );
                },
                child: const Text('Editar'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Editar'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '2,5');
      await tester.pump();
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      expect(change!.cantidad, 2.5);
      expect(change!.tipo, 'consumo');
      expect(row['cantidad'], 0.5);
    },
  );
  testWidgets('Tocar el registro edita; deslizar descubre Borrar', (
    tester,
  ) async {
    var edits = 0;
    var deletes = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MovementHistoryCard(
            movimiento:
                EditingDatabase().tables['Movimiento_Inventario']!.single,
            unit: 'lt',
            onTap: () => edits++,
            onDelete: () => deletes++,
          ),
        ),
      ),
    );
    expect(find.text('Editar'), findsNothing);
    expect(find.text('Eliminar'), findsNothing);
    await tester.tap(find.text('Consumo registrado'));
    await tester.pumpAndSettle();
    expect(edits, 1);
    await tester.drag(find.byType(MovementHistoryCard), const Offset(-300, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Borrar'));
    await tester.pumpAndSettle();
    expect(deletes, 1);
  });
  testWidgets('Tocar un producto en Inicio abre la edición directamente', (
    tester,
  ) async {
    final db = EditingDatabase();
    final inventario = InventarioDB.conDatabase(db, verificarEsquema: true);
    await inventario.database;
    await tester.pumpWidget(const AlacenaPreviewApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Leche'));
    await tester.pumpAndSettle();
    expect(find.text('Editar artículo'), findsOneWidget);
    expect(find.text('Detalle del producto'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await inventario.close();
  });
  testWidgets('Tocar un producto del carrito edita los datos de la compra', (
    tester,
  ) async {
    final db = EditingDatabase();
    final inventario = InventarioDB.conDatabase(db, verificarEsquema: true);
    await inventario.database;
    final controller = ShoppingListsPreviewController();
    final product = (await ProductoDao(db).obtenerPorId(1))!.toPreview();
    await controller.addProduct(product);
    await tester.pumpWidget(
      ShoppingListsPreviewScope(
        controller: controller,
        child: const MaterialApp(home: CartScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Leche'));
    await tester.pumpAndSettle();
    expect(find.byType(PurchaseArticleEditor), findsOneWidget);
    expect(find.text('Cantidad a comprar'), findsOneWidget);
    expect(find.text('Detalle del producto'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
    await inventario.close();
  });
  testWidgets(
    'Cambiar consumo a desecho registra producto completo sin cantidades parciales',
    (tester) async {
      final db = EditingDatabase();
      MovementEdit? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: FilledButton(
                onPressed: () async {
                  result = await showDialog<MovementEdit>(
                    context: context,
                    builder: (_) => MovementEditorDialog(
                      movimiento: db.tables['Movimiento_Inventario']!.single,
                      unit: 'ml',
                    ),
                  );
                },
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '0,2');
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Desecho').last);
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Producto completo'), findsOneWidget);
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      expect(result!.tipo, 'desecho');
      expect(result!.cantidad, isNull);
      await LoteDao(db).editarMovimiento(
        1,
        tipo: result!.tipo,
        cantidad: result!.cantidad,
        fecha: result!.fecha,
      );
      expect(db.tables['Movimiento_Inventario']!.single['cantidad'], isNull);
      expect(db.tables['Lote']!.single['cantidad'], 2.0);
    },
  );
}

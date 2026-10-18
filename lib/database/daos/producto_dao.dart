import 'package:sqflite/sqflite.dart';

import '../../models/producto_model.dart';
import '../../models/lote_model.dart';
import '../../utils/cantidades.dart';
import '../../utils/presentaciones.dart';
import '../inventario_db.dart';

class ProductoDao {
  final Database? _database;

  ProductoDao([this._database]);

  Future<Database> get _db async => _database ?? await InventarioDB().database;

  Future<List<Producto>> obtenerConStock() async {
    final db = await _db;
    final res = await db.rawQuery('''
      SELECT
        p.*,
        (SELECT fecha_caducidad FROM Lote WHERE producto_id = p.id AND cantidad > 0 ORDER BY fecha_caducidad, id LIMIT 1) AS proxima_caducidad,
        (SELECT id FROM Lote WHERE producto_id = p.id AND cantidad > 0 ORDER BY fecha_caducidad, id LIMIT 1) AS primer_lote_id,
        (SELECT cantidad FROM Lote WHERE producto_id = p.id AND cantidad > 0 ORDER BY fecha_caducidad, id LIMIT 1) AS cantidad_primer_lote,
        c.nombre AS categoria_nombre,
        t.nombre AS ultima_tienda_nombre,
        COALESCE(SUM(l.cantidad), 0.0) AS stock_actual,
        MAX(CASE
          WHEN l.cantidad > 0 AND date(l.fecha_caducidad) < date('now', 'localtime') THEN 1
          ELSE 0
        END) AS tiene_caducado,
        MAX(CASE
          WHEN l.cantidad > 0
               AND date(l.fecha_caducidad) >= date('now', 'localtime')
               AND date(l.fecha_caducidad) <= date('now', 'localtime', '+3 days') THEN 1
          ELSE 0
        END) AS tiene_por_caducar
      FROM Producto p
      LEFT JOIN Categoria c ON p.categoria_id = c.id
      LEFT JOIN Tienda t ON p.ultima_tienda_id = t.id
      LEFT JOIN Lote l ON p.id = l.producto_id AND l.cantidad > 0
      GROUP BY p.id
      ORDER BY proxima_caducidad IS NULL, proxima_caducidad ASC, p.nombre ASC;
    ''');
    return _conLotes(res);
  }

  Future<Producto?> obtenerPorId(int id) async {
    final db = await _db;
    final res = await db.rawQuery(
      '''
      SELECT
        p.*,
        (SELECT fecha_caducidad FROM Lote WHERE producto_id = p.id AND cantidad > 0 ORDER BY fecha_caducidad, id LIMIT 1) AS proxima_caducidad,
        (SELECT id FROM Lote WHERE producto_id = p.id AND cantidad > 0 ORDER BY fecha_caducidad, id LIMIT 1) AS primer_lote_id,
        (SELECT cantidad FROM Lote WHERE producto_id = p.id AND cantidad > 0 ORDER BY fecha_caducidad, id LIMIT 1) AS cantidad_primer_lote,
        c.nombre AS categoria_nombre,
        t.nombre AS ultima_tienda_nombre,
        COALESCE(SUM(l.cantidad), 0.0) AS stock_actual,
        MAX(CASE
          WHEN l.cantidad > 0 AND date(l.fecha_caducidad) < date('now', 'localtime') THEN 1
          ELSE 0
        END) AS tiene_caducado,
        MAX(CASE
          WHEN l.cantidad > 0
               AND date(l.fecha_caducidad) >= date('now', 'localtime')
               AND date(l.fecha_caducidad) <= date('now', 'localtime', '+3 days') THEN 1
          ELSE 0
        END) AS tiene_por_caducar
      FROM Producto p
      LEFT JOIN Categoria c ON p.categoria_id = c.id
      LEFT JOIN Tienda t ON p.ultima_tienda_id = t.id
      LEFT JOIN Lote l ON p.id = l.producto_id AND l.cantidad > 0
      WHERE p.id = ?
      GROUP BY p.id;
    ''',
      [id],
    );
    if (res.isEmpty) return null;
    return (await _conLotes(res, productoId: id)).first;
  }

  Future<List<Producto>> _conLotes(
    List<Map<String, Object?>> rows, {
    int? productoId,
  }) async {
    if (rows.isEmpty) return [];
    final db = await _db;
    final lotes = await db.query(
      'Lote',
      where: productoId == null
          ? 'cantidad > 0'
          : 'producto_id = ? AND cantidad > 0',
      whereArgs: productoId == null ? null : [productoId],
      orderBy: 'fecha_caducidad ASC, id ASC',
    );
    final porProducto = <int, List<Lote>>{};
    for (final row in lotes) {
      final lote = Lote.fromMap(row);
      porProducto.putIfAbsent(lote.productoId, () => []).add(lote);
    }
    for (final lotes in porProducto.values) {
      lotes.sort((a, b) {
        final orden = a.fechaCaducidad.compareTo(b.fechaCaducidad);
        return orden != 0 ? orden : (a.id ?? 0).compareTo(b.id ?? 0);
      });
    }
    return rows.map((row) {
      final producto = Producto.fromMap(row);
      return producto.copyWith(lotesActivos: porProducto[producto.id] ?? []);
    }).toList();
  }

  Future<int> insertar(Producto producto) async {
    final db = await _db;
    return await db.insert('Producto', producto.toMap());
  }

  Future<Producto?> obtenerPorCodigo(String codigo) async {
    final db = await _db;
    final rows = await db.query(
      'Producto',
      where: 'codigo = ?',
      whereArgs: [codigo.trim()],
    );
    if (rows.isEmpty) return null;
    return obtenerPorId(rows.first['id'] as int);
  }

  Future<void> asignarCodigo(int productoId, String codigo) async {
    final db = await _db;
    await db.update(
      'Producto',
      {'codigo': codigo.trim()},
      where: 'id = ?',
      whereArgs: [productoId],
    );
  }

  Future<int> actualizar(Producto producto) async {
    final db = await _db;
    return await db.update(
      'Producto',
      producto.toMap(),
      where: 'id = ?',
      whereArgs: [producto.id],
    );
  }

  Future<void> guardarConLotes(Producto producto, List<Lote> lotes) async {
    final db = await _db;
    await db.transaction((txn) async {
      final anteriores = await txn.query(
        'Producto',
        where: 'id = ?',
        whereArgs: [producto.id],
      );
      if (anteriores.isEmpty) throw StateError('No se encontró el producto.');
      final anterior = Producto.fromMap(anteriores.single);
      final cambios = await txn.update(
        'Producto',
        producto.toMap(),
        where: 'id = ?',
        whereArgs: [producto.id],
      );
      if (cambios != 1) throw StateError('No se encontró el producto.');
      // Si se corrige el tamaño del catálogo, el carrito conserva el número de envases.
      if (anterior.presentacion != producto.presentacion ||
          anterior.contenidoEnvase != producto.contenidoEnvase ||
          anterior.unidadMedida != producto.unidadMedida) {
        final envase = PresentacionCompra.leer(producto.presentacion).esEnvase;
        final carrito = await txn.query(
          'Carrito',
          where: 'producto_id = ?',
          whereArgs: [producto.id],
        );
        for (final item in carrito) {
          final cantidad = envase
              ? normalizarCantidad(
                  ((item['numero_envases'] as num?) ?? 1) *
                      producto.contenidoEnvase,
                )
              : (item['cantidad_a_comprar'] as num).toDouble();
          if (!cantidadValida(cantidad)) {
            throw ArgumentError('Revisa la cantidad del carrito.');
          }
          await txn.update(
            'Carrito',
            {
              'presentacion': producto.presentacion,
              'contenido_envase': producto.contenidoEnvase,
              'cantidad_a_comprar': cantidad,
            },
            where: 'id = ?',
            whereArgs: [item['id']],
          );
        }
      }
      for (final lote in lotes) {
        if (lote.productoId != producto.id ||
            !cantidadValida(lote.cantidad, permiteCero: true) ||
            !cantidadValida(lote.contenidoEnvase) ||
            DateTime.tryParse(lote.fechaCaducidad) == null) {
          throw ArgumentError('Revisa la cantidad y fecha de los lotes.');
        }
        final datos = {
          ...lote.toMap(),
          'cantidad': normalizarCantidad(lote.cantidad),
        };
        if (lote.cantidad == 0) datos['alarma_activa'] = 0;
        if (lote.id == null) {
          await txn.insert('Lote', datos);
        } else {
          final changed = await txn.update(
            'Lote',
            datos,
            where: 'id = ? AND producto_id = ?',
            whereArgs: [lote.id, producto.id],
          );
          if (changed != 1) {
            throw StateError('No se encontró uno de los lotes.');
          }
        }
      }
    });
  }

  Future<int> eliminar(int idProducto) async {
    final db = await _db;
    return await db.delete(
      'Producto',
      where: 'id = ?',
      whereArgs: [idProducto],
    );
  }
}

import 'package:sqflite/sqflite.dart';

import '../../models/carrito_model.dart';
import '../../utils/cantidades.dart';
import '../inventario_db.dart';

class CarritoDao {
  final Database? _database;

  CarritoDao([this._database]);

  Future<Database> get _db async => _database ?? await InventarioDB().database;

  Future<void> guardarArticulo(CarritoItem item) async {
    if (!cantidadValida(item.cantidadAComprar) ||
        !cantidadValida(item.contenidoEnvase) ||
        item.numeroEnvases < 1 ||
        item.numeroEnvases > 999999 ||
        (item.presentacion.esEnvase &&
            normalizarCantidad(item.numeroEnvases * item.contenidoEnvase) !=
                item.cantidadAComprar)) {
      throw ArgumentError('Cantidad inválida');
    }
    final db = await _db;
    await db.transaction((txn) async {
      final existentes = await txn.query(
        'Carrito',
        where: 'producto_id = ?',
        whereArgs: [item.productoId],
      );
      final existente = existentes.isEmpty
          ? null
          : CarritoItem.fromMap(existentes.first);
      if (existente == null) {
        await txn.insert('Carrito', item.toMap());
      } else {
        await txn.update(
          'Carrito',
          item.toMap(),
          where: 'id = ?',
          whereArgs: [existente.id],
        );
      }
    });
  }

  Future<int> eliminarArticulo(CarritoItem item) async {
    final db = await _db;
    return db.delete(
      'Carrito',
      where: 'producto_id = ?',
      whereArgs: [item.productoId],
    );
  }

  // Vacía la lista de compras
  Future<int> vaciar() async {
    final db = await _db;
    return await db.delete('Carrito');
  }

  // Obtiene los elementos del carrito con detalles del producto y stock
  Future<List<CarritoItem>> obtenerItems() async {
    final db = await _db;
    final res = await db.rawQuery('''
      SELECT 
        c.*,
        p.nombre AS producto_nombre,
        p.unidad_medida AS unidad_medida,
        p.imagen AS imagen,
        p.stock_minimo AS stock_minimo,
        COALESCE((SELECT SUM(l.cantidad) FROM Lote l WHERE l.producto_id = p.id AND l.cantidad > 0), 0.0) AS stock_actual
      FROM Carrito c
      INNER JOIN Producto p ON c.producto_id = p.id
      ORDER BY p.nombre ASC;
    ''');
    return res.map((m) => CarritoItem.fromMap(m)).toList();
  }
}

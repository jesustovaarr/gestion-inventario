import 'package:sqflite/sqflite.dart';
import '../../models/carrito_model.dart';
import '../inventario_db.dart';

class CarritoDao {
  final Database? _database;

  CarritoDao([this._database]);

  Future<Database> get _db async => _database ?? await InventarioDB().database;

  // Agrega un producto a la lista de compras o incrementa su cantidad si ya existe
  Future<int> agregarOIncrementar(int productoId, {double cantidad = 1.0}) async {
    final db = await _db;
    final itemExistente = await db.query(
      'Carrito',
      where: 'producto_id = ?',
      whereArgs: [productoId],
    );

    if (itemExistente.isNotEmpty) {
      final actual = (itemExistente.first['cantidad_a_comprar'] as num).toDouble();
      return await db.update(
        'Carrito',
        {'cantidad_a_comprar': actual + cantidad},
        where: 'producto_id = ?',
        whereArgs: [productoId],
      );
    } else {
      return await db.insert('Carrito', {
        'producto_id': productoId,
        'cantidad_a_comprar': cantidad,
      });
    }
  }

  // Actualiza la cantidad de un artículo. Si la cantidad es <= 0, lo elimina
  Future<int> actualizarCantidad(int productoId, double nuevaCantidad) async {
    final db = await _db;
    if (nuevaCantidad <= 0) {
      return await eliminar(productoId);
    }
    return await db.update(
      'Carrito',
      {'cantidad_a_comprar': nuevaCantidad},
      where: 'producto_id = ?',
      whereArgs: [productoId],
    );
  }

  Future<int> eliminar(int productoId) async {
    final db = await _db;
    return await db.delete('Carrito', where: 'producto_id = ?', whereArgs: [productoId]);
  }

  // Vacía la lista de compras
  Future<int> vaciar() async {
    final db = await _db;
    return await db.delete('Carrito');
  }

  // Conteo de unidades totales en el carrito para el badge
  Future<int> contar() async {
    final db = await _db;
    final res = await db.rawQuery('SELECT COALESCE(SUM(cantidad_a_comprar), 0) as total FROM Carrito');
    if (res.isNotEmpty && res.first['total'] != null) {
      return (res.first['total'] as num).round();
    }
    return 0;
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

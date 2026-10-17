import 'package:sqflite/sqflite.dart';
import '../../models/producto_model.dart';
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
        c.nombre AS categoria_nombre,
        t.nombre AS ultima_tienda_nombre,
        COALESCE(SUM(l.cantidad), 0.0) AS stock_actual,
        MAX(CASE 
          WHEN l.cantidad > 0 AND date(l.fecha_caducidad) < date('now') THEN 1 
          ELSE 0 
        END) AS tiene_caducado,
        MAX(CASE 
          WHEN l.cantidad > 0 
               AND date(l.fecha_caducidad) >= date('now') 
               AND date(l.fecha_caducidad) <= date('now', '+3 days') THEN 1 
          ELSE 0 
        END) AS tiene_por_caducar
      FROM Producto p
      LEFT JOIN Categoria c ON p.categoria_id = c.id
      LEFT JOIN Tienda t ON p.ultima_tienda_id = t.id
      LEFT JOIN Lote l ON p.id = l.producto_id AND l.cantidad > 0
      GROUP BY p.id
      ORDER BY p.nombre ASC;
    ''');
    return res.map((m) => Producto.fromMap(m)).toList();
  }

  Future<Producto?> obtenerPorId(int id) async {
    final db = await _db;
    final res = await db.rawQuery('''
      SELECT 
        p.*,
        c.nombre AS categoria_nombre,
        t.nombre AS ultima_tienda_nombre,
        COALESCE(SUM(l.cantidad), 0.0) AS stock_actual,
        MAX(CASE 
          WHEN l.cantidad > 0 AND date(l.fecha_caducidad) < date('now') THEN 1 
          ELSE 0 
        END) AS tiene_caducado,
        MAX(CASE 
          WHEN l.cantidad > 0 
               AND date(l.fecha_caducidad) >= date('now') 
               AND date(l.fecha_caducidad) <= date('now', '+3 days') THEN 1 
          ELSE 0 
        END) AS tiene_por_caducar
      FROM Producto p
      LEFT JOIN Categoria c ON p.categoria_id = c.id
      LEFT JOIN Tienda t ON p.ultima_tienda_id = t.id
      LEFT JOIN Lote l ON p.id = l.producto_id AND l.cantidad > 0
      WHERE p.id = ?
      GROUP BY p.id;
    ''', [id]);
    if (res.isEmpty) return null;
    return Producto.fromMap(res.first);
  }

  Future<int> insertar(Producto producto) async {
    final db = await _db;
    return await db.insert('Producto', producto.toMap());
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

  Future<int> eliminar(int idProducto) async {
    final db = await _db;
    return await db.delete('Producto', where: 'id = ?', whereArgs: [idProducto]);
  }
}

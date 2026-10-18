import 'package:sqflite/sqflite.dart';

import '../../models/tienda_model.dart';
import '../inventario_db.dart';

class TiendaDao {
  final Database? _database;

  TiendaDao([this._database]);

  Future<Database> get _db async => _database ?? await InventarioDB().database;

  // Tiendas con su tipo y el conteo de compras
  Future<List<Tienda>> obtenerTodas() async {
    final db = await _db;
    final res = await db.rawQuery('''
      SELECT 
        t.id,
        t.nombre,
        t.ubicacion,
        t.tipo_tienda_id,
        tt.nombre AS tipo_tienda_nombre,
        COUNT(DISTINCT COALESCE('compra_' || hc.compra_id, 'articulo_' || hc.id)) AS total_compras
      FROM Tienda t
      LEFT JOIN Tipo_Tienda tt ON t.tipo_tienda_id = tt.id
      LEFT JOIN Historial_Compras hc ON t.id = hc.tienda_id
      GROUP BY t.id
      ORDER BY t.nombre ASC;
    ''');
    return res.map((m) => Tienda.fromMap(m)).toList();
  }

  Future<Tienda?> obtenerPorId(int id) async {
    final db = await _db;
    final res = await db.rawQuery(
      '''
      SELECT 
        t.id,
        t.nombre,
        t.ubicacion,
        t.tipo_tienda_id,
        tt.nombre AS tipo_tienda_nombre,
        COUNT(DISTINCT COALESCE('compra_' || hc.compra_id, 'articulo_' || hc.id)) AS total_compras
      FROM Tienda t
      LEFT JOIN Tipo_Tienda tt ON t.tipo_tienda_id = tt.id
      LEFT JOIN Historial_Compras hc ON t.id = hc.tienda_id
      WHERE t.id = ?
      GROUP BY t.id;
    ''',
      [id],
    );
    if (res.isEmpty) return null;
    return Tienda.fromMap(res.first);
  }

  Future<int> insertar(Tienda tienda) async {
    final db = await _db;
    return await db.insert('Tienda', tienda.toMap());
  }

  Future<int> actualizar(Tienda tienda) async {
    final db = await _db;
    return await db.update(
      'Tienda',
      tienda.toMap(),
      where: 'id = ?',
      whereArgs: [tienda.id],
    );
  }

  // Verifica si una tienda tiene compras registradas
  Future<bool> tieneCompras(int idTienda) async {
    final db = await _db;
    final res = await db.rawQuery(
      'SELECT COUNT(*) as total FROM Historial_Compras WHERE tienda_id = ?',
      [idTienda],
    );
    final count = Sqflite.firstIntValue(res) ?? 0;
    return count > 0;
  }

  // Eliminar tienda y limpiar compras vinculadas
  Future<int> eliminar(int idTienda) async {
    final db = await _db;
    return await db.transaction<int>((txn) async {
      await txn.delete(
        'Historial_Compras',
        where: 'tienda_id = ?',
        whereArgs: [idTienda],
      );
      await txn.delete('Compra', where: 'tienda_id = ?', whereArgs: [idTienda]);
      await txn.update(
        'Producto',
        {'ultima_tienda_id': null},
        where: 'ultima_tienda_id = ?',
        whereArgs: [idTienda],
      );
      return await txn.delete('Tienda', where: 'id = ?', whereArgs: [idTienda]);
    });
  }
}

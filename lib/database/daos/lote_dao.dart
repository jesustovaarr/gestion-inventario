import 'package:sqflite/sqflite.dart';
import '../../models/lote_model.dart';
import '../inventario_db.dart';

class LoteDao {
  final Database? _database;

  LoteDao([this._database]);

  Future<Database> get _db async => _database ?? await InventarioDB().database;

  // Algoritmo FEFO
  // Descuenta stock en cascada a partir del lote activo con la fecha de caducidad mas proxima
  Future<bool> descontarStockFEFO(int productoId, double cantidadADescontar) async {
    if (cantidadADescontar <= 0) return false;
    final db = await _db;

    return await db.transaction<bool>((txn) async {
      final lotes = await txn.query(
        'Lote',
        where: 'producto_id = ? AND cantidad > 0',
        whereArgs: [productoId],
        orderBy: 'fecha_caducidad ASC, id ASC',
      );

      double pendiente = cantidadADescontar;

      for (var row in lotes) {
        if (pendiente <= 0) break;

        final int idLote = row['id'] as int;
        final double cantidadLote = (row['cantidad'] as num).toDouble();

        if (cantidadLote <= pendiente) {
          // Lote consumido en su totalidad
          pendiente -= cantidadLote;
          await txn.update(
            'Lote',
            {'cantidad': 0.0, 'alarma_activa': 0},
            where: 'id = ?',
            whereArgs: [idLote],
          );
        } else {
          // Lote consumido parcialmente
          final nuevaCantidad = cantidadLote - pendiente;
          pendiente = 0;
          await txn.update(
            'Lote',
            {'cantidad': nuevaCantidad},
            where: 'id = ?',
            whereArgs: [idLote],
          );
        }
      }

      return pendiente == 0;
    });
  }

  // Lotes activos de un producto
  Future<List<Lote>> obtenerLotesActivosPorProducto(int productoId) async {
    final db = await _db;
    final res = await db.query(
      'Lote',
      where: 'producto_id = ? AND cantidad > 0',
      whereArgs: [productoId],
      orderBy: 'fecha_caducidad ASC, id ASC',
    );
    return res.map((m) => Lote.fromMap(m)).toList();
  }

  // Lotes activos de una fecha específica
  Future<List<Lote>> obtenerLotesPorFecha(String fechaIso) async {
    final db = await _db;
    final res = await db.rawQuery('''
      SELECT 
        l.*,
        p.nombre AS producto_nombre,
        p.unidad_medida AS unidad
      FROM Lote l
      INNER JOIN Producto p ON l.producto_id = p.id
      WHERE l.cantidad > 0 AND l.fecha_caducidad = ?
      ORDER BY p.nombre ASC;
    ''', [fechaIso]);
    return res.map((m) => Lote.fromMap(m)).toList();
  }

  // Consulta todos los lotes activos
  Future<List<Lote>> obtenerTodosLotesActivos() async {
    final db = await _db;
    final res = await db.rawQuery('''
      SELECT 
        l.*,
        p.nombre AS producto_nombre,
        p.unidad_medida AS unidad
      FROM Lote l
      INNER JOIN Producto p ON l.producto_id = p.id
      WHERE l.cantidad > 0
      ORDER BY l.fecha_caducidad ASC;
    ''');
    return res.map((m) => Lote.fromMap(m)).toList();
  }

  // Fechas distintas con productos activos por caducar
  Future<List<String>> obtenerFechasConAlertas() async {
    final db = await _db;
    final res = await db.rawQuery('''
      SELECT DISTINCT fecha_caducidad
      FROM Lote
      WHERE cantidad > 0
      ORDER BY fecha_caducidad ASC;
    ''');
    return res.map((r) => r['fecha_caducidad'] as String).toList();
  }

  Future<int> insertarLote(Lote lote) async {
    final db = await _db;
    return await db.insert('Lote', lote.toMap());
  }

  Future<int> descartarLote(int idLote) async {
    final db = await _db;
    return await db.update(
      'Lote',
      {'cantidad': 0.0, 'alarma_activa': 0},
      where: 'id = ?',
      whereArgs: [idLote],
    );
  }

  Future<int> actualizarCantidad(int idLote, double nuevaCantidad) async {
    final db = await _db;
    return await db.update(
      'Lote',
      {
        'cantidad': nuevaCantidad,
        if (nuevaCantidad <= 0) 'alarma_activa': 0,
      },
      where: 'id = ?',
      whereArgs: [idLote],
    );
  }
}

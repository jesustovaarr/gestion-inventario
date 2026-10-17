import 'package:sqflite/sqflite.dart';
import '../../models/historial_compra_model.dart';
import '../../models/tienda_model.dart';
import '../inventario_db.dart';

class CompraDao {
  final Database? _database;

  CompraDao([this._database]);

  Future<Database> get _db async => _database ?? await InventarioDB().database;

  // Registrar una compra y actualizar el inventario
  Future<int> registrarCompra({
    required int productoId,
    required int tiendaId,
    required double cantidad,
    required double precioUnitario,
    required String fechaCompra,
    required String fechaCaducidad,
  }) async {
    final db = await _db;
    return await db.transaction<int>((txn) async {
      // Guardar en Historial_Compras
      final idCompra = await txn.insert('Historial_Compras', {
        'producto_id': productoId,
        'tienda_id': tiendaId,
        'fecha_compra': fechaCompra,
        'cantidad': cantidad,
        'precio_unitario': precioUnitario,
      });

      // Crear lote
      await txn.insert('Lote', {
        'producto_id': productoId,
        'cantidad': cantidad,
        'fecha_caducidad': fechaCaducidad,
        'alarma_activa': 1,
      });

      // Actualizar ultima_tienda_id en Producto
      await txn.update(
        'Producto',
        {'ultima_tienda_id': tiendaId},
        where: 'id = ?',
        whereArgs: [productoId],
      );

      return idCompra;
    });
  }

  // Consulta todas las tiendas donde se ha adquirido un producto
  Future<List<Tienda>> obtenerTiendasPorProducto(int productoId) async {
    final db = await _db;
    final res = await db.rawQuery('''
      SELECT DISTINCT 
        t.id, 
        t.nombre, 
        t.ubicacion, 
        t.tipo_tienda_id,
        tt.nombre AS tipo_tienda_nombre
      FROM Tienda t
      INNER JOIN Tipo_Tienda tt ON t.tipo_tienda_id = tt.id
      INNER JOIN Historial_Compras hc ON t.id = hc.tienda_id
      WHERE hc.producto_id = ?
      ORDER BY t.nombre ASC;
    ''', [productoId]);
    return res.map((m) => Tienda.fromMap(m)).toList();
  }

  // Historial de compras para un producto
  Future<List<HistorialCompra>> obtenerHistorialPorProducto(int productoId) async {
    final db = await _db;
    final res = await db.rawQuery('''
      SELECT 
        hc.*,
        p.nombre AS producto_nombre,
        t.nombre AS tienda_nombre
      FROM Historial_Compras hc
      INNER JOIN Producto p ON hc.producto_id = p.id
      INNER JOIN Tienda t ON hc.tienda_id = t.id
      WHERE hc.producto_id = ?
      ORDER BY hc.fecha_compra DESC, hc.id DESC;
    ''', [productoId]);
    return res.map((m) => HistorialCompra.fromMap(m)).toList();
  }

  // Historial de compras
  Future<List<HistorialCompra>> obtenerHistorialGeneral() async {
    final db = await _db;
    final res = await db.rawQuery('''
      SELECT 
        hc.*,
        p.nombre AS producto_nombre,
        t.nombre AS tienda_nombre
      FROM Historial_Compras hc
      INNER JOIN Producto p ON hc.producto_id = p.id
      INNER JOIN Tienda t ON hc.tienda_id = t.id
      ORDER BY hc.fecha_compra DESC, hc.id DESC;
    ''');
    return res.map((m) => HistorialCompra.fromMap(m)).toList();
  }
}

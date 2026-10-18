import 'package:sqflite/sqflite.dart';

import '../../models/lote_model.dart';
import '../../utils/cantidades.dart';
import '../inventario_db.dart';

class LoteDao {
  final Database? _database;

  LoteDao([this._database]);

  Future<Database> get _db async => _database ?? await InventarioDB().database;

  // Algoritmo FEFO
  // Descuenta stock en cascada a partir del lote activo con la fecha de caducidad mas proxima
  Future<bool> descontarStockFEFO(
    int productoId,
    double cantidadADescontar,
  ) async {
    if (!cantidadValida(cantidadADescontar)) return false;
    final db = await _db;

    return await db.transaction<bool>((txn) async {
      final lotes = await txn.query(
        'Lote',
        where: 'producto_id = ? AND cantidad > 0',
        whereArgs: [productoId],
        orderBy: 'fecha_caducidad ASC, id ASC',
      );
      final hoy = DateTime.now();
      final hoyIso =
          '${hoy.year.toString().padLeft(4, '0')}-${hoy.month.toString().padLeft(2, '0')}-${hoy.day.toString().padLeft(2, '0')}';
      // No consumir mientras haya un lote caducado pendiente de desechar.
      if (lotes.any(
        (l) => (l['fecha_caducidad'] as String).compareTo(hoyIso) < 0,
      )) {
        return false;
      }
      final disponible = lotes.fold<int>(
        0,
        (sum, l) => sum + cantidadEnMilesimas(l['cantidad'] as num),
      );
      int pendiente = cantidadEnMilesimas(cantidadADescontar);
      if (disponible < pendiente) return false;

      for (final row in lotes) {
        if (pendiente == 0) break;
        final idLote = row['id'] as int;
        final cantidadLote = cantidadEnMilesimas(row['cantidad'] as num);
        if (cantidadLote == 0) continue;
        final descontada = cantidadLote < pendiente ? cantidadLote : pendiente;
        final restante = cantidadLote - descontada;
        pendiente -= descontada;
        await txn.insert('Movimiento_Inventario', {
          'producto_id': productoId,
          'lote_id': idLote,
          'tipo': 'consumo',
          'cantidad': descontada / escalaCantidad,
          'fecha': DateTime.now().toIso8601String(),
        });
        await txn.update(
          'Lote',
          {
            'cantidad': restante / escalaCantidad,
            if (restante == 0) 'alarma_activa': 0,
          },
          where: 'id = ?',
          whereArgs: [idLote],
        );
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
    final res = await db.rawQuery(
      '''
      SELECT 
        l.*,
        p.nombre AS producto_nombre,
        p.unidad_medida AS unidad,
        p.imagen AS producto_imagen,
        p.stock_minimo AS stock_minimo,
        p.zona_almacenamiento AS zona_almacenamiento,
        c.nombre AS categoria_nombre,
        (SELECT COALESCE(SUM(l2.cantidad), 0.0) FROM Lote l2 WHERE l2.producto_id = p.id AND l2.cantidad > 0) AS stock_total_producto
      FROM Lote l
      INNER JOIN Producto p ON l.producto_id = p.id
      LEFT JOIN Categoria c ON p.categoria_id = c.id
      WHERE l.cantidad > 0 AND l.fecha_caducidad = ?
      ORDER BY p.nombre ASC;
    ''',
      [fechaIso],
    );
    return res.map((m) => Lote.fromMap(m)).toList();
  }

  // Consulta todos los lotes activos
  Future<List<Lote>> obtenerTodosLotesActivos() async {
    final db = await _db;
    final res = await db.rawQuery('''
      SELECT 
        l.*,
        p.nombre AS producto_nombre,
        p.unidad_medida AS unidad,
        p.imagen AS producto_imagen,
        p.stock_minimo AS stock_minimo,
        p.zona_almacenamiento AS zona_almacenamiento,
        c.nombre AS categoria_nombre,
        (SELECT COALESCE(SUM(l2.cantidad), 0.0) FROM Lote l2 WHERE l2.producto_id = p.id AND l2.cantidad > 0) AS stock_total_producto
      FROM Lote l
      INNER JOIN Producto p ON l.producto_id = p.id
      LEFT JOIN Categoria c ON p.categoria_id = c.id
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

  Future<List<Map<String, Object?>>> obtenerMovimientos(int productoId) async {
    final db = await _db;
    return db.query(
      'Movimiento_Inventario',
      where: 'producto_id = ?',
      whereArgs: [productoId],
      orderBy: 'fecha DESC, id DESC',
    );
  }

  Future<List<Lote>> obtenerLotesPorProducto(int productoId) async {
    final db = await _db;
    final rows = await db.query(
      'Lote',
      where: 'producto_id = ?',
      whereArgs: [productoId],
      orderBy: 'fecha_caducidad ASC, id ASC',
    );
    return rows.map(Lote.fromMap).toList();
  }

  Future<void> editarMovimiento(
    int id, {
    required String tipo,
    required double? cantidad,
    required DateTime fecha,
  }) async {
    if (!['consumo', 'desecho'].contains(tipo) ||
        (tipo == 'consumo' &&
            (cantidad == null || !cantidadValida(cantidad)))) {
      throw ArgumentError(
        'Escribe una cantidad de consumo válida con hasta tres decimales.',
      );
    }
    final db = await _db;
    final changed = await db.update(
      'Movimiento_Inventario',
      {
        'tipo': tipo,
        'cantidad': tipo == 'consumo' ? normalizarCantidad(cantidad!) : null,
        if (tipo == 'consumo') 'cantidad_descartada': null,
        'fecha': fecha.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    if (changed != 1) throw StateError('El movimiento ya no existe.');
  }

  Future<void> eliminarMovimiento(int id) async {
    final db = await _db;
    final changed = await db.delete(
      'Movimiento_Inventario',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (changed != 1) throw StateError('El movimiento ya no existe.');
  }

  Future<int> insertarLote(Lote lote) async {
    final db = await _db;
    if (!cantidadValida(lote.cantidad, permiteCero: true) ||
        !cantidadValida(lote.contenidoEnvase)) {
      throw ArgumentError(
        'La cantidad debe ser válida y tener hasta tres decimales',
      );
    }
    return await db.insert('Lote', {
      ...lote.toMap(),
      'cantidad': normalizarCantidad(lote.cantidad),
    });
  }

  Future<int> descartarLote(int idLote) async {
    final db = await _db;
    return db.transaction<int>((txn) async {
      final rows = await txn.query(
        'Lote',
        where: 'id = ? AND cantidad > 0',
        whereArgs: [idLote],
      );
      if (rows.isEmpty) return 0;
      final lote = rows.first;
      final changed = await txn.update(
        'Lote',
        {'cantidad': 0.0, 'alarma_activa': 0},
        where: 'id = ?',
        whereArgs: [idLote],
      );
      await txn.insert('Movimiento_Inventario', {
        'producto_id': lote['producto_id'],
        'lote_id': idLote,
        'tipo': 'desecho',
        'cantidad': null,
        'cantidad_descartada': normalizarCantidad(lote['cantidad'] as num),
        'fecha': DateTime.now().toIso8601String(),
      });
      return changed;
    });
  }

  Future<int> actualizarFechaCaducidad(int idLote, String fechaIso) async {
    final fecha = DateTime.tryParse(fechaIso);
    if (fecha == null || fecha.toIso8601String().substring(0, 10) != fechaIso) {
      throw ArgumentError('Indica una fecha de caducidad válida.');
    }
    final db = await _db;
    return db.update(
      'Lote',
      {'fecha_caducidad': fechaIso},
      where: 'id = ? AND cantidad > 0',
      whereArgs: [idLote],
    );
  }

  Future<int> actualizarCantidad(int idLote, double nuevaCantidad) async {
    if (!nuevaCantidad.isFinite ||
        nuevaCantidad < 0 ||
        nuevaCantidad > cantidadMaxima) {
      throw ArgumentError('Cantidad inválida');
    }
    nuevaCantidad = normalizarCantidad(nuevaCantidad);
    final db = await _db;
    return await db.update(
      'Lote',
      {'cantidad': nuevaCantidad, if (nuevaCantidad <= 0) 'alarma_activa': 0},
      where: 'id = ?',
      whereArgs: [idLote],
    );
  }

  Future<void> actualizarAlarma(
    int idLote, {
    required int alarmaId,
    required int alarmaActiva,
  }) async {
    final db = await _db;
    await db.update(
      'Lote',
      {'alarma_id': alarmaId, 'alarma_activa': alarmaActiva},
      where: 'id = ?',
      whereArgs: [idLote],
    );
  }

  Future<Lote?> obtenerLotePorId(int idLote) async {
    final db = await _db;
    final res = await db.rawQuery(
      '''
      SELECT 
        l.*,
        p.nombre AS producto_nombre,
        p.unidad_medida AS unidad,
        p.imagen AS producto_imagen
      FROM Lote l
      INNER JOIN Producto p ON l.producto_id = p.id
      WHERE l.id = ?;
    ''',
      [idLote],
    );
    if (res.isEmpty) return null;
    return Lote.fromMap(res.first);
  }

  Future<void> actualizarConfiguracionAlarma(
    int idLote, {
    int? alarmaActiva,
    String? horaAviso,
    String? fechaCaducidad,
  }) async {
    final db = await _db;
    final map = <String, dynamic>{};
    if (alarmaActiva != null) map['alarma_activa'] = alarmaActiva;
    if (horaAviso != null && horaAviso.isNotEmpty) map['hora_aviso'] = horaAviso;
    if (fechaCaducidad != null && fechaCaducidad.isNotEmpty) {
      map['fecha_caducidad'] = fechaCaducidad;
    }
    if (map.isNotEmpty) {
      await db.update(
        'Lote',
        map,
        where: 'id = ?',
        whereArgs: [idLote],
      );
    }
  }
}

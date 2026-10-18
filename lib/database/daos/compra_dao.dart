import 'package:sqflite/sqflite.dart';

import '../../utils/cantidades.dart';
import '../../utils/importes.dart';
import '../../models/compra_model.dart';
import '../../models/historial_compra_model.dart';
import '../../models/tienda_model.dart';
import '../inventario_db.dart';

class CompraDao {
  static const _historialConDatos = '''
    SELECT hc.*, p.nombre AS producto_nombre, p.unidad_medida, p.imagen,
      t.nombre AS tienda_nombre, l.fecha_caducidad
    FROM Historial_Compras hc
    LEFT JOIN Producto p ON hc.producto_id = p.id
    LEFT JOIN Tienda t ON hc.tienda_id = t.id
    LEFT JOIN Lote l ON hc.lote_id = l.id
  ''';
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
    if (!precioUnitario.isFinite ||
        precioUnitario < 0 ||
        precioUnitario > precioMaximoCentavos / 100) {
      throw ArgumentError('Indica un precio válido.');
    }
    final result = await registrarCompraCompleta(
      tiendaId: tiendaId,
      fechaCompra: fechaCompra,
      articulos: [
        ArticuloCompra(
          productoId: productoId,
          cantidad: cantidad,
          precioUnitarioCentavos: (precioUnitario * 100).round(),
          fechaCaducidad: fechaCaducidad,
        ),
      ],
    );
    return result.id;
  }

  Future<CompraGuardada> registrarCompraCompleta({
    required int tiendaId,
    required String fechaCompra,
    required List<ArticuloCompra> articulos,
    bool quitarDelCarrito = false,
  }) async {
    final fecha = _fechaValida(fechaCompra);
    if (fecha == null || articulos.isEmpty) {
      throw ArgumentError('Agrega artículos e indica la fecha de compra.');
    }
    final ids = <int>{};
    for (final item in articulos) {
      final caducidad = _fechaValida(item.fechaCaducidad);
      if (!ids.add(item.productoId) ||
          !cantidadValida(item.cantidad) ||
          (item.presentacion.esEnvase &&
              (item.numeroEnvases < 1 ||
                  item.numeroEnvases > 999999 ||
                  !cantidadValida(item.contenidoEnvase) ||
                  (item.cantidad -
                              normalizarCantidad(
                                item.numeroEnvases * item.contenidoEnvase,
                              ))
                          .abs() >
                      1e-9)) ||
          item.precioUnitarioCentavos < 0 ||
          item.precioUnitarioCentavos > precioMaximoCentavos ||
          caducidad == null ||
          caducidad.isBefore(fecha)) {
        throw ArgumentError(
          'Revisa las cantidades, precios y caducidades de los artículos.',
        );
      }
    }
    final total = articulos.fold<int>(0, (s, a) => s + a.subtotalCentavos);
    final db = await _db;
    return db.transaction((txn) async {
      if ((await txn.query(
        'Tienda',
        where: 'id = ?',
        whereArgs: [tiendaId],
      )).isEmpty) {
        throw StateError('Selecciona una tienda existente.');
      }
      final compraId = await txn.insert('Compra', {
        'tienda_id': tiendaId,
        'fecha_compra': fechaCompra,
        'total_centavos': total,
      });
      for (final item in articulos) {
        if ((await txn.query(
          'Producto',
          where: 'id = ?',
          whereArgs: [item.productoId],
        )).isEmpty) {
          throw StateError('Uno de los productos ya no está en el catálogo.');
        }
        final loteId = await txn.insert('Lote', {
          'producto_id': item.productoId,
          'cantidad': normalizarCantidad(item.cantidad),
          'fecha_caducidad': item.fechaCaducidad,
          'alarma_activa': 1,
          'presentacion': item.presentacion.name,
          'contenido_envase': item.contenidoEnvase,
        });
        await txn.insert('Historial_Compras', {
          'compra_id': compraId,
          'lote_id': loteId,
          'producto_id': item.productoId,
          'tienda_id': tiendaId,
          'fecha_compra': fechaCompra,
          'cantidad': normalizarCantidad(item.cantidad),
          'precio_unitario': item.precioPorUnidadInventario,
          'presentacion': item.presentacion.name,
          'numero_envases': item.numeroEnvases,
          'contenido_envase': item.contenidoEnvase,
          'precio_envase_centavos': item.presentacion.esEnvase
              ? item.precioUnitarioCentavos
              : null,
        });
        await txn.update(
          'Producto',
          {
            'ultima_tienda_id': tiendaId,
            'precio': item.precioPorUnidadInventario,
            'presentacion': item.presentacion.name,
            'contenido_envase': item.contenidoEnvase,
          },
          where: 'id = ?',
          whereArgs: [item.productoId],
        );
        if (quitarDelCarrito) {
          await txn.delete(
            'Carrito',
            where: 'producto_id = ?',
            whereArgs: [item.productoId],
          );
        }
      }
      return CompraGuardada(
        id: compraId,
        totalCentavos: total,
        articulos: articulos.length,
      );
    });
  }

  DateTime? _fechaValida(String value) {
    final date = DateTime.tryParse(value);
    return date != null && date.toIso8601String().substring(0, 10) == value
        ? date
        : null;
  }

  // Consulta todas las tiendas donde se ha adquirido un producto
  Future<List<Tienda>> obtenerTiendasPorProducto(int productoId) async {
    final db = await _db;
    final res = await db.rawQuery(
      '''
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
    ''',
      [productoId],
    );
    return res.map((m) => Tienda.fromMap(m)).toList();
  }

  // Historial de compras para un producto
  Future<List<HistorialCompra>> obtenerHistorialPorProducto(
    int productoId,
  ) async {
    final db = await _db;
    final res = await db.rawQuery(
      '''$_historialConDatos
      WHERE hc.producto_id = ?
      ORDER BY hc.fecha_compra DESC, hc.id DESC;
    ''',
      [productoId],
    );
    return res.map((m) => HistorialCompra.fromMap(m)).toList();
  }

  // Historial de compras
  Future<List<HistorialCompra>> obtenerHistorialGeneral() async {
    final db = await _db;
    final res = await db.rawQuery('''$_historialConDatos
      ORDER BY hc.fecha_compra DESC, hc.id DESC;
    ''');
    return res.map((m) => HistorialCompra.fromMap(m)).toList();
  }

  /// Borra el recibo y sus registros históricos, sin revertir las existencias.
  Future<void> eliminarDelHistorial(CompraEnHistorial compra) async {
    final db = await _db;
    await db.transaction((txn) async {
      if (compra.id != null) {
        await txn.delete(
          'Historial_Compras',
          where: 'compra_id = ?',
          whereArgs: [compra.id],
        );
        final cambios = await txn.delete(
          'Compra',
          where: 'id = ?',
          whereArgs: [compra.id],
        );
        if (cambios != 1) throw StateError('La compra ya no existe.');
      } else {
        // Los registros anteriores a los recibos se muestran como compras individuales.
        if (compra.articulos.length != 1 ||
            compra.articulos.single.id == null) {
          throw ArgumentError('No se pudo identificar el registro de compra.');
        }
        final id = compra.articulos.single.id!;
        final registros = await txn.query(
          'Historial_Compras',
          where: 'id = ?',
          whereArgs: [id],
        );
        if (registros.isEmpty || registros.single['compra_id'] != null) {
          throw StateError('El registro de compra ya no está disponible.');
        }
        await txn.delete('Historial_Compras', where: 'id = ?', whereArgs: [id]);
      }
    });
  }

  Future<List<CompraEnHistorial>> obtenerCompras() async {
    final db = await _db;
    return db.transaction((txn) async {
      final recibos = await txn.rawQuery('''
        SELECT c.*, t.nombre AS tienda_nombre FROM Compra c
        LEFT JOIN Tienda t ON c.tienda_id = t.id
        ORDER BY c.fecha_compra DESC, c.id DESC
      ''');
      final registros = (await txn.rawQuery('''$_historialConDatos
        ORDER BY hc.fecha_compra DESC, hc.id DESC
      ''')).map(HistorialCompra.fromMap).toList();
      final porCompra = <int, List<HistorialCompra>>{};
      for (final registro in registros) {
        if (registro.compraId != null) {
          porCompra.putIfAbsent(registro.compraId!, () => []).add(registro);
        }
      }
      final compras = [
        for (final recibo in recibos)
          CompraEnHistorial(
            clave: 'compra-${recibo['id']}',
            id: recibo['id'] as int,
            tiendaId: recibo['tienda_id'] as int,
            tiendaNombre:
                recibo['tienda_nombre'] as String? ?? 'Tienda no disponible',
            fechaCompra: recibo['fecha_compra'] as String,
            totalCentavos: (recibo['total_centavos'] as num).toInt(),
            articulos: porCompra[recibo['id']] ?? [],
          ),
        // Los registros antiguos no permiten saber cuáles formaban una compra.
        // Mantenerlos separados evita inventar recibos o duplicar artículos.
        for (final registro in registros.where((r) => r.compraId == null))
          CompraEnHistorial(
            clave: 'registro-${registro.id}',
            tiendaId: registro.tiendaId,
            tiendaNombre: registro.tiendaNombre ?? 'Tienda no disponible',
            fechaCompra: registro.fechaCompra,
            totalCentavos: registro.subtotalCentavos,
            articulos: [registro],
          ),
      ];
      compras.sort((a, b) {
        final fecha = b.fechaCompra.compareTo(a.fechaCompra);
        return fecha != 0
            ? fecha
            : (b.id ?? b.articulos.first.id ?? 0).compareTo(
                a.id ?? a.articulos.first.id ?? 0,
              );
      });
      return compras;
    });
  }
}
